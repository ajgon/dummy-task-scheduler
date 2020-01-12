FROM ruby:2.7-alpine

RUN apk add --no-cache wget && \
    wget -O /tmp/s6-overlay-amd64.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && \
    rm -rf /tmp/s6-overlay-amd64.tar.gz && \
    apk del --purge wget

WORKDIR /app
COPY Gemfile* /app/

ENV BUNDLE_PATH=/app/vendor

RUN apk update && \
    apk add --no-cache --virtual .build-deps alpine-sdk && \
    gem install bundler && \
    bundle install && \
    apk del --purge .build-deps

RUN apk add --no-cache curl

COPY . /app
COPY ./docker/sidekiq /etc/services.d/sidekiq/run
RUN chown -R nobody:nobody /app

EXPOSE 7777
VOLUME ["/app/tasks"]
ENTRYPOINT ["/init"]
HEALTHCHECK CMD sh -c "(curl -f http://localhost:7777/metrics && curl -f http://localhost:7777) || exit 1"

CMD ["s6-setuidgid", "nobody", "/usr/local/bin/bundler", "exec", "puma"]
