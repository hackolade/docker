# Installing Custom TLS Certificates in Containers

When working with Hackolade CLI in Docker containers, you may need to install custom TLS certificates to establish secure connections to internal services or systems that use self-signed certificates or certificates from private Certificate Authorities (CAs).

## Overview

The `compose.yml` file includes an `installCustomCertificates` service that helps you bundle custom certificates into a Docker volume. This volume can then be mounted into any service where you want to run `hck-cli` commands that need to trust these certificates.

## How It Works

1. **Certificate Installation**: The `installCustomCertificates` service runs `update-ca-certificates` as root to bundle all certificates from `/etc/ssl/certs` into a single `ca-certificates.crt` file.
2. **Volume Storage**: The bundled certificates are stored in the `installed-tls-certificates` Docker volume.
3. **Usage**: Mount this volume into any service where `hck-cli` needs to use the custom certificates.

## Step-by-Step Instructions

### Step 1: Prepare Your Custom Certificate Files

Place your custom certificate files (`.crt` or `.pem` format) in a directory accessible to Docker Compose. For example:

```bash
# Create a directory for your certificates
mkdir -p ./certificates

# Copy your custom certificate(s) to this directory
cp /path/to/your/custom-certificate.crt ./certificates/
cp /path/to/your/another-certificate.crt ./certificates/
```

### Step 2: Configure the installCustomCertificates Service

In your `compose.yml`, uncomment and modify the `installCustomCertificates` service to bind mount your certificate files:

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
    - ./certificates/another-certificate.crt:/etc/ssl/certs/another-certificate.crt:ro
    # Add more certificates as needed
```

**Important Notes:**
- Each certificate file must be bind mounted individually into `/etc/ssl/certs/` with a unique filename
- Use the `:ro` (read-only) flag to prevent accidental modification
- Do **not** override the entire `/etc/ssl/certs` directory - only mount individual certificate files
- The `update-ca-certificates` command will bundle all certificates (including system certificates) into `ca-certificates.crt`

### Step 3: Run the Certificate Installation

Execute the `installCustomCertificates` service to bundle the certificates:

```bash
docker compose run --rm installCustomCertificates
```

This command will:
- Mount your custom certificate files into `/etc/ssl/certs`
- Run `update-ca-certificates` as root to create the bundled `ca-certificates.crt` file
- Store the bundled certificates in the `installed-tls-certificates` volume

**Note:** You only need to run this service once, or whenever you add or update custom certificates. The `installed-tls-certificates` volume will persist the bundled certificates.

### Step 4: Mount the Volume in Services Using hck-cli

To use the custom certificates in any service where you run `hck-cli`, mount the `installed-tls-certificates` volume:

#### Using Docker Compose

Add the volume mount to your service definition:

```yaml
services:
  hck-cli:
    image: hackolade/hck-cli:8.9.2
    command: ["version"]
    restart: 'no'
    volumes:
      - hackolade-studio-app-data:/home/hackolade/.config
      - hackolade-studio-logs:/data/logs
      - ${PWD}/models:/data/models
      - hackolade-studio-output:/data/output
      # Mount the custom certificates volume
      - installed-tls-certificates:/etc/ssl/certs:ro
```

#### Using Docker CLI Directly

When running `docker run` commands, add the volume mount:

```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config \
  -v hackolade-studio-logs:/data/logs \
  -v ${PWD}/models:/data/models \
  -v hackolade-studio-output:/data/output \
  -v installed-tls-certificates:/etc/ssl/certs:ro \
  hackolade/hck-cli:8.9.2 COMMAND [OPTIONS]
```

**Important:** Use the `:ro` (read-only) flag when mounting the `installed-tls-certificates` volume to prevent accidental modification of the bundled certificates.

### Alternative Method: Bind Mount Only ca-certificates.crt

Instead of mounting the entire `installed-tls-certificates` volume, you can extract the `ca-certificates.crt` file and bind mount only that single file. This approach is more lightweight and doesn't require mounting the entire volume.

#### Step 1: Extract ca-certificates.crt from the Volume

After running `installCustomCertificates`, extract the `ca-certificates.crt` file from the volume:

**Option A: Extract from a temporary container**

```bash
# Create a temporary container to extract the file
docker run --rm \
  -v installed-tls-certificates:/source:ro \
  -v ${PWD}/certificates:/output \
  --entrypoint cp \
  hackolade/hck-cli:8.9.2 \
  /source/ca-certificates.crt /output/ca-certificates.crt
