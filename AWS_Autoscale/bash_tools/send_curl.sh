#!/bin/bash -vx
while true
do
    curl -d '{"account":"730386877786", "region":"us-east-1"}' --request POST http://localhost:8000/start
    sleep 60
done
