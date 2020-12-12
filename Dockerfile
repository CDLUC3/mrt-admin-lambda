# This image has been built from an image that matches the Lambda Ruby runtime
# MySql binary dependencies have been embedded into the image
FROM cdluc3/mysql-ruby-lambda as mysql

FROM public.ecr.aws/lambda/ruby:2.7

COPY --from=mysql /usr/lib64/mysql/ /usr/lib64/mysql
COPY --from=mysql /var/task/vendor .

ARG GH_TOKEN

#RUN gem update bundler

# Copy function code
COPY src/ /var/task/

RUN find /usr/lib64/mysql

RUN bundle config https://rubygems.pkg.github.com/CDLUC3 ${GH_TOKEN} && \
    bundle install 

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "lambda_function.LambdaFunctions::Handler.process" ]