```

**Option B: Extract using Docker Compose**

```bash
# Create a temporary service to extract the file
docker compose run --rm --entrypoint cp \
  -v installed-tls-certificates:/source:ro \
  -v ${PWD}/certificates:/output \
  hackolade/hck-cli:8.9.2 \
  /source/ca-certificates.crt /output/ca-certificates.crt
```

**Option C: Use docker cp with a running container**

```bash
# Run the installCustomCertificates service and keep it running briefly
docker compose run -d --name cert-extractor installCustomCertificates

# Copy the file from the container
docker cp cert-extractor:/etc/ssl/certs/ca-certificates.crt ./certificates/ca-certificates.crt

# Clean up
docker rm cert-extractor
```

After extraction, you'll have `./certificates/ca-certificates.crt` on your host system.

#### Step 2: Bind Mount Only ca-certificates.crt

Instead of mounting the entire volume, bind mount only the extracted `ca-certificates.crt` file:

**Using Docker Compose:**

```yaml
services:
  hck-cli:
    image: hackolade/hck-cli:8.9.2
    command: ["version"]
    restart: 'no'
    volumes:
      - hackolade-studio-app-data:/home/hackolade/.config
      - hackolade-studio-logs:/data/logs
      - ${PWD}/models:/data/models
      - hackolade-studio-output:/data/output
      # Bind mount only the ca-certificates.crt file
      - ./certificates/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro
```

**Using Docker CLI Directly:**

```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config \
  -v hackolade-studio-logs:/data/logs \
  -v ${PWD}/models:/data/models \
  -v hackolade-studio-output:/data/output \
  -v ${PWD}/certificates/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro \
  hackolade/hck-cli:8.9.2 COMMAND [OPTIONS]
```

**Advantages of this approach:**
- More lightweight - only mounts a single file instead of the entire volume
- Easier to version control - the `ca-certificates.crt` file can be stored in your repository
- More portable - doesn't depend on Docker volumes existing
- Simpler configuration - direct file path instead of volume reference

**When to use this method:**
- You want to avoid managing Docker volumes
- You need to version control the bundled certificates file
- You're running in environments where volume management is restricted
- You prefer explicit file paths over volume references

**Note:** If you update certificates and re-run `installCustomCertificates`, you'll need to extract the updated `ca-certificates.crt` file again and update your bind mount.

## Complete Example

Here's a complete example showing how to set up and use custom certificates:

### 1. Directory Structure

```
.
├── compose.yml
├── certificates/
│   ├── internal-ca.crt
│   └── company-root-ca.crt
└── models/
    └── my-model.hck.json
```

### 2. compose.yml Configuration

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
      - ./certificates/company-root-ca.crt:/etc/ssl/certs/company-root-ca.crt:ro

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

### 3. Installation and Usage

```bash
# Step 1: Install the custom certificates (run once)
docker compose run --rm installCustomCertificates

# Step 2: Run hck-cli commands - they will now trust your custom certificates
docker compose run --rm hck-cli genDoc \
  --format=HTML \
  --model '/data/models/my-model.hck.json' \
  --doc /data/output/doc-test
```

### Alternative Example: Using Bind Mount for ca-certificates.crt

Here's an example using the alternative method of bind mounting only the `ca-certificates.crt` file:

#### 1. Directory Structure

```
.
├── compose.yml
├── certificates/
│   ├── internal-ca.crt
│   ├── company-root-ca.crt
│   └── ca-certificates.crt  # Extracted after running installCustomCertificates
└── models/
    └── my-model.hck.json
```

#### 2. compose.yml Configuration (Alternative Method)

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
      - ./certificates/company-root-ca.crt:/etc/ssl/certs/company-root-ca.crt:ro

  hck-cli:
    image: hackolade/hck-cli:8.9.2
    command: ["version"]
    restart: 'no'
    volumes:
      - hackolade-studio-app-data:/home/hackolade/.config
      - hackolade-studio-logs:/data/logs
      - ${PWD}/models:/data/models
      - hackolade-studio-output:/data/output
      # Bind mount only the ca-certificates.crt file (alternative to volume mount)
      - ./certificates/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro

volumes:
  hackolade-studio-app-data:
  hackolade-studio-logs:
  hackolade-studio-output:
  installed-tls-certificates:
```

