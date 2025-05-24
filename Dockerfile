# Dockerfile for deployment to back4app.com
FROM ruby:3.2.3

RUN apt-get update -qq && apt-get install -y nodejs yarn
WORKDIR /myapp

COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN bundle install

COPY . /myapp
# RUN bundle exec rake ollama:setup
RUN bundle exec rails db:seed
RUN bundle exec rake db:import_trees[15]
RUN ./ollama-install.sh
RUN ollama serve & sleep 5 && ollama pull Qwen3:0.6b && bundle exec rake db:name_trees && bundle exec rake db:add_relationships && bundle exec rake db:system_prompts

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
