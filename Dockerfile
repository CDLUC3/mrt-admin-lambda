# This image has been built from an image that matches the Lambda Ruby runtime
# MySql binary dependencies have been embedded into the image
FROM cdluc3/mysql-ruby-lambda 

COPY src/ /var/task/

RUN bundle install 
