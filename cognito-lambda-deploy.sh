#!/bin/bash

# Set param 1 to Y if the lambda config should be updated
run_config=${1:-N}

EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

AWS_ACCOUNT_ID=`aws sts get-caller-identity| jq -r .Account` || die "AWS Account Not Found"
FUNCTNAME=uc3-mrt-cognitousers

# Get the ARN for the lambda to publish
LAMBDA_ARN=arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:uc3-mrt-cognitousers-img-prd

# Get the ECR image to publish
ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
ECR_IMAGE_TAG=${ECR_REGISTRY}/${FUNCTNAME}:latest

# login to ecr
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS \
    --password-stdin ${ECR_REGISTRY}

# build cognito lambda
docker build --build-arg ECR_REGISTRY=${ECR_REGISTRY} -t ${ECR_IMAGE_TAG} cognito-lambda-nonvpc || die "Image build failure for ${ECR_IMAGE_TAG}"

# aws ecr create-repository --repository-name ${FUNCTNAME}
docker push ${ECR_IMAGE_TAG} || die "Image push failure for ${ECR_IMAGE_TAG}"

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
