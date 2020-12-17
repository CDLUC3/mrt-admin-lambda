#!/bin/bash

export SSM_ROOT_PATH=/uc3/mrt/dev/
EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

DEPLOY_ENV=dev
SSM_DEPLOY_PATH=${SSM_ROOT_PATH//dev/${DEPLOY_ENV}}

# Get the ARN for the lambda to publish
LAMBDA_ARN_BASE=`get_ssm_value_by_name admintool/lambda-arn-base`
LAMBDA_ARN=${LAMBDA_ARN_BASE}-${DEPLOY_ENV}

# Get the ECR image to publish
ECR_REGISTRY=`get_ssm_value_by_name admintool/ecr-registry`
ECR_IMAGE_NAME=`get_ssm_value_by_name admintool/ecr-image`
ECR_IMAGE_TAG=${ECR_REGISTRY}${ECR_IMAGE_NAME}:${DEPLOY_ENV}

# Get the URL for links to Merritt
MERRITT_PATH=`get_ssm_value_by_name admintool/merritt-path`
# if [ $DEPLOY_ENV == '...' ]
# then
#  MERRITT_PATH=
# fi
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker build -t ${ECR_IMAGE_TAG} .
docker push ${ECR_IMAGE_TAG} 

# deploy lambda code
aws lambda update-function-code --function-name ${LAMBDA_ARN} --image-uri ${ECR_IMAGE_TAG} --region us-west-2

# Set environment and set timeout
aws lambda update-function-configuration --function-name ${LAMBDA_ARN} --region us-west-2 --timeout 60 --memory-size 128 --environment "Variables={SSM_ROOT_PATH=${SSM_DEPLOY_PATH},MERRITT_PATH=${MERRITT_PATH}}"

