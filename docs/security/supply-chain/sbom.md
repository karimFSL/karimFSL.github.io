---
sidebar_position: 3
---

# 📋 SBOM - Software Bill of Materials

Le **SBOM** est un inventaire complet des composants logiciels utilisés dans une application.

## 🎯 Pourquoi un SBOM ?

- ✅ **Traçabilité** : Savoir ce qui est dans vos applications
- ✅ **Sécurité** : Identifier rapidement les vulnérabilités (ex: Log4Shell)
- ✅ **Conformité** : Répondre aux exigences réglementaires
- ✅ **Supply Chain Security** : Protéger la chaîne d'approvisionnement

## 📊 Formats SBOM

### CycloneDX (Recommandé)
```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "components": [
    {
      "type": "library",
      "name": "spring-boot-starter-web",
      "version": "3.2.0",
      "purl": "pkg:maven/org.springframework.boot/spring-boot-starter-web@3.2.0"
    }
  ]
}
```

### SPDX
```json
{
  "spdxVersion": "SPDX-2.3",
  "name": "mon-app",
  "packages": [
    {
      "name": "spring-boot-starter-web",
      "versionInfo": "3.2.0"
    }
  ]
}
```

## 🔧 Génération du SBOM

### Syft (Recommandé - Universel)

**Installation**
```bash
# Linux/macOS
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Docker
docker pull anchore/syft:latest
```

**Utilisation**
```bash
# Image Docker
syft mon-app:latest -o cyclonedx-json > sbom.json

# Répertoire
syft dir:. -o cyclonedx-json > sbom.json

# Fichier (JAR, ZIP, TAR...)
syft target/mon-app.jar -o cyclonedx-json > sbom.json

# Format SPDX
syft mon-app:latest -o spdx-json > sbom.json
```

### Outils spécifiques par langage

| Langage | Outil | Commande |
|---------|-------|----------|
| **Java** | CycloneDX Maven | `mvn cyclonedx:makeAggregateBom` |
| **Java** | CycloneDX Gradle | `gradle cyclonedxBom` |
| **PHP** | CycloneDX Composer | `cyclonedx-php-composer make-sbom` |
| **Node.js** | CycloneDX npm | `cyclonedx-npm --output-file sbom.json` |
| **Python** | CycloneDX Python | `cyclonedx-py --output sbom.json` |
| **.NET** | CycloneDX .NET | `dotnet cyclonedx` |
| **Go** | CycloneDX Go | `cyclonedx-gomod mod -json > sbom.json` |

### Configuration Maven (Java)

```xml
<!-- pom.xml -->
<plugin>
    <groupId>org.cyclonedx</groupId>
    <artifactId>cyclonedx-maven-plugin</artifactId>
    <version>2.7.11</version>
    <executions>
        <execution>
            <phase>package</phase>
            <goals>
                <goal>makeAggregateBom</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

## 🔄 Intégration CI/CD

### Pipeline GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - build
  - sbom
  - security

variables:
  SBOM_FILE: "sbom.json"

generate-sbom:
  stage: sbom
  image: anchore/syft:latest
  script:
    # Pour image Docker
    - syft $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -o cyclonedx-json=$SBOM_FILE
    # OU pour répertoire
    - syft dir:. -o cyclonedx-json=$SBOM_FILE
    # OU pour artifact
    - syft path/to/artifact.jar -o cyclonedx-json=$SBOM_FILE
  artifacts:
    paths:
      - $SBOM_FILE
    reports:
      cyclonedx: $SBOM_FILE

scan-sbom:
  stage: security
  image: anchore/grype:latest
  script:
    - grype sbom:$SBOM_FILE --fail-on high
  dependencies:
    - generate-sbom

# Template GitLab intégré
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml
```

### Pipeline Jenkins

```groovy
pipeline {
    agent any
    stages {
        stage('Generate SBOM') {
            steps {
                sh 'syft . -o cyclonedx-json=sbom.json'
            }
        }
        stage('Scan SBOM') {
            steps {
                sh 'grype sbom:sbom.json --fail-on high'
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'sbom.json'
            }
        }
    }
}

## 🔍 Analyse du SBOM

### Grype (Scan de vulnérabilités)

```bash
# Scanner un SBOM
grype sbom:sbom.json

# Format JSON
grype sbom:sbom.json -o json > vulnerabilities.json

