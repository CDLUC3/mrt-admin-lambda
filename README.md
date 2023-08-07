# Merritt Admin Tool

This library is part of the [Merritt Preservation System](https://github.com/CDLUC3/mrt-doc).

## Admin Tool Web Interface 
Each Admin Lambda application functions as a simple web server displaying the pages for the application.

```mermaid
%%{init: {'theme': 'neutral', 'securityLevel': 'loose', 'themeVariables': {'fontFamily': 'arial'}}}%%
graph TD
  ADMIN([Admin Tool - Lambda])
  click ADMIN href "https://github.com/CDLUC3/mrt-admin-lambda" "source code"
  ADMINWEB[[Admin Tool - Browser]]
  click ADMINWEB href "https://github.com/CDLUC3/mrt-admin-lambda" "source code"
  WAF[Web application Firewall]
  COG[AWS Cognito User Auth]
  SAML[SAML Authentication]

  subgraph flowchart
    ALB --> ADMIN
    ADMIN --> |json| ALB
    ADMINWEB --> |2. ajax req for data| ALB
    ALB --> |3. json data| ADMINWEB
    ALB --> |1. retrieve web assets|ADMINWEB
    ALB --> |authorize| WAF
    ALB --> |authorize| COG
    COG --> SAML
  end
  style ADMIN stroke:red,stroke-width:4px
  style ADMINWEB stroke:red,stroke-width:4px
  style ALB fill:cyan
  style WAF fill:cyan
  style COG fill:cyan
  style SAML fill:cyan
```

## Admin Tool Lambda
This code contains a generalized query tool for the Merritt team.

```mermaid
%%{init: {'theme': 'neutral', 'securityLevel': 'loose', 'themeVariables': {'fontFamily': 'arial'}}}%%
graph TD
  ADMIN([Admin Tool - Lambda])
  click ADMIN href "https://github.com/CDLUC3/mrt-admin-lambda" "source code"
  ADMINWEB[[Admin Tool - Browser]]
  click ADMINWEB href "https://github.com/CDLUC3/mrt-admin-lambda" "source code"
  WAF[Web application Firewall]
  COG[AWS Cognito User Auth]
  SAML[SAML Authentication]

  subgraph flowchart
    ALB --> ADMIN
    ADMIN --> |json| ALB
    ADMINWEB --> |2. ajax req for data| ALB
    ALB --> |3. json data| ADMINWEB
    ALB --> |1. retrieve web assets|ADMINWEB
    ALB --> |authorize| WAF
    ALB --> |authorize| COG
    COG --> SAML
  end
  style ADMIN stroke:red,stroke-width:4px
  style ADMINWEB stroke:red,stroke-width:4px
  style ALB fill:cyan
  style WAF fill:cyan
  style COG fill:cyan
  style SAML fill:cyan
```

## Collection Admin Tool

```mermaid
%%{init: {'theme': 'neutral', 'securityLevel': 'loose', 'themeVariables': {'fontFamily': 'arial'}}}%%
graph TD
  RDSINV[(Inventory Database)]
  COLLADMIN([Collection Admin - Lambda])
  click COLLADMIN href "https://github.com/CDLUC3/mrt-admin-lambda" "source code"
  ADMINWEB[[Admin Tool - Browser]]
  click ADMINWEB href "https://github.com/CDLUC3/mrt-admin-lambda" "source code"
  COGLAMB([Cognito API Lambda])
  click COGLAMB href "https://github.com/CDLUC3/mrt-admin-lambda/cognito-lambda-nonvpc" "source code"
  WAF[Web application Firewall]
  COG[AWS Cognito User Auth]
  SAML[SAML Authentication]
  ECR[ECR Hosted Lambda Image]
  ING(Ingest)
  INV(Inventory)
  STORE(Storage)
  REP(Replication)
  click ING href "https://github.com/CDLUC3/mrt-ingest" "source code"
  ZOOING>Zookeeper Ingest]
  click ZOOING href "https://github.com/CDLUC3/mrt-zoo" "source code"
  LDAP[/LDAP\]
  ZOOINV>Zookeeper Inventory]
  ZOOACC>Zookeeper Access]
  S3RPT[[S3 Report Bucket - TBD]]

  subgraph flowchart
    COLLADMIN --> |"query / update"| RDSINV
    COLLADMIN --> |html/json| ALB
    ADMINWEB --> |page requests/ajax| ALB
    ALB --> |html/json| ADMINWEB
    ALB --> |authorize| WAF
    ALB --> |authorize| COG
    ECR --> COLLADMIN
    COLLADMIN --> ING
    COLLADMIN --> REP
    COLLADMIN --> STORE
    COLLADMIN --> INV
    COLLADMIN --> LDAP
    COLLADMIN --> S3RPT
    COLLADMIN --> COGLAMB
    COGLAMB --> |user management| COG
    COG --> SAML
    ING --> ZOOING
    ING --> ZOOINV
    ING --> ZOOACC
  end
  
  style RDSINV fill:#F68D2F
  style COLLADMIN stroke:red,stroke-width:4px
  style ADMINWEB stroke:red,stroke-width:4px
  style ALB fill:cyan
  style WAF fill:cyan
  style COG fill:cyan
  style ECR fill:cyan
  style ZOOING fill:cyan
  style ZOOINV fill:cyan
  style ZOOACC fill:cyan
  style LDAP fill:cyan
  style S3RPT fill:#77913C
  style SAML fill:cyan
  style COGLAMB fill:yellow
```

The Lambda deployment will pull database credentials from AWS SSM.  SSM Parameters will be explicitly granted to the Lambda.  The lambda will be packaged as a docker image built from [mysql-ruby-lambda](mysql-ruby-lambda).

For testing purposes, another docker image will be run to simulate the ALB interface to the lambda.  See [simulate-lambda-alb](simulate-lambda-alb).  The files [docker-compose.yml](docker-compose.yml) and [admintool.yml](admintool.yml) will facilitate application testing.

The Lambda code is deployed to the Ruby 2.7 environment.  A build process is required to prepare a deployment zip file for Lambda.

## Directories
- mysql-ruby-lambda
  - base image for the lambda code
- simulate-lambda-alb
  - docker image to facilitate localhost testing with docker-compose
- src-admintool: Admintool Lambda source code
- src-colladmin: Collection Admin Lambda source code
- src-common: Code common to both Admin Tool and CollAdmin Tool
  - web: web resources served from the lambda
- cognito-lambda-nonvpc: Wrapper around the Cognito API (used by Colladmin)
  - Cognito API calls cannot be made directly from the VPC 
## Deployment Preparation
- This code relies on a set of SSM parameters to control the application.
- https://github.com/CDLUC3/uc3-aws-cli contains the code for reading Merritt SSM parameters.
- Lambda Image Push/Deploy variables

### Deploy the Lambda Code

The following script should be run from a host that is authorized to 
- push to ECR
- deploy to Lambda.

Deploy Scripts
- Admin Tool: [lambda-deploy.sh](lambda-deploy.sh)
- Collection Admin Tool: [colladmin-lambda-deploy.sh](colladmin-lambda-deploy.sh)
- Cognito User Management: [cognito-lambda-deploy.sh](colladmin-lambda-deploy.sh)

This will build a docker image, push it to ECR, and update lambda to use the new image.

This script requires SSM parameters to be configured.  Requires lambda update function permissions.

This script **requires aws cli V2** in order to deploy a docker image to lambda.  
- The host running this script needs to be able to push to ECR and to update a lambda.

## Automated Testing

This may be performed from a DEV box against Stage instances.

```
cd src-testdriver
bundle exec rspec
```

## Local Testing

### Placeholder Lambda Testing
- Home page: [simulate-lambda-alb/web/index.html](simulate-lambda-alb/web/index.html)
- Lambda entrypoint: [simulate-lambda-alb/alb_simulate.rb](simulate-lambda-alb/alb_simulate.rb)
- Lambda Dockerfile: [simulate-lambda-alb/Dockerfile](simulate-lambda-alb/Dockerfile)

```
docker-compose -f docker-compose.yml up -d
```

### Admin Tool (from server with SSM)
- Home page: [web/index.html](web/index.html)
- Lambda entrypoint: [src-admintool/lambda_function.rb](src-admintool/lambda_function.rb)
- Lambda Dockerfile: [src-admintool/Dockerfile](src-admintool/Dockerfile)
```
docker-compose -f docker-compose.yml -f admintool.yml up -d
```

### Collection Admin Tool (from server with SSM)
- Home page: [web/collAdmin.html](web/collAdmin.html)
- Lambda entrypoint: [src-colladmin/lambda_function.rb](src-colladmin/lambda_function.rb)
- Lambda Dockerfile: [src-colladmin/Dockerfile](src-colladmin/Dockerfile)
```
docker-compose -f docker-compose.yml -f colladmin.yml up -d
```

### Collection Admin Tool (from desktop without SSM)
```
docker-compose -f docker-compose.yml -f colladmin.yml -f local.yml up -d
```

Open the following URL to test.

- [http://localhost:8091/web/index.html](http://localhost:8091/web/index.html)
- [http://localhost:8091/web/collAdmin.html](http://localhost:8091/web/collAdmin.html)
