# CI/CD Setup Guide

This document explains how to set up the self-hosted GitHub Actions runner
on your **Windows machine** to enable automated deployments.

---

## Prerequisites

Make sure you have these installed on your machine:

| Tool | Purpose | Download |
|------|---------|---------|
| Docker Desktop | Run containers | https://www.docker.com/products/docker-desktop |
| Java 17 (JDK) | Build the project | https://adoptium.net |
| Git | Source control | Already installed (you're using GitHub) |

---

## Step 1 — Add GitHub Secrets

Your `.env` file contains credentials that must **never be committed to git**.
Instead, add them as GitHub Secrets:

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add each of these:

| Secret Name | Value |
|-------------|-------|
| `MYSQL_ROOT_PASSWORD` | `root` |
| `MYSQL_USER` | `pms_user` |
| `MYSQL_PASSWORD` | `root1234` |

> ⚠️ **Security tip**: Change these values from your `.env` to something stronger
> before adding them as secrets.

---

## Step 2 — Register a Self-Hosted Runner

A self-hosted runner is a small background agent that listens for jobs from
GitHub and runs them on YOUR machine.

### 2a. Get the registration token

1. Go to your GitHub repository
2. Click **Settings** → **Actions** → **Runners**
3. Click **New self-hosted runner**
4. Select **Windows** → **x64**
5. GitHub will show you a set of commands — copy the **token** from the
   `--token` flag shown on that page

### 2b. Install the runner on your Windows machine

Open **PowerShell as Administrator** and run:

```powershell
# Create a folder for the runner
mkdir C:\actions-runner; cd C:\actions-runner

# Download the runner (check GitHub page for latest version URL)
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-win-x64-2.317.0.zip -OutFile actions-runner-win-x64.zip

# Extract it
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD\actions-runner-win-x64.zip", "$PWD")

# Configure the runner (replace YOUR_GITHUB_USERNAME, YOUR_REPO, and YOUR_TOKEN)
.\config.cmd --url https://github.com/YOUR_GITHUB_USERNAME/ProductManagementSystem --token YOUR_TOKEN
```

When prompted:
- **Runner group**: Press Enter (use default)
- **Runner name**: e.g., `windows-local`
- **Work folder**: Press Enter (use default `_work`)

### 2c. Install as a Windows Service (auto-start)

```powershell
# Install as a service so it starts automatically with Windows
.\svc.cmd install
.\svc.cmd start
```

Verify it's running:
```powershell
.\svc.cmd status
```

---

## Step 3 — Verify the runner is connected

1. Go to **Settings** → **Actions** → **Runners** in your GitHub repo
2. You should see your runner listed with a green **"Idle"** status

---

## Step 4 — Test the pipeline

Push any commit to the `main` branch:

```powershell
git add .
git commit -m "ci: add GitHub Actions CI/CD"
git push origin main
```

Then go to your GitHub repo → **Actions** tab to watch the pipeline run.

---

## Pipeline Overview

```
Push to any branch  →  CI workflow (runs on GitHub servers)
                           ├── Checkout code
                           ├── Set up Java 17
                           ├── ./mvnw clean package
                           └── Build Docker image (smoke test)

Push to main  →  CD workflow (runs on YOUR machine via self-hosted runner)
                    ├── Checkout code
                    ├── Write .env from GitHub Secrets
                    ├── ./mvnw clean package -DskipTests
                    ├── docker compose down
                    ├── docker compose up -d --build
                    └── Wait for port 8080 to be reachable
```

---

## Stopping / Uninstalling the Runner

```powershell
cd C:\actions-runner
.\svc.cmd stop
.\svc.cmd uninstall
.\config.cmd remove --token YOUR_TOKEN
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Runner shows "Offline" | Run `.\svc.cmd start` in `C:\actions-runner` |
| Docker not found | Ensure Docker Desktop is running and in PATH |
| `mvnw` not executable | The `mvnw` file needs Unix line endings; already handled by `.gitattributes` |
| Port 8080 already in use | Run `docker compose down` manually, then re-trigger the pipeline |
| Secrets not found | Double-check secret names exactly match what's in `cd.yml` |
