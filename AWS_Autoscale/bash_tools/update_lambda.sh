#!/usr/bin/env bash -vx
rm ../build/functions.zip
zappa package -o ../build/functions.zip
aws lambda update-function-code --function-name handler --zip-file fileb://../build/functions.zip



