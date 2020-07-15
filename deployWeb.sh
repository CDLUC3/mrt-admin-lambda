#!/bin/bash
for file in web/*
do
  aws s3 cp --acl public-read $file s3://${S3WEB_BUCKET}
done
