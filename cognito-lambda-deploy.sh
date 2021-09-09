#!/bin/bash

# Set param 1 to Y if the lambda config should be updated
run_config=${1:-N}

EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

# Get the ARN for the lambda to publish
LAMBDA_ARN_BASE=`get_ssm_value_by_name cognito-users/lambda-arn-base`
LAMBDA_ARN=${LAMBDA_ARN_BASE}

# Get the ECR image to publish
ECR_REGISTRY=`get_ssm_value_by_name admintool/ecr-registry`
ECR_IMAGE_NAME=`get_ssm_value_by_name cognito-users/ecr-image`
# One deployment will support all domains - no tag included
ECR_IMAGE_TAG=${ECR_REGISTRY}${ECR_IMAGE_NAME}

docker build -t ${ECR_IMAGE_TAG} cognito-lambda-nonvpc || die "Image build failure"

# To test: 
#   docker run --rm -p 8090:8080 --name admintool -d ${ECR_IMAGE_TAG}

aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS \
    --password-stdin ${ECR_REGISTRY}

# aws ecr create-repository --repository-name ${ECR_IMAGE_NAME}

docker push ${ECR_IMAGE_TAG} || die "Image push failure"

# deploy lambda code
aws lambda update-function-code \
  --function-name ${LAMBDA_ARN} \
  --image-uri ${ECR_IMAGE_TAG} \
  --output text --region us-west-2 \
  --no-cli-pager \
  || die "Lambda Update failure"

if [ "$run_config" == 'Y' ]
then
  echo " -- pause 60 sec then update function config"
  sleep 60

  aws lambda update-function-configuration \
    --function-name ${LAMBDA_ARN} \
    --region us-west-2 \
    --output text \
    --timeout 180 \
    --memory-size 128 \
    --no-cli-pager 
fi
