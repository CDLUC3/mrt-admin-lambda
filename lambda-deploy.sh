#!/bin/bash

# A zip file of dependencies will be constructed with GitHub actions.
# The results are saved to a GitHub actions artifact.

# In order to pull this artifact, you must create a GitHub access token
# with the following privileges. (Click settings on your GH user account.)
# - repo:status
# - public_repo
# - read:packages
# Save your token to a variable GH_TOKEN in your account
# export GH_TOKEN=username:token

# Depends on https://github.com/CDLUC3/uc3-aws-cli scripts
EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

# Get the ARN for the lambda to publish
LAMBDA_ARN=`get_ssm_value_by_name admintool/lambda-arn`

# Get the URL for links to Merritt
MERRITT_PATH=`get_ssm_value_by_name admintool/merritt-path`

CREATED_AT=`curl -s "https://api.github.com/repos/CDLUC3/mrt-admin-lambda/actions/artifacts" | jq -r ".artifacts[0]" | jq -r ".created_at"`

CREATED_AT=`date -d $CREATED_AT`

ZIPSIZE=`curl -s "https://api.github.com/repos/CDLUC3/mrt-admin-lambda/actions/artifacts" | jq -r ".artifacts[0]" | jq -r ".size_in_bytes"`

echo " ********************* "
echo " ===> ${SSM_ROOT_PATH}"
echo " Created:  ${CREATED_AT}"
echo " Zip Size: ${ZIPSIZE}"
echo " ********************* "
echo "Press Enter to continue or Cntl-C to cancel"

read

LATEST_DEPLOY=`curl -s "https://api.github.com/repos/CDLUC3/mrt-admin-lambda/actions/artifacts" | jq -r ".artifacts[0]" | jq -r ".archive_download_url"`

curl -u ${GH_TOKEN} -L -s ${LATEST_DEPLOY} -o artifact.zip

rm deploy.zip
unzip artifact.zip
rm artifact.zip

# Temporary install step - chat with Ashley to ensure valid json wrapper
cp ~/inventory.json src/inventory

# Copy ruby code into zip
cd src
zip -r ../deploy.zip *
cd ..

# Display zip contents to the user
unzip -l deploy.zip

# deploy lambda code
aws lambda update-function-code --function-name ${LAMBDA_ARN} --zip-file fileb://deploy.zip --region us-west-2

# Set environment and set timeout
aws lambda update-function-configuration --function-name ${LAMBDA_ARN} --region us-west-2 --timeout 60 --memory-size 128 --environment "Variables={SSM_ROOT_PATH=${SSM_ROOT_PATH},MERRITT_PATH=${MERRITT_PATH}}"

SITE_URL=`get_ssm_value_by_name admintool/site-url`

echo " *** Preview changes at "
echo $SITE_URL
