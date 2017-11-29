#!/bin/bash

function check () {
    containerName="$1"
    container=`docker container ls | grep $containerName | awk '{print $1}'`
    secName="$2"
    secValue="$3"

    strResult=`docker exec $container cat /run/secrets/$secName`
    ret=$?

    if [ $ret -ne 0 ] || [ "$strResult" != "$secValue" ]; then
        echo "FAIL - Couldn't get secret $secName on function $containerName"
    else
        echo "PASS - $secName exists on function $containerName, is of value $secValue"
    fi
}

function countSecrets () {
    containerName="$1"
    targetCount="$2"
    container=`docker container ls | grep $containerName | awk '{print $1}'`
    count=`docker exec $container ls -l /run/secrets/ | grep sec | wc -l`

    if [ "$count" != "$targetCount" ]; then
        echo "FAIL - Secret count not correct: want $targetCount, got $count"
    else
        echo "PASS - Correct secret count of $count"
    fi
}

echo "secret1" | docker secret create sec1 -
echo "secret2" | docker secret create sec2 -
echo "secret3" | docker secret create sec3 -
echo "secret4" | docker secret create sec4 -

docker pull functions/alpine:0.6.9
faas-cli deploy -f samples.yml
sleep 30

pa1='protectedapi1'
pa2='protectedapi2'

echo "*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*"
echo "THE FOLLOWING 3 TESTS SHOULD PASS"
echo "*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*"
check $pa1 "sec1" "secret1"
check $pa2 "sec1" "secret1"
check $pa2 "sec2" "secret2"

faas-cli deploy -f samples.yml --secret sec3 --filter *1
faas-cli deploy -f samples.yml --secret sec3 --secret sec4 --filter *2
sleep 30

echo "*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*"
echo "THE FOLLOWING 6 TESTS SHOULD PASS"
echo "*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*"
check $pa1 "sec1" "secret1"
check $pa2 "sec1" "secret1"
check $pa2 "sec2" "secret2"
check $pa1 "sec3" "secret3"
check $pa2 "sec3" "secret3"
check $pa2 "sec4" "secret4"

faas-cli deploy -f samples.yml --secret sec1 --secret sec3 --filter *1
faas-cli deploy -f samples.yml --secret sec1 --secret sec2 --secret sec3 --filter *2
sleep 30

echo "*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*"
echo "THE FOLLOWING 7 TESTS SHOULD PASS"
echo "*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*"
check $pa1 "sec1" "secret1"
check $pa1 "sec3" "secret3"
check $pa2 "sec1" "secret1"
check $pa2 "sec2" "secret2"
check $pa2 "sec3" "secret3"
countSecrets $pa1 2
countSecrets $pa2 3

echo "*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*"
echo "THE FOLLOWING 3 TESTS SHOULD FAIL"
echo "*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*_*"
check $pa1 "sec2" "secret2"
check $pa1 "sec4" "secret4"
check $pa2 "sec5" "secret5"

faas-cli rm -f samples.yml
docker secret rm sec1 sec2 sec3 sec4
