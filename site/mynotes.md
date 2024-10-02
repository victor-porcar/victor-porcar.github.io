

bucle infinito 

while true; do cat file ; sleep 1; done





desplegar en NEXU artifact directamente

mvn deploy:deploy-file -DgroupId=com.wialon \
    -DartifactId=sdk-core \
    -Dversion=1.3.57  \
    -Dpackaging=jar \
    -Dfile=wialon-sdk-1.3.57.jar \
    -DgeneratePom=true \
    -DrepositoryId=nexus\
    -Durl=http://nexus.grupogimeno.com/nexus/repository/thirdparty/





JAVA, cambiar entorno

sudo update-alternatives --config javac



/iotsens/010251794002/devices/0001052E99CE/up


BORRAR BRANCH LOCAL

git branch -D release/ç

git branch --delete --remotes origin/release/1.16



ln -s -f jars/iot-itron-reader-1.0.22.jar iot-itron-reader.jar


ln -s -f /opt/iotsens/readers/jars/iotsens-reader-industrial-experlims-1.0.0.jar iotsens-reader-industrial-experlims.jar



ln -s -f /opt/iotsens/readers/jars/iotsens-reader-kron-1.2.jar iotsens-reader-kron.jar


ln -s -f /opt/iotsens/readers/jars/iotsens-reader-smartwaste-distromel-1.0.22-SNAPSHOT.jar iotsens-reader-smartwaste-distromel.jar



TERMINAR TOMCAT EMBEBIDO -> fuser -k 8080/tcp
fuser -k 5050/tcp







ln -s -f /opt/iotsens/readers/jars/iotsens-reader-kron-1.2.jar iotsens-reader-kron.jar

ln -s -f /opt/iotsens/processes/jars/iot-process-genevents-2.7.jar iot-process-genevents.jar



cambiar idioma 

 linux ubuntu
 setxkbmap es



 
/opt/bin/deploy_all_pipelines versió

 
mosquitto_pub -h 172.20.20.15 -u 'iotsens' -p 30002 -P 'iot-adc' -t '/iot/server/0101FE020006/4657'  -m '{"type":"4657","node":"020E7E130012","data":"LUQtLFUylwkUtiLB///AA==","time":"1554768031","gateway":"0101FE020006","key":"3f437e864792d73efd7816443c234ace"}'

 mosquitto_sub -h 172.20.16.200 -u 'iotsens' -P 'iot-adc' -t '/iot/process/datauplogs'  

 mosquitto_sub -h 172.20.16.200 -u 'iotsens' -P 'iot-adc' -t '/iot/server/+/4657'  

 mosquitto_sub -h 172.20.20.15 -u 'iotsens' -p 30001 -P 'iot-adc' -t '/iot/server/+/4657'  


mosquitto_pub -h 172.20.20.15 -u 'iotsens' -p 30002 -P 'iot-adc' -t '/iot/process/FACTORY/rawmeasures/1'  -m '{"variableId":"DM202","sensorUniqueId":"AA0000AB50846","timestamp":1554899869000,"rawValue":"0","source":"SENSOR","author":"00000AB50846","traceId":"1f857f53-7f5d-4c66-abd2-4d0f74c54773"}
'

 
 
 
 robocopy I:\FSD-MASTER\REFERENCE z:\reference /mir /z /xd *__

kubectl delete deployment -l app=iot-process-gensumaries
















VER SEPARACION OREILLY



 
 

 


