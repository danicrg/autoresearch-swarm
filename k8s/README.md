# Kubernetes Backend

Optional: run experiments on a k8s cluster instead of locally.

## Prerequisites

- `kubectl` configured and pointing at your cluster
- At least one node with an NVIDIA GPU and the [device plugin](https://github.com/NVIDIA/k8s-device-plugin)
- A shared filesystem (PVC) with `ReadWriteMany` access

## Setup

### 1. Configure `job-template.yaml`

Edit `k8s/job-template.yaml`:
- Replace `YOUR_PVC_NAME` with your PVC (find it with `kubectl get pvc`)
- Uncomment `nodeSelector`/`tolerations` if your GPU nodes have taints
- Change the image if needed (default: `pytorch/pytorch:2.9.1-cuda12.8-cudnn9-devel`)

### 2. Launch the workspace pod

```bash
kubectl apply -f k8s/workspace-pod.yaml
kubectl wait --for=condition=Ready pod/ar-workspace --timeout=120s
```

### 3. Copy the repo

```bash
kubectl cp . ar-workspace:/workspace/autoresearch-swarm
```

### 4. Initialize git

```bash
kubectl exec ar-workspace -- bash -c "
  cd /workspace/autoresearch-swarm &&
  git init && git add -A && git commit -m 'chore: initial setup'
"
```

### 5. Prepare data (one-time)

```bash
kubectl apply -f k8s/prep-job.yaml
kubectl wait --for=condition=complete job/ar-prep --timeout=300s
kubectl delete job ar-prep
```

### 6. Run

```bash
AR_BACKEND=k8s ./orchestrator.sh
```
