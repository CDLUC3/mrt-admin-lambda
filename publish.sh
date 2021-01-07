#!/bin/bash
# Depends on https://github.com/CDLUC3/uc3-aws-cli scripts
EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

cd web
APIGW_URL=`get_ssm_value_by_name admintool/api-path`
S3WEB_BUCKET=`get_ssm_value_by_name admintool/s3-bucket`
S3WEB_PATH=`get_ssm_value_by_name admintool/s3-path`
SITE_URL=`get_ssm_value_by_name admintool/site-url`
DATESTR=`date +%Y%m%d_%H%M%S`

# Embed the api path into the javascript for ajax requests
git checkout -- lambda.base.js
git checkout -- index.html
sed -i -e "s|/lambda|${APIGW_URL}|" lambda.base.js
sed -i -e "s|lambda.base.js|lambda.base.js?${DATESTR}|" index.html
sed -i -e "s|api-table.js|api-table.js?${DATESTR}|" index.html
sed -i -e "s|api-table.css|api-table.css?${DATESTR}|" index.html

# Copy static website assets to S3
for file in *.*
do
  aws s3 cp $file s3://${S3WEB_BUCKET}${S3WEB_PATH}
done

git checkout -- lambda.base.js
git checkout -- index.html

# echo site url
echo "Website Updated:"
echo ${SITE_URL}
