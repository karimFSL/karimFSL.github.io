---
sidebar_position: 4
title: Guide Développeur Dokploy
description: Guide complet pour déployer vos applications sur Dokploy
---

# 🚀 Guide Développeur Dokploy

Dokploy est une plateforme **self-hosted** open-source (alternative à Vercel/Heroku) qui simplifie le déploiement d'applications Docker.

:::tip Pourquoi Dokploy ?
- 🆓 **Gratuit** et open-source
- 🐳 **Docker natif** avec interface web intuitive
- 🔄 **Auto-déploiement** depuis Git (GitHub/GitLab)
- 🔒 **SSL automatique** via Let's Encrypt + Traefik
- 📊 **Monitoring** CPU, RAM, logs en temps réel
- 💾 **Bases de données** managées (PostgreSQL, MySQL, MongoDB, Redis)
- 📦 **Templates** one-click (Supabase, Plausible, etc.)
:::

---

## 📦 Installation de Dokploy

### Prérequis Serveur

**Serveur minimum :**
- **OS** : Ubuntu 22.04 LTS (recommandé), Debian 11+, ou autre Linux
- **CPU** : 2 cores minimum (4 cores recommandé)
- **RAM** : 4GB minimum (8GB recommandé pour production)
- **Disque** : 50GB minimum (SSD recommandé)
- **Réseau** : Ports 80, 443, 3000 ouverts

**Providers compatibles :**
- VPS (OVH, Hetzner, DigitalOcean, Scaleway)
- Cloud (AWS EC2, Azure VM, GCP Compute Engine)
- On-premise (serveur physique, Proxmox, VMware)

### Installation Rapide (5 minutes)

**1. Connexion SSH au serveur**

```bash
ssh root@votre-serveur.com
```

**2. Mise à jour du système**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl -y
```

**3. Installation Dokploy (script officiel)**

```bash
curl -sSL https://dokploy.com/install.sh | sh
```

Le script installe automatiquement :
- ✅ Docker Engine
- ✅ Docker Compose
- ✅ Dokploy
- ✅ Traefik (reverse proxy)
- ✅ PostgreSQL (base de données Dokploy)

**Durée : ~3-5 minutes**

**4. Accès à l'interface**

Une fois installé, vous verrez :

```
✅ Dokploy installed successfully!

🌐 Access Dokploy at: http://VOTRE_IP:3000

📧 Default credentials:
   Email: admin@dokploy.com
   Password: <généré automatiquement - affiché dans le terminal>

⚠️  Please change your password after first login!
```

**5. Première connexion**

Ouvrez votre navigateur : `http://VOTRE_IP:3000`

- **Login** : `admin@dokploy.com`
- **Password** : Le mot de passe affiché dans le terminal

**6. Configuration initiale**

Une fois connecté :

1. **Change Password** : Settings → Account → Change Password
2. **Update Email** : Settings → Account → Email
3. **Configure Domain** (optionnel) : Settings → General → Domain
   - Ex: `dokploy.votredomaine.com`
   - Pointez votre DNS vers l'IP du serveur
4. **SSL** (optionnel mais recommandé) : Settings → SSL → Enable Let's Encrypt

:::success Installation terminée !
Dokploy est prêt à l'emploi. Vous pouvez maintenant déployer vos applications.
:::

### Configuration du Pare-feu

```bash
# UFW (Ubuntu)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # Dokploy UI (optionnel si domaine configuré)
sudo ufw enable

# Firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

---

## 🎯 Exemple Complet : Stack Angular + Java (Spring Boot)

### Architecture de la Stack

```mermaid
graph TB
    subgraph "GitLab Repository"
        GITLAB_FE[📂 frontend-angular]
        GITLAB_BE[📂 backend-java]
    end
    
    subgraph "GitLab CI/CD"
        CI_FE[🔨 Build Angular]
        CI_BE[🔨 Build Java]
        DOCKER_FE[🐳 Docker Image Frontend]
        DOCKER_BE[🐳 Docker Image Backend]
        PUSH[📤 Push to Harbor/DockerHub]
    end
    
    subgraph "Dokploy Server"
        direction TB
        
        subgraph "Project: E-Commerce"
            FRONTEND[🅰️ Angular Frontend<br/>Port: 80]
            BACKEND[☕ Spring Boot API<br/>Port: 8080]
            DATABASE[🐘 PostgreSQL<br/>Port: 5432]
            REDIS[🔴 Redis Cache<br/>Port: 6379]
        end
        
        TRAEFIK[🌐 Traefik]
    end
    
    subgraph "Domaines"
        DOMAIN_FE[🌍 app.votresite.com]
        DOMAIN_BE[🌍 api.votresite.com]
    end
    
    GITLAB_FE -->|git push| CI_FE
    GITLAB_BE -->|git push| CI_BE
    
    CI_FE --> DOCKER_FE
    CI_BE --> DOCKER_BE
    
    DOCKER_FE --> PUSH
    DOCKER_BE --> PUSH
    
    PUSH -->|webhook| FRONTEND
    PUSH -->|webhook| BACKEND
    
    FRONTEND --> DATABASE
    BACKEND --> DATABASE
    BACKEND --> REDIS
    
    TRAEFIK --> FRONTEND
    TRAEFIK --> BACKEND
    
    TRAEFIK --> DOMAIN_FE
    TRAEFIK --> DOMAIN_BE
    
    style FRONTEND fill:#DD0031,color:#fff
    style BACKEND fill:#6DB33F,color:#fff
    style TRAEFIK fill:#24A1C1,color:#fff
