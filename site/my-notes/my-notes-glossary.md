### Glossary [<img align="right" src="../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-notes/my-notes-glossary.md)

Vocabulario de proyecto y de industria. Las dos primeras secciones son terminología de trabajo en español; el resto son términos estándar que aparecen en cualquier conversación de arquitectura.

---


#### Terminología de proyecto

##### QCC 
Quien - Como - Cuando

##### EAC - EFC
Estado Actual - Estado Futuro

##### mejora / peora / defecto
No usar defecto por "defecto", siempre es mejor "mejora"

##### KTP = Handover
Knowledge Transfer Process

##### Alcance = Scope
Establecer que entra y que no entra

*Queda fuera del alcance....*

##### Analisis de Impacto
Ver que supone una ampliacion de un proyecto existente

---

#### Conceptos

* KTP (Knowledge Transfer Process)	
* Alcance = scope del proyecto	definir lo que entra en el trabajo acordado y lo que queda fuera
* Puesta en Marcha = release	
* Baseline = version	
* Test unitario  / Pruebas de Regresión	
* Plan de pruebas	
* Plan de Supervision	
* Mejora / Peora	
* EAC / EFC	
* tablas maestras	
* prefijo de la app en nombre de tablas,…	Asi se evitan colisiones de nombre en las queries entre distintos esquemas, bbdd..
* erwin/powerdesigner/ e/R studio	herramientas lideres de modelado de datos
* tener caudal	
* PostgreSQL  / oracle / mysql / h2	RDBMS mas populares
* regla 80/20	
* crear FK  y deshabilitarla	en general va bien crear FK, pero a veces no conviene o no se quiere, pero en este caso es mejor crearla y desahibilitarla ¿Por qué? Porque le da informacion a oracle y es MAS RAPIDO (comprobado por pruebas realizadas)
* plano (conceptual / logico…)	diagrama
* pctree,initran	parametros de una tabla
* estrategia espejo en tablas	se trata de tener dos tablas espejo y se va cambiando el sinonimo para evitar problemas de indisponibilidad por actualizacion refresco.
* defecto	error 
* OID / OHS (balanceo)	
* internet of things	
* aws = amazon web services	
* docker architecture	
* tamaño A3, A4	formula matematica
* algoritmo de TOMASULO	para  procesadores 
* informe AWR de performance	
* magnitudes de carga "normal", que nodos de WebLogic y cuanta memoria hace falta para atender n peticiones simultaneas "normalitas", cuello de la * BBDD?...	
* Arquitectura tipica de una aplicación web, por ejemplo teletienda, DMZ, nodos, potencia de cada nodo, etc…	
* corporate governance -> subtipo = IT Governance -> subtipo = SOA governance	
* HTML 5 y websocket 	
 
* JSON	
* QCC	
* 24x7 QoS, el portal es 24x7 alta disponibilidad	
* batch vs web service para enviar datos: el batch tiene la ventaja que se puede relanzar	
* cuando se utilizan dates, es mejor calcularla y pasarla a las queries desde java o en la propia query como sysdate ?	
* model (oracle sql stament), muy potente!!!	
* SQL Antipatterns (libro de Bill Karwin)	
* update or insert  comando muy utilizado se puede hacer en oracle con merge (ConstantesDAO.INCREMENTA_NUMERO_ACCESOS_DENEGADOS)	
* aprovisionar	
* si una imagen vale mas que mil palabras, una animacion vale mas que mil imágenes	
* Agnosticismo, ser agnostico con respecto a una tecnologia	
* blindaje	
* propietario del portal	
* tornillo	
* Coordinador Proyecto (CP)	
* Gestion de la demanda	concepto de ITIL
* Arquitectura de datos vs Arquitectura de informacion vs Arquitectura Empresarial	
* Model Driven Architecture (MDA)	
* Preguntas Java Companion( 400 ? Lineas)	
* spin-off 	un proyecto nacido como extensión de otro anterior, o más aún de una empresa nacida a partir de otra mediante la separación de una división subsidiaria
* KPI (key performance indicator), pueden seguir el criterio SMART  (Specific , Measurable, Achievable, Relevant, Realistic, Time-bound)	 is a type of performance measurement. 
* JEE6 (JAX-RS)….	
* jQuery	
* Angular	
* CSS3	
* HTML 5 y websocket 	
* Mercadona como empresa	
* Infraestructura de Mercadona	
* Ciclo de vida Evolutivos Mercadona	
* Arquitectura Empresarial Mercadona (5 Capas)	
* WAF	
* IPS	(cagada), si hay rangos y un de los extremos es NULL blindar siempre esto con una fecha extrema (01/01/1999)
* Funciones Analiticas	
* Cuidado con operaciones con dates 	
* Cuidado con tablas vacias	de lo contrario oracle hace lo que quiere y pueden haber problemas
* commits siempre uno y al final de todo	
* las queries siempre con un order by, 	
* solucion estrategica vs táctica	
* CMMI	
* meeting minutes	
* book of work	
* Introscope	
* Axway Orquestador	
* DMZ	
* CEH (Certified Ethical Hacking)	
* Sistemas CRM (Customer Relationship Management) y ERP (Enterprise Resource Planning)	
* BPM vs ARIS ??	
* taxonomia	clasificacion en base a un criterio, por ejemplo en caso de Sistemas Operativos: -SO monolíticos -SO estructurados:     ● SO multinivel (por capas o jerárquico)     ● SO con micronúcleo (modelo cliente/servidor)
* tabla maestra	
* "cross"	que sirve a muchos (o todos) los departamentos, etc…
* Modelo de datos	asi llaman en Mercadona a un schema de la bbdd
* centro	Tienda o almacen
* silo	
* prescribir  / prescripción	
* pass through	
* abordar	
* encajar	
* alcance = scope del proyecto	
* fasear	
* 
* negocio dice lo que hace informatica y no al reves	
* rfc	
* circuito de pagar	
* PF=PA=PI 	
* correctivo / evolutivo 	
* los parametros con get van protegidos con HTTPS	
* sql profile

