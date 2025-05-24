# single Dockerfile that does it all
FROM ruby:3.2.3

# install OS deps + netcat for waiting on Ollama
RUN apt-get update -qq \
 && apt-get install -y nodejs yarn wget ca-certificates netcat-openbsd \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /myapp

# 1) install Ruby gems
COPY Gemfile* ./
RUN bundle install --jobs=4 --retry=3

# 2) copy app source + Ollama installer
COPY . .
# make sure your ollama-install.sh is executable
RUN chmod +x ./ollama-install.sh

# 3) install Ollama & pre-pull your model
RUN ./ollama-install.sh \
 && ollama pull Qwen3:0.6b

# 4) provide a tiny entrypoint to orchestrate startup
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# expose both services
EXPOSE 3000 11434

ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
