# Image variants, startup checks, and arbitrary UIDs

**Part of:** [Getting started](./getting-started-hck-cli.md) · [All guides](../README.md#documentation)

This page covers three things the other guides only mention in passing:

1. **`hackolade/hck-cli:<version>` vs `hackolade/hck-cli:<version>-hardened`** — two OS bases, same CLI
2. **Startup preflight** — what `hck-cli` checks before Studio runs, and which failures are fatal
3. **Arbitrary UID** — what Kubernetes / OpenShift actually inject, and the constraints that follow

## Two meanings of “hardened”

| What | Where it shows up | What it changes |
| --- | --- | --- |
| **Image tag** `-hardened` | `hackolade/hck-cli:8.12.8-hardened` | OS **base**: [Docker Hardened Images](https://docs.docker.com/dhi/) (Debian) instead of Ubuntu 26.04 LTS |
| **Runtime profile** | [`compose.hardened.yml`](../compose.hardened.yml), [`k8s/`](../k8s/) | **How you run** the container: read-only rootfs, `cap_drop: ALL`, non-root, no-new-privileges |

They combine independently. Use the Ubuntu 26.04 tag or the `-hardened` tag with `compose.yml`, `compose.hardened.yml`, or the Kubernetes Jobs. The CLI, plugins, volume layout, and preflight checks are the same.

`compose.hardened.yml` is named for the **runtime profile**, not for the `-hardened` image tag. Point `image:` at whichever tag your policy requires.

## Image tags

`latest` is not published. Pin a Studio version.

| Tag | Base OS | Meaning |
| --- | --- | --- |
| `hackolade/hck-cli:8.12.8` | **Ubuntu 26.04 LTS** (Resolute Raccoon) | Current Studio release (default) |
| `hackolade/hck-cli:8.12.8-hardened` | Docker Hardened Image (Debian) | Same Studio release and plugins, DHI base |
| `hackolade/hck-cli:8.12.8-2026-08-07` | Ubuntu 26.04 LTS | Intermediate tag (plugin refreshes on the current release) |
| `hackolade/hck-cli:8.12.8-2026-08-07-hardened` | Docker Hardened Image (Debian) | Same intermediate build on the DHI base |

The un-suffixed **8.12.8** runtime reports:

```text
PRETTY_NAME="Ubuntu 26.04 LTS"
NAME="Ubuntu"
VERSION_ID="26.04"
VERSION="26.04 LTS (Resolute Raccoon)"
VERSION_CODENAME=resolute
ID=ubuntu
```

(`cat /etc/os-release` inside the container.) Later Studio releases may move the default tag to a newer Ubuntu; pin the image and re-check `/etc/os-release` if the base OS matters for your policy.

See [Docker Hub tags](https://hub.docker.com/r/hackolade/hck-cli/tags). Re-validate the floating license when the image tag (or digest) changes — license state is tied to the image UUID.

### What is the same on both bases

- Hackolade Studio CLI, bundled plugins, `hck-cli` entrypoint
- Numeric `USER 1000:1001` (`hackolade` / `data-modelers`)
- Writable roots: **`/data`** (persistent) and **`/tmp`** (scratch)
- `/data` owned **`1000:0` mode 2775** (setgid) so an OpenShift-style arbitrary UID in **group 0** can write
- `libnss-wrapper` so a UID with no `/etc/passwd` entry still resolves for Studio
- Startup preflight and license flow

### What differs on `-hardened`

The Docker Hardened Image base is a minimal Debian image. Apt **recommends are disabled**, extra packages (passwd, ssh, sudo, systemd) are stripped after build-time user setup, and the default account is the DHI `nonroot` user renamed to `hackolade` (Ubuntu tags rename `ubuntu`).

Functionally you still run the same CLI. Choose `-hardened` when policy requires a DHI-based image; choose the un-suffixed tag when you want **Ubuntu 26.04 LTS**.

```bash
# Default (Ubuntu 26.04 LTS)
image: hackolade/hck-cli:8.12.8

# DHI Debian base — same compose / Kubernetes files
image: hackolade/hck-cli:8.12.8-hardened
```

## Startup preflight

On the official `hackolade/hck-cli` image, `hck-cli` prepares the Linux/Electron stack **before** Studio starts. Typical log lines:

```text
[hackolade-cli-image/linux] Runtime detected (hackolade-cli-image/linux)
[hackolade-cli-image/linux] Checking writable mounts
[hackolade-cli-image/linux] Checking volume mounts
[hackolade-cli-image/linux] Ensuring Docker log directory (/data/logs)
Activating license key...
```

| Step | Severity | What it requires |
| --- | --- | --- |
| Runtime detected | Info | Official CLI image |
| **Checking writable mounts** | **Fatal** if any required path cannot be written | `/data/app` (license / Electron userData), `/data/logs`, `/tmp`, and the XDG runtime dir under `/tmp` |
| Checking volume mounts | Warning | License and logs should sit on a **volume** so they survive `docker compose run --rm`. Skipped for `version`, `help`, `getComputerId`, `showLicense`, `listLogs`, `showLogs`, `warm-cache` |
| Ensuring Docker log directory | Info | Creates `/data/logs` when the volume is writable |
| Passwd for the current UID | Silent unless the UID is unknown | `libnss-wrapper` synthesizes a passwd entry on the tmpfs (OpenShift random UID) |
| D-Bus / gnome-keyring / safeStorage | Fatal only if those daemons fail later | `/tmp` must be writable (tmpfs recommended) |
| Activating license | Depends on online/offline setup | See [license-validation.md](./license-validation.md) |

Writable-mount checks run **after** env alignment, so a legacy bind mount at `/home/hackolade/.config` still counts as the config home on a writable rootfs. With `read_only: true`, only `/data` and `/tmp` can succeed.

### Fatal: no writable location

```text
The container has no writable location for data it must produce.

Running as uid=31337 gid=31337 groups=31337.

Not writable:
  /data/app (license state and Electron userData)
  /data/logs (CLI run logs)
```

Usual causes:

1. **`/data` or `/tmp` not mounted** (or tmpfs mode wrong — Compose long-form `tmpfs.mode: 1777` is decimal; use `1023`, or the short form `tmpfs: ["/tmp:rw,size=1g,mode=1777"]`).
2. **Arbitrary UID without group 0** — see [below](#arbitrary-uid).
3. **Named volume created as `root:root` `755`** — first mount of an empty volume should copy the image’s `1000:0` `2775` layout. If the volume already existed with the wrong owner, recreate it (`docker volume rm …`) or set Kubernetes `fsGroup` so the kubelet can chown it.
4. **Host bind** under `/data/models` (or similar) not writable by the container UID/GID.

## Arbitrary UID

The image is built so **Kubernetes and OpenShift can assign a random UID**. That is an arbitrary **UID**, not an arbitrary **primary GID**.

### What the orchestrator injects

| Runtime | UID | Group 0 |
| --- | --- | --- |
| Default image `USER` | `1000` | Primary GID is **`1001`** (`data-modelers`). UID 1000 still writes `/data` as **owner**. |
| OpenShift `restricted-v2` | Random (no passwd entry) | **Group 0** as primary or supplemental. `runAsUser` is omitted; SCC assigns the UID. |
| Kubernetes Restricted | You set `runAsUser` (or keep 1000) | Add group 0 with **`fsGroup: 0`** and/or `runAsGroup: 0`. |
| Compose / `docker run` | You set `user:` | Keep group 0 with **`group_add: ["0"]`** (already in [`compose.hardened.yml`](../compose.hardened.yml)) or `user: "<uid>:0"`. |

`nss-wrapper` only invents a passwd line so `os.userInfo()` and gnome-keyring do not crash. It does **not** chmod the volume. Writability comes from:

- `/data` in the image: owner `1000`, group `0`, directories `2775` (setgid)
- `/tmp`: tmpfs `mode=1777` (any UID)

Copying the image `USER` as `"<uid>:1001"` or `"<uid>:<uid>"` **without** group 0 is not what OpenShift does, and `/data` will not be writable.

### Compose

[`compose.hardened.yml`](../compose.hardened.yml) already sets `group_add: ["0"]` on the base service, so overriding `user:` keeps group 0:

```bash
# OpenShift-style primary GID 0 (service hck-cli-arbitrary-uid)
docker compose -f compose.hardened.yml run --rm hck-cli-arbitrary-uid

# Fully arbitrary primary GID — still works because group_add: ["0"]
docker compose -f compose.hardened.yml run --rm --user 31337:31337 hck-cli
```

If you omit `group_add` in your own compose file:

```yaml
user: "31337:0"          # primary GID 0
# or
user: "31337:31337"
group_add:
  - "0"
```

### Kubernetes / OpenShift

Use [`k8s/hck-cli-job.yaml`](../k8s/hck-cli-job.yaml) for a fixed UID `1000:1001` with `fsGroup: 0`.

Use [`k8s/hck-cli-job-openshift.yaml`](../k8s/hck-cli-job-openshift.yaml) for `restricted-v2`:

```yaml
securityContext:
  runAsNonRoot: true
  # runAsUser omitted — SCC assigns an arbitrary UID
  runAsGroup: 0
  fsGroup: 0
```

Some clusters assign `fsGroup` from the namespace range (not `0`). That still works: the kubelet chowns the PVC to that group and adds it as a supplemental group. Image ownership of `/data` then matters less than `fsGroup` on the volume.

### `docker run`

```bash
docker run --rm \
  --init --read-only --user 31337:0 --group-add 0 \
  --cap-drop ALL --security-opt no-new-privileges:true \
  -v hackolade-studio-data:/data \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.12.8-hardened version
```

`--user 31337` (UID only, no GID) typically defaults GID to `0` when the UID is not in `/etc/passwd`. `--user 31337:31337` needs `--group-add 0`.

### Bind-mounted host folders

Host paths under `/data` (models, output) must be writable by the **container** UID, or by group 0 if you rely on the OpenShift group. For the default user:

```bash
chown -R 1000:1001 ./models
```

For an OpenShift-style UID, prefer a PVC with `fsGroup` rather than a hostPath, or chown the host tree so group 0 can write (`chown -R 1000:0` and `chmod g+w`).

## See also

- [Getting started](./getting-started-hck-cli.md) — `/data` + `/tmp`, deployment profiles, quick start
- [Docker CLI how-to](./docker-cli-howto.md) — `docker run` templates
- [Kubernetes examples](../k8s/README.md)
- [License validation](./license-validation.md)
