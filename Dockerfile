FROM public.ecr.aws/lambda/ruby:2.7

# Copy function code
COPY demo.rb /var/task

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "app.LambdaFunction::Handler.process" ]