# Actions Runner Controller (ARC) — setup

Runs GitHub Actions jobs as ephemeral pods inside this CCE cluster, so CI/CD never needs
network access to the private kube-apiserver from outside the VPC — see the chat history
for why (private cluster, no public endpoint, GitHub-hosted runners have no route in).

This is **not Terraform-managed**. Neither `huaweicloud_cce_autopilot_cluster` (resource
or data source) exports a kubeconfig/certificate attribute, so there's no verified way to
point Terraform's `helm`/`kubernetes` providers at this cluster — confirmed by checking the
actual provider docs rather than guessing. Everything below runs via `helm`/`kubectl`
through CloudShell (Console → CCE → your cluster → CloudShell) for the one-time bootstrap.

## 1. Register a GitHub App (one-time, manual — can't be scripted)

Settings you use depend on whether runners serve one repo or your whole org — start
repo-scoped (narrower blast radius); switch to org-wide later by changing `githubConfigUrl`
and the App's install target.

1. GitHub → Settings → Developer settings → GitHub Apps → New GitHub App.
2. Permissions needed:
   - Repository permissions → **Actions**: Read and write
   - Repository permissions → **Administration**: Read and write (runner registration)
   - (Org-wide only) Organization permissions → **Self-hosted runners**: Read and write
3. Generate a private key (downloads a `.pem` file) — treat this like any other credential,
   never commit it.
4. Install the App on the target repo (or org).
5. Note down: **App ID**, **Installation ID** (visible in the install URL), and the `.pem`
   file's contents.

## 2. Create the auth Secret (via CloudShell, not committed anywhere)

```bash
kubectl create namespace arc-systems
kubectl create namespace arc-runners

kubectl create secret generic imto-arc-github-app \
  --namespace arc-runners \
  --from-literal=github_app_id="<APP_ID>" \
  --from-literal=github_app_installation_id="<INSTALLATION_ID>" \
  --from-file=github_app_private_key=<path-to-downloaded>.pem
```

## 3. Install the controller (once per cluster)

```bash
helm install arc \
  --namespace arc-systems \
  -f platform/arc/controller-values.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

## 4. Install the runner scale set

```bash
helm install imto-arc-runners \
  --namespace arc-runners \
  -f platform/arc/runner-scale-set-values.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

`platform/arc/runner-scale-set-values.yaml` has `githubConfigUrl` pointed at a placeholder repo —
update it to your actual repo (or org) URL before installing. It references the Secret from
step 2 by name only — no credential lives in the values file itself.

## 5. Apply the deploy RBAC (what the runner pods are actually allowed to do)

```bash
kubectl apply -f platform/arc/rbac.yaml
```

Scoped to the `default` namespace only — deployments/services/serviceaccounts/HPAs/
SecretProviderClasses/HTTPRoutes, full CRUD. Deliberately **not** cluster-admin, and has no
access to `envoy-gateway-system` (where the Gateway itself lives) or CSMS/CCE APIs directly.
Widen it later if a specific workflow step needs more.

## 6. Confirm it's working

```bash
kubectl get pods -n arc-systems
kubectl get pods -n arc-runners
```

Then push to a branch that triggers `.github/workflows/deploy.yml` — a runner pod should
appear in `arc-runners` for the duration of the job and disappear after.

## Sizing notes

- `minRunners: 0` in `runner-scale-set-values.yaml` — scales to zero when idle, since CCE
  Autopilot bills per-pod-resource; no CI activity means no idle runner cost.
- `containerMode: kubernetes` — each job step that needs its own container gets a pod,
  rather than a privileged Docker-in-Docker sidecar. If your pipeline needs `docker build`
  specifically, switch to `containerMode: dind` (see the chart's own values.yaml for the
  tradeoffs) — not set up here since it's not yet confirmed which build tooling you'll use.
