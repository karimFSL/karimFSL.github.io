---
sidebar_position: 2
---
# 🔍 SonarQube Community + Branch Plugin

**SonarQube Community** avec le **Community Branch Plugin** permet l'analyse de branches et la décoration de PR/MR, normalement réservées à la version Developer.

## 🎯 Pourquoi ce plugin ?

- ✅ **Branch analysis** : Scanner plusieurs branches (feature, develop, main)
- ✅ **PR/MR decoration** : Commentaires automatiques sur les PR/MR
- ✅ **Gratuit** : Alternative à SonarQube Developer Edition
- ✅ **Multi-plateforme** : GitLab, GitHub, Bitbucket, Azure DevOps

## 📦 Installation

### Docker Compose (Recommandé)

```yaml
# docker-compose.yml
version: '3'

services:
  sonarqube:
    image: mc1arke/sonarqube-with-community-branch-plugin:latest
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      - SONAR_JDBC_URL=jdbc:postgresql://db:5432/sonar
      - SONAR_JDBC_USERNAME=sonar
      - SONAR_JDBC_PASSWORD=sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
    depends_on:
      - db
  
  db:
    image: postgres:15-alpine
    container_name: sonarqube-db
    environment:
      - POSTGRES_USER=sonar
      - POSTGRES_PASSWORD=sonar
      - POSTGRES_DB=sonar
    volumes:
      - postgresql_data:/var/lib/postgresql/data

volumes:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:
  postgresql_data:
```

```bash
# Démarrage
docker-compose up -d

# Accès : http://localhost:9000
# Login par défaut : admin / admin
```

### Installation manuelle

```bash
# 1. Télécharger SonarQube Community
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.3.0.82913.zip
unzip sonarqube-10.3.0.82913.zip

# 2. Télécharger le plugin
wget https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/1.18.0/sonarqube-community-branch-plugin-1.18.0.jar

# 3. Installer le plugin
cp sonarqube-community-branch-plugin-1.18.0.jar sonarqube-10.3.0.82913/extensions/plugins/

# 4. Démarrer SonarQube
cd sonarqube-10.3.0.82913/bin/linux-x86-64
./sonar.sh start
```

## ⚙️ Configuration

### 1. Première connexion

```bash
# URL : http://localhost:9000
# Login : admin / admin
# → Changer le mot de passe
```

### 2. Créer un projet

1. **Administration** → **Projects** → **Create Project**
2. **Project key** : `my-project`
3. **Display name** : `My Project`
4. **Main branch** : `main`

### 3. Générer un token

1. **My Account** → **Security** → **Generate Tokens**
2. **Name** : `gitlab-ci` ou `github-actions`
3. **Type** : Global Analysis Token
4. **Expires in** : No expiration
5. **Generate** → Copier le token

### 4. Configuration GitLab/GitHub

**GitLab** :
1. **Administration** → **Configuration** → **ALM**
2. **GitLab** → **Create configuration**
3. **Configuration name** : `GitLab`
4. **GitLab URL** : `https://gitlab.com`
5. **Personal Access Token** : Token GitLab avec scope `api`

**GitHub** :
1. **Administration** → **Configuration** → **ALM**
2. **GitHub** → **Create configuration**
3. **GitHub App** : Créer une GitHub App avec permissions

## 🔄 Intégration CI/CD

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - sonar

variables:
  SONAR_HOST_URL: "http://sonarqube:9000"
  SONAR_TOKEN: $SONAR_TOKEN
  GIT_DEPTH: 0

sonarqube-check:
  stage: sonar
  image: 
    name: sonarsource/sonar-scanner-cli:latest
    entrypoint: [""]
  script:
    - sonar-scanner
      -Dsonar.projectKey=my-project
      -Dsonar.sources=.
      -Dsonar.host.url=$SONAR_HOST_URL
      -Dsonar.token=$SONAR_TOKEN
      -Dsonar.branch.name=$CI_COMMIT_REF_NAME
  only:
    - branches
    - merge_requests

