#!/bin/bash
cp dependencies.zip deploy.zip
cd src
zip -r ../deploy.zip *
cd ..
unzip -l deploy.zip
aws lambda update-function-code --function-name ${LAMBDA_ARN} --zip-file fileb://deploy.zip --region us-west-2

aws lambda update-function-configuration --function-name ${LAMBDA_ARN} --region us-west-2 --timeout 60 --environment=SSM_ROOT_PATH=${SSM_ROOT_PATH}
