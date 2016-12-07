#!/bin/bash

source ../demo.sh

javac A.java
boldecho "We'll run a simple java program that runs a synchonized block with many threads"
runecho java -Dcom.sun.management.jmxremote.ssl=false \
	-Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=9999 -cp . A &
boldecho "Let's see it in visualvm"
read
A=`jps -v|grep A|awk '{print $1}'`
trap "kill $A" EXIT
jvisualvm --openid $A
read
runecho java -jar ~/jmxstat-0.2.2-SNAPSHOT/jmxstat-0.2.2-SNAPSHOT.jar localhost:9999 --contention

