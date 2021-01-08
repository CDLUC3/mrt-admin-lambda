#*********************************************************************
#   Copyright 2021 Regents of the University of California
#   All rights reserved
#*********************************************************************

# This image has been built from an image that matches the Lambda Ruby runtime
# MySql binary dependencies have been embedded into the image

FROM cdluc3/mysql-ruby-lambda 

# Add Admin Tool Code to the image
COPY src/ /var/task/

# Bundle dependencies
RUN bundle install 