# Sévérité minimale
grype sbom:sbom.json --fail-on high
```

### Dependency Track (Plateforme centralisée)

```yaml
# docker-compose.yml
services:
  dtrack-apiserver:
    image: dependencytrack/apiserver:latest
    environment:
      - ALPINE_DATABASE_MODE=external
      - ALPINE_DATABASE_URL=jdbc:postgresql://postgres:5432/dtrack
      - ALPINE_DATABASE_USERNAME=dtrack
      - ALPINE_DATABASE_PASSWORD=changeme
    ports:
      - '8081:8080'
  
  dtrack-frontend:
    image: dependencytrack/frontend:latest
    environment:
      - API_BASE_URL=http://dtrack-apiserver:8080
    ports:
      - '8080:8080'
  
  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=dtrack
      - POSTGRES_USER=dtrack
      - POSTGRES_PASSWORD=changeme
```

**Upload automatique**
```bash
curl -X POST "http://localhost:8081/api/v1/bom" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -F "project=PROJECT_UUID" \
  -F "bom=@sbom.json"
```

## 🔐 Signature et vérification

### Cosign

```bash
# Signer
cosign sign-blob --key cosign.key sbom.json --output-signature sbom.sig

# Vérifier
cosign verify-blob --key cosign.pub --signature sbom.sig sbom.json
```

### Sigstore (keyless)

```bash
# Signature sans clé
cosign sign-blob sbom.json --bundle sbom.bundle

# Vérification
cosign verify-blob \
  --bundle sbom.bundle \
  --certificate-identity=user@example.com \
  --certificate-oidc-issuer=https://accounts.google.com \
  sbom.json
```

## 🎯 Meilleures pratiques

### 1. Génération automatique
```yaml
# À chaque build
on: [push, merge_request, tag]
```

### 2. Validation systématique
```bash
cyclonedx validate --input-file sbom.json
```

### 3. Signature des SBOMs
```bash
# Production uniquement
only: [main, tags]
```

### 4. Analyse continue
```yaml
# Scan quotidien dans scheduled pipeline
schedule:
  - cron: '0 2 * * *'
```

### 5. Storage centralisé
```bash
# Dependency Track ou Artifactory
artifacts:
  expire_in: never  # SBOMs produits
```

## 📋 SBOM Compliance

### NTIA Minimum Elements
```json
{
  "minimum_elements": {
    "author": "Organization Name",
    "timestamp": "2024-01-01T00:00:00Z",
    "component": {
      "name": "component-name",
      "version": "1.0.0",
      "unique_identifier": "pkg:maven/..."
    }
  }
}
```

## 🔄 Script d'automatisation

### Makefile

```makefile
.PHONY: sbom scan sign upload

sbom:
	syft . -o cyclonedx-json=sbom.json
	cyclonedx validate --input-file sbom.json

scan:
	grype sbom:sbom.json --fail-on high

sign:
	cosign sign-blob --key cosign.key sbom.json --output-signature sbom.sig

upload:
	curl -X POST "$(DTRACK_URL)/api/v1/bom" \
		-H "X-Api-Key: $(DTRACK_API_KEY)" \
		-F "project=$(PROJECT_UUID)" \
		-F "bom=@sbom.json"

all: sbom scan sign upload
```

## 📈 Métriques importantes

```yaml
- Total components: 350
- Direct dependencies: 50
- Critical vulnerabilities: 0
- High vulnerabilities: 2
- SBOM freshness: < 24h
```

## 🆘 Troubleshooting

### SBOM incomplet
```bash
# Vérifier
cyclonedx validate --input-file sbom.json

# Régénérer avec verbose
syft . -vv -o cyclonedx-json
```

### Conversion de format
```bash
cyclonedx convert \
  --input-file sbom.spdx.json \
  --output-file sbom.cdx.json \
  --input-format spdx-json \
  --output-format cyclonedx-json
```

## 📚 Ressources

- [CycloneDX Specification](https://cyclonedx.org/)
- [Syft Documentation](https://github.com/anchore/syft)
- [Dependency Track](https://dependencytrack.org/)
- [NTIA SBOM Guidelines](https://www.ntia.gov/sbom)

---

**Votre SBOM est maintenant automatiquement généré, validé, scanné et archivé !** 📋🔒