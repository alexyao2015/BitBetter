#!/bin/sh

# Remove any existing key files
[ ! -e "cert.pem" ]  || rm "cert.pem"
[ ! -e "key.pem" ]   || rm "key.pem"
[ ! -e "cert.cert" ] || rm "cert.cert"
[ ! -e "cert.pfx" ]  || rm "cert.pfx"

# Generate new keys
openssl	req -x509 -newkey rsa:4096 -keyout "key.pem" -out "cert.cert" -days 36500 -subj '/CN=www.mydom.com/O=My Company Name LTD./C=US'  -outform DER -passout pass:test
openssl x509 -inform DER -in "cert.cert" -out "cert.pem"
openssl pkcs12 -export -out "cert.pfx" -inkey "key.pem" -in "cert.pem" -passin pass:test -passout pass:test

chmod 644 "cert.pem" "key.pem" "cert.cert" "cert.pfx"
