#!/bin/bash


# To enable SSL/TLS for Redis, you need to create a CA certificate and 
# server certificates. You can use tools like OpenSSL to generate these 
# certificates.
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -sha256 -days 3650 -out ca-cert.pem

openssl genrsa -out server-key.pem 2048
openssl req -new -key server-key.pem -out server.csr
openssl x509 -req -in server.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -days 3650 -sha256
