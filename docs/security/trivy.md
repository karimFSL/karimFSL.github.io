---
sidebar_position: 2
---

# 🔍 Trivy - Scan de vulnérabilités

**Trivy** est un scanner de vulnérabilités open-source complet et facile à utiliser. Il scanne les conteneurs, systèmes de fichiers, repositories Git, et configurations IaC.

## 🎯 Pourquoi Trivy ?

- ✅ **Complet** : Conteneurs, FS, IaC, SBOM
- ✅ **Rapide** : Scan en quelques secondes
- ✅ **Précis** : Faible taux de faux positifs
- ✅ **Multi-sources** : NVD, GitHub Security Advisories, etc.
- ✅ **Gratuit** : Open-source et maintenu activement

## 📦 Installation

### Binaire
```bash
# Linux
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz
tar zxvf trivy_0.48.0_Linux-64bit.tar.gz
sudo mv trivy /usr/local/bin/

# macOS
brew install trivy

# Vérification
trivy --version
```

### Docker
```bash
docker pull aquasec/trivy:latest
```

## 🔍 Types de scans

### 1. Scan d'images Docker

```bash
# Scan d'une image locale
trivy image mon-app:latest

# Scan avec sévérité spécifique
trivy image --severity HIGH,CRITICAL mon-app:latest

# Scan avec sortie JSON
trivy image --format json --output results.json mon-app:latest

# Scan avec exit code si vulnérabilités
trivy image --exit-code 1 --severity CRITICAL mon-app:latest

# Ignorer les vulnérabilités non fixées
trivy image --ignore-unfixed mon-app:latest
```

### 2. Scan du système de fichiers

```bash
# Scan du répertoire actuel
trivy fs .

# Scan d'un répertoire spécifique
trivy fs /path/to/project

# Scan avec fichier de suppression
trivy fs --ignorefile .trivyignore .

# Scan Java (JAR, WAR)
trivy fs target/my-app.jar
```

### 3. Scan de configuration IaC

```bash
# Scan Terraform
trivy config ./infrastructure/terraform

# Scan Kubernetes
trivy config ./k8s-manifests

# Scan Docker Compose
trivy config docker-compose.yml

# Avec policy personnalisée
trivy config --policy ./policies ./infrastructure
```

### 4. Scan de repository Git

```bash
# Scan d'un repo distant
trivy repo https://github.com/votre-org/votre-repo

# Scan d'une branche spécifique
trivy repo --branch develop https://github.com/votre-org/votre-repo
```

### 5. Scan SBOM

```bash
# Scan d'un SBOM CycloneDX
trivy sbom sbom.json

# Scan d'un SBOM SPDX
trivy sbom sbom.spdx.json
```

## 🔧 Configuration avancée

### Fichier de configuration

```yaml title="trivy.yaml"
# trivy.yaml
severity:
  - CRITICAL
  - HIGH
  - MEDIUM

vulnerability:
  ignore-unfixed: true
  
output: json

cache:
  dir: /tmp/trivy-cache

timeout: 10m

format: sarif
```

Utilisation :
```bash
trivy image --config trivy.yaml mon-app:latest
```

### Fichier d'exclusion

```text title=".trivyignore"
# .trivyignore - Ignorer des CVE spécifiques

# CVE avec false positive
CVE-2023-12345

# CVE accepté avec justification
CVE-2023-67890  # Utilisé uniquement en dev, pas de risque

# Ignorer un package spécifique
pkg:maven/com.example/vulnerable-lib@1.0.0
```

## 🔄 Intégration CI/CD

### GitHub Actions

