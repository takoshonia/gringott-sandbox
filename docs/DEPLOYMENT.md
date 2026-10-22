# Deploy the standalone Gringott mock

Use a private GitHub repository. No actual bank credentials or personal data belong in this project. This deployment is independent of GeoBridge and does not replace its container, database volume or environment.

## Upload to GitHub

Easiest: GitHub Desktop -> File -> Add local repository -> choose this folder -> create repository here if prompted -> Publish repository -> keep private.

Alternatively, open PowerShell in THIS folder (not BullRun's root):

```powershell
git init -b main
git add .
git status --short
git commit -m "Prepare private Gringott mock sandbox"
```

Before committing, confirm `secrets/` and `.env` are absent from staged files. Create an empty private GitHub repository, then use the exact remote URL GitHub supplies:

```powershell
git remote add origin YOUR_GITHUB_REPOSITORY_URL
git push -u origin main
```

No remote/repository is created automatically. Do not upload the outer `untracked` directory, GeoBridge database, or other project references.

## DigitalOcean: deploy beside GeoBridge

Prerequisites: Docker Engine and Docker Compose v2 (`docker compose version`). The original docker.io-only setup may not include Compose; check before proceeding. Install Compose using Docker's official instructions if missing. Use a separate repository-specific read-only deploy key for a private repository; GitHub passwords do not authenticate Git operations.

Clone your new repository to `/opt/gringott-sandbox`, then:

```bash
cd /opt/gringott-sandbox
sh scripts/create-secret.sh
docker network inspect geobridge-mocks >/dev/null 2>&1 || docker network create geobridge-mocks
docker compose config --quiet
docker compose up -d --build
docker compose ps
curl -fsS http://127.0.0.1:4173/api/health
```

Port 4173 is bound ONLY to server loopback. Do not open it in UFW, add a public Caddy route, or publish the API console without separate authentication. Compose imposes a 128 MiB memory cap, 0.25 CPU, non-root process, read-only filesystem, reduced privileges and rotating logs.

Container health becomes unhealthy intentionally when API OFF is selected. Docker does NOT restart containers merely because they are unhealthy; this is required to keep the deliberate outage in place. If you later add an external auto-healer, exclude this container from health-triggered restarts. A process restart resets synthetic state and availability to ON.

## Private console from Windows

```powershell
ssh -i "$env:USERPROFILE\.ssh\id_ed25519" -L 14173:127.0.0.1:4173 root@68.183.218.89
```

Keep that session open. Browse to `http://127.0.0.1:14173`. To use admin controls, privately retrieve `secrets/admin.key` on the server and paste it into Private administration. Never send it in chat or screenshots. The browser keeps it in tab memory only.

## Connect GeoBridge availability monitoring

GeoBridge needs the separately implemented availability-monitoring code; the currently deployed old image will not gain it by deploying this mock alone.

When rebuilding GeoBridge, preserve its existing database volume and settings. Connect its container to `geobridge-mocks` and mount this repository's `secrets/admin.key` read-only at `/run/secrets/gringott-admin.key`. Docker mounts cannot be added to an already running container; include the mount when recreating it. Keep its existing loopback port binding.

Set GeoBridge's `GEOBRIDGE_MOCK_TARGETS` to:

```json
[{"id":"gringott","name":"Gringott mock","origin":"http://gringott:4173","tenant":"bank-demo","adminKeyFile":"/run/secrets/gringott-admin.key"}]
```

Compose supplies the `gringott` DNS alias on the shared network. Do not use `localhost` from inside GeoBridge to reach another container. Omit `adminKeyFile` if only observing availability without enabling GeoBridge's operator switch.

In GeoBridge: Monitoring -> Configure -> enable, interval 5 seconds for a demo (30 normally), deadline 1–2 seconds. Wait for UP -> API OFF -> at least two failed probes -> API ON -> recovery -> Report & export. Settings/history persist in GeoBridge; the mock deliberately retains no database.

## Update this mock later

```bash
cd /opt/gringott-sandbox
git pull --ff-only
docker compose up -d --build
```

Updates reset synthetic consents/tokens/faults. They do not alter GeoBridge history. Keep the existing `secrets/admin.key`; rotating it also requires recreating/restarting GeoBridge with the matching secret. `docker compose down` stops this mock only; no GeoBridge volume deletion is required.
