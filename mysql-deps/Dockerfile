# This image has been built from an image that matches the Lambda Ruby runtime
# MySql binary dependencies have been embedded into the image
FROM cdluc3/mysql-ruby-lambda

ARG USERNAME=USER
ARG GITHUB_TOKEN=TOKEN

# This Dockerfile is used to build all project dependencies including those that require a GitHub token to pull
# This code is used in a GitHub Actions workflow to build Lambda dependencies
COPY Gemfile ./

# This can pull pre-built Gems from GitHub
RUN bundle config https://rubygems.pkg.github.com/CDLUC3 ${USERNAME}:${GITHUB_TOKEN} && \
    bundle install && \
    # Zip the dependencies
    zip -r mysql-dependencies.zip .

# Sleep the docker container for 10 seconds.  This will allow the generated zip file to be copied out of the container.
CMD sleep 10
