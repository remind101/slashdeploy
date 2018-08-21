FROM ruby:2.5.1
RUN apt-get update && \
  apt-get install -y build-essential openssl libssl-dev libpq-dev postgresql-client
RUN gem install bundler

RUN mkdir -p /home/app
WORKDIR /home/app

COPY Gemfile /home/app/
COPY Gemfile.lock /home/app/
RUN bundle install --jobs 4 --retry 3

COPY . /home/app

CMD ["bundle", "exec", "rake"]