#!/bin/bash

zip deploy.zip src/*
aws lambda update-function-code --function-name ${LAMBDA_ARN} --zip-file fileb://deploy.zip