---

#### Requisitos no funcionales

##### [-Non-Functional Requirements=Service Level Agreement=quality of service (QoS)](https://en.wikipedia.org/wiki/Non-functional_requirement)  
*   [Functional Requirements vs Non Functional Requirements](https://www.guru99.com/functional-vs-non-functional-requirements.html)
*   [Architecting For The -ilities](https://towardsdatascience.com/architecting-for-the-ilities-6fae9d00bf6b)
*   [Non-Functional Requirements from SCEA](https://www.informit.com/articles/article.aspx?p=29030&seqNum=5)  
    - Performance: measured in terms of response time for a given screen transaction per user. In addition to response time, performance can also be measured in transaction throughput, which is the number of transactions in a given time period, usually one second.  
    
    - Scalability: is the ability to support the required quality of service as the system load increases without changing the system. A system can be considered scalable if, as the load increases, the system still responds within the acceptable limits.  
    
    - Reliability: ensures the integrity and consistency of the application and all its transactions. As the load increases on your system, your system must continue to process requests and handle transactions as accurately as it did before the load increased. Reliability can have a negative impact on scalability.  
    
    - Availability: ensures that a service/resource is always accessible. Reliability can contribute to availability, but availability can be achieved even if components fail (24x7) 
    
    - Extensibility: is the ability to add additional functionality or modify existing functionality without impacting existing system functionality.  
    
    - Maintainability: is the ability to correct flaws in the existing functionality without impacting other components of the system.  
    
    - Manageability: is the ability to manage the system to ensure the continued health of a system with respect to scalability, reliability, availability, performance, and security.  
    
    - Security: is the ability to ensure that the system cannot be compromised. Security is by far the most difficult systemic quality to address. Security includes not only issues of confidentiality and integrity, but also relates to Denial-of-Service (DoS) attacks that impact availability.

---

#### Fiabilidad y nivel de servicio

| Término | Qué es |
|---|---|
| **SLI** (Service Level Indicator) | La **medida**: latencia p99, tasa de error, disponibilidad. Un número que sale de los datos |
| **SLO** (Service Level Objective) | El **objetivo interno** sobre ese indicador: "p99 < 300 ms el 99,9% del mes" |
| **SLA** (Service Level Agreement) | El **contrato** con el cliente, con penalización si se incumple. Siempre más laxo que el SLO |
| **Error budget** | Lo que el SLO permite fallar. Con un SLO de 99,9% mensual son ~43 minutos. Si se agota, se congelan los cambios |

La jerarquía importa: se mide el SLI, se gestiona contra el SLO, y el SLA es lo que te cuesta dinero. Poner el SLO igual que el SLA deja sin margen de maniobra.

| Término | Qué es |
|---|---|
| **RTO** (Recovery Time Objective) | Cuánto tiempo puede estar caído antes de que sea inaceptable |
| **RPO** (Recovery Point Objective) | Cuántos datos se puede permitir perder, medido en tiempo. Un RPO de 1 h significa backups al menos cada hora |
| **MTTR** (Mean Time To Recovery) | Cuánto se tarda en recuperarse de media |
| **MTBF** (Mean Time Between Failures) | Cuánto aguanta de media entre fallos |

En sistemas distribuidos se optimiza **MTTR**, no MTBF: se asume que va a fallar y se invierte en recuperar rápido.

##### Percentiles

- **p50** (mediana): la experiencia típica
- **p95 / p99**: la cola. Es donde viven los problemas reales
- La **media** es engañosa: con 99 peticiones de 10 ms y una de 10 s, la media es 110 ms y nadie ha vivido eso

Regla: **la media miente, el p99 es lo que sufre el usuario**, y en un flujo con 10 llamadas internas el p99 de cada una es casi la experiencia media del conjunto.

#### Despliegue y entrega

| Término | Qué es |
|---|---|
| **Rolling update** | Se sustituyen instancias poco a poco. Conviven dos versiones — de ahí el [expand-contract](../my-techtalks/TechTalk-Zero-Downtime-Database-Migrations) en base de datos |
| **Blue-green** | Dos entornos completos; se conmuta el tráfico de golpe. Rollback instantáneo, coste doble |
| **Canary** | La versión nueva recibe un % pequeño del tráfico real y se vigila antes de ampliar |
| **Feature flag** | El código nuevo va desplegado pero apagado. Separa *desplegar* de *activar* |
| **Trunk-based development** | Ramas de vida muy corta contra `main`. Menos conflictos, más flags |
| **Shift left** | Mover la detección de problemas lo más pronto posible en el ciclo |

##### Idempotencia

Una operación es **idempotente** si ejecutarla dos veces deja el mismo resultado que ejecutarla una. `GET` y `PUT` lo son; `POST` normalmente no.

Es la propiedad que decide si se puede reintentar. Ver [Resilience](../my-techtalks/TechTalk-Resilience-Patterns).

#### Arquitectura

| Término | Qué es |
|---|---|
| **Acoplamiento / cohesión** | Lo de siempre: poco acoplamiento entre módulos, mucha cohesión dentro |
| **Monolito modular** | Un despliegue, módulos con fronteras reales. Casi siempre el paso correcto antes de microservicios |
| **Bounded context** | La frontera dentro de la cual un término significa una sola cosa. "Cliente" no es lo mismo en facturación que en soporte |
| **Hexagonal / puertos y adaptadores** | El dominio no conoce la infraestructura; se comunica por interfaces que la infraestructura implementa |
| **CQRS** | Separar el modelo de lectura del de escritura |
| **Event sourcing** | El estado es la suma de los eventos, no una fila que se actualiza |
| **Saga** | Transacción de negocio repartida en varios servicios, con compensaciones en vez de rollback |
| **Outbox** | Escribir el evento en la misma transacción que el dato, y publicarlo aparte. Evita el 2PC |
| **Strangler fig** | Migrar un legacy rodeándolo y sustituyendo funcionalidad poco a poco, no de golpe |
| **ADR** (Architecture Decision Record) | Documento corto: contexto, decisión, consecuencias. Sobrevive a quien la tomó |
| **Fitness function** | Una prueba automática que verifica una propiedad de arquitectura (ArchUnit, por ejemplo) |

##### Teorema CAP

Ante una **partición de red** (P), hay que elegir entre **consistencia** (C) y **disponibilidad** (A). No es un menú de tres donde eliges dos: la partición ocurre, no se elige.

En la práctica la pregunta útil es: cuando se corte la red entre dos nodos, **¿prefiero devolver un dato posiblemente desactualizado o devolver un error?**

- **Consistencia eventual**: si dejan de llegar escrituras, todas las réplicas convergen. No dice cuándo
- **Read-your-writes**: al menos tú ves lo que acabas de escribir

#### Deuda técnica

Cuatro tipos, y mezclarlos es lo que hace imposible la conversación con negocio:

- **Deliberada y prudente**: "sabemos que esto no escala, salimos ya y lo arreglamos en Q3"
- **Deliberada e imprudente**: "no hay tiempo para diseñar"
- **Accidental y prudente**: "ahora que está hecho, vemos cómo debería haber sido"
- **Accidental e imprudente**: no se sabía que existía una forma mejor

Solo la primera es una decisión de ingeniería. El resto son síntomas.

#### Rendimiento

| Término | Qué es |
|---|---|
| **Throughput** | Peticiones por unidad de tiempo |
| **Latencia** | Lo que tarda una |
| **Ley de Little** | `concurrencia = throughput × latencia`. Con 100 rps y 200 ms de latencia hay 20 peticiones en vuelo — y eso dicta el tamaño de los pools |
| **Backpressure** | El consumidor le dice al productor que vaya más despacio, en vez de acumular |
| **Head-of-line blocking** | Una petición lenta bloquea a las que van detrás en la misma cola |
| **Thundering herd** | Todos reintentan a la vez y rematan al que se estaba recuperando. Se evita con jitter |
| **Cache stampede** | Expira una entrada muy usada y mil peticiones van a la vez al origen |
| **N+1** | Una consulta para la lista y una por cada elemento. El clásico de todo ORM |

La **ley de Little** es la más rentable de las cuatro: convierte "¿de qué tamaño pongo el pool?" en una cuenta en lugar de una opinión.
