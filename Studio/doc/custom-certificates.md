# Installing Custom TLS Certificates in Containers

When working with Hackolade CLI in Docker containers, you may need to trust custom TLS certificates to establish secure connections to internal services or systems that use self-signed certificates or certificates from private Certificate Authorities (CAs).

## Overview

Trusting a private CA is a read-only operation: mount the certificate into the container and point the runtime at it with an environment variable. There is no installation step, nothing runs as root, and nothing is written to the container filesystem — which is what makes this work with `read_only: true` and with a Kubernetes `readOnlyRootFilesystem` security context.

Two environment variables cover everything the CLI does:

| Variable | Used by | Notes |
| --- | --- | --- |
| `NODE_EXTRA_CA_CERTS` | Hackolade Studio and the CLI (Node/Electron) | Additive: your CA is trusted **in addition to** the public roots bundled with the image |
| `SSL_CERT_FILE` | Tools that link OpenSSL directly, such as `git` over HTTPS | Replacing: the file you point at becomes the complete trust store |

Because `SSL_CERT_FILE` replaces rather than extends the trust store, point it at a bundle that contains both your CA and the public roots when the container also has to reach public endpoints — for example license validation against Hackolade's servers. Building that bundle is a one-liner and is covered below.

> Earlier versions of this guide used an `installCustomCertificates` service that ran `update-ca-certificates` as root against a shared volume. That approach is no longer needed, and no longer works with a read-only root filesystem. Remove the service and the `installed-tls-certificates` volume when you migrate.

## Quick start

### 1. Put your certificate somewhere the container can read

Use PEM format — the file starts with `-----BEGIN CERTIFICATE-----`. A single file may contain a chain.

```
./certificates/internal-ca.crt
```

### 2. Mount it read-only and set the variable

```yaml
services:
  hck-cli:
    image: hackolade/hck-cli:8.12.7
    command: ["version"]
    read_only: true
    user: "1000:1001"
    environment:
      NODE_EXTRA_CA_CERTS: /certs/internal-ca.crt
    volumes:
      - hackolade-studio-data:/data
      - ./certificates/internal-ca.crt:/certs/internal-ca.crt:ro
    tmpfs:
      - /tmp:rw,size=1g,mode=1777

volumes:
  hackolade-studio-data:
```

That is the whole configuration. Run any command as usual:

```bash
docker compose run --rm hck-cli genDoc --format=HTML --model '/data/models/model.hck.json' --doc /data/output/doc
```

### 3. Add `SSL_CERT_FILE` only if you need it

Reverse-engineering connectors and Git integration that use OpenSSL rather than Node's TLS stack read `SSL_CERT_FILE`. Since it replaces the trust store, build a bundle that also carries the public roots:

```bash
mkdir -p certificates
docker run --rm --entrypoint cat hackolade/hck-cli:8.12.7 \
  /etc/ssl/certs/ca-certificates.crt > certificates/ca-bundle.crt
cat certificates/internal-ca.crt >> certificates/ca-bundle.crt
```

Then mount the bundle and point both variables at it:

```yaml
    environment:
      NODE_EXTRA_CA_CERTS: /certs/ca-bundle.crt
      SSL_CERT_FILE: /certs/ca-bundle.crt
    volumes:
      - ./certificates/ca-bundle.crt:/certs/ca-bundle.crt:ro
```

Regenerate the bundle whenever you upgrade the image, so it keeps the public roots that version ships with.

## Kubernetes

Mount the CA from a `ConfigMap` or `Secret` and set the variable. No init container and no privileged step:

```yaml
spec:
  containers:
    - name: hck-cli
      image: hackolade/hck-cli:8.12.7
      env:
        - name: NODE_EXTRA_CA_CERTS
          value: /certs/internal-ca.crt
      volumeMounts:
        - name: custom-ca
          mountPath: /certs
          readOnly: true
      securityContext:
        readOnlyRootFilesystem: true
        runAsNonRoot: true
        runAsUser: 1000
        allowPrivilegeEscalation: false
        capabilities: { drop: ["ALL"] }
  volumes:
    - name: custom-ca
      configMap:
        name: internal-ca
```

Create the ConfigMap from your PEM file:

```bash
kubectl create configmap internal-ca --from-file=internal-ca.crt=./certificates/internal-ca.crt
```

## Behind an intercepting proxy

When traffic is intercepted (a corporate proxy, mitmproxy, Zscaler), you need the proxy's CA in addition to the proxy variables:

```yaml
    environment:
      HTTPS_PROXY: http://proxy.internal:8080
      HTTP_PROXY: http://proxy.internal:8080
      NO_PROXY: localhost,127.0.0.1
      NODE_EXTRA_CA_CERTS: /certs/proxy-ca.crt
    volumes:
      - ./certificates/proxy-ca.crt:/certs/proxy-ca.crt:ro
```

Online license validation goes through the same stack, so `validateKey` is a good way to confirm the CA is being picked up.

## Updating certificates

Replace the PEM file on the host and restart the container. There is no cached copy inside the image and nothing to reinstall.

## Troubleshooting

**Certificate not trusted**

- Confirm the mount arrived and the path matches the variable:
  ```bash
  docker compose run --rm --entrypoint sh hck-cli -c 'ls -l "$NODE_EXTRA_CA_CERTS"'
  ```
- Confirm the file is PEM, not DER. A DER file is binary; convert it with
  `openssl x509 -inform der -in cert.cer -out cert.crt`.
- If only some operations fail, the failing one is likely using OpenSSL rather than Node. Add `SSL_CERT_FILE` as described above.

**Public endpoints stopped working after setting `SSL_CERT_FILE`**

You pointed it at a file containing only your private CA, which replaced the public roots. Rebuild the bundle so it contains both.

## Related documentation

- [Getting Started with hck-cli](./getting-started-hck-cli.md) - Main guide for using the Hackolade CLI Docker image
