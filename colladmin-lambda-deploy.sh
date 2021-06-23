#!/bin/bash

DEPLOY_ENV=${1:-dev}

# Uncommend the following line when a config change is needed
# run_config=Y

EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

# Assume deploy runs from DEV
# Set ENV based on deploy env
SSM_DEPLOY_PATH=${SSM_ROOT_PATH//dev/${DEPLOY_ENV}}

# Get the ARN for the lambda to publish
LAMBDA_ARN_BASE=`get_ssm_value_by_name colladmin/lambda-arn-base`
LAMBDA_ARN=${LAMBDA_ARN_BASE}-${DEPLOY_ENV}

# Get the ECR image to publish
ECR_REGISTRY=`get_ssm_value_by_name admintool/ecr-registry`
ECR_IMAGE_NAME=`get_ssm_value_by_name colladmin/ecr-image`
ECR_IMAGE_TAG=${ECR_REGISTRY}${ECR_IMAGE_NAME}:${DEPLOY_ENV}

# Get the URL for links to Merritt
MERRITT_PATH=`get_ssm_value_by_name admintool/merritt-path`
if [ $DEPLOY_ENV == 'stg' ]
then
  MERRITT_PATH=http://merritt-stage.cdlib.org
elif [ $DEPLOY_ENV == 'prd' ]
then
  MERRITT_PATH=http://merritt.cdlib.org
fi
docker build -t cdluc3/uc3-mrt-admin-common src-common || die "Image build failure"
docker build -t ${ECR_IMAGE_TAG} src-colladmin || die "Image build failure"

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

  S3WEB_BUCKET=`get_ssm_value_by_name admintool/s3-bucket`
  S3WEB_BUCKET=${S3WEB_BUCKET//dev/${DEPLOY_ENV}}

  aws lambda update-function-configuration \
    --function-name ${LAMBDA_ARN} \
    --region us-west-2 \
    --output text \
    --timeout 180 \
    --memory-size 512 \
    --no-cli-pager \
    --environment "Variables={SSM_ROOT_PATH=${SSM_DEPLOY_PATH},MERRITT_PATH=${MERRITT_PATH},BUCKET=${S3WEB_BUCKET}}" 
fi
