#!/bin/bash
# Depends on https://github.com/CDLUC3/uc3-aws-cli scripts

DEPLOY_ENV=${1:-dev}

EXIT_ON_DIE=true

source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

SSM_DEPLOY_PATH=${SSM_ROOT_PATH//dev/${DEPLOY_ENV}}

cd web
ADMIN_ALB_URL=`get_ssm_value_by_name admintool/api-path`
ADMIN_ALB_URL=${ADMIN_ALB_URL//dev/${DEPLOY_ENV}}

COLLADMIN_ALB_URL=`get_ssm_value_by_name colladmin/api-path`
COLLADMIN_ALB_URL=${COLLADMIN_ALB_URL//dev/${DEPLOY_ENV}}

S3WEB_BUCKET=`get_ssm_value_by_name admintool/s3-bucket`
S3WEB_BUCKET=${S3WEB_BUCKET//dev/${DEPLOY_ENV}}

S3WEB_PATH=`get_ssm_value_by_name admintool/s3-path`
SITE_URL=`get_ssm_value_by_name admintool/site-url`
SITE_URL=${SITE_URL//dev/${DEPLOY_ENV}}

DATESTR=`date +%Y%m%d_%H%M%S`

# Embed the api path into the javascript for ajax requests

MFILES="index.html ark.html doi.html localid.html lambda.base.js coll-lambda.base.js"
HFILES="index.html ark.html doi.html localid.html"

for file in ${MFILES}
do
  git checkout -- $file
done

sed -i -e "s|/lambda|${ADMIN_ALB_URL}|" lambda.base.js
sed -i -e "s|/lambda|${COLLADMIN_ALB_URL}|" coll-lambda.base.js

for file in ${HFILES}
do
  sed -i -e "s|lambda.base.js|lambda.base.js?${DATESTR}|" $file
  sed -i -e "s|api-table.js|api-table.js?${DATESTR}|" $file
  sed -i -e "s|api-table.css|api-table.css?${DATESTR}|" $file
  sed -i -e "s|api-table.css|arkform.js?${DATESTR}|" $file
done

# Copy static website assets to S3
for file in *.*
do
  aws s3 cp $file s3://${S3WEB_BUCKET}${S3WEB_PATH}
done

for file in ${MFILES}
do
  git checkout -- $file
done

# echo site url
echo "Website Updated:"
echo ${SITE_URL}
