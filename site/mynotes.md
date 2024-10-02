

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
