#!/bin/bash

DEPLOY_ENV=${1:-dev}

EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

# Assume deploy runs from DEV
# Set ENV based on deploy env
SSM_DEPLOY_PATH=${SSM_ROOT_PATH//dev/${DEPLOY_ENV}}

# Get the ECR image to publish
AWS_ACCOUNT_ID=`aws sts get-caller-identity| jq -r .Account` || die "AWS Account Not Found"
FUNCTNAME=uc3-mrt-colladmin-lambda

# Get the ARN for the lambda to publish
LAMBDA_ARN_BASE=arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:uc3-mrt-colladmin-img
LAMBDA_ARN=${LAMBDA_ARN_BASE}-${DEPLOY_ENV}

if [ "${DEPLOY_ENV}" == "prd" ]
then
  REP=
  FORMENV=production
elif [ "${DEPLOY_ENV}" == "stg" ]
then
  REP=-${DEPLOY_ENV}
  FORMENV=stage
else
  REP=-${DEPLOY_ENV}
  FORMENV=docker
fi

ADMIN_ALB_URL=`get_ssm_value_by_name admintool/api-path`
ADMIN_ALB_URL=${ADMIN_ALB_URL//-dev/${REP}}

COLLADMIN_ALB_URL=`get_ssm_value_by_name colladmin/api-path`
COLLADMIN_ALB_URL=${COLLADMIN_ALB_URL//-dev/${REP}}

VARS="SSM_ROOT_PATH=${SSM_DEPLOY_PATH}"
VARS="${VARS},ADMIN_ALB_URL=${ADMIN_ALB_URL}"
VARS="${VARS},COLLADMIN_ALB_URL=${COLLADMIN_ALB_URL}"
VARS="${VARS},FORMENV=${FORMENV}"

aws lambda update-function-configuration \
  --function-name ${LAMBDA_ARN} \
  --region us-west-2 \
  --output text \
  --timeout 180 \
  --memory-size 1024 \
  --no-cli-pager \
  --environment "Variables={${VARS}}" 

date