sonarqube-mr-decoration:
  stage: sonar
  image: 
    name: sonarsource/sonar-scanner-cli:latest
    entrypoint: [""]
  script:
    - sonar-scanner
      -Dsonar.projectKey=my-project
      -Dsonar.sources=.
      -Dsonar.host.url=$SONAR_HOST_URL
      -Dsonar.token=$SONAR_TOKEN
      -Dsonar.pullrequest.key=$CI_MERGE_REQUEST_IID
      -Dsonar.pullrequest.branch=$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
      -Dsonar.pullrequest.base=$CI_MERGE_REQUEST_TARGET_BRANCH_NAME
      -Dsonar.pullrequest.gitlab.projectId=$CI_PROJECT_PATH
  only:
    - merge_requests
```

### Jenkins

```groovy
pipeline {
    agent any
    
    environment {
        SONAR_HOST = 'http://sonarqube:9000'
        SONAR_TOKEN = credentials('sonar-token')
    }
    
    stages {
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                              -Dsonar.projectKey=my-project \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=${SONAR_HOST} \
                              -Dsonar.token=${SONAR_TOKEN} \
                              -Dsonar.branch.name=${env.BRANCH_NAME}
                        """
                    }
                }
            }
        }
    }
}
```

### Ligne de commande

```bash
# Scan basique
sonar-scanner \
  -Dsonar.projectKey=my-project \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=$SONAR_TOKEN

# Avec branch
sonar-scanner \
  -Dsonar.projectKey=my-project \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=$SONAR_TOKEN \
  -Dsonar.branch.name=feature/my-feature
```

## 📁 Configuration générique

### Fichier sonar-project.properties

```properties
# Configuration de base (tous langages)
sonar.projectKey=my-project
sonar.projectName=My Project
sonar.projectVersion=1.0

# Chemins sources
sonar.sources=src
sonar.tests=tests

# Exclusions communes
sonar.exclusions=\
  **/node_modules/**,\
  **/vendor/**,\
  **/dist/**,\
  **/build/**,\
  **/target/**,\
  **/*.min.js,\
  **/*.generated.*

sonar.test.exclusions=\
  **/*Test.*,\
  **/*.spec.*,\
  **/test/**
```

### Configuration par outil de build

#### Maven (Java)

```xml
<!-- pom.xml -->
<properties>
    <sonar.projectKey>my-project</sonar.projectKey>
    <sonar.host.url>http://localhost:9000</sonar.host.url>
    <sonar.coverage.jacoco.xmlReportPaths>target/site/jacoco/jacoco.xml</sonar.coverage.jacoco.xmlReportPaths>
</properties>
```

```bash
mvn clean verify sonar:sonar -Dsonar.token=$SONAR_TOKEN
```

#### Gradle (Java/Kotlin)

```groovy
// build.gradle
plugins {
    id 'org.sonarqube' version '4.4.1.3373'
}

sonar {
    properties {
        property "sonar.projectKey", "my-project"
        property "sonar.host.url", "http://localhost:9000"
    }
}
```

```bash
./gradlew sonar -Dsonar.token=$SONAR_TOKEN
```

#### Composer (PHP)

```properties
# sonar-project.properties
sonar.projectKey=my-project
sonar.sources=src,modules
sonar.tests=tests
sonar.php.coverage.reportPaths=coverage.xml
sonar.exclusions=vendor/**
```

#### npm (JavaScript/TypeScript)

```properties
# sonar-project.properties
sonar.projectKey=my-project
sonar.sources=src
sonar.tests=tests
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.typescript.lcov.reportPaths=coverage/lcov.info
sonar.exclusions=node_modules/**,dist/**
```

#### Autres langages

```properties
# Python
sonar.python.coverage.reportPaths=coverage.xml

# Go
sonar.go.coverage.reportPaths=coverage.out

# .NET
sonar.cs.vscoveragexml.reportsPaths=coverage.xml

# Ruby
sonar.ruby.coverage.reportPaths=coverage/coverage.xml
```

### Scan universel avec sonar-scanner

```bash
# Installation
# Linux
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip sonar-scanner-cli-5.0.1.3006-linux.zip
export PATH=$PATH:/path/to/sonar-scanner/bin

# macOS
brew install sonar-scanner

# Docker
docker run sonarsource/sonar-scanner-cli sonar-scanner [options]

# Scan
sonar-scanner -Dsonar.token=$SONAR_TOKEN
```

## 🎯 Configuration avancée

### Quality Gate

```yaml
# Dans SonarQube UI
# Quality Gates → Create → Configure:
- Coverage > 80%
- Duplicated Lines < 3%
- Maintainability Rating = A
- Reliability Rating = A
- Security Rating = A
- Security Hotspots Reviewed > 80%
```

### Quality Profile

```yaml
# Administration → Quality Profiles
# Créer un profil personnalisé par langage
# Activer/désactiver des règles selon vos besoins
```

### Exclusions globales

```properties
# sonar-project.properties
sonar.exclusions=\
  **/node_modules/**,\
  **/vendor/**,\
  **/dist/**,\
  **/build/**,\
  **/target/**,\
  **/*.min.js,\
  **/*.generated.*

sonar.test.exclusions=\
  **/*Test.java,\
  **/*.spec.ts,\
  **/test/**
```

## 🔐 Sécurité

### SSL/TLS

```yaml
# docker-compose.yml
services:
  sonarqube:
    environment:
      - SONAR_WEB_HTTPS_ENABLED=true
      - SONAR_WEB_HTTPS_KEYSTORE_PATH=/opt/sonarqube/certs/keystore.p12
      - SONAR_WEB_HTTPS_KEYSTORE_PASSWORD=changeit
    volumes:
      - ./certs:/opt/sonarqube/certs
```

### Authentification LDAP

```properties
# sonar.properties
sonar.security.realm=LDAP
ldap.url=ldap://ldap.example.com:389
ldap.bindDn=cn=sonar,ou=users,dc=example,dc=com
ldap.bindPassword=secret
ldap.user.baseDn=ou=users,dc=example,dc=com
```

## 📊 Webhooks et intégrations

### GitLab Webhook

```yaml
# Administration → Configuration → Webhooks
# URL: https://gitlab.com/api/v4/projects/{project_id}/statuses/{commit_sha}
# Secret: Token GitLab
```

### Alertes email

```yaml
# Administration → Configuration → Email
SMTP host: smtp.gmail.com
SMTP port: 587
SMTP username: your-email@gmail.com
From address: sonarqube@example.com
```

## 🆘 Troubleshooting

### Plugin non chargé

```bash
# Vérifier les logs
docker logs sonarqube

# Vérifier le plugin
ls -la /opt/sonarqube/extensions/plugins/

# Restart
docker-compose restart sonarqube
```

### Erreur de connexion DB

```bash
# Vérifier PostgreSQL
docker logs sonarqube-db

# Recreate
docker-compose down -v
docker-compose up -d
```

### Branch analysis ne fonctionne pas

```bash
# Vérifier la version du plugin
# Plugin version >= 1.14.0 requis pour SonarQube 10.x

# Vérifier les paramètres
-Dsonar.branch.name=$CI_COMMIT_REF_NAME
```

### MR decoration ne s'affiche pas

```yaml
# Vérifier la configuration ALM
# Administration → Configuration → ALM → GitLab/GitHub

# Vérifier le token
# Token doit avoir les permissions api/repo
```

## 🎯 Meilleures pratiques

### 1. Scanner à chaque commit
```yaml
on: [push, pull_request]
```

### 2. Quality Gate obligatoire
```yaml
# Bloquer les MR si Quality Gate failed
allow_failure: false
```

### 3. Coverage minimale
```properties
sonar.coverage.minimum=80
```

### 4. Exclure les fichiers générés
```properties
sonar.exclusions=**/*.generated.*,**/node_modules/**
```

### 5. Maintenance régulière
```bash
# Backup DB hebdomadaire
# Nettoyage des anciennes analyses (> 90 jours)
# Mise à jour du plugin
```

## 📈 Métriques importantes

```yaml
# À surveiller dans SonarQube
- Code Coverage: > 80%
- Duplicated Lines: < 3%
- Technical Debt: < 5 days
- Security Hotspots: 0
- Bugs: 0
- Vulnerabilities: 0
- Code Smells: < 10
```

## 🔄 Mise à jour

```bash
# 1. Backup
docker-compose exec db pg_dump -U sonar sonar > backup.sql

# 2. Arrêt
docker-compose down

# 3. Mise à jour
docker-compose pull

# 4. Redémarrage
docker-compose up -d
```

## 📚 Ressources

- [SonarQube Community Branch Plugin](https://github.com/mc1arke/sonarqube-community-branch-plugin)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [SonarScanner CLI](https://docs.sonarqube.org/latest/analyzing-source-code/scanners/sonarscanner/)

---

**SonarQube analyse maintenant vos branches et décore vos MR/PR automatiquement !** 🔍✨