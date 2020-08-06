# This image is based on an architecture that matches the Lambda Ruby runtime
FROM cdluc3/mysql-ruby-lambda

ARG USERNAME=USER
ARG GITHUB_TOKEN=TOKEN

# Start with a Gemfile containing only MySQL
COPY Gemfile ./

RUN bundle config https://rubygems.pkg.github.com/CDLUC3 ${USERNAME}:${GITHUB_TOKEN} && \
    bundle install && \
    # Zip the dependencies
    zip -r mysql-dependencies.zip .

# Sleep the docker container for 10 seconds.  This will allow the generated zip file to be copied out of the container.
CMD sleep 10