```yaml title=".github/workflows/trivy.yml"
name: Trivy Security Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * *'  # Scan quotidien

jobs:
  trivy-scan:
    name: Trivy Security Scan
    runs-on: ubuntu-latest
    
    permissions:
      contents: read
      security-events: write
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      # Scan du code source
      - name: Run Trivy FS scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-fs-results.sarif'
          severity: 'CRITICAL,HIGH'
      
      - name: Upload Trivy FS results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-fs-results.sarif'
          category: 'trivy-fs'
      
      # Scan de l'image Docker
      - name: Build Docker image
        run: docker build -t test-image:${{ github.sha }} .
      
      - name: Run Trivy image scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'test-image:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-image-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'  # Fail le build si vulnérabilités
      
      - name: Upload Trivy image results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-image-results.sarif'
          category: 'trivy-image'
      
      # Scan IaC
      - name: Run Trivy config scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
          scan-ref: './infrastructure'
          format: 'sarif'
          output: 'trivy-config-results.sarif'
          severity: 'CRITICAL,HIGH'
      
      - name: Upload Trivy config results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-config-results.sarif'
          category: 'trivy-config'
      
      # Génération de rapport HTML
      - name: Generate HTML report
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'image'
          image-ref: 'test-image:${{ github.sha }}'
          format: 'template'
          template: '@/html.tpl'
          output: 'trivy-report.html'
      
      - name: Upload HTML report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: trivy-report
          path: trivy-report.html
```

### GitLab CI

```yaml title=".gitlab-ci.yml"
trivy-scan:
  stage: security
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    # Scan FS
    - trivy fs --exit-code 0 --format json --output trivy-fs-report.json .
    
    # Scan image
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  artifacts:
    reports:
      container_scanning: trivy-fs-report.json
    paths:
      - trivy-fs-report.json
  only:
    - main
    - develop
```

### Jenkins

```groovy
pipeline {
    agent any
    
    stages {
        stage('Trivy Scan') {
            steps {
                script {
                    // Scan FS
                    sh '''
                        trivy fs \
                          --format json \
                          --output trivy-fs-results.json \
                          --severity CRITICAL,HIGH \
                          .
                    '''
                    
                    // Scan image
                    sh '''
                        trivy image \
                          --format json \
                          --output trivy-image-results.json \
                          --severity CRITICAL,HIGH \
                          --exit-code 1 \
                          my-app:${BUILD_NUMBER}
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-*.json'
                    publishHTML([
                        reportName: 'Trivy Scan',
                        reportDir: '.',
                        reportFiles: 'trivy-image-results.json'
                    ])
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

```json
{
  "SchemaVersion": 2,
  "ArtifactName": "mon-app:latest",
  "ArtifactType": "container_image",
  "Results": [
    {
      "Target": "mon-app:latest (alpine 3.18.4)",
      "Vulnerabilities": [
        {
          "VulnerabilityID": "CVE-2023-12345",
          "PkgName": "openssl",
          "InstalledVersion": "3.1.3",
          "FixedVersion": "3.1.4",
          "Severity": "HIGH",
          "Title": "OpenSSL vulnerability",
          "Description": "A vulnerability was found in OpenSSL...",
          "References": ["https://nvd.nist.gov/vuln/detail/CVE-2023-12345"]
        }
      ]
    }
  ]
}
```

### SARIF (pour GitHub Security)
```bash
trivy image --format sarif --output results.sarif mon-app:latest
```

### Table (par défaut)
```bash
trivy image mon-app:latest

# Output:
# mon-app:latest (alpine 3.18.4)
# ==================================
# Total: 15 (CRITICAL: 2, HIGH: 7, MEDIUM: 6, LOW: 0, UNKNOWN: 0)
```

### Template personnalisé
```bash
trivy image --format template --template "@contrib/html.tpl" --output report.html mon-app:latest
```

## 🎯 Meilleures pratiques

### 1. Scans réguliers
```yaml
# Scan quotidien avec cron
on:
  schedule:
    - cron: '0 2 * * *'  # 2h du matin tous les jours
```

### 2. Politique de sévérité
```bash
# Bloquer uniquement les CRITICAL
trivy image --exit-code 1 --severity CRITICAL mon-app:latest

# Ou CRITICAL+HIGH
trivy image --exit-code 1 --severity CRITICAL,HIGH mon-app:latest
```

### 3. Cache pour performance
```bash
# Utiliser un cache local
export TRIVY_CACHE_DIR=/tmp/trivy-cache
trivy image mon-app:latest

