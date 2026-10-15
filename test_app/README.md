# IMTO CCE Test App

A minimal two-service app for testing your Huawei CCE setup end-to-end:
a Next.js frontend calling a C# (.NET 8) backend over a simple REST API.
Two separate Docker images, built independently, so you can push each to
SWR and deploy each into CCE separately — mirroring how the real IMTO
backend and frontend will eventually be split.

## What's here

```
backend/    C# minimal API — GET /api/greeting, GET /health
frontend/   Next.js app — fetches from the backend and displays the response
docker-compose.yml   Local test of both containers together
```

## 1. Test locally first (before touching SWR/CCE at all)

Requires Docker installed locally.

```bash
docker compose up --build
```

Then open http://localhost:3000 — you should see a JSON response from the
backend rendered on the page. If you see a "could not reach backend" error
instead, check `docker compose logs backend` before moving on to CCE at all
— easier to debug here than inside a cluster.

## 2. Build each image separately

```bash
# Backend
docker build -t imto-test-backend:latest ./backend

# Frontend — BACKEND_URL is baked into the frontend bundle at build time,
# so set it to wherever the backend will actually be reachable once both
# are running in CCE (a Kubernetes Service DNS name, not localhost).
docker build -t imto-test-frontend:latest \
  --build-arg BACKEND_URL=http://imto-test-backend-svc:8080 \
  ./frontend
```

## 3. Push to SWR

Replace `<region>`, `<organization>`, and `<your-swr-domain>` with your
actual Huawei values (organization is a namespace you create once in the
SWR console if you haven't already).

```bash
# Log in to SWR — use your AK/SK, not your console password
docker login -u <region>@<AK> -p <login-key> swr.<region>.myhuaweicloud.com

# Tag each image for your SWR organization
docker tag imto-test-backend:latest \
  swr.<region>.myhuaweicloud.com/<organization>/imto-test-backend:latest

docker tag imto-test-frontend:latest \
  swr.<region>.myhuaweicloud.com/<organization>/imto-test-frontend:latest

# Push both
docker push swr.<region>.myhuaweicloud.com/<organization>/imto-test-backend:latest
docker push swr.<region>.myhuaweicloud.com/<organization>/imto-test-frontend:latest
```

**Note on the login command:** SWR's `docker login` doesn't use your AK/SK
directly as shown above — it uses a temporary login command you generate
from the SWR console (Console → SWR → My Images → "Generate Login
Command"), since the login key is a short-lived token, not your raw SK.
Grab the exact command from there rather than typing this one verbatim.

## 4. Deploy into CCE

Once both images are in SWR, point your CCE Autopilot cluster's
Deployment manifests (or the `huaweicloud_cce_autopilot_addon`/workload
resources) at these image URIs:

```
swr.<region>.myhuaweicloud.com/<organization>/imto-test-backend:latest
swr.<region>.myhuaweicloud.com/<organization>/imto-test-frontend:latest
```

Inside the cluster, the frontend should reach the backend through a
Kubernetes **Service** DNS name (e.g. `imto-test-backend-svc`), not
`localhost` and not the backend's pod IP directly — pod IPs are not
stable, which is the exact problem Services exist to solve (covered
earlier: this is the "service network" concept).

## What this validates

- Your CCE Autopilot cluster can actually pull images from SWR
  (confirms the `enable_swr_image_access` / VPC endpoint setup works)
- Two separately-deployed workloads can reach each other over the
  cluster's internal networking
- Your image build pipeline (Dockerfile → SWR push) works end-to-end
  before you point it at anything resembling the real IMTO workload