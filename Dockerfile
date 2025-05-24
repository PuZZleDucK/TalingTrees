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

# bring in our entrypoint helper
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3000 11434
ENTRYPOINT ["entrypoint.sh"]
