# Kubernetes examples for hackolade/hck-cli
#
# All manifests follow the Kubernetes Restricted Pod Security Standard and match
# compose.hardened.yml: read-only root filesystem, dropped capabilities, non-root
# user, persistent storage at /data, and a memory-backed emptyDir at /tmp.
#
# Files:
#   hck-cli-job.yaml            — smoke test (version) with PVC + /tmp emptyDir
#   hck-cli-job-openshift.yaml  — same, but for OpenShift restricted-v2 (arbitrary UID)
#   hck-cli-gendoc-job.yaml     — generate documentation from a model on the PVC
#
# Apply (pick the manifest that matches your platform):
#   kubectl apply -f hck-cli-job.yaml
#   kubectl apply -f hck-cli-job-openshift.yaml
#   kubectl apply -f hck-cli-gendoc-job.yaml
#
# Prerequisites:
#   - A validated license stored on the /data PVC (run validateKey once via a Job
#     or copy license state from a Docker Compose volume).
#   - For genDoc: place a model at /data/models/smoke.hck.json on the PVC.
