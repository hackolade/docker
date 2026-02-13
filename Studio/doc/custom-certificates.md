# Installing Custom TLS Certificates in Containers

When working with Hackolade CLI in Docker containers, you may need to install custom TLS certificates to establish secure connections to internal services or systems that use self-signed certificates or certificates from private Certificate Authorities (CAs).

## Overview

The `compose.yml` file includes an `installCustomCertificates` service that bundles custom certificates into a Docker volume. Mount this volume (or extract the bundled `ca-certificates.crt` file) into any service where you want to run `hck-cli` commands that need to trust these certificates.

## Quick Start

### Step 1: Configure and Run Certificate Installation

1. **Prepare your certificate files** in a directory (e.g., `./certificates/`)

2. **Update `compose.yml`** to bind mount your certificates into the `installCustomCertificates` service:

```yaml
installCustomCertificates:
  image: hackolade/hck-cli:8.9.2
  entrypoint: [ "bash", "-c" ]
  command: ['update-ca-certificates']
  restart: 'no'
  user: root
  volumes:
    - installed-tls-certificates:/etc/ssl/certs
    # Bind mount your custom certificate(s) into /etc/ssl/certs
    - ./certificates/custom-certificate.crt:/etc/ssl/certs/custom-certificate.crt:ro
    # Add more certificates as needed
```

**Important:** Mount individual certificate files (not the entire directory) with unique filenames.

3. **Run the installation**:

```bash
docker compose run --rm installCustomCertificates
```

### Step 2: Use Certificates in hck-cli Services

You have two options:

#### Option A: Mount the Volume (Recommended)

Mount the `installed-tls-certificates` volume in your service:

```yaml
services:
  hck-cli:
    image: hackolade/hck-cli:8.9.2
    volumes:
      - hackolade-studio-app-data:/home/hackolade/.config
      - hackolade-studio-logs:/data/logs
      - ${PWD}/models:/data/models
      - hackolade-studio-output:/data/output
      - installed-tls-certificates:/etc/ssl/certs:ro  # Add this line
```

#### Option B: Bind Mount Only ca-certificates.crt

Extract the bundled certificate file and bind mount it:

1. **Extract the file**:
```bash
docker run --rm \
  -v installed-tls-certificates:/source:ro \
  -v ${PWD}/certificates:/output \
  --entrypoint cp \
  hackolade/hck-cli:8.9.2 \
  /source/ca-certificates.crt /output/ca-certificates.crt
```

2. **Bind mount it** in your service:
```yaml
services:
  hck-cli:
    image: hackolade/hck-cli:8.9.2
    volumes:
      - hackolade-studio-app-data:/home/hackolade/.config
      - hackolade-studio-logs:/data/logs
      - ${PWD}/models:/data/models
      - hackolade-studio-output:/data/output
      - ./certificates/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro  # Add this line
```

## Complete Example

```yaml
services:
  installCustomCertificates:
    image: hackolade/hck-cli:8.9.2
    entrypoint: [ "bash", "-c" ]
    command: ['update-ca-certificates']
    restart: 'no'
    user: root
    volumes:
      - installed-tls-certificates:/etc/ssl/certs
      - ./certificates/internal-ca.crt:/etc/ssl/certs/internal-ca.crt:ro

  hck-cli:
    image: hackolade/hck-cli:8.9.2
    command: ["version"]
    restart: 'no'
    volumes:
      - hackolade-studio-app-data:/home/hackolade/.config
      - hackolade-studio-logs:/data/logs
      - ${PWD}/models:/data/models
      - hackolade-studio-output:/data/output
      - installed-tls-certificates:/etc/ssl/certs:ro

volumes:
  hackolade-studio-app-data:
  hackolade-studio-logs:
  hackolade-studio-output:
  installed-tls-certificates:
```

**Usage:**
```bash
# Install certificates (run once)
docker compose run --rm installCustomCertificates

# Run hck-cli commands
docker compose run --rm hck-cli genDoc --format=HTML --model '/data/models/model.hck.json' --doc /data/output/doc
```

## Updating Certificates

1. Add or replace certificate files in your certificates directory
2. Update the `installCustomCertificates` service in `compose.yml` to include new certificate bind mounts
3. Re-run: `docker compose run --rm installCustomCertificates`

**If using Option B (bind mount):** After re-running, extract the updated `ca-certificates.crt` file again using the extraction command from Step 2.

## Troubleshooting

**Certificates not trusted:**
- Verify the volume/file is mounted: `docker compose run --rm hck-cli ls -la /etc/ssl/certs/ca-certificates.crt`
- Re-run the installation: `docker compose run --rm installCustomCertificates`

**Certificate format:**
- Use PEM format (files should start with `-----BEGIN CERTIFICATE-----`)
- Each file should contain a single certificate (not a chain)

## Related Documentation

- [Getting Started with hck-cli](./getting-started-hck-cli.md) - Main guide for using the Hackolade CLI Docker image
