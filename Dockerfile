FROM ruby:3.0

# Create a non-root user to run the app and own app-specific files
RUN adduser package

# Switch to this user
USER package

# Same was in the docker-compose.yml
WORKDIR /home/package

# Copy over the code. This honors the .dockerignore file.
COPY --chown=package . ./

RUN bundle install