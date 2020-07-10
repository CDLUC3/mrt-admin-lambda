#!/bin/bash

cd src
zip -r ../deploy.zip *
cd ..
unzip -l deploy.zip
aws lambda update-function-code --function-name ${LAMBDA_ARN} --zip-file fileb://deploy.zip --region us-west-2