- JAVA / JEE (



- JAVASCRIPT

https://auth0.com/blog/a-brief-history-of-javascript/

- historia de javasript, ver presentacion dani pecos y  https://dzone.com/articles/a-brief-history-of-javascript?oid=linkedin&utm_content=buffer92704&utm_medium=social&utm_source=linkedin.com&utm_campaign=buffer
- Javascript / jquery / handlebars / ...


-SEGURIDAD
- certificados, GPG, CA y cadenas, como funciona e


- PREGUNTAS

-idempotente (peticiones)


- KURENTO 

- MQTT

prince / ¿Metodologia?  

oauth

HW: bytes, bigendian, direccionamiento memoria, tipos de procesadores



Acceso remoto máquinas desarrollo vdi-senda0X (mobaxterm y su configuracoin)., que son las X en linux ?

ortogonalidad registros procesador (repertorio ortogonal)
 
 
 (bitcoin) https://es.wikipedia.org/wiki/Cadena_de_bloques 

 

cheksum (CRC), tipos de polinomio 


EXPRESIONES -> "algo es mas semantico"

uso de CURL 


----
white list , black list  en validaciones para mitigar riesgos (relacionado con seguridad) -> mejor las white list

https://www.quora.com/What-is-the-difference-between-a-blacklist-and-whitelist


Fuzzing test -> valores aleatorios y ver como reacciona



Component Driven Develompent, Model Driven Architecture, Domain Driven Architecture


Arquitectura de informacion:

Arquitectura de Información por lo que me he decidido a comentarlo brevemente. 
Es una especialidad del área TIC que trata de modelar la información corporativa de forma óptima para que permita a las empresas confiar en la información que tienen.
Se trata de que no haya inconsistencias en los datos, y que independientemente de la base de datos que se consulte para crear informe el resultado sea el mismo y sea fiable.

Por ejemplo, supongamos una empresa en 100 bases de datos y estos datos están distribuidos en dichas bases de datos. Incluso ubicadas en distintos países. Debería dar igual la base de datos que se consulte. Siempre se debe obtenerse información consistente.

La arquitectura de Información ofrece muchas ventajas competitivas a las empresas.



https://martinfowler.com/bliki/FlagArgument.html



MUY BUENO: https://www.smartsheet.com/agile-vs-scrum-vs-waterfall-vs-kanban




po Que es peor?

[9:26] 
que un metodo devuelva null y luego el llamador a ese metodo haga if (xx == null)

[9:27] 
o que ese metodo lance una excepcion y el llamador haga try { .. } catch

[9:27] 
hagan sus apuestas

[9:27] 
claro, muchos diran


Tecnologias DEVOPS  (https://apiumhub.com/tech-blog-barcelona/devops-technologies-benefits/)

Jenkins
Docker
Github
Consul
Zookeeper
Bash
Netstat
Htop
Iotop
Telnet
Ngrep
Ping
Curl
Samba
Cifs
Nfs


- concepto de rapel de precios

- niveles de log y prioridad


-disruptor LMAX


-

1) CONSTRUCTOR CON N parametros o setters ?   


https://dzone.com/articles/constructor-or-setter
http://stackoverflow.com/questions/19359548/setter-methods-or-constructors


 UpdaterExecuterLog updaterExecuterLog = new UpdaterExecuterLog();
 updaterExecuterLog.setLastExecutionSecondsDuration(executionTime);
 updaterExecuterLog.setLastExecution(new Date());
 updaterExecuterLog.setSuccess(success);

o 

UpdaterExecuterLog updaterExecuterLog = new UpdaterExecuterLog(updaterName, new Date(), success,executionTime);
updaterExecuterLogDAO.insert(updaterExecuterLog);

2) Este bloque es infernal de leer de un vistazo:

action.setResource(getOrCreatePlantByCode(landfill, areaName)); 
action.setLongitude(distromelLandFillWeightResource.getLongitude()); 
action.setLatitude(distromelLandFillWeightResource.getLatitude()); 
action.setTimestamp(DistromelReaderDateUtils.getTimeInDistromelFormat(timestamp));

¿Es mejor usar asignaciones a variables y luego usar un constructor?



https://developer.okta.com/blog/2017/06/20/develop-microservices-with-jhipster


http://xyz.insightdataengineering.com/

http://xyz.insightdataengineering.com/blog/pipeline_map/


comando linux ip a



Technologies in use:
? Microservice architecture based on Docker + Kubernetes / Docker-Compose + Vagrant for local deployment
? MongoDB as the main data persistence choice for NoSQL data store
? Back-end development using Spring (Boot, Security, AOP, HATEOAS...), RxJava, OAuth2
? Front-end development using TypeScript, npm, Angular (2+) [angular-cli], RxJS, SASS...
? Automated testing JUnit, Jasmine, Karma, Protractor
? TeamCity as our build management and continuous integration server
? Atlassian JIRA for Issue and Project management
? Atlassian Confluence for project documentation
? Git for version control system




Dado lo siguiente:

CrearDumpster(nombre, deployment)

hasta ahora este CrearDumpster los creaba de un tipo determinado, ahora surge la necesidad de que pueda haber mas de un tipo

como hacemos

1) CrearDumpster(nombre, deployment, tipo)  -> se obliga a todos los llamadores a añadir el tercer parametro, tiene ese inconveninente, grandes refactors

2) dos alternativas
 CrearDumpster(nombre, deployment, tipo) 
 CrearDumpster(nombre, deployment)
 
que es mejor?






duda

que es mejor

1) un metodo que devuelva algo y que sea muy costoso, que es mejor?  dejar que pueda devolver null o lanzar exception
https://stackoverflow.com/questions/175532/should-a-retrieval-method-return-null-or-throw-an-exception-when-it-cant-prod








https://www.linkedin.com/feed/update/urn:li:activity:6289361313537851392/






-----------------------

Como implementar una herencia lógica en bbdd?

 

è Se puede tener una tabla muy larga con columnas para cada atributo existente en todas las subclases, esto hara que haya filas con  NULL

è Se puede tener tablas por herencia por ID (como measure conversor)

 

Mirar documentación para ver como se llama esto.
