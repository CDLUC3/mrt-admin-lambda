#!/bin/bash

EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

DEPLOY_ENV=dev
# Assume deploy runs from DEV
# Set ENV based on deploy env
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
docker build -t ${ECR_IMAGE_TAG} . || die "Image build failure"

aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS \
    --password-stdin ${ECR_REGISTRY}

docker push ${ECR_IMAGE_TAG} || die "Image push failure"

# deploy lambda code
aws lambda update-function-code \
  --function-name ${LAMBDA_ARN} \
  --image-uri ${ECR_IMAGE_TAG} \
  --output text --region us-west-2 \
  || die "Lambda Update failure"

if [ $run_config == 'Y' ]
then
  aws lambda update-function-configuration \
    --function-name ${LAMBDA_ARN} \
    --region us-west-2 \
    --output text \
    --timeout 60 \
    --memory-size 128 \
    --environment "Variables={SSM_ROOT_PATH=${SSM_DEPLOY_PATH},MERRITT_PATH=${MERRITT_PATH}}" \
    || die "Lambda Config Update failure"
fi
