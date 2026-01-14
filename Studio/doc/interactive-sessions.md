# Using Hackolade Studio Docker Image Interactively

Sometimes you may want to run the Docker container interactively to explore the environment, debug issues, or run multiple commands in the same session. This guide explains how to use the Hackolade Studio Docker image in an interactive shell session.

---

## What is an Interactive Session?

An interactive session allows you to open a shell (command prompt) inside a running Docker container. This is useful when you want to:
- Run multiple Hackolade CLI commands without starting a new container each time
- Explore the container's file system
- Debug issues by inspecting files and logs
- Test commands before scripting them
- Work with files interactively

---

## Starting an Interactive Session

To start an interactive session, you need to override the default entrypoint with `bash` (or another shell).

### Method 1: Using Docker CLI

**Basic interactive session:**
```bash
docker run -it --rm \
  --entrypoint /bin/bash \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest
```

**What each part does:**
- `docker run` - Creates and runs a container
- `-it` - Interactive terminal (allows you to type commands)
- `--rm` - Automatically removes the container when you exit
- `--entrypoint /bin/bash` - Overrides the default entrypoint to start a bash shell
- `-v ...` - Mounts volumes (same as regular commands)
- `-w /home/hackolade/Documents` - Sets the working directory
- `hackolade:latest` - The image to use

**With all volumes (recommended):**
```bash
docker run -it --rm \
  --entrypoint /bin/bash \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest
```

### Method 2: Using Docker Compose

Docker Compose doesn't have a direct equivalent for interactive sessions, but you can use Docker CLI with the same volumes. Alternatively, you can create a temporary override:

```bash
docker compose run --rm --entrypoint /bin/bash hackoladeStudioCLI
```

This will start an interactive bash session with all volumes from `docker-compose.yml` automatically mounted.

---

## Running Hackolade CLI Commands in Interactive Sessions

Once you're inside the interactive shell, you **cannot** run Hackolade CLI commands directly. Instead, you must use the `startup.sh` script.

### Basic Syntax

```bash
startup.sh <COMMAND> [OPTIONS]
```

### Examples

**Show help:**
```bash
startup.sh help
```

**Check version:**
```bash
startup.sh version
```

**Generate documentation:**
```bash
startup.sh genDoc \
  --model=/home/hackolade/Documents/models/model.json \
  --format=HTML \
  --doc=/home/hackolade/Documents/output/doc.html
```

**Forward engineering:**
```bash
startup.sh forweng \
  --model=/home/hackolade/Documents/models/model.json \
  --jsonschemacompliance=full \
  --skipUndefinedLevel \
  --structuredpath=false \
  --path=/home/hackolade/Documents/output/ \
  --outputtype=jsonschema
```

**Reverse engineering:**
```bash
startup.sh revEng \
  --target=MONGODB \
  --connectFile=/home/hackolade/Documents/models/connection.bin \
  --model=/home/hackolade/Documents/models/output-model.json \
  --selectedObjects="database_name" \
  --inferRelationships=true
```

---

## Example Scenario: Interactive Development Workflow

Let's walk through a practical scenario where you want to:
1. Explore the container environment
2. Check what model files are available
3. Run multiple commands in sequence
4. Inspect generated output files

### Step 1: Start an Interactive Session

```bash
docker run -it --rm \
  --entrypoint /bin/bash \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest
```

You should see a prompt like:
```bash
hackolade@container-id:/home/hackolade/Documents$
```

### Step 2: Explore the Environment

Once inside, you can explore:

**Check current directory:**
```bash
pwd
# Output: /home/hackolade/Documents
```

**List available model files:**
```bash
ls -la models/
```

**Check if output directory exists:**
```bash
ls -la output/
```

### Step 3: Run Multiple Commands

Now you can run multiple Hackolade commands in the same session:

**First, check the version:**
```bash
startup.sh version
```

**List available models:**
```bash
ls -lh models/
```

**Generate documentation for a model:**
```bash
startup.sh genDoc \
  --model=/home/hackolade/Documents/models/my-model.json \
  --format=HTML \
  --doc=/home/hackolade/Documents/output/doc.html
```

**Check if the documentation was created:**
```bash
ls -lh output/
```

**Generate PDF documentation for the same model:**
```bash
startup.sh genDoc \
  --model=/home/hackolade/Documents/models/my-model.json \
  --format=PDF \
  --doc=/home/hackolade/Documents/output/doc.pdf
```

