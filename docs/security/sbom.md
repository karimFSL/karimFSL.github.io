---
sidebar_position: 3
---

# 📋 SBOM - Software Bill of Materials

Le **SBOM** (Software Bill of Materials) est un inventaire complet des composants logiciels utilisés dans une application. C'est essentiel pour la sécurité, la conformité et la traçabilité.

## 🎯 Pourquoi un SBOM ?

- ✅ **Traçabilité** : Savoir exactement ce qui est dans vos applications
- ✅ **Sécurité** : Identifier rapidement les vulnérabilités (ex: Log4Shell)
- ✅ **Conformité** : Répondre aux exigences réglementaires (Executive Order 14028)
- ✅ **Supply Chain Security** : Protéger contre les attaques de la chaîne d'approvisionnement
- ✅ **Licence Compliance** : Vérifier les licences des dépendances

## 📊 Formats SBOM

### CycloneDX (Recommandé)
```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "serialNumber": "urn:uuid:...",
  "version": 1,
  "metadata": {
    "timestamp": "2024-01-01T00:00:00Z",
    "component": {
      "type": "application",
      "name": "mon-app",
      "version": "1.0.0"
    }
  },
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
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "mon-app",
  "packages": [
    {
      "SPDXID": "SPDXRef-Package-spring-boot",
      "name": "spring-boot-starter-web",
      "versionInfo": "3.2.0"
    }
  ]
}
```

## 🔧 Outils de génération

### 1. Syft (Recommandé)

**Installation**
```bash
# Linux
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# macOS
brew install syft

# Docker
docker pull anchore/syft:latest
```

**Utilisation**
```bash
# Générer SBOM d'une image Docker
syft mon-app:latest -o cyclonedx-json > sbom.json

# Générer SBOM d'un répertoire
syft dir:. -o cyclonedx-json > sbom.json

# Générer SBOM d'un JAR
syft target/mon-app.jar -o cyclonedx-json > sbom.json

# SPDX format
syft mon-app:latest -o spdx-json > sbom.spdx.json

# Multiple formats
syft mon-app:latest -o cyclonedx-json=sbom.cdx.json -o spdx-json=sbom.spdx.json
```

### 2. CycloneDX Maven Plugin

```xml title="pom.xml"
<project>
    <build>
        <plugins>
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
                <configuration>
                    <projectType>application</projectType>
                    <schemaVersion>1.5</schemaVersion>
                    <includeBomSerialNumber>true</includeBomSerialNumber>
                    <includeCompileScope>true</includeCompileScope>
                    <includeProvidedScope>true</includeProvidedScope>
                    <includeRuntimeScope>true</includeRuntimeScope>
                    <includeSystemScope>true</includeSystemScope>
                    <includeTestScope>false</includeTestScope>
                    <includeLicenseText>false</includeLicenseText>
                    <outputFormat>all</outputFormat>
                    <outputName>bom</outputName>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

**Génération**
```bash
./mvnw cyclonedx:makeAggregateBom
# Génère target/bom.json et target/bom.xml
```

### 3. CycloneDX Composer Plugin (Drupal/PHP)

```json title="composer.json"
{
    "require-dev": {
        "cyclonedx/cyclonedx-php-composer": "^4.1"
    },
    "scripts": {
        "generate-sbom": "cyclonedx-php-composer make-sbom --output-format=JSON --output-file=sbom.json"
    }
}
```

**Génération**
```bash
composer generate-sbom
```

### 4. npm (JavaScript/Node.js)

```bash
# CycloneDX npm
npm install -g @cyclonedx/cyclonedx-npm

# Générer SBOM
cyclonedx-npm --output-file sbom.json
```

## 🔄 Intégration CI/CD

### GitHub Actions - Java

```yaml title=".github/workflows/sbom-java.yml"
name: Generate and Sign SBOM

on:
  push:
    branches: [main]
  release:
    types: [published]

