# Use a base image suitable for your Rails application
FROM ruby:3.0.3

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    yarn

# Set the working directory in the container
WORKDIR /app

# Copy Gemfile and Gemfile.lock to the container
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle install

# Copy the rest of your Rails application code to the container
COPY . .

# Set the entrypoint script
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

# Expose port 3000
EXPOSE 3000

# Start the Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]
