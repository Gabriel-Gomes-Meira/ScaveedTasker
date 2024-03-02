# syntax=docker/dockerfile:1
FROM ruby:3.1.2
RUN apt-get update -qq && apt-get install -y postgresql-client libpq-dev wget curl firefox-esr
WORKDIR /myapp
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
COPY geckodriver /usr/bin
RUN chmod +x /usr/bin/geckodriver
RUN bundle install
RUN gem install pg


# Configure the main process to run when running the image
CMD ["ruby", "main.rb"]
