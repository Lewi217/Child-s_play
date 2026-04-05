# Jenkins Setup — Child's Play

## 1. Start Jenkins

```bash
cd jenkins/
docker compose up -d
```

Open http://localhost:8080 in your browser.

Get the initial admin password:
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## 2. Install Plugins

Go to **Manage Jenkins → Plugins → Available plugins** and install:

| Plugin | Why |
|--------|-----|
| Git | Clone repos |
| Pipeline | Jenkinsfile support |
| SSH Agent | `sshagent()` block in pipeline |
| Credentials Binding | `withCredentials()` block |
| GitHub | Webhook integration |
| Blue Ocean (optional) | Better pipeline UI |

Click **Install without restart**, then restart Jenkins.

## 3. Add Credentials

Go to **Manage Jenkins → Credentials → System → Global credentials → Add Credential**

### A. Production .env file
- Kind: **Secret file**
- ID: `childs-play-env`
- File: upload your production `.env`
- Description: `Child's Play production .env`

### B. Deploy server SSH key
- Kind: **SSH Username with private key**
- ID: `deploy-server-ssh`
- Username: `deployer`
- Private Key: paste the private key that has access to your production server
- Description: `Deploy server SSH key`

### C. GitHub token (for webhooks/private repos)
- Kind: **Username with password**
- ID: `github-token`
- Username: your GitHub username
- Password: your GitHub Personal Access Token (needs `repo` scope)

## 4. Set the DEPLOY_HOST environment variable

Go to **Manage Jenkins → System → Global properties → Environment variables**

Add:
- Name: `DEPLOY_HOST`
- Value: your production server IP or hostname (e.g. `192.168.1.10`)

## 5. Create the Pipeline Job

1. **New Item** → name it `childs-play` → choose **Pipeline** → OK
2. Under **Build Triggers**: check **GitHub hook trigger for GITScm polling**
3. Under **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: your GitHub repo URL
   - Credentials: `github-token`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
4. **Save**

## 6. Set Up GitHub Webhook

In your GitHub repo → **Settings → Webhooks → Add webhook**

- Payload URL: `http://<your-jenkins-server-ip>:8080/github-webhook/`
- Content type: `application/json`
- Which events: **Just the push event**
- Active: checked

> Note: GitHub must be able to reach your Jenkins server. If running locally,
> use ngrok to expose it: `ngrok http 8080`

## 7. Test It

1. Click **Build Now** on the pipeline job in Jenkins UI
2. Watch the stages run in the Blue Ocean or classic UI
3. Fix any failures (usually SSH key permissions or missing credentials)
4. Push a commit to `main` and confirm the webhook triggers automatically

## Deploy Server Prerequisites

Your production server needs:
- Docker + Docker Compose installed
- A `deployer` user with SSH access
- The app cloned at `/opt/childs-play`
- The `deployer` user added to the `docker` group: `usermod -aG docker deployer`
