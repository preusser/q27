# Overview

The Java-implemented backbone infrastructure comprises a central
[Server](me/preusser/q27/Server.java) and an attaching
[Client](me/preusser/q27/Client.java). They communicate through
a TLS-secured TCP channel with mutual authentication:

1. The Server hands out subproblems upon the request from a Client.
2. The Client relays assigned subproblems to the attached FPGA solvers, eventually receives the solution count to forward it to the Server.
3. The Server logs a completed subproblem to the manages Q27 database.

# Requirements

1. [Java 8 SE](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

# Authentication

The TLS-secured communication between Server and Clients requires an
appropriate authentication infrastructure. This can be based on a private,
self-signed *Certificate Authority* recognized throughout the system.
Appropriate certificate chains may be generated using `openssl` and `keytool`:

```
# Generate Root Key
openssl genrsa -des3 -out private/root.key 2048

# Create Self-Signed Root Certificate
openssl req -config ca.conf -x509 -new -nodes -key private/root.key -days 1000 -out root.pem
# Dump Certificate
openssl x509 -in root.pem -text
# Convert to Java Keystore Format (use keytool from Java installation!)
keytool -import -keystore root.store -alias Q26CA -file root.pem

# Generate new Client Key and Certificate Request
openssl req -config ca.conf -nodes -newkey rsa -keyout client.key -out client.csr

# Sign Certificate(s)
openssl ca -config ca.conf -in req.csr
openssl ca -config ca.conf -infiles req1.csr req2.csr ...

openssl ca -config ca.conf -extensions srv_cert -in req.csr

# Generate pkcs12-File
openssl pkcs12 -export -out cert.p12 -inkey client.key -in client.pem
```
