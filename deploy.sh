#!/bin/bash
rm -rf build
mkdir build build/lib
cp lib-include/* build/lib
cp src/* build
bundle install --path=build/vendor/bundle
cd build
zip -r ../deploy.zip *
cd ..
unzip -l deploy.zip
aws lambda update-function-code --function-name ${LAMBDA_ARN} --zip-file fileb://deploy.zip --region us-west-2