jobs:
  generate-sbom:
    runs-on: ubuntu-latest
    
    permissions:
      contents: write
      packages: write
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Build application
        run: ./mvnw clean package -DskipTests
      
      - name: Generate SBOM with CycloneDX Maven
        run: ./mvnw cyclonedx:makeAggregateBom
      
      - name: Generate SBOM with Syft
        uses: anchore/sbom-action@v0
        with:
          path: ./target/*.jar
          format: cyclonedx-json
          output-file: sbom-syft.json
      
      - name: Merge SBOMs (optional)
        run: |
          # Merge multiple SBOMs if needed
          cyclonedx merge --input-files target/bom.json sbom-syft.json --output-file sbom-merged.json
      
      - name: Sign SBOM with Cosign
        run: |
          # Install cosign
          curl -LO https://github.com/sigstore/cosign/releases/download/v2.2.0/cosign-linux-amd64
          chmod +x cosign-linux-amd64
          
          # Sign SBOM
          ./cosign-linux-amd64 sign-blob \
            --key env://COSIGN_PRIVATE_KEY \
            target/bom.json \
            --output-signature sbom.sig \
            --output-certificate sbom.crt
        env:
          COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_PRIVATE_KEY }}
          COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
      
      - name: Upload SBOM to GitHub Release
        if: github.event_name == 'release'
        uses: softprops/action-gh-release@v1
        with:
          files: |
            target/bom.json
            target/bom.xml
            sbom.sig
            sbom.crt
      
      - name: Upload SBOM as artifact
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: |
            target/bom.json
            target/bom.xml
            sbom.sig
      
      - name: Scan SBOM with Grype
        uses: anchore/scan-action@v3
        with:
          sbom: target/bom.json
          fail-build: true
          severity-cutoff: high
      
      - name: Push SBOM to Dependency Track
        run: |
          curl -X "POST" "${{ secrets.DEPENDENCY_TRACK_URL }}/api/v1/bom" \
            -H "Content-Type: multipart/form-data" \
            -H "X-Api-Key: ${{ secrets.DEPENDENCY_TRACK_API_KEY }}" \
            -F "project=${{ secrets.DEPENDENCY_TRACK_PROJECT_UUID }}" \
            -F "bom=@target/bom.json"
```

### GitHub Actions - Drupal

```yaml title=".github/workflows/sbom-drupal.yml"
name: Generate SBOM - Drupal

on: [push]

jobs:
  generate-sbom:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          tools: composer:v2
      
      - name: Install dependencies
        run: composer install --no-dev
      
      - name: Install CycloneDX
        run: composer require --dev cyclonedx/cyclonedx-php-composer
      
      - name: Generate SBOM
        run: |
          vendor/bin/cyclonedx-php-composer make-sbom \
            --output-format=JSON \
            --output-file=sbom-drupal.json
      
      - name: Upload SBOM
        uses: actions/upload-artifact@v4
        with:
          name: sbom-drupal
          path: sbom-drupal.json
```

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

### Dependency Track

**Dependency Track** est une plateforme de gestion de risques de la chaîne d'approvisionnement logicielle.

```bash
# Installation Docker
docker-compose -f dependency-track/docker-compose.yml up -d
```

```yaml title="dependency-track/docker-compose.yml"
version: '3.7'

services:
  dtrack-apiserver:
    image: dependencytrack/apiserver:latest
    environment:
      - ALPINE_DATABASE_MODE=external
      - ALPINE_DATABASE_URL=jdbc:postgresql://postgres:5432/dtrack
      - ALPINE_DATABASE_DRIVER=org.postgresql.Driver
      - ALPINE_DATABASE_USERNAME=dtrack
      - ALPINE_DATABASE_PASSWORD=changeme
    ports:
      - '8081:8080'
    volumes:
      - 'dependency-track:/data'
    depends_on:
      - postgres
  
  dtrack-frontend:
    image: dependencytrack/frontend:latest
    environment:
      - API_BASE_URL=http://dtrack-apiserver:8080
    ports:
      - '8080:8080'
    depends_on:
      - dtrack-apiserver
  
  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=dtrack
      - POSTGRES_USER=dtrack
      - POSTGRES_PASSWORD=changeme
    volumes:
      - 'postgres-data:/var/lib/postgresql/data'

volumes:
  dependency-track:
  postgres-data:
```

**Upload automatique**
```bash
# API pour upload SBOM
curl -X "POST" "http://localhost:8081/api/v1/bom" \
  -H "Content-Type: multipart/form-data" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -F "project=PROJECT_UUID" \
  -F "bom=@sbom.json"
```

## 📊 Visualisation et Reporting

### SBOM en HTML

```bash
# Convertir SBOM en HTML lisible
cyclonedx-cli convert --input-file sbom.json --output-file sbom.html --output-format html
```

### Dashboard Grafana

```prometheus
# Métriques Dependency Track
dependency_track_vulnerabilities{severity="CRITICAL"}
dependency_track_components_total
dependency_track_projects_total
```

## 🔐 Signature et vérification

### Cosign

```bash
# Signer un SBOM
cosign sign-blob \
  --key cosign.key \
  sbom.json \
  --output-signature sbom.sig

# Vérifier la signature
cosign verify-blob \
  --key cosign.pub \
  --signature sbom.sig \
  sbom.json
```

### Sigstore (keyless signing)

```bash
# Signature sans clé privée
cosign sign-blob sbom.json --bundle sbom.bundle

# Vérification
cosign verify-blob \
  --bundle sbom.bundle \
  --certificate-identity=user@example.com \
  --certificate-oidc-issuer=https://accounts.google.com \
  sbom.json
```

## 📋 SBOM Compliance

### Executive Order 14028 (US)
```json
{
  "required_fields": [
    "Supplier Name",
    "Component Name",
    "Version",
    "Dependencies",
    "Author",
    "Timestamp"
  ]
}
```

### NTIA Minimum Elements
```json
{
  "minimum_elements": {
    "author": "Organization Name",
    "timestamp": "2024-01-01T00:00:00Z",
    "component": {
      "name": "component-name",
      "version": "1.0.0",
      "unique_identifier": "pkg:maven/...",
      "relationships": []
    }
  }
}
```

## 🔄 Automatisation complète

### Makefile

```makefile title="Makefile"
.PHONY: sbom sbom-sign sbom-upload sbom-scan

sbom:
	@echo "Generating SBOM..."
	syft . -o cyclonedx-json=sbom.json
	cyclonedx-cli validate --input-file sbom.json

sbom-sign:
	@echo "Signing SBOM..."
	cosign sign-blob --key cosign.key sbom.json --output-signature sbom.sig

sbom-upload:
	@echo "Uploading SBOM to Dependency Track..."
	curl -X POST "$(DEPENDENCY_TRACK_URL)/api/v1/bom" \
		-H "X-Api-Key: $(DEPENDENCY_TRACK_API_KEY)" \
		-F "project=$(PROJECT_UUID)" \
		-F "bom=@sbom.json"

sbom-scan:
	@echo "Scanning SBOM for vulnerabilities..."
	grype sbom:sbom.json --fail-on high

all: sbom sbom-sign sbom-scan sbom-upload
```

**Utilisation**
```bash
make all
```

## 📈 Métriques et KPIs

### Métriques importantes
```yaml
- Total components: 350
- Direct dependencies: 50
- Transitive dependencies: 300
- Unique licenses: 15
- Critical vulnerabilities: 0
- High vulnerabilities: 2
- SBOM freshness: < 24h
```

### Alertes
```yaml
alerts:
  - name: CriticalVulnerability
    condition: critical_vulns > 0
    action: Block deployment
  
  - name: OutdatedSBOM
    condition: sbom_age > 7d
    action: Trigger regeneration
  
  - name: UnknownLicense
    condition: unknown_licenses > 0
    action: Alert legal team
```

## 🎯 Meilleures pratiques

### 1. Génération automatique
```yaml
# À chaque build
on: [push, release]
```

### 2. Signature systématique
```bash
# Toujours signer les SBOMs
cosign sign-blob sbom.json
```

### 3. Storage centralisé
```
# Dependency Track ou Artifactory
centralized_sbom_storage: true
```

### 4. Analyse continue
```bash
# Scan quotidien
cron: '0 2 * * *'
```

### 5. Traçabilité
```json
{
  "metadata": {
    "component": {
      "bom-ref": "pkg:maven/...",
      "supplier": "Organization",
      "author": "Team Name",
      "timestamp": "2024-01-01T00:00:00Z"
    }
  }
}
```

## 🆘 Troubleshooting

### SBOM incomplet
```bash
# Vérifier avec CycloneDX CLI
cyclonedx-cli validate --input-file sbom.json

# Régénérer avec verbose
syft . -vv -o cyclonedx-json
```

### Erreur de format
```bash
# Convertir entre formats
cyclonedx-cli convert \
  --input-file sbom.spdx.json \
  --output-file sbom.cdx.json \
  --input-format spdx-json \
  --output-format cyclonedx-json
```

## 📚 Ressources

- [CycloneDX Specification](https://cyclonedx.org/specification/overview/)
- [SPDX Specification](https://spdx.dev/specifications/)
- [Syft Documentation](https://github.com/anchore/syft)
- [Dependency Track](https://dependencytrack.org/)
- [NTIA SBOM Guidelines](https://www.ntia.gov/sbom)

## 🎓 Exemple complet - Pipeline SBOM

```yaml title="complete-sbom-pipeline.yml"
name: Complete SBOM Pipeline

on: [push, release]

jobs:
  sbom-lifecycle:
    runs-on: ubuntu-latest
    steps:
      # 1. Build
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '17'
      - run: ./mvnw package
      
      # 2. Generate SBOM
      - uses: anchore/sbom-action@v0
        with:
          format: cyclonedx-json
          output-file: sbom.json
      
      # 3. Validate
      - run: cyclonedx-cli validate --input-file sbom.json
      
      # 4. Sign
      - run: cosign sign-blob sbom.json --output-signature sbom.sig
        env:
          COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_PRIVATE_KEY }}
      
      # 5. Scan
      - uses: anchore/scan-action@v3
        with:
          sbom: sbom.json
          fail-build: true
      
      # 6. Upload
      - uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: |
            sbom.json
            sbom.sig
      
      # 7. Push to Dependency Track
      - run: |
          curl -X POST "$DTRACK_URL/api/v1/bom" \
            -H "X-Api-Key: $DTRACK_KEY" \
            -F "project=$PROJECT_UUID" \
            -F "bom=@sbom.json"
```

---

**Votre SBOM est maintenant généré, signé, scanné et archivé automatiquement !** 📋🔒
