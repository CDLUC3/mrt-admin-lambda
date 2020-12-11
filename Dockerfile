FROM public.ecr.aws/lambda/ruby:2.7

# Copy function code
COPY app.rb /var/task/app.rb

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "app.LambdaFunctions::Handler.process" ]