**Forward engineer the model:**
```bash
startup.sh forweng \
  --model=/home/hackolade/Documents/models/my-model.json \
  --jsonschemacompliance=full \
  --path=/home/hackolade/Documents/output/ \
  --outputtype=jsonschema
```

### Step 4: Inspect Generated Files

**List all generated files:**
```bash
find output/ -type f
```

**View the HTML documentation (first few lines):**
```bash
head -20 output/doc.html
```

**Check log files:**
```bash
ls -lh HackoladeLogs/
tail -50 HackoladeLogs/hackolade.log
```

**Check file sizes:**
```bash
du -sh output/*
```

### Step 5: Exit the Session

When you're done, exit the interactive session:
```bash
exit
```

Or press `Ctrl+D`.

The container will automatically be removed (because of `--rm` flag).

---

## Advanced: Keeping a Container Running

If you want to keep the container running and reconnect to it later, you can start it without `--rm` and in detached mode:

**Start a detached container:**
```bash
docker run -d --name hackolade-interactive \
  --entrypoint /bin/bash \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest -c "tail -f /dev/null"
```

**Connect to the running container:**
```bash
docker exec -it hackolade-interactive /bin/bash
```

**Stop and remove the container when done:**
```bash
docker stop hackolade-interactive
docker rm hackolade-interactive
```

---

## Tips and Best Practices

### 1. Always Mount Required Volumes

Make sure to mount all necessary volumes, especially:
- `hackolade-studio-app-data` - For license and settings
- `hackolade-studio-logs` - For log files
- `hackolade-studio-output` - For generated files
- Your models folder - For input files

### 2. Use Absolute Paths in Commands

When running `startup.sh` commands, use absolute paths:
```bash
# Good
startup.sh genDoc --model=/home/hackolade/Documents/models/model.json --doc=/home/hackolade/Documents/output/doc.html

# Avoid relative paths (may not work as expected)
startup.sh genDoc --model=models/model.json --doc=output/doc.html
```

### 3. Check Your Working Directory

The default working directory is `/home/hackolade/Documents`. You can verify this:
```bash
pwd
```

### 4. Inspect Files Before Running Commands

Before running commands, verify your files exist:
```bash
ls -la models/
cat models/my-model.json | head -20
```

### 5. Check Logs for Errors

If a command fails, check the logs:
```bash
tail -100 HackoladeLogs/Hackolade.log
```

### 6. Use Tab Completion

Bash tab completion works in interactive sessions, so you can:
- Press `Tab` to auto-complete file names
- Press `Tab` twice to see available options

---

## Troubleshooting

### Issue: "startup.sh: command not found"

**Solution:** Make sure you're using the correct script name. It should be `startup.sh`, not `hackolade` or any other name.

### Issue: "Permission denied" when accessing files

**Solution:** Check file permissions:
```bash
ls -la models/
chmod +r models/*.json  # If needed
```

### Issue: "License validation failed"

**Solution:** Make sure the `hackolade-studio-app-data` volume is mounted when running the container.

### Issue: Generated files not appearing

**Solution:**
1. Check that the output volume is mounted
2. Verify the path in your command
3. Check for errors in logs:
```bash
tail -50 HackoladeLogs/hackolade.log
```

---

## Comparison: Interactive vs Non-Interactive

| Feature | Interactive Session | Non-Interactive (One-shot) |
|---------|-------------------|---------------------------|
| **Command execution** | Multiple commands in one session | One command per container |
| **File inspection** | Easy to explore files | Need to extract files first |
| **Debugging** | Can inspect environment | Limited debugging |
| **Resource usage** | Container stays running | Container removed after command |
| **State safety** | ⚠️ State persists between commands (can cause issues) | ✅ Fresh state for each command (safer, **preferred**) |
| **Use case** | Development, debugging, exploration | CI/CD pipelines, automation (**recommended for production**) |

---

## Summary

Interactive sessions are useful for:
- **Development and testing** - Run multiple commands quickly
- **Debugging** - Inspect files and logs easily
- **Exploration** - Learn about the container environment

**Important:** Non-interactive (one-shot) commands are **preferred** for most use cases because they provide a fresh state for each command, making them safer and more predictable. Interactive sessions can retain state between commands, which may lead to unexpected behavior.

Remember:
- Always use `startup.sh <COMMAND>` to run Hackolade CLI commands
- Mount all necessary volumes
- Use absolute paths in commands
- Exit with `exit` or `Ctrl+D` when done

For production workflows, automation, and CI/CD pipelines, **always use non-interactive one-shot commands**. See the [Getting Started Guide](./getting-started.md) for those examples.
