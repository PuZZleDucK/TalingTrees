FROM ollama/ollama:0.6.6

# avoid interactive tzdata prompts, set proper zone
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Australia/Melbourne

USER root
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libssl-dev \
      libreadline-dev \
      zlib1g-dev \
      libffi-dev \
      libyaml-dev \
      git \
      curl \
      nodejs \
      yarn \
      libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# asdf for Ruby 3.2.3 (your .tool-versions)
ENV ASDF_DIR=/root/.asdf
ENV PATH=${ASDF_DIR}/bin:${ASDF_DIR}/shims:${PATH}

RUN git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} --branch v0.12.0

WORKDIR /myapp
COPY .tool-versions Gemfile Gemfile.lock ./

RUN bash -lc "\
      . ${ASDF_DIR}/asdf.sh && \
      asdf plugin-add ruby || true && \
      asdf install && \
      asdf global ruby \$(awk '/^ruby/ {print \$2}' .tool-versions) \
    " && \
    bash -lc "gem install bundler && bundle install --jobs 4 --retry 3"

# copy the rest of your code
COPY . .
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE=705bbf912138dbddea76f9a859a37a9f1e966d0d61fdc9f093ded8f4bfa44f0104ebae62022199d31700a8346aa912f39212ca2f7d8e8cc9a3f7600a2eb3375c
RUN bundle exec rails db:migrate
RUN bundle exec rails db:seed
RUN bundle exec rake db:download_trees
RUN bundle exec rake db:import_trees

# bring in our entrypoint helper
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3000 11434
ENTRYPOINT ["entrypoint.sh"]