```

### Étape 1 : Créer le Projet dans Dokploy

**Dashboard** → **Projects** → **Create Project**

- **Name** : `e-commerce`
- **Description** : "Application e-commerce Angular + Spring Boot"
- **Create**

---

### Étape 2 : Créer la Base de Données PostgreSQL

**Project "e-commerce"** → **Create** → **Database** → **PostgreSQL**

**Configuration :**
- **Name** : `ecommerce-db`
- **Database** : `ecommerce`
- **Username** : `ecommerce_user`
- **Password** : `Change_Me_123!` (ou auto-généré)
- **Port** : `5432`
- **Version** : `15`

**Create Database**

**Connection String générée :**
```
postgresql://ecommerce_user:Change_Me_123!@ecommerce-db:5432/ecommerce
```

Notez cette URL pour la configuration du backend.

---

### Étape 3 : Créer le Cache Redis

**Project "e-commerce"** → **Create** → **Database** → **Redis**

**Configuration :**
- **Name** : `ecommerce-cache`
- **Port** : `6379`
- **Password** : Auto-généré

**Create Database**

**Connection URL :**
```
redis://ecommerce-cache:6379
```

---

### Étape 4 : Configuration GitLab CI - Backend Java

**Structure du repository backend :**
```
backend-java/
├── src/
├── pom.xml
├── Dockerfile
└── .gitlab-ci.yml
```

**Dockerfile (Multi-stage build)**

```dockerfile title="backend-java/Dockerfile"
# Stage 1: Build
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**GitLab CI/CD Pipeline**

```yaml title="backend-java/.gitlab-ci.yml"
stages:
  - build
  - deploy

variables:
  DOCKER_IMAGE: harbor.votredomaine.com/ecommerce/backend
  DOCKER_TAG: $CI_COMMIT_SHORT_SHA

# Build et push de l'image Docker
build-backend:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - echo $HARBOR_PASSWORD | docker login harbor.votredomaine.com -u $HARBOR_USERNAME --password-stdin
  script:
    # Build de l'image
    - docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
    - docker tag $DOCKER_IMAGE:$DOCKER_TAG $DOCKER_IMAGE:latest
    
    # Push vers Harbor
    - docker push $DOCKER_IMAGE:$DOCKER_TAG
    - docker push $DOCKER_IMAGE:latest
    
    - echo "✅ Backend image built and pushed"
    - echo "Image: $DOCKER_IMAGE:$DOCKER_TAG"
  only:
    - main
    - develop

# Déclencher le déploiement Dokploy
deploy-backend:
  stage: deploy
  image: curlimages/curl:latest
  script:
    # Appel API Dokploy pour redéployer
    - |
      curl -X POST "https://dokploy.votredomaine.com/api/application.deploy" \
        -H "Authorization: Bearer $DOKPLOY_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"applicationId\": \"$BACKEND_APP_ID\"}"
    
    - echo "✅ Backend deployment triggered"
  only:
    - main
  when: manual
```

**Variables GitLab (Settings → CI/CD → Variables) :**

| Variable | Valeur | Masqué |
|----------|--------|--------|
| `HARBOR_USERNAME` | `robot$gitlab-ci` | ❌ |
| `HARBOR_PASSWORD` | Token du robot account | ✅ |
| `DOKPLOY_API_KEY` | API Key Dokploy | ✅ |
| `BACKEND_APP_ID` | ID de l'app (voir Dokploy) | ❌ |

---

### Étape 5 : Configuration GitLab CI - Frontend Angular

**Structure du repository frontend :**
```
frontend-angular/
├── src/
├── angular.json
├── package.json
├── Dockerfile
└── .gitlab-ci.yml
```

**Dockerfile (Build optimisé)**

