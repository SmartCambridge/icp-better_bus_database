#!/bin/bash

loops=$1
cmd=$2

echo ${cmd}

total=0
max=0
min=8640 # 24 hours

for ((loop=1; loop<=${loops}; loop+=1))
do
    echo "Loop ${loop}:"
    start=${SECONDS}
    eval ${cmd}
    secs="$((SECONDS-start))"
    echo "  ...took $secs secs"
    total=$((total+secs))
    min=$((min>secs?secs:min))
    max=$((max<secs?secs:max))
done

echo "Total ${total} sec"
echo "Mean: $((total / loops)) sec"
echo "Max: ${max} sec"
echo "Min: ${min} sec"
