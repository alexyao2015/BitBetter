FROM alpine:latest

RUN apk update && \
  apk add --no-cache openssl && \
  rm -rf "/var/cache/apk/*"

COPY entrypoint.sh /

WORKDIR /certs

ENTRYPOINT [ "/entrypoint.sh"]
