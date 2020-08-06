# Admin Lambda

This code contains a generalized query tool for the Merritt team.

This code will be deployed as an AWS Lambda that is accessible to staff from a static website deployed to S3.

The Lambda deployment will pull database credentials from AWS SSM.  SSM Parameters will be explicitly granted to the Lambda.

For testing purposes, a local copy of the code will be accessible using Sinatra.  Database credentials will be pulled from a config file.

The Lambda code is deployed to the Ruby 2.7 environment.  A build process is required to prepare a deployment zip file for Lambda.

## Directories
- src: Lambda source code
- mysql-deps: build OS-specific mysql binaries used by mysql gems
- test: Sinatra driver for desktop testing
- web: static website code to be deployed to S3

## Deployment Preparation
- This code relies on a set of SSM parameters to control the application.
- https://github.com/CDLUC3/uc3-aws-cli contains the code for reading Merritt SSM parameters.
  - ../admintool/lambda-arn - arn for the function
  - ../admintool/api-path - api gateway path (or cloudfront path)
  - ../admintool/s3-bucket - Website S3 bucket
  - ../admintool/s3-path - Website path in S3
  - ../admintool/site-url - CloudFront website

## Lambda Build Process

### Configure Your GitHub Token

In order to pull this artifact, you must create a GitHub access token
with the following privileges. (Click settings on your GH user account.)
- repo:status
- public_repo
- read:packages

Save your token to a variable GH_TOKEN in your account

```
export GH_TOKEN=username:token
```

### UC3-SSM Gem
The uc3-ssm gem is built by GitHub Actions.  

The gem requires a GitHub token to pull the packaged gem.

https://github.com/CDLUC3/uc3-ssm/packages

### Build MySql dependencies for Lambda OS

The following GitHub Action will build a zip file containing all Gem dependencies needed to run the application.

- [GitHub Action Build](.github/workflows/build-deploy-zip.yml)

This action generates a GitHub artifact named **deploy.zip**

This GitHub action utilizes a Dockerfile that pre-builds dependencies for a Ruby Lambda with MySql.  See the [cdluc3/mysql-ruby-lambda Dockerfile](mysql-ruby-lambda/Dockerfile)

### Deploy the Lambda Code

The following script should be run from a host that is authorized to deploy to Lambda.

- [lambda-deploy.sh](lambda-deploy.sh)

This will download the artifact dependencies from GitHub and re-embed source files into the zip file.

This script requires SSM parameters to be configured.  Requires lambda update function permissions.

Output: **deploy.zip**

## Static Website Publishing
- A static website provides the user interface for these queries.
- On page load, URL parameters are read to determine the query to run
- A query request is made via ajax
- Query results are reformatted into an html table and displayed to the user  
- A publishing script `publish.sh` will copy assets into an S3 bucket
- AWS Cloud Front has been configured to provide a URL for the static website
  - Cloud Front is also used to restrict access to the website

## Local Testing
- A Sinatra web server can be started in lieu of Cloud Front / API Gateway / Lambda.
- This web server is designed to mimic the pass through of request parameters to a Lambda function.  Request parameters are packaged into an event object.
- Since the desktop environment may not have a local copy of SSM parameters, the code is configured to pull database credentials from an untracked configuration file `test/config/database.localcred.yml`
