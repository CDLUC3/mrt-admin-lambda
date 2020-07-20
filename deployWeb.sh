#!/bin/bash
for file in web/*.*
do
  #aws s3 cp --acl public-read $file s3://${S3WEB_BUCKET}/mrt/admintool/
  aws s3 cp $file s3://${S3WEB_BUCKET}/mrt/admintool/
done
