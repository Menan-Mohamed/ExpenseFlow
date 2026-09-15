FROM ruby:3.3.5

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3000
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails db:prepare && bundle exec rails db:seed && bundle exec rails s -b 0.0.0.0"]