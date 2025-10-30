# 🐙 GitHub Setup Guide

## ✅ Local Repository Ready!

Your Couchbase project is now initialized with Git:
- ✅ 30 files committed
- ✅ API keys and secrets excluded
- ✅ Branch: `main`
- ✅ Commit: "Initial commit: Couchbase + Datadog integration on Minikube"

---

## 📝 Step 1: Create GitHub Repository

### Option A: Via GitHub Website (Recommended)

1. Go to: https://github.com/new

2. Fill in:
   - **Repository name**: `couchbase-datadog-minikube`
   - **Description**: `Couchbase 7.2.0 deployment on Minikube with Datadog integration - 165+ metrics`
   - **Visibility**: Choose `Private` or `Public`
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)

3. Click **"Create repository"**

4. GitHub will show you commands - **IGNORE THEM**, use the commands below instead

### Option B: Via GitHub CLI (If you have `gh` installed)

```bash
cd /Users/eran.rahmani/Documents/VC/minikube/couchbase
gh repo create couchbase-datadog-minikube --private --source=. --remote=origin --push
```

---

## 🚀 Step 2: Push to GitHub

### If you created via website (Option A):

```bash
cd /Users/eran.rahmani/Documents/VC/minikube/couchbase

# Add GitHub as remote (replace USERNAME with your GitHub username)
git remote add origin https://github.com/USERNAME/couchbase-datadog-minikube.git

# Push to GitHub
git push -u origin main
```

**Replace `USERNAME`** with your actual GitHub username!

Example:
```bash
git remote add origin https://github.com/eran-rahmani/couchbase-datadog-minikube.git
git push -u origin main
```

---

## 🔐 If You Get Authentication Error

### Use Personal Access Token (PAT):

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give it a name: `Couchbase Project`
4. Select scopes: Check **`repo`** (full control of private repositories)
5. Click **"Generate token"**
6. **COPY THE TOKEN** (you'll only see it once!)

7. When pushing, use token as password:
```bash
Username: your-github-username
Password: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # Your PAT
```

---

## 📊 Step 3: Verify on GitHub

After pushing, go to your repository URL:
```
https://github.com/USERNAME/couchbase-datadog-minikube
```

You should see:
- ✅ 30 files
- ✅ 8 documentation files
- ✅ All Kubernetes manifests
- ✅ Deployment scripts
- ✅ No secrets or API keys (protected by .gitignore)

---

## 🔄 Future Updates - How to Sync

After making changes to your project:

```bash
cd /Users/eran.rahmani/Documents/VC/minikube/couchbase

# Check what changed
git status

# Add all changes
git add .

# Commit with a message
git commit -m "Description of your changes"

# Push to GitHub
git push origin main
```

---

## 📁 Repository Structure on GitHub

```
couchbase-datadog-minikube/
├── .gitignore                          # Excludes secrets
├── README.md                           # Main documentation
├── DEPLOYMENT_PLAN.md                  # Complete deployment plan
├── CONFIGURATION_EXPLAINED.md          # Config deep-dive
├── QUICK_START.md                      # Quick reference
├── METRICS_VERIFICATION.md             # All 165+ metrics
├── DEPLOYMENT_COMPLETE.md              # Success summary
├── FIX_MISSING_METRICS.md              # Troubleshooting
├── DATADOG_INTEGRATION_SETUP.md        # Integration guide
│
├── Kubernetes Manifests:
│   ├── namespace.yaml
│   ├── couchbase-operator.yaml
│   ├── couchbase-cluster-crd.yaml
│   ├── couchbase-cluster.yaml
│   ├── couchbase-service.yaml
│   └── traffic-generator-pod.yaml
│
├── Datadog Configuration:
│   ├── datadog-agent.yaml
│   ├── datadog-values.yaml
│   └── deploy-datadog-complete.sh.template  # Template (no API key)
│
└── Scripts:
    ├── deploy.sh
    ├── verify.sh
    ├── cleanup.sh
    ├── generate-metrics.sh
    └── continuous-traffic.sh
```

---

## 🔒 What's Protected (Not in Git)

These files are in `.gitignore` and will **NEVER** be committed:

❌ `datadog-secret.yaml` - Your Datadog API key
❌ `couchbase-secret.yaml` - Couchbase admin password
❌ `deploy-datadog-complete.sh` - Script with actual API key
❌ `*.log` - Log files
❌ `.DS_Store` - Mac system files

---

## 👥 Sharing with Team/Customers

### When sharing this repository:

**Recipients need to create these files locally:**

1. **`couchbase-secret.yaml`**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cb-admin-auth
  namespace: couchbase
type: Opaque
stringData:
  username: Administrator
  password: YOUR_PASSWORD_HERE
```

2. **`datadog-secret.yaml`**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: datadog-secret
  namespace: couchbase
type: Opaque
stringData:
  api-key: THEIR_DATADOG_API_KEY
```

3. **`deploy-datadog-complete.sh`**:
```bash
# Copy from template
cp deploy-datadog-complete.sh.template deploy-datadog-complete.sh
# Then use it with their API key
./deploy-datadog-complete.sh THEIR_API_KEY
```

---

## 📖 Adding to GitHub README

Consider adding this badge to your README.md on GitHub:

```markdown
## 🎯 Quick Stats

![Kubernetes](https://img.shields.io/badge/kubernetes-v1.28+-blue.svg)
![Couchbase](https://img.shields.io/badge/couchbase-7.2.0-red.svg)
![Datadog](https://img.shields.io/badge/datadog-agent%207.x-purple.svg)
![Metrics](https://img.shields.io/badge/metrics-165+-green.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
```

---

## 🆘 Need Help?

### Common Issues:

**1. "remote origin already exists"**
```bash
git remote remove origin
git remote add origin https://github.com/USERNAME/couchbase-datadog-minikube.git
```

**2. "rejected (non-fast-forward)"**
```bash
git pull origin main --rebase
git push origin main
```

**3. "Permission denied"**
- Use Personal Access Token instead of password
- Or set up SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

---

## ✨ Success!

Once pushed, your repository will be accessible at:
```
https://github.com/YOUR-USERNAME/couchbase-datadog-minikube
```

Share this URL with your team or customers!

---

## 🔄 Next Steps After GitHub Sync

1. ✅ Clone on another machine:
   ```bash
   git clone https://github.com/YOUR-USERNAME/couchbase-datadog-minikube.git
   cd couchbase-datadog-minikube
   ```

2. ✅ Create the secret files (not in git)
3. ✅ Follow README.md for deployment
4. ✅ All metrics will flow to Datadog!

**Happy Deploying! 🚀**

