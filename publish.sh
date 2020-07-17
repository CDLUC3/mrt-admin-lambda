#!/bin/bash
cd web
sed -i -e "s|http://localhost:4567|${APIGW_URL}|" api-table.js
for file in *.*
do
  aws s3 cp $file s3://${S3WEB_BUCKET}/mrt/admintool/
done
