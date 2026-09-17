# TechTalk: Autoboxing and the Integer Cache[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-Autoboxing-and-the-Integer-Cache/README.md)

The JDK already does interning, quietly, for a very small range of numbers. Knowing where that range ends explains a bug that everybody meets once, and a memory problem that almost nobody looks for.

This is the direct continuation of the [Interning](../TechTalk-Interning) talk.

 - [Introduction](#introduction)
 - [The 128 problem](#the-128-problem)
 - [Where the cache lives](#where-the-cache-lives)
 - [The expensive part: the garbage nobody sees](#the-expensive-part-the-garbage-nobody-sees)
 - [The NullPointerException with no null in sight](#the-nullpointerexception-with-no-null-in-sight)
 - [Extending the cache](#extending-the-cache)
 - [Good practices](#good-practices)
 - [Appendix: what is cached and what is not](#appendix-what-is-cached-and-what-is-not)

<br/>

## Introduction

In the [Interning](../TechTalk-Interning) talk we built an `Interner` to reuse instances of immutable objects and stop wasting memory on 153.000 copies of the same String.

The interesting thing is that **the JDK does exactly that**, by itself, for boxed integers. It just does it for a range so small that most of us never notice - until the day the range runs out, and then it produces two very different problems: a comparison that stops working, and a lot of garbage.

## The 128 problem

The classic, and it is worth running it rather than reading it:

```java
Integer a = 127;
Integer b = 127;
System.out.println(a == b);      // true

Integer c = 128;
Integer d = 128;
System.out.println(c == d);      // false
```

Same code, same types, different result. The number changed and the semantics of `==` changed with it.

The explanation is one method. When we write `Integer a = 127`, the compiler does not create an object: it calls

```java
Integer.valueOf(127)
```

and `valueOf` has a cache:

```java
public static Integer valueOf(int i) {
    if (i >= IntegerCache.low && i <= IntegerCache.high)
        return IntegerCache.cache[i + (-IntegerCache.low)];   // the SAME instance, always
    return new Integer(i);                                     // a new one, every time
}
```

The default range is **-128 to 127**. Inside it, `valueOf` returns a shared instance - it is an interner, with a pre-filled map and a fixed range. Outside it, a new object on every call.

So `a == b` is true for 127 because they are literally the same object, and false for 128 because they are two objects with the same value. `==` on a boxed type compares **references**, and always did. The cache is what makes it look like it compares values, which is far worse than if it never worked at all: **the bug hides until production has numbers bigger than 127**.

The rule is not "be careful with 128". The rule is:

> **never compare boxed types with `==`. Use `equals`, or unbox explicitly**

```java
Integer c = 128, d = 128;
c.equals(d)                  // true
c.intValue() == d.intValue() // true
```

## Where the cache lives

`IntegerCache` is a static inner class that is initialised once, when `Integer` is first loaded. It builds an array of 256 `Integer` objects and keeps it for the life of the JVM.

Which means the cache is not free either: it is 256 objects allocated at startup whether we use them or not. It is simply a very good trade, because those values are the ones every loop counter, every flag and every small identifier uses.

## The expensive part: the garbage nobody sees

The `==` bug is famous. This one costs much more and nobody talks about it.

```java
Long sum = 0L;                     // Long, not long
for (long i = 0; i < 10_000_000L; i++) {
    sum += i;
}
```

That loop looks like arithmetic. What it actually does, ten million times, is:

1. unbox `sum` to a `long`
2. add
3. **box the result into a new `Long`** - outside the cache range, so a new object

**Ten million objects allocated** to add up ten million numbers. The result is correct, the code reads fine, and the profiler shows an allocation rate that makes no sense for a loop that "does not create anything".

Change one character - `Long` to `long` - and the allocation goes to zero.

The same thing, less obviously, in collections:

```java
Map<Integer, Car> carsById = new HashMap<>();
carsById.get(1234567);         // boxes 1234567 on EVERY call
```

Every lookup with an `int` key creates an `Integer` above 127 that lives just long enough to compute a hash and be thrown away. In a service doing thousands of lookups per second, that is a constant stream of short-lived garbage. It does not leak - the young generation handles it - but it is pure waste, and it raises the GC frequency for nothing.

And the storage side is worse than it looks:

| | Memory for 1.000.000 values |
|---|---|
| `int[]` | ~4 MB |
| `List<Integer>` | ~20 MB |

Each `Integer` is an object: header, the `int` field, alignment padding - roughly 16 bytes - plus the reference that points at it. **Five times the memory, and the values are scattered over the heap instead of being contiguous**, which also costs cache misses on every traversal.

This is the same problem as the Interning talk, in a different disguise: many instances holding few distinct values.

## The NullPointerException with no null in sight

Unboxing has its own trap, and it produces the most confusing NPE in Java.

```java
Map<String, Integer> stock = new HashMap<>();
int available = stock.get("ABC123");     // NPE if the key is not there
```

`get` returns `null`, and the assignment to `int` calls `null.intValue()`. The stack trace points at a line with no visible dereference.

The nastier version, because the code looks completely safe:

```java
Integer discount = findDiscount(customer);    // may return null
int result = flag ? 0 : discount;             // NPE when flag is TRUE
```

The ternary operator forces both branches to a common type. Since one branch is `int`, **the other is unboxed - even when it is not the branch being taken**. The NPE happens on the path where `discount` is never used.

Rule of thumb: **every unboxing is a potential NPE**, and the compiler will not warn about any of them.

## Extending the cache

The upper bound is configurable:

```shell
-XX:AutoBoxCacheMax=10000
# or
-Djava.lang.Integer.IntegerCache.high=10000
```

This raises the cached range to -128..10000. It genuinely helps when the application handles a bounded set of small identifiers - status codes, type ids, a catalogue of a few thousand entries - because those boxes stop being allocated entirely.

Two warnings before touching it:

- it only affects **`Integer`**. Not `Long`, not `Short`, not `Byte`
- it makes `==` "work" for a wider range, which **hides the bug even better** on the machine where the flag is set, and brings it back on the one where it is not

So it is a memory optimisation, never a correctness one. And it is the same decision as in the Interning talk: we are choosing to hold instances forever in exchange for not allocating them repeatedly. Set the bound to what the domain actually needs, not to a round number.

## Good practices

### AntiPattern: `==` on boxed types

Already covered, but it earns the label because of how it fails: it works in the tests, with small numbers, and breaks with real data.

The same applies to `Long` ids coming from a database. A sequence starts at 1 and everything compares fine for the first 127 rows.

### Use primitives in anything hot

```java
// generates garbage
List<Integer> ids = new ArrayList<>();

// does not
int[] ids = new int[n];
IntStream.range(0, n).sum();          // primitive stream, no boxing
```

`IntStream`, `LongStream` and `DoubleStream` exist exactly for this. `stream().map(...)` on a `List<Integer>` boxes at every step; `mapToInt` gets out of the boxed world and stays out.

For maps and lists of primitives with real volume, the primitive collections of Eclipse Collections or fastutil store `int[]` internally and remove the problem entirely.

### Careful with the accumulator type

```java
long total = 0;                       // good
Long total = 0L;                      // one object per iteration
```

The most expensive typo in Java is a capital L.

### Do not use `new Integer(...)`

Deprecated for removal since Java 9. It always creates an object, bypassing the cache, and it is the one way to get `Integer a = new Integer(127); a == 127` to be false for the "cached" range too. Always `valueOf`, or just let autoboxing call it.

### Measure before optimising

The way to know whether any of this matters in our application is not to read about it, it is to look:

```shell
jcmd <pid> GC.class_histogram | head -20
```

If `java.lang.Integer` or `java.lang.Long` appear near the top with millions of instances, this talk applies. If they do not, changing types will buy nothing and will make the code worse.

For the allocation rate rather than the live set, a Flight Recorder capture with `settings=profile` shows which call sites are allocating, which points straight at the loop responsible.

## Appendix: what is cached and what is not

| Type | Cached by `valueOf` |
|---|---|
| `Boolean` | always - there are only two |
| `Byte` | the whole range, -128..127 |
| `Short` | -128..127 |
| `Integer` | -128..127, upper bound configurable |
| `Long` | -128..127, **not** configurable |
| `Character` | 0..127 |
| `Float`, `Double` | **never** |

`Float` and `Double` are not cached at all: every boxing allocates. Which makes a `Map<Double, X>` or a `List<Double>` in a hot path considerably worse than the `Integer` version, and it is the one people are least likely to suspect.