#### 3. Installation and Usage (Alternative Method)

```bash
# Step 1: Install the custom certificates (run once)
docker compose run --rm installCustomCertificates

# Step 2: Extract ca-certificates.crt from the volume
docker run --rm \
  -v installed-tls-certificates:/source:ro \
  -v ${PWD}/certificates:/output \
  --entrypoint cp \
  hackolade/hck-cli:8.9.2 \
  /source/ca-certificates.crt /output/ca-certificates.crt

# Step 3: Run hck-cli commands - they will now trust your custom certificates
docker compose run --rm hck-cli genDoc \
  --format=HTML \
  --model '/data/models/my-model.hck.json' \
  --doc /data/output/doc-test
```

**Note:** With this alternative method, you don't need to mount the `installed-tls-certificates` volume in your `hck-cli` service - only the extracted `ca-certificates.crt` file is bind mounted.

## Updating Certificates

If you need to add or update custom certificates:

1. **Add or replace certificate files** in your certificates directory
2. **Update the `installCustomCertificates` service** in `compose.yml` to include the new certificate bind mounts
3. **Re-run the installation**:
   ```bash
   docker compose run --rm installCustomCertificates
   ```

**If using volume mount method:**
The `installed-tls-certificates` volume will be updated with the new bundled certificates, and all services using this volume will automatically have access to the updated certificates.

**If using bind mount method (ca-certificates.crt only):**
After re-running `installCustomCertificates`, you need to extract the updated `ca-certificates.crt` file again:
```bash
docker run --rm \
  -v installed-tls-certificates:/source:ro \
  -v ${PWD}/certificates:/output \
  --entrypoint cp \
  hackolade/hck-cli:8.9.2 \
  /source/ca-certificates.crt /output/ca-certificates.crt
```
This will update the `ca-certificates.crt` file on your host, and services using the bind mount will automatically use the updated certificates.

## Troubleshooting

### Certificates Not Being Trusted

If `hck-cli` still doesn't trust your certificates:

1. **Verify the volume is mounted**: Check that `installed-tls-certificates` is mounted in your service:
   ```bash
   docker compose run --rm hck-cli ls -la /etc/ssl/certs/ | grep ca-certificates
   ```

2. **Verify certificates were bundled**: Check that `ca-certificates.crt` exists and contains your certificates:
   ```bash
   docker compose run --rm --entrypoint bash \
     -v installed-tls-certificates:/etc/ssl/certs:ro \
     hackolade/hck-cli:8.9.2 \
     -c "grep -i 'your-certificate-name' /etc/ssl/certs/ca-certificates.crt"
   ```

3. **Re-run installation**: If certificates are missing, re-run the installation:
   ```bash
   docker compose run --rm installCustomCertificates
   ```

### Permission Errors

The `installCustomCertificates` service runs as `root` (required for `update-ca-certificates`). If you encounter permission errors:

- Ensure the service has `user: root` specified
- Check that certificate files are readable by the Docker daemon
- Verify volume permissions

### Certificate Format Issues

Ensure your certificate files are in the correct format:

- **PEM format** (recommended): Files should start with `-----BEGIN CERTIFICATE-----`
- **CRT files**: Should be in PEM format (despite the `.crt` extension)
- **Multiple certificates**: Each certificate file should contain a single certificate (not a certificate chain)

If you have a certificate chain, split it into individual certificate files and mount each one separately.

## Security Considerations

- **Read-only mounts**: Always use `:ro` flag when mounting the `installed-tls-certificates` volume to prevent accidental modification
- **Certificate storage**: Store certificate files securely on the host system with appropriate file permissions
- **Volume access**: Only mount the `installed-tls-certificates` volume in services that actually need to trust custom certificates
- **Certificate validation**: Verify the authenticity of custom certificates before installing them

## Related Documentation

- [Getting Started with hck-cli](./getting-started-hck-cli.md) - Main guide for using the Hackolade CLI Docker image
- [Docker Compose Documentation](https://docs.docker.com/compose/) - Official Docker Compose documentation
