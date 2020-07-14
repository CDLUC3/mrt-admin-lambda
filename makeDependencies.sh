#!/bin/bash

docker build -t depbuild .
docker run --rm --name depbuild -d depbuild
docker cp depbuild:/var/task/dependencies.zip .
