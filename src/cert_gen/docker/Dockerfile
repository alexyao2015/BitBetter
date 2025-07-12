FROM alpine:latest

RUN apk update && \
  apk add --no-cache openssl

COPY entrypoint.sh /

WORKDIR /certs

ENTRYPOINT [ "/entrypoint.sh"]