# Mettre à jour la DB manuellement
trivy image --download-db-only
```

### 4. Ignorer vulnérabilités non fixées
```bash
# Ne rapporter que ce qui peut être corrigé
trivy image --ignore-unfixed mon-app:latest
```

### 5. Policy as Code
```rego title="policies/deny-high-vulns.rego"
package trivy

default deny = false

deny {
    vuln := input.Vulnerabilities[_]
    vuln.Severity == "CRITICAL"
}

deny {
    vuln := input.Vulnerabilities[_]
    vuln.Severity == "HIGH"
    not vuln.FixedVersion
}
```

## 🔐 Scanning images privées

### Docker Hub privé
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

## 📈 Métriques et reporting

### Dashboard Grafana
```yaml
# Prometheus exporter for Trivy
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trivy-scan
spec:
  schedule: "0 */6 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: trivy
            image: aquasec/trivy:latest
            args:
            - image
            - --format
            - json
            - --output
            - /metrics/trivy-results.json
            - mon-app:latest
```

### Alertes

```yaml
# Alert sur nouvelles vulnérabilités CRITICAL
alert: TrivyCriticalVulnerabilities
expr: trivy_vulnerabilities{severity="CRITICAL"} > 0
for: 5m
annotations:
  summary: "Critical vulnerabilities detected"
  description: "{{ $value }} critical vulnerabilities found"
```

## 🔄 Automatisation complète

### Pre-commit hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running Trivy scan..."
trivy fs --exit-code 1 --severity CRITICAL,HIGH .

if [ $? -ne 0 ]; then
    echo "❌ Trivy scan failed. Fix vulnerabilities before committing."
    exit 1
fi

echo "✅ Trivy scan passed"
```

### Daily scan avec rapport email
```bash
#!/bin/bash
# daily-trivy-scan.sh

REPORT_FILE="trivy-report-$(date +%Y%m%d).html"

trivy image \
  --format template \
  --template "@contrib/html.tpl" \
  --output $REPORT_FILE \
  mon-app:latest

# Envoi par email
mail -s "Trivy Daily Report" -a $REPORT_FILE devops@example.com < /dev/null
```

## 🆘 Troubleshooting

### Base de données non à jour
```bash
# Forcer la mise à jour
trivy image --download-db-only

# Vérifier la version de la DB
trivy --version
```

### Erreur de connexion
```bash
# Utiliser un proxy
export HTTP_PROXY=http://proxy:8080
export HTTPS_PROXY=http://proxy:8080

trivy image mon-app:latest
```

### Scan trop lent
```bash
# Réduire les scanners actifs
trivy image --scanners vuln mon-app:latest

# Ignorer les dépendances de dev
trivy image --skip-dirs node_modules mon-app:latest
```

## 📚 Ressources

- [Documentation officielle Trivy](https://aquasecurity.github.io/trivy/)
- [Trivy GitHub](https://github.com/aquasecurity/trivy)
- [Best practices](https://aquasecurity.github.io/trivy/latest/docs/scanner/vulnerability/)
- [Intégrations CI/CD](https://aquasecurity.github.io/trivy/latest/docs/integrations/)

## 🎓 Exemple complet

```yaml title="complete-trivy-workflow.yml"
name: Complete Trivy Security Pipeline

on: [push, pull_request]

jobs:
  trivy-all-scans:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      # 1. Scan du code source
      - name: Scan filesystem
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          format: 'sarif'
          output: 'trivy-fs.sarif'
      
      # 2. Build image
      - name: Build image
        run: docker build -t app:${{ github.sha }} .
      
      # 3. Scan image
      - name: Scan image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'app:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-image.sarif'
          exit-code: '1'
      
      # 4. Scan IaC
      - name: Scan infrastructure
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
          scan-ref: './infrastructure'
          format: 'sarif'
          output: 'trivy-iac.sarif'
      
      # 5. Upload tous les résultats
      - name: Upload results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: '.'
```

---

**Trivy est maintenant intégré dans vos pipelines CI/CD et scanne automatiquement toutes vos vulnérabilités !** 🔒
