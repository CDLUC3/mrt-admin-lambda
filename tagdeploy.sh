#!/bin/bash

DEPLOY_TAG=${1:-main}

./lambda-tagdeploy.sh dev $DEPLOY_TAG
./lambda-tagdeploy.sh stg $DEPLOY_TAG
./lambda-tagdeploy.sh prd $DEPLOY_TAG
./colladmin-lambda-tagdeploy.sh dev $DEPLOY_TAG
./colladmin-lambda-tagdeploy.sh stg $DEPLOY_TAG
./colladmin-lambda-tagdeploy.sh prd $DEPLOY_TAG