```dockerfile title="frontend-angular/Dockerfile"
# Stage 1: Build Angular
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build -- --configuration production

# Stage 2: Nginx pour servir
FROM nginx:alpine
COPY --from=build /app/dist/frontend-angular /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Configuration Nginx**

```nginx title="frontend-angular/nginx.conf"
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gestion du routing Angular
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache pour assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Pas de cache pour index.html
    location = /index.html {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
```

**GitLab CI/CD Pipeline**

```yaml title="frontend-angular/.gitlab-ci.yml"
stages:
  - build
  - deploy

variables:
  DOCKER_IMAGE: harbor.votredomaine.com/ecommerce/frontend
  DOCKER_TAG: $CI_COMMIT_SHORT_SHA

build-frontend:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - echo $HARBOR_PASSWORD | docker login harbor.votredomaine.com -u $HARBOR_USERNAME --password-stdin
  script:
    - docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
    - docker tag $DOCKER_IMAGE:$DOCKER_TAG $DOCKER_IMAGE:latest
    - docker push $DOCKER_IMAGE:$DOCKER_TAG
    - docker push $DOCKER_IMAGE:latest
    - echo "✅ Frontend image built and pushed"
  only:
    - main
    - develop

deploy-frontend:
  stage: deploy
  image: curlimages/curl:latest
  script:
    - |
      curl -X POST "https://dokploy.votredomaine.com/api/application.deploy" \
        -H "Authorization: Bearer $DOKPLOY_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"applicationId\": \"$FRONTEND_APP_ID\"}"
    - echo "✅ Frontend deployment triggered"
  only:
    - main
  when: manual
```

---

### Étape 6 : Créer l'Application Backend dans Dokploy

**Project "e-commerce"** → **Create** → **Application**

**Configuration Générale :**
- **Name** : `backend-api`
- **Description** : "API Spring Boot"

**Source :**
- **Provider** : **Docker Registry**
- **Registry** : `harbor.votredomaine.com`
- **Image** : `ecommerce/backend`
- **Tag** : `latest`
- **Credentials** :
  - Username : `robot$dokploy`
  - Password : Token du robot

**Build :**
- **Build Type** : **Docker** (image pré-buildée)

**Environment Variables :**

```bash
# Database
SPRING_DATASOURCE_URL=jdbc:postgresql://ecommerce-db:5432/ecommerce
SPRING_DATASOURCE_USERNAME=ecommerce_user
SPRING_DATASOURCE_PASSWORD=Change_Me_123!

# Redis
SPRING_REDIS_HOST=ecommerce-cache
SPRING_REDIS_PORT=6379

# Application
SPRING_PROFILES_ACTIVE=production
SERVER_PORT=8080

# CORS (pour Angular)
ALLOWED_ORIGINS=https://app.votredomaine.com
```

**Port :**
- **Container Port** : `8080`

**Advanced → Health Check :**
- **Path** : `/actuator/health`
- **Interval** : `30s`
- **Timeout** : `10s`
- **Retries** : `3`

**Save** → **Deploy**

---

### Étape 7 : Créer l'Application Frontend dans Dokploy

**Project "e-commerce"** → **Create** → **Application**

**Configuration Générale :**
- **Name** : `frontend-app`
- **Description** : "Application Angular"

**Source :**
- **Provider** : **Docker Registry**
- **Registry** : `harbor.votredomaine.com`
- **Image** : `ecommerce/frontend`
- **Tag** : `latest`
- **Credentials** : (même que backend)

**Build :**
- **Build Type** : **Docker**

**Environment Variables :**

```bash
# API Backend URL (utilisé par Angular)
API_URL=https://api.votredomaine.com
```

**Port :**
- **Container Port** : `80`

**Advanced → Health Check :**
- **Path** : `/`
- **Interval** : `30s`

**Save** → **Deploy**

---

### Étape 8 : Configurer les Domaines

#### Backend API

**Application "backend-api"** → **Domains** → **Add Domain**

- **Domain** : `api.votredomaine.com`
- **Port** : `8080`
- **SSL** : **Let's Encrypt**
- **Certificate Type** : `letsencrypt`

**DNS (chez votre registrar) :**
```
Type: A
Name: api
Value: <IP_SERVEUR_DOKPLOY>
TTL: 300
```

**Save** → SSL généré automatiquement ✅

#### Frontend Angular

**Application "frontend-app"** → **Domains** → **Add Domain**

- **Domain** : `app.votredomaine.com`
- **Port** : `80`
- **SSL** : **Let's Encrypt**

**DNS :**
```
Type: A
Name: app
Value: <IP_SERVEUR_DOKPLOY>
TTL: 300
```

**Save** → SSL généré automatiquement ✅

---

### Étape 9 : Configuration de l'API Dokploy pour GitLab CI

**Dokploy** → **Settings** → **API** → **Generate API Key**

- **Name** : `gitlab-ci`
- **Permissions** : Application Deploy
- **Generate**

Copiez la clé générée et ajoutez-la dans GitLab CI/CD Variables :
- Variable : `DOKPLOY_API_KEY`
- Value : `dkp_xxxxxxxxxxxxx`
- Masked : ✅

**Récupérer les IDs des applications :**

```bash
# Depuis l'URL de l'application dans Dokploy
# Ex: https://dokploy.example.com/dashboard/project/123/application/456

BACKEND_APP_ID=456
FRONTEND_APP_ID=789
```

Ajoutez-les dans GitLab Variables :
- `BACKEND_APP_ID` : `456`
- `FRONTEND_APP_ID` : `789`

---

### Étape 10 : Premier Déploiement

**1. Push du code vers GitLab :**

```bash
# Backend
cd backend-java
git add .
git commit -m "feat: initial backend setup"
git push origin main

# Frontend
cd frontend-angular
git add .
git commit -m "feat: initial frontend setup"
git push origin main
```

**2. GitLab CI déclenche automatiquement :**
- ✅ Build de l'image Docker
- ✅ Push vers Harbor
- ⏸️ Deploy manuel (bouton à cliquer)

**3. Déclencher le déploiement :**

GitLab → **CI/CD** → **Pipelines** → **deploy-backend** → **Play** ▶️

Même chose pour **deploy-frontend**

**4. Vérifier dans Dokploy :**

**Applications** → **backend-api** / **frontend-app**

Statut : 🟢 **Running**

---

### Étape 11 : Vérification de la Stack

**1. Tester le Backend :**

```bash
# Health check
curl https://api.votredomaine.com/actuator/health

# Réponse attendue :
{
  "status": "UP",
  "components": {
    "db": {"status": "UP"},
    "redis": {"status": "UP"}
  }
}
```

**2. Tester le Frontend :**

Ouvrir : `https://app.votredomaine.com`

L'application Angular doit se charger et communiquer avec l'API.

**3. Vérifier les logs :**

**Dokploy** → **Applications** → **backend-api** → **Logs**

```
2024-12-21 10:30:15 INFO  - Starting SpringBootApplication
2024-12-21 10:30:16 INFO  - Connected to PostgreSQL
2024-12-21 10:30:16 INFO  - Connected to Redis
2024-12-21 10:30:16 INFO  - Tomcat started on port 8080
```

**4. Monitoring :**

**Applications** → **backend-api** → **Monitoring**

```
CPU:    ████░░░░ 32%
Memory: ██████░░ 58% (1.2GB / 2GB)
```

---

### Workflow Complet de Développement

```mermaid
sequenceDiagram
    participant Dev as 👨‍💻 Développeur
    participant Git as 🦊 GitLab
    participant CI as 🔨 GitLab CI
    participant Harbor as 🐳 Harbor
    participant Dokploy as 🚀 Dokploy
    participant App as 📱 Application

    Dev->>Git: git push origin main
    Git->>CI: Trigger Pipeline
    CI->>CI: Build Docker Image
    CI->>Harbor: Push Image
    Harbor-->>CI: OK
    CI->>Dokploy: Webhook Deploy
    Dokploy->>Harbor: Pull Image
    Dokploy->>App: Deploy Container
    App-->>Dokploy: Health Check OK
    Dokploy-->>Dev: ✅ Deployment Success
```

---

## 🔄 Workflow Quotidien

### Développement d'une Feature

**1. Créer une branche**
```bash
git checkout -b feature/new-payment-method
```

**2. Développer + Commit**
```bash
git add .
git commit -m "feat: add Stripe payment"
git push origin feature/new-payment-method
```

**3. GitLab CI build automatiquement**
- Image taguée : `feature-new-payment-method-abc123`
- Pas de déploiement auto (seulement main)

**4. Merge Request → main**
```bash
# Après review
git checkout main
git merge feature/new-payment-method
git push origin main
```

**5. Pipeline main s'exécute**
- Build + Push image `latest`
- Job `deploy-backend` disponible (manuel)

**6. Déploiement en production**
- Cliquez sur **Play** dans GitLab
- Dokploy pull la nouvelle image
- Zero-downtime deployment ✅

---

## 📊 Monitoring de la Stack

### Vue d'ensemble

**Dokploy** → **Project "e-commerce"** → **Overview**

```
┌─────────────────────────────────────────────┐
│ E-Commerce Project                          │
├─────────────────────────────────────────────┤
│                                             │
│ 🅰️ frontend-app        🟢 Running          │
│    CPU: 12%  RAM: 256MB  Uptime: 15d       │
│                                             │
│ ☕ backend-api         🟢 Running          │
│    CPU: 28%  RAM: 1.2GB  Uptime: 15d       │
│                                             │
│ 🐘 ecommerce-db       🟢 Running          │
│    CPU: 15%  RAM: 512MB  Size: 2.1GB       │
│                                             │
│ 🔴 ecommerce-cache    🟢 Running          │
│    CPU: 5%   RAM: 128MB  Keys: 1,234       │
│                                             │
└─────────────────────────────────────────────┘
```

### Alertes (optionnel)

**Settings** → **Notifications** → **Add Webhook**

- **Type** : Slack / Discord
- **Webhook URL** : `https://hooks.slack.com/...`
- **Events** : Deployment Failed, High CPU, High Memory

---

## 🎯 Récapitulatif de la Stack

```mermaid
graph TB
    subgraph "Développeurs"
        DEV[👨‍💻 Vous]
    end
    
    subgraph "Source Code"
        GIT[📂 Git Repository]
        GITLAB[🦊 GitLab]
        GITHUB[🐙 GitHub]
    end
    
    subgraph "Dokploy Platform"
        DOKPLOY[🚀 Dokploy Core]
        
        subgraph "Build Methods"
            NIXPACKS[⚡ Nixpacks<br/>Auto-détection]
            DOCKERFILE[🐳 Dockerfile<br/>Custom]
            BUILDPACK[📦 Buildpacks<br/>Heroku/Paketo]
            COMPOSE[🔧 Docker Compose<br/>Multi-services]
        end
        
        subgraph "Services"
            TRAEFIK[🌐 Traefik<br/>Reverse Proxy + SSL]
            POSTGRES[🐘 PostgreSQL]
            REDIS[🔴 Redis]
            MONGO[🍃 MongoDB]
        end
    end
    
    subgraph "Déploiement"
        CONTAINER[📦 Containers Docker]
        DOMAINS[🌍 Domaines HTTPS]
    end
    
    DEV -->|git push| GITLAB
    DEV -->|git push| GITHUB
    DEV -->|git push| GIT
    
    GITLAB -->|webhook| DOKPLOY
    GITHUB -->|webhook| DOKPLOY
    GIT -->|pull| DOKPLOY
    
    DOKPLOY --> NIXPACKS
    DOKPLOY --> DOCKERFILE
    DOKPLOY --> BUILDPACK
    DOKPLOY --> COMPOSE
    
    NIXPACKS --> CONTAINER
    DOCKERFILE --> CONTAINER
    BUILDPACK --> CONTAINER
    COMPOSE --> CONTAINER
    
    DOKPLOY --> TRAEFIK
    DOKPLOY --> POSTGRES
    DOKPLOY --> REDIS
    DOKPLOY --> MONGO
    
    TRAEFIK --> DOMAINS
    CONTAINER --> DOMAINS
    
    style DOKPLOY fill:#326CE5,color:#fff
    style TRAEFIK fill:#24A1C1,color:#fff
    style CONTAINER fill:#2496ED,color:#fff
```

---

## 🎨 Interface Dokploy

### Dashboard Principal

```
┌─────────────────────────────────────────────────────────────┐
│ 🚀 Dokploy                    👤 Admin    🔔 Notifications  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  📊 Projects                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ 🟢 Java App  │  │ 🟢 Drupal    │  │ 🟡 Angular   │      │
│  │ 3 services   │  │ 2 services   │  │ Building...  │      │
│  │ CPU: 12%     │  │ CPU: 8%      │  │ CPU: 45%     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  💾 Databases                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ 🐘 PostgreSQL│  │ 🔴 Redis     │  │ 🍃 MongoDB   │      │
│  │ prod-db      │  │ cache        │  │ logs-db      │      │
│  │ 2.1GB / 5GB  │  │ 512MB        │  │ 1.8GB / 3GB  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  📈 System Resources                                          │
│  CPU:  ████████░░░░░ 65%    RAM: ██████████░░ 80%           │
│  Disk: ██████░░░░░░░ 45%    Net: ████░░░░░░░░ 32%           │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Récapitulatif de la Stack

| Composant | Type | Port | Domaine | Status |
|-----------|------|------|---------|--------|
| **Frontend Angular** | Application | 80 | app.votredomaine.com | 🟢 |
| **Backend Spring Boot** | Application | 8080 | api.votredomaine.com | 🟢 |
| **PostgreSQL** | Database | 5432 | ecommerce-db (interne) | 🟢 |
| **Redis** | Cache | 6379 | ecommerce-cache (interne) | 🟢 |

**URLs de production :**
- Frontend : `https://app.votredomaine.com`
- Backend API : `https://api.votredomaine.com`
- Dokploy : `https://dokploy.votredomaine.com`

---

## 💡 Points Clés à Retenir

### ✅ Ce que Dokploy gère pour vous

1. **Déploiement** : Pull image → Start container → Health check
2. **SSL/TLS** : Certificats Let's Encrypt automatiques
3. **Routing** : Traefik configure automatiquement les routes
4. **Monitoring** : Logs, métriques CPU/RAM en temps réel
5. **Databases** : PostgreSQL, Redis gérés avec backups
6. **Zero-downtime** : Rolling updates automatiques

### 🔄 Workflow GitLab CI → Dokploy

```
1. git push → GitLab
2. GitLab CI → Build Docker image
3. Push image → Harbor
4. Webhook/API → Dokploy
5. Dokploy → Pull + Deploy
6. ✅ Application en ligne
```

### 🎨 Alternative : Build Direct dans Dokploy

Si vous ne voulez **pas** utiliser GitLab CI pour builder :

**Application** → **Source** → **Git** (au lieu de Docker Registry)

Dokploy peut builder directement depuis Git avec :
- **Nixpacks** (auto-détection)
- **Dockerfile** (si présent dans le repo)
- **Buildpacks** (Heroku/Paketo)

:::warning Attention
Builder sur Dokploy consomme des ressources serveur. Pour la production, préférez builder dans GitLab CI.
:::

---

## 🔗 Ressources

### Documentation
- [Dokploy Docs](https://docs.dokploy.com)
- [API Reference](https://docs.dokploy.com/docs/api)
- [CLI](https://docs.dokploy.com/docs/cli)

### Support
- [Discord](https://discord.gg/dokploy)
- [GitHub](https://github.com/Dokploy/dokploy)

---

**Dokploy : Déployez en toute simplicité ! 🚀🐳**

### Étape 1 : Créer un Projet

1. **Connexion** : `https://dokploy.votre-serveur.com`
2. **Dashboard** → **Projects** → **Create Project**
3. Remplir :
   - **Nom** : `mon-projet`
   - **Description** : "Mon application de production"
4. **Create**

:::info Projet vs Application
Un **Projet** peut contenir plusieurs **Applications** et **Bases de données**.

Exemple : Projet "E-commerce" → API Backend + Frontend + PostgreSQL + Redis
:::

### Étape 2 : Créer une Application

**Dans votre projet** → **Create** → **Application**

```mdx-code-block
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

<Tabs>
  <TabItem value="nixpacks" label="Nixpacks (Recommandé)" default>
```

**Méthode la plus simple - Auto-détection**

**Configuration :**

**Nom** : `api-backend`

**Source** : Git

**Provider** : GitHub / GitLab

**Repository** : `votre-username/votre-repo`

**Branch** : `main`

**Build Type** : **Nixpacks** (par défaut)

**Port** : `3000` (ou le port de votre app)

**Nixpacks détecte automatiquement :**

Node.js (package.json), Python (requirements.txt, pyproject.toml), Go (go.mod), PHP (composer.json), Ruby (Gemfile), Rust (Cargo.toml), Java (pom.xml, build.gradle), .NET, Deno, Bun, et plus !

**Personnalisation (optionnel) :**

Créer `nixpacks.toml` à la racine :

```toml
# nixpacks.toml
[phases.setup]
nixPkgs = ["nodejs-18_x", "yarn"]

[phases.install]
cmds = ["yarn install"]

[phases.build]
cmds = ["yarn build"]

[start]
cmd = "yarn start"
```

**Déployer** : Cliquez sur **Deploy** ✅

```mdx-code-block
  </TabItem>
  <TabItem value="dockerfile" label="Dockerfile (Contrôle total)">
```

**Pour projets avec Dockerfile existant**

**Configuration :**

**Nom** : `api-backend`

**Source** : Git

**Repository** : `votre-username/votre-repo`

**Branch** : `main`

**Build Type** : **Dockerfile**

**Dockerfile Path** : `./Dockerfile` (ou chemin personnalisé)

**Docker Context Path** : `.` (racine du repo)

**Target Stage** (optionnel) : `production` (si multi-stage)

**Exemple Dockerfile multi-stage (Node.js) :**

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:20-alpine AS production
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

**Build Args (optionnel) :**

```
NODE_VERSION=20
APP_VERSION=1.0.0
```

**Build Secrets (pour infos sensibles) :**

```
NPM_TOKEN=ghp_xxxxx
```

**Déployer** : **Deploy** ✅

```mdx-code-block
  </TabItem>
  <TabItem value="compose" label="Docker Compose (Multi-services)">
```

**Pour applications complexes avec plusieurs services**

**Configuration :**

**Nom** : `fullstack-app`

**Source** : Git

**Repository** : `votre-username/votre-repo`

**Branch** : `main`

**Compose File** : `docker-compose.yml` (ou chemin personnalisé)

**Exemple docker-compose.yml :**

```yaml
version: '3.8'

services:
  # API Backend
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.example.com`)"
      - "traefik.http.services.api.loadbalancer.server.port=3000"

  # Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "80:80"
    depends_on:
      - api
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`example.com`)"

  # Database
  db:
    image: postgres:15-alpine
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=mydb

  # Cache
  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data

volumes:
  postgres-data:
  redis-data:
```

**Déployer** : **Deploy** ✅

Dokploy déploie tous les services en une fois !

```mdx-code-block
  </TabItem>
  <TabItem value="static" label="Site statique (React/Vue/Angular)">
```

**Pour sites statiques compilés**

**Configuration :**

**Nom** : `mon-site`

**Source** : Git

**Repository** : `votre-username/site-vitrine`

**Branch** : `main`

**Build Type** : **Static**

**Publish Directory** : `dist` (ou `build` pour CRA)

**Port** : `80` (Nginx écoute sur 80)

**Exemples par framework :**

**React (Vite)** : `dist`

**React (CRA)** : `build`

**Vue** : `dist`

**Angular** : `dist/my-app`

**Next.js (export)** : `out`

**SPA (Single Page App)** : Activer **SPA mode** pour gérer le routing

**Déployer** : **Deploy** ✅

Nginx sert automatiquement vos fichiers statiques !

```mdx-code-block
  </TabItem>
</Tabs>
```

---

## 🌐 Configurer un Domaine

### Option 1 : Domaine Auto-généré (Test)

Après déploiement, Dokploy génère un domaine automatique :

`https://mon-app-abc123.votre-serveur.com`

### Option 2 : Domaine Personnalisé (Production)

**1. Onglet Domains** → **Add Domain**

**2. Configurer :**

- **Domain** : `api.monsite.com`
- **Port** : `3000` (port de votre app)
- **SSL** : **Let's Encrypt** (auto)
- **Certificate Type** : `letsencrypt`

**3. DNS :** Pointer votre domaine vers le serveur Dokploy :

```
Type: A
Nom: api
Valeur: <IP_SERVEUR_DOKPLOY>
```

**4. Save** → SSL généré automatiquement en ~2 minutes ✅

:::tip Multi-domaines
Vous pouvez ajouter plusieurs domaines pour une même app :
- `api.monsite.com` (principal)
- `api-v2.monsite.com` (staging)
- `old-api.monsite.com` (legacy)
:::

---

## 🔐 Variables d'Environnement

### Ajouter des Variables

**Application** → **Environment** → **Add Variable**

```bash
# Production
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@postgres:5432/mydb
REDIS_URL=redis://redis:6379
JWT_SECRET=super-secret-key-change-me
API_KEY=sk-xxxxxxxxxxxxx

# Optionnel : Variables pour build
REACT_APP_API_URL=https://api.monsite.com
VITE_API_URL=https://api.monsite.com
```

:::warning Secrets
Pour les secrets sensibles (API keys, mots de passe), utilisez les **Build Secrets** dans l'onglet **Build Type** plutôt que les variables d'environnement normales.
:::

### Variables depuis .env (local)

Si vous avez un fichier `.env` local, copiez-collez son contenu directement dans l'éditeur Dokploy.

**Astuce :** Vous pouvez aussi utiliser l'**API** pour injecter les variables :

```bash
# Depuis votre .env local
export $(cat .env | grep -v '^#' | xargs)
curl -X POST https://dokploy.example.com/api/environment.create \
  -H "Authorization: Bearer <API_KEY>" \
  -d "{\"applicationId\": \"...\", \"key\": \"DATABASE_URL\", \"value\": \"$DATABASE_URL\"}"
```

---

## 💾 Créer une Base de Données

### PostgreSQL

**Projects** → **Votre projet** → **Create** → **Database** → **PostgreSQL**

**Configuration :**

- **Nom** : `prod-db`
- **Database Name** : `myapp`
- **Username** : `myapp_user`
- **Password** : Généré automatiquement (ou custom)
- **Port** : `5432`
- **Version** : `15` (ou 14, 13, 12)

**Storage** : Volume Docker automatique

**Create** ✅

**Connection String générée :**

```
postgresql://myapp_user:generated_password@prod-db:5432/myapp
```

Copiez cette URL dans les variables d'environnement de votre app !

### Redis (Cache)

**Même processus :**

- **Type** : Redis
- **Nom** : `cache`
- **Port** : `6379`
- **Password** : Auto ou custom

**URL** : `redis://cache:6379`

### MongoDB

- **Type** : MongoDB
- **Nom** : `logs-db`
- **Port** : `27017`

**URL** : `mongodb://logs-db:27017/mydb`

:::tip Backups
**Database** → **Backups** → **Schedule Backup**

Programmez des backups automatiques vers S3, MinIO ou local !
:::

---

## 🔄 Auto-Déploiement (GitLab/GitHub)

### Activer les Webhooks

**1. Dans Dokploy :**

**Application** → **Settings** → **Git**

**Auto Deploy** : **Activé** ✅

**Trigger** : `push` ou `tag`

**Branch** : `main` (ou `production`, `develop`)

**2. Copier le Webhook URL :**

```
https://dokploy.example.com/webhook/<app-id>/<token>
```

### Configurer GitLab

**Votre projet GitLab** → **Settings** → **Webhooks**

- **URL** : `https://dokploy.example.com/webhook/...`
- **Trigger** : ✅ Push events
- **Branch filter** : `main`
- **SSL verification** : ✅ Enabled

**Add webhook** → **Test** → Push event

✅ Maintenant chaque `git push` déclenche un déploiement !

### Configurer GitHub

**Repository** → **Settings** → **Webhooks** → **Add webhook**

- **Payload URL** : `https://dokploy.example.com/webhook/...`
- **Content type** : `application/json`
- **Events** : ✅ Just the push event

---

## 📊 Monitoring et Logs

### Voir les Logs en Temps Réel

**Application** → **Logs**

```bash
[2024-12-21 10:30:15] Starting server...
[2024-12-21 10:30:16] Connected to database
[2024-12-21 10:30:16] Server listening on port 3000
[2024-12-21 10:30:20] GET /api/users - 200 - 45ms
[2024-12-21 10:30:25] POST /api/auth/login - 200 - 123ms
```

**Filtres** : Level (info/warn/error), Date, Recherche

### Monitoring Ressources

**Application** → **Monitoring**

```
CPU Usage:     ████████░░░░ 65%
Memory:        ██████░░░░░░ 48% (1.2GB / 2.5GB)
Disk I/O:      ████░░░░░░░░ 32%
Network In:    ↓ 2.5 MB/s
Network Out:   ↑ 1.8 MB/s
```

**Alertes** : Configurez des notifications Slack/Discord

**Settings** → **Notifications** → **Add Webhook**

---

## 🔧 Commandes Avancées

### Ouvrir un Terminal dans le Container

**Application** → **Terminal**

```bash
# Vous êtes dans le container !
$ ls
dist  node_modules  package.json

$ npm run migrate
$ node scripts/seed.js
$ ps aux
```

### Scaling (Réplicas)

**Application** → **Advanced** → **Replicas**

```yaml
Replicas: 3  # Lance 3 instances de l'app
```

Dokploy utilise Docker Swarm pour load-balancing automatique.

### Health Checks

**Advanced** → **Health Check**

```bash
# HTTP Health Check
Path: /health
Interval: 30s
Timeout: 10s
Retries: 3

# Ou commande custom
Command: curl -f http://localhost:3000/health || exit 1
```

---

## 🎨 Exemples par Stack

### Node.js (Express/NestJS)

```javascript title="index.js"
// Votre app Express
const express = require('express');
const app = express();

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**Dokploy Config :**

- **Build Type** : Nixpacks (auto-détecte Node.js)
- **Port** : 3000
- **Start Command** : Auto-détecté depuis `package.json`

### Python (FastAPI/Django)

```python title="main.py"
# FastAPI
from fastapi import FastAPI
app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

**Dokploy Config :**

- **Build Type** : Nixpacks
- **Port** : 8000
- **Start Command** : `uvicorn main:app --host 0.0.0.0`

### PHP (Laravel/Symfony)

```php title="index.php"
<?php
// Laravel public/index.php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Kernel::class);
$response = $kernel->handle($request = Request::capture());
```

**Dokploy Config :**

- **Build Type** : Dockerfile (voir ci-dessous)
- **Port** : 8000

```dockerfile title="Dockerfile"
FROM php:8.2-fpm-alpine
WORKDIR /app
COPY . .
RUN composer install --no-dev
EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
```

### Go

```go title="main.go"
package main

import (
    "fmt"
    "net/http"
)

func health(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, `{"status":"ok"}`)
}

func main() {
    http.HandleFunc("/health", health)
    http.ListenAndServe(":8080", nil)
}
```

**Dokploy Config :**

- **Build Type** : Nixpacks (auto-détecte Go)
- **Port** : 8080

---

## 🚨 Troubleshooting

### L'app ne démarre pas

**1. Vérifier les logs**

```
Application → Logs
```

Cherchez les erreurs : `ERROR`, `ECONNREFUSED`, `Cannot find module`

**2. Variables d'environnement manquantes ?**

```
Application → Environment
```

Vérifiez que toutes les variables requises sont présentes.

**3. Port incorrect ?**

Votre app écoute sur le port défini dans **Settings** → **Port** ?

```javascript
// ✅ Correct
const PORT = process.env.PORT || 3000;
app.listen(PORT);

// ❌ Incorrect (hardcodé)
app.listen(8080);
```

### Build échoue

**1. Vérifier les logs de build**

```
Application → Deployments → Dernier déploiement → Logs
```

**2. Problème de dépendances ?**

```bash
# Node.js
npm ERR! 404 Not Found

# Python
ERROR: Could not find a version that satisfies the requirement
```

→ Vérifiez `package.json` / `requirements.txt`

**3. Manque de RAM pour le build ?**

→ Augmentez les ressources du serveur ou utilisez un **Build Server** externe

### SSL ne fonctionne pas

**1. DNS configuré correctement ?**

```bash
dig api.monsite.com
# Doit retourner l'IP du serveur Dokploy
```

**2. Port 80/443 ouvert ?**

```bash
sudo ufw allow 80
sudo ufw allow 443
```

**3. Attendre 2-5 minutes**

Let's Encrypt prend un peu de temps pour valider et émettre le certificat.

---

## 💡 Best Practices

### ✅ À Faire

1. **Utiliser Nixpacks** pour prototyper rapidement
2. **Dockerfile custom** pour la production
3. **Variables d'environnement** pour la config (jamais hardcodé)
4. **Health checks** pour monitoring
5. **Backups automatiques** des bases de données
6. **Webhooks** pour auto-déploiement
7. **Monitoring actif** avec alertes
8. **Tests** avant de push (CI/CD externe)

### ❌ À Éviter

1. **Ne pas hardcoder** les secrets
2. **Ne pas utiliser** `latest` comme tag Docker
3. **Ne pas négliger** les health checks
4. **Ne pas builder** sur le serveur prod (RAM limitée)
5. **Ne pas oublier** les backups
6. **Ne pas exposer** directement les ports (utiliser Traefik)

---

## 🔗 Ressources

### Documentation

- [Dokploy Docs](https://docs.dokploy.com)
- [Nixpacks](https://nixpacks.com)
- [Traefik](https://doc.traefik.io/traefik/)

### Support

- [Discord Dokploy](https://discord.gg/dokploy)
- [GitHub Issues](https://github.com/Dokploy/dokploy/issues)
- [GitHub Discussions](https://github.com/Dokploy/dokploy/discussions)

### Templates Prêts à l'Emploi

Dans Dokploy : **Projects** → **Create** → **Template**

- 📊 **Plausible** : Analytics
- 📧 **Postal** : Mail server
- 🔐 **Authentik** : SSO
- 📝 **Ghost** : Blog
- 💬 **Mattermost** : Chat
- 📦 **Supabase** : Backend as a Service
- 🗓️ **Cal.com** : Scheduling
- 📱 **PocketBase** : Backend SQLite

---

## 🎓 Résumé Rapide

```mermaid
graph LR
    A[1. Créer Projet] --> B[2. Créer Application]
    B --> C[3. Connecter Git]
    C --> D[4. Choisir Build Type]
    D --> E[5. Configurer Env Vars]
    E --> F[6. Deploy]
    F --> G[7. Ajouter Domaine]
    G --> H[8. Activer Webhook]
    H --> I[✅ Production Ready!]
    
    style A fill:#4CAF50,color:#fff
    style I fill:#4CAF50,color:#fff
```

**Temps total : 10-15 minutes** ⚡

---

**Dokploy : Déployez en toute simplicité ! 🚀🐳**