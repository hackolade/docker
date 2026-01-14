# Running with Electron Chrome sandboxing enabled

By default, Hackolade Studio CLI runs with Chrome sandboxing **disabled** for simplicity. This is safe because:
- Containers provide their own security isolation
- Hackolade only loads local application code (no external websites)
- We use the `--no-sandbox` Chrome flag

This default approach allows us to avoid using the **securityPolicies.json** file as a seccomp profile, which can be problematic in some security contexts.

However, if your organization's security policies require Chrome sandboxing to be enabled, you can do so by setting the `WITH_SANDBOXING` environment variable and using the **securityPolicies.json** file.

---

## Enabling Chrome Sandboxing

### Method 1: Using Docker CLI

When running commands with Docker CLI, add the environment variable and security profile:

```bash
docker run --rm \
  --security-opt seccomp=../securityPolicies.json \
  -e WITH_SANDBOXING=true \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest COMMAND [OPTIONS]
```

**What this does:**
- `--security-opt seccomp=../securityPolicies.json` - Applies the security policies file (adjust the path if needed)
- `-e WITH_SANDBOXING=true` - Enables Chrome sandboxing inside the container
- The rest of the command is the standard Docker CLI setup

**Example: Running help with sandboxing enabled**
```bash
docker run --rm \
  --security-opt seccomp=../securityPolicies.json \
  -e WITH_SANDBOXING=true \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest help
```

**Note:** Make sure the path to `securityPolicies.json` is correct relative to where you're running the command. If the file is in the same directory, use `./securityPolicies.json`. If it's in the parent directory, use `../securityPolicies.json`.

### Method 2: Using Docker Compose

With Docker Compose, you can enable sandboxing by:

**Option A: Set environment variable in the command (temporary)**
```bash
docker compose run --rm -e WITH_SANDBOXING=true hackoladeStudioCLI COMMAND [OPTIONS]
```

However, you also need to uncomment the security profile in your `docker-compose.yml` file:

```yaml
services:
  hackoladeStudioCLI:
    image: hackolade:latest
    working_dir: /home/hackolade/Documents
    security_opt:
    - seccomp:securityPolicies.json
    environment:
    - WITH_SANDBOXING=true
    volumes:
    # ... rest of your volumes
```

**Option B: Configure in docker-compose.yml (permanent)**

Edit your `docker-compose.yml` file and uncomment/modify these lines:

```yaml
services:
  hackoladeStudioCLI:
    image: hackolade:latest
    working_dir: /home/hackolade/Documents
    security_opt:
    - seccomp:securityPolicies.json
    environment:
    - WITH_SANDBOXING=true
    volumes:
    # ... your existing volumes
```

Then run commands normally:
```bash
docker compose run --rm hackoladeStudioCLI COMMAND [OPTIONS]
```

**Example: Running help with sandboxing enabled**
```bash
docker compose run --rm hackoladeStudioCLI help
```

---

## Important Notes

- **Security policies file location**: The `securityPolicies.json` file must be accessible. With Docker CLI, specify the path explicitly. With Docker Compose, it should be in the same directory as `docker-compose.yml` or adjust the path in the configuration.

- **Performance**: Enabling sandboxing may have a slight performance impact, but it's usually negligible.

- **When to use**: Only enable sandboxing if your organization's security policies require it. The default (sandboxing disabled) is safe and simpler for most use cases.

- **Troubleshooting**: If you encounter errors with sandboxing enabled, check that:
  1. The `securityPolicies.json` file path is correct
  2. The file is readable by Docker
  3. Your Docker daemon supports seccomp profiles
