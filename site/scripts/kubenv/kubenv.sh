#!/bin/bash


kill_child_processes() {
    isTopmost=$1
    curPid=$2
    childPids=`ps -o pid --no-headers --ppid ${curPid}`
    for childPid in $childPids
    do
        kill_child_processes 0 $childPid
    done
    if [ $isTopmost -eq 0 ]; then
        kill -9 $curPid 2> /dev/null
    fi
}

# Ctrl-C trap. Catches INT signal
trap "kill_child_processes 1 $$; exit 0" INT

echo $1
export KUBECONFIG=$1


usedNamespace=$(kubectl config view | grep namespace:)

echo ""
echo   "USING $usedNamespace"

echo ""
echo "====================  BEGIN PORTFORWARDS ============================"


# Iterate the string variable using for loop
for val in "${@:2}"; do

  podPrefix=$(echo $val | awk 'BEGIN{FS=":"} {print $1}')
  desiredPort=$(echo $val | awk 'BEGIN{FS=":"} {print $2}')


  pod=$(kubectl get pods | grep $podPrefix  | head -n 1 | awk '{print $1}')


  port=$(kubectl get pod $pod --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}')



  # kills any process listening to desiredPort

  processOnPort=$(lsof -t -i:$desiredPort)
  if [[ ! -z $processOnPort ]]
  then
     echo "As first step killing  existing process $processOnPort listening on $desiredPort"      
     kill $processOnPort
  fi


  echo "====> POD $pod  listening on $desiredPort  (launched command: kubectl port-forward $pod $desiredPort:$port)"

  kubectl port-forward $pod $desiredPort:$port &
done
echo ""
echo "==================== END PORTFORWARDS ============================"
sleep infinity
