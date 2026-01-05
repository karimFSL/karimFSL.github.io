---
sidebar_position: 2
---

# 🔍 Trivy - Scan de vulnérabilités

**Trivy** est un scanner de vulnérabilités open-source complet et facile à utiliser. Il scanne conteneurs, systèmes de fichiers, repositories Git, et configurations IaC.

## 🎯 Pourquoi Trivy ?

- ✅ **Complet** : Conteneurs, FS, IaC, SBOM
- ✅ **Rapide** : Scan en quelques secondes
- ✅ **Précis** : Faible taux de faux positifs
- ✅ **Gratuit** : Open-source et maintenu activement

## 📦 Installation

```bash
# Linux
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz
tar zxvf trivy_0.48.0_Linux-64bit.tar.gz
sudo mv trivy /usr/local/bin/

# macOS
brew install trivy

# Docker
docker pull aquasec/trivy:latest
```

## 🔍 Types de scans

### Images Docker
```bash
# Scan basique
trivy image mon-app:latest

# Sévérité spécifique
trivy image --severity HIGH,CRITICAL mon-app:latest

# Exit code si vulnérabilités
trivy image --exit-code 1 --severity CRITICAL mon-app:latest

# Ignorer non fixées
trivy image --ignore-unfixed mon-app:latest

# Format JSON
trivy image --format json --output results.json mon-app:latest
```

### Système de fichiers
```bash
# Répertoire actuel
trivy fs .

# Répertoire spécifique
trivy fs /path/to/project

# Fichier JAR/WAR
trivy fs target/my-app.jar
```

### Configuration IaC
```bash
# Terraform
trivy config ./infrastructure/terraform

# Kubernetes
trivy config ./k8s-manifests

# Docker Compose
trivy config docker-compose.yml
```

### Repository Git
```bash
# Repo distant
trivy repo https://github.com/org/repo

# Branche spécifique
trivy repo --branch develop https://github.com/org/repo
```

### SBOM
```bash
# Scan SBOM
trivy sbom sbom.json
```

## 🔧 Configuration

### Fichier de configuration
```yaml
# trivy.yaml
severity:
  - CRITICAL
  - HIGH

vulnerability:
  ignore-unfixed: true

output: json
format: sarif
```

```bash
trivy image --config trivy.yaml mon-app:latest
```

### Fichier d'exclusion
```text
# .trivyignore
CVE-2023-12345
CVE-2023-67890  # Justification
```

## 🔄 Intégration CI/CD

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - security

variables:
  IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

trivy-scan:
  stage: security
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    # Scan filesystem
    - trivy fs --exit-code 0 --format json --output trivy-fs.json .
    
    # Scan image
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $IMAGE
    
    # Scan IaC
    - trivy config --exit-code 0 ./infrastructure
  artifacts:
    reports:
      container_scanning: trivy-fs.json
    paths:
      - trivy-fs.json
  only:
    - main
    - merge_requests

# Scan quotidien
trivy-daily:
  stage: security
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image --severity CRITICAL,HIGH $CI_REGISTRY_IMAGE:latest
  only:
    - schedules
```

### Jenkins

```groovy
pipeline {
    agent any
    stages {
        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy image \
                      --format json \
                      --output trivy-results.json \
                      --severity CRITICAL,HIGH \
                      --exit-code 1 \
                      my-app:${BUILD_NUMBER}
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-results.json'
                }
            }
        }
    }
}
```

## 📊 Formats de sortie

### JSON
```bash
trivy image --format json --output results.json mon-app:latest
```

### SARIF (GitHub Security)
```bash
trivy image --format sarif --output results.sarif mon-app:latest
```

### Table (défaut)
```bash
trivy image mon-app:latest
# Output: Total: 15 (CRITICAL: 2, HIGH: 7, MEDIUM: 6)
```

### HTML
```bash
trivy image --format template --template "@contrib/html.tpl" --output report.html mon-app:latest
```

## 🎯 Meilleures pratiques

### 1. Scans réguliers
```yaml
# Scan quotidien
schedule:
  - cron: '0 2 * * *'
```

### 2. Politique de sévérité
```bash
# Bloquer CRITICAL uniquement
trivy image --exit-code 1 --severity CRITICAL mon-app:latest

# Ou CRITICAL+HIGH
trivy image --exit-code 1 --severity CRITICAL,HIGH mon-app:latest
```

### 3. Cache pour performance
```bash
export TRIVY_CACHE_DIR=/tmp/trivy-cache
trivy image mon-app:latest
```

### 4. Ignorer non fixées
```bash
trivy image --ignore-unfixed mon-app:latest
```

## 🔐 Registries privés

### Docker Hub
```bash
docker login
trivy image private-registry/mon-app:latest
```

### AWS ECR
```bash
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.eu-west-1.amazonaws.com
trivy image 123456789.dkr.ecr.eu-west-1.amazonaws.com/mon-app:latest
```

### Azure ACR
```bash
az acr login --name myregistry
trivy image myregistry.azurecr.io/mon-app:latest
```

### GitLab Registry
```bash
docker login registry.gitlab.com
trivy image registry.gitlab.com/group/project:latest
```

## 🔄 Automatisation

### Pre-commit hook
```bash
#!/bin/bash
# .git/hooks/pre-commit
echo "Running Trivy scan..."
trivy fs --exit-code 1 --severity CRITICAL,HIGH .

if [ $? -ne 0 ]; then
    echo "❌ Trivy scan failed"
    exit 1
fi
echo "✅ Trivy scan passed"
```

## 🆘 Troubleshooting

### Base de données non à jour
```bash
trivy image --download-db-only
```

### Erreur de connexion
```bash
export HTTP_PROXY=http://proxy:8080
export HTTPS_PROXY=http://proxy:8080
trivy image mon-app:latest
```

### Scan trop lent
```bash
# Réduire les scanners
trivy image --scanners vuln mon-app:latest

# Ignorer node_modules
trivy image --skip-dirs node_modules mon-app:latest
```

## 📚 Ressources

- [Documentation Trivy](https://aquasecurity.github.io/trivy/)
- [GitHub Trivy](https://github.com/aquasecurity/trivy)
- [Intégrations CI/CD](https://aquasecurity.github.io/trivy/latest/docs/integrations/)

---

**Trivy scanne maintenant automatiquement vos vulnérabilités !** 🔒