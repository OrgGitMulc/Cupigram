ARG RUBY_VERSION=3.2.3
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base
 
# Install packages needed to build gems
RUN apt-get update -yqq
RUN apt-get install -yqq --no-install-recommends nodejs
RUN apt-get install -y build-essential libgmp-dev
 
COPY . /user/src/app/
ARG SECRET_KEY_BASE
 
WORKDIR /user/src/app
 
# Set production environment
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE=$(SECRET_KEY_BASE)
 
RUN gem install bundler:2.4.19
RUN bundle install
RUN bundle exec rake db:create db:migrate db:seed
 
RUN rails assets:precompile
 
# Open port 3000 for the web server
EXPOSE 3000
 
CMD ["rails", "server", "-b", "0.0.0.0"]
