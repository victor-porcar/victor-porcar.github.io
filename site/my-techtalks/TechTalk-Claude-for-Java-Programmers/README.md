# TechTalk: Introduction to Claude for Java Programmers[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-Claude-for-Java-Programmers/README.md)

This is a practical introduction to [Claude](https://www.anthropic.com/claude) aimed at senior Java developers, with two goals: using it as a daily tool and calling it from our own Java code.

The official documentation is [here](https://docs.claude.com) and the Java SDK [here](https://github.com/anthropics/anthropic-sdk-java)

 - [Introduction](#introduction)
 - [Part 1: Claude as a daily tool](#part-1-claude-as-a-daily-tool)
     - [CLAUDE.md](#claudemd)
     - [What it is good at and what it is not](#what-it-is-good-at-and-what-it-is-not)
 - [Part 2: Calling Claude from Java](#part-2-calling-claude-from-java)
     - [Dependency and client](#dependency-and-client)
     - [The first request](#the-first-request)
     - [The API is stateless](#the-api-is-stateless)
     - [Streaming](#streaming)
     - [Thinking and effort](#thinking-and-effort)
     - [Prompt caching](#prompt-caching)
     - [Tool use: letting Claude call our code](#tool-use-letting-claude-call-our-code)
     - [Structured output](#structured-output)
 - [Tokens and cost](#tokens-and-cost)
 - [Good practices](#good-practices)
 - [Appendix: current models](#appendix-current-models)

<br/>

## Introduction

A Large Language Model is, from our point of view as engineers, a **stateless function**: text in, text out. Everything else - chat history, memory, agents - is built on top of that function by resending context.

This matters more than it looks, and we will come back to it.

There are two different ways a Java developer meets Claude, and they are often confused:

*   **as a tool**: we use it to read, write and refactor code in our own projects

*   **as a dependency**: we call it from our services, the same way we call any other HTTP API, to solve a problem inside our business logic

They require completely different skills. Let's look at both.

## Part 1: Claude as a daily tool

[Claude Code](https://docs.claude.com/en/docs/claude-code) is a CLI that runs in the terminal, inside the project directory. It reads files, runs commands, edits code and runs the build.

```shell
npm install -g @anthropic-ai/claude-code
cd my-spring-boot-project
claude
```

The important part is not the installation, it is the **working method**. The usual mistake is to treat it as a search engine and ask _"how do I do X in Spring"_. That is a waste: it has our code in front of it.

A much better use is to give it a task with a **verifiable outcome**:

*   _"this test fails, find out why"_ → it can run the test and read the stack trace

*   _"extract the retry logic of this class into its own component and keep the tests green"_ → it can run `mvn test` and check itself

*   _"explain how a request flows from the controller to the repository in this module"_ → it can read the whole call chain, which is much faster than us doing it by hand in a codebase we don't know

### CLAUDE.md

A `CLAUDE.md` file in the root of the repository is read automatically and injected in every conversation. This is the single highest-value thing to set up, because it removes the need to repeat the same instructions over and over.

It should contain what is **not** obvious from the code:

```markdown
## Build
mvn clean verify -DskipITs

## Conventions
- Java 17, Spring Boot 3
- Never use field injection, always constructor injection
- Integration tests use Testcontainers, they are slow: run them only when asked
- Do not add comments unless the logic is genuinely not obvious
```

Rule of thumb: every time we find ourselves correcting the same thing twice, that correction belongs in `CLAUDE.md`

### What it is good at and what it is not

Being honest about this saves a lot of frustration.

It is **good** at:

*   navigating and explaining unknown code, which is most of our job in a legacy project

*   mechanical refactors across many files

*   writing tests for existing code

*   the boring first draft: DTOs, mappers, builders, configuration

It is **weak** at:

*   problems where the definition of _correct_ lives only in someone's head, not in the code or in a test

*   deep architectural decisions with trade-offs that depend on context it cannot see, such as the roadmap or the team

*   anything where we cannot verify the answer. **If we cannot check it, we cannot trust it**

That last one is the real rule. The productivity gain comes from tasks with a **fast feedback loop** - a compiler, a test, a running service. Without a feedback loop we are just reviewing text, and reviewing text is slower than writing it.

## Part 2: Calling Claude from Java

Now the other side: Claude as a dependency of our service.

### Dependency and client

```xml
<dependency>
    <groupId>com.anthropic</groupId>
    <artifactId>anthropic-java</artifactId>
    <version>2.34.0</version>
</dependency>
```

```java
// reads the ANTHROPIC_API_KEY environment variable
AnthropicClient client = AnthropicOkHttpClient.fromEnv();
```

The client is **thread safe and expensive to create**: build it once and inject it, exactly as we would do with a `RestTemplate` or a `WebClient`.

```java
@Configuration
public class ClaudeConfig {

    @Bean
    public AnthropicClient anthropicClient() {
        return AnthropicOkHttpClient.fromEnv();
    }
}
```

### The first request

```java
MessageCreateParams params = MessageCreateParams.builder()
        .model("claude-opus-5")
        .maxTokens(16000L)
        .system("You are a helpful assistant for a car rental company.")
        .addUserMessage("Summarize this incident report in one sentence: ...")
        .build();

Message response = client.messages().create(params);

response.content().stream()
        .flatMap(block -> block.text().stream())
        .forEach(textBlock -> System.out.println(textBlock.text()));
```

Three things deserve attention here.

**`system`** is where the instructions go: role, rules, output format. Not in the user message. It stays stable across requests, and as we will see, that is what makes caching work.

**`maxTokens`** is a **hard ceiling on the response**, not a target. If the answer needs more room than we gave it, it is cut off mid sentence and we have to call again. Do not lowball it: 16000 is a sane default for a non streaming call.

**`content()` is a list of blocks**, not a String. A response may contain text blocks, thinking blocks and tool use blocks. This is why we flat map instead of calling something like `getText()`.

### The API is stateless

This is the part that surprises everybody coming from a normal REST API.

There is **no session, no conversation id, no server side history**. If we want a second turn, we resend everything:

```java
MessageCreateParams secondTurn = MessageCreateParams.builder()
        .model("claude-opus-5")
        .maxTokens(16000L)
        .system(SYSTEM_PROMPT)
        .addUserMessage("Summarize this incident report: ...")   // turn 1
        .addAssistantMessage(previousAnswer)                     // turn 1 response
        .addUserMessage("Now list the parties involved")         // turn 2
        .build();
```

Two consequences we have to design for:

*   the conversation **grows on every turn**, and so does the cost of every turn, because we pay for the input we resend

*   the history lives in **our** process. It is our problem to store it, trim it and decide what to keep

So a long conversation is not free. Which brings us to caching, but first, two things that change how the call behaves.

### Streaming

A non streaming call returns when the whole answer is ready, which can be tens of seconds. For anything user facing, or for any request with a large `maxTokens`, stream it:

```java
MessageCreateParams params = MessageCreateParams.builder()
        .model("claude-opus-5")
        .maxTokens(64000L)
        .addUserMessage("Write the migration plan for this module")
        .build();

try (StreamResponse<RawMessageStreamEvent> streamResponse = client.messages().createStreaming(params)) {
    streamResponse.stream()
            .flatMap(event -> event.contentBlockDelta().stream())
            .flatMap(deltaEvent -> deltaEvent.delta().text().stream())
            .forEach(textDelta -> System.out.print(textDelta.text()));
}
```

Note the **try with resources**: the stream holds an HTTP connection and it has to be closed.

Streaming is not only a UX decision. Very large responses **require** it, because a single non streaming HTTP call would hit the client timeout before finishing.

### Thinking and effort

Current models can reason before answering. This is not a prompt trick, it is a request parameter:

```java
MessageCreateParams params = MessageCreateParams.builder()
        .model("claude-opus-5")
        .maxTokens(16000L)
        .thinking(ThinkingConfigAdaptive.builder().build())
        .outputConfig(OutputConfig.builder()
                .effort(OutputConfig.Effort.HIGH)   // LOW, MEDIUM, HIGH, XHIGH, MAX
                .build())
        .addUserMessage("Why does this deadlock? ...")
        .build();
```

**Adaptive** means the model decides by itself how much to think, per request. We don't set a budget.

**Effort** is the knob that matters for cost. It trades thoroughness against tokens:

*   **LOW** for simple, high volume, latency sensitive work: classification, extraction, routing

*   **HIGH** (the default) for most things

*   **MAX** only when being right matters more than what it costs

Rule of thumb: tune effort **per use case**, not globally, and measure before raising it. A cheaper request that needs three retries to be useful is not cheaper.

### Prompt caching

Remember that the whole context travels on every request. If our system prompt is a 30 page policy document, we are paying to send those 30 pages every single time.

Caching fixes exactly that:

```java
.systemOfTextBlockParams(List.of(
        TextBlockParam.builder()
                .text(longPolicyDocument)
                .cacheControl(CacheControlEphemeral.builder()
                        .ttl(CacheControlEphemeral.Ttl.TTL_1H)
                        .build())
                .build()))
```

The mechanism is a **prefix match**, and this is the only thing to really understand about it:

> the cache matches from the beginning of the request. **Any byte that changes, invalidates everything after it**

The order is `tools` → `system` → `messages`. So the design rule follows directly:

*   put **stable** content first: the frozen system prompt, a deterministic tool list

*   put **volatile** content last: the user question, timestamps, request ids

The classic mistake is a `LocalDateTime.now()` or a non deterministic JSON serialization inside the system prompt. It changes on every call, the prefix never matches, and the cache silently does nothing. Nothing fails, we just pay full price forever.

Which is why this has to be **verified, not assumed**:

```java
Message response = client.messages().create(params);

log.info("cache write={} read={} input={}",
        response.usage().cacheCreationInputTokens(),
        response.usage().cacheReadInputTokens(),
        response.usage().inputTokens());
```

If `cacheReadInputTokens` is zero across repeated calls, there is a silent invalidator in the prefix.

### Tool use: letting Claude call our code

This is the feature that turns a text generator into something useful inside a service. We declare methods it may call, and it decides when to call them.

The flow is a loop: the model answers with a _tool use_ block instead of text, we execute it, we send the result back, it continues. The SDK can drive that loop for us.

A tool is a class with a description and an execution:

```java
@JsonClassDescription("Get the rental status of a car given its plate number")
static class GetCarStatus implements Supplier<String> {

    @JsonPropertyDescription("The plate number, e.g. 1234ABC")
    public String plate;

    @Override
    public String get() {
        return carService.findStatusByPlate(plate);  // our own business logic
    }
}
```

```java
BetaToolRunner toolRunner = client.beta().messages().toolRunner(
        MessageCreateParams.builder()
                .model("claude-opus-5")
                .maxTokens(16000L)
                .putAdditionalHeader("anthropic-beta", "structured-outputs-2025-11-13")
                .addTool(GetCarStatus.class)
                .addUserMessage("Is the car 1234ABC available?")
                .build());

for (BetaMessage message : toolRunner) {
    log.debug("turn: {}", message);
}
```

The description is **not documentation, it is the interface contract**. The model chooses the tool by reading that text and nothing else. A vague description means a tool that is called when it shouldn't be, or never called at all. Treat those strings with the same care as a public API signature.

And a warning that costs people a whole afternoon: **a tool executes real code**. If we expose a tool that deletes rentals, sooner or later it will be called. Tools that write should be behind a confirmation, exactly as we would design any other dangerous endpoint.

### Structured output

Most of the time we don't want prose, we want an object. Parsing free text with regular expressions is not an option in production.

The SDK derives the JSON schema from our own types and returns them typed:

```java
record Party(String name, String role) {}
record IncidentReport(String summary, List<Party> parties, boolean requiresLegalReview) {}

StructuredMessageCreateParams<IncidentReport> params = MessageCreateParams.builder()
        .model("claude-opus-5")
        .maxTokens(16000L)
        .outputConfig(IncidentReport.class)
        .addUserMessage("Extract the structured data from this report: ...")
        .build();

client.messages().create(params).content().stream()
        .flatMap(block -> block.text().stream())
        .forEach(typed -> {
            IncidentReport report = typed.text();   // typed, not String
            log.info("legal review required: {}", report.requiresLegalReview());
        });
```

No manual schema, no manual parsing, no _"please answer only with JSON"_ in the prompt.

## Tokens and cost

A **token** is roughly 3 or 4 characters. Input and output are billed separately, per million tokens, and **output is five times more expensive than input**.

| Model | Context | Input $/1M | Output $/1M |
|---|---|---|---|
| Claude Opus 5 | 1M | $5.00 | $25.00 |
| Claude Sonnet 5 | 1M | $2.00 | $10.00 |
| Claude Haiku 4.5 | 200K | $1.00 | $5.00 |

_(rates at the time of writing, check the [pricing page](https://www.anthropic.com/pricing))_

Before estimating, we can count exactly, without spending anything on generation:

```java
long tokens = client.messages().countTokens(
        MessageCountTokensParams.builder()
                .model("claude-opus-5")
                .addUserMessage(theDocument)
                .build()
).inputTokens();
```

Never estimate tokens by counting characters or by using a tokenizer from another vendor. Different models tokenize differently.

The order in which to attack cost, if it becomes a problem:

1.  **caching** first: it is free, it changes nothing about quality

2.  **input hygiene**: are we really sending that entire document, or only the part that matters?

3.  **effort**: lower it per use case and measure whether quality holds

4.  **a smaller model**, but only after the three above, and only for the parts that tolerate it

## Good practices

### Never truncate the input silently

If a document does not fit, chunking or summarizing are design decisions. Cutting it at N characters and hoping is not. We get an answer that looks perfectly confident and is based on half the document.

### Don't build a retry loop

The SDK already retries connection errors, 429 and 5xx, twice by default. Wrapping it in our own loop means retries multiply and we hit the rate limit harder.

```java
AnthropicClient client = AnthropicOkHttpClient.builder()
        .fromEnv()
        .maxRetries(3)
        .timeout(Duration.ofMinutes(5))
        .build();
```

### AntiPattern: catching one broad exception

Avoid this:

```java
try {
    client.messages().create(params);
} catch (AnthropicServiceException e) {
    log.error("Claude failed", e);
    return fallback();
}
```

It treats a rate limit, which we should retry or queue, the same as a malformed request, which will fail identically forever. Catch a chain, most specific first:

```java
try {
    return client.messages().create(params);
} catch (NotFoundException e) {
    throw new ModelNotAvailableException("Unknown model: " + model, e);
} catch (RateLimitException e) {
    throw new ClaudeOverloadedException("Rate limited, retry later", e);
} catch (AnthropicServiceException e) {
    throw new ClaudeRequestException("Request rejected: " + e.errorType(), e);
}
```

Same rule as always: do not log and throw, wrap in an exception with semantic meaning and let the caller decide.

### Parse tool input as JSON, never with string matching

The arguments a model produces are JSON, and its escaping may vary between models and versions. `input.contains("\"plate\"")` works today and breaks silently the day we change the model.

### Log the usage, always

```java
log.info("model={} in={} out={} cacheRead={}",
        params.model(), response.usage().inputTokens(),
        response.usage().outputTokens(), response.usage().cacheReadInputTokens());
```

This is the equivalent of one summary log line per request, as described in the [Logging Policy](../TechTalk-Logging-Policy) talk. Without it, the first sign that something is wrong is the invoice.

### Treat the model as a remote dependency, because it is

It is slow, it can rate limit us, it can be temporarily unavailable, it costs money per call, and **it is not deterministic**: the same input may produce a different output.

That last point is the only genuinely new one. Everything else we already know how to handle - timeouts, circuit breakers, bulkheads, budgets. The non determinism is what forces the real design rule of this whole talk:

> **design the system so that a wrong answer is detectable and recoverable**

Validate the structured output against our own rules. Keep destructive tools behind confirmation. Where correctness is critical, make the model propose and a human, or a test, dispose.

## Appendix: current models

*   **Claude Opus 5** (`claude-opus-5`) - the default choice. Best for code, reasoning and agentic work

*   **Claude Sonnet 5** (`claude-sonnet-5`) - cheaper, for high volume work that does not need the full depth

*   **Claude Haiku 4.5** (`claude-haiku-4-5`) - the fastest and cheapest, for classification, routing and simple extraction

Use the exact id strings, without appending any date suffix. The list of available models and their capabilities can also be queried at runtime:

```java
client.models().list().data()
        .forEach(model -> log.info("{} -> {}", model.id(), model.displayName()));
```
