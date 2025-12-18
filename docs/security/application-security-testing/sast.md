---
sidebar_position: 1
---

# 🔍 SAST - Static Application Security Testing

**SAST** (Test de sécurité statique) analyse le code source sans l'exécuter pour détecter vulnérabilités, bugs et mauvaises pratiques.

## 🎯 Pourquoi SAST ?

- ✅ **Détection précoce** : Trouve les failles avant le déploiement
- ✅ **Code source** : Analyse directe du code (white-box)
- ✅ **Rapide** : Intégration CI/CD automatique
- ✅ **Pas de runtime** : Pas besoin d'application en cours d'exécution
- ❌ **Faux positifs** : Peut générer des alertes incorrectes

## 🔧 Meilleurs outils SAST

### 1. SonarQube (Recommandé)

**Langages** : Java, PHP, JavaScript, TypeScript, Python, C#, Go, Ruby...

```yaml
# .gitlab-ci.yml
sonarqube:
  stage: security
  image: sonarsource/sonar-scanner-cli:latest
  script:
    - sonar-scanner
      -Dsonar.projectKey=my-project
      -Dsonar.sources=.
      -Dsonar.host.url=$SONAR_HOST_URL
      -Dsonar.token=$SONAR_TOKEN
```

```properties
# sonar-project.properties
sonar.projectKey=my-project
sonar.sources=src
sonar.exclusions=**/test/**,**/vendor/**
```

---

### 2. Semgrep (Open-source)

**Langages** : 30+ langages supportés

```yaml
# .gitlab-ci.yml
semgrep:
  stage: security
  image: returntocorp/semgrep:latest
  script:
    - semgrep ci --config=auto --sarif > semgrep.sarif
  artifacts:
    reports:
      sast: semgrep.sarif
```

```yaml
# .semgrep.yml (règles personnalisées)
rules:
  - id: sql-injection
    patterns:
      - pattern: $DB.query($USER_INPUT)
    message: Potential SQL injection
    severity: ERROR
```

---

### 3. Snyk Code

**Langages** : JavaScript, TypeScript, Java, Python, Go, Ruby, PHP, C#

```yaml
# .gitlab-ci.yml
snyk-code:
  stage: security
  image: snyk/snyk:node
  script:
    - snyk code test --sarif-file-output=snyk-code.sarif
  artifacts:
    reports:
      sast: snyk-code.sarif
  only:
    - merge_requests
```

**Configuration** :
```yaml
# .snyk
language-settings:
  javascript:
    exclude:
      - node_modules/**
      - dist/**
```

---

### 4. CodeQL (GitHub)

**Langages** : JavaScript, Python, Java, C/C++, C#, Ruby, Go

```yaml
# .gitlab-ci.yml
codeql:
  stage: security
  image: ghcr.io/github/codeql-action/codeql:latest
  script:
    - codeql database create db --language=java
    - codeql database analyze db --format=sarif-latest --output=results.sarif
  artifacts:
    reports:
      sast: results.sarif
```

---

### 5. Checkmarx (Enterprise)

**Langages** : 30+ langages

```yaml
# .gitlab-ci.yml
checkmarx:
  stage: security
  script:
    - |
      docker run --rm \
        -v $(pwd):/src \
        checkmarx/cx-flow:latest \
        --scan \
        --project=my-project \
        --cx-token=$CX_TOKEN
```

---

### 6. SpotBugs (Java)

**Langage** : Java uniquement

```xml
<!-- pom.xml -->
<plugin>
    <groupId>com.github.spotbugs</groupId>
    <artifactId>spotbugs-maven-plugin</artifactId>
    <version>4.8.3.0</version>
    <configuration>
        <effort>Max</effort>
        <threshold>Low</threshold>
    </configuration>
</plugin>
```

```bash
mvn spotbugs:check
```

---

### 7. Bandit (Python)

**Langage** : Python uniquement

```yaml
# .gitlab-ci.yml
bandit:
  stage: security
  image: python:3.11
  script:
    - pip install bandit
    - bandit -r src/ -f json -o bandit-report.json
  artifacts:
    paths:
      - bandit-report.json
```

```yaml
# .bandit
skips: ['B101', 'B601']
exclude_dirs: ['/test', '/venv']
```

---

### 8. ESLint Security (JavaScript)

**Langage** : JavaScript/Node.js

```json
// package.json
{
  "devDependencies": {
    "eslint": "^8.0.0",
    "eslint-plugin-security": "^1.7.1"
  }
}
```

```js
// .eslintrc.js
module.exports = {
  plugins: ['security'],
  extends: ['plugin:security/recommended']
};
```

```bash
npm run lint
```

---

## 📊 Comparaison des outils

| Outil | Langages | Gratuit | CI/CD | Faux positifs |
|-------|----------|---------|-------|---------------|
| **SonarQube** | 25+ | ✅ Community | ✅ | 🟡 Moyen |
| **Semgrep** | 30+ | ✅ Open-source | ✅ | 🟢 Faible |
| **Snyk Code** | 8+ | 🟡 Limité | ✅ | 🟢 Faible |
| **CodeQL** | 7+ | ✅ Open-source | ✅ | 🟡 Moyen |
| **Checkmarx** | 30+ | ❌ Payant | ✅ | 🟡 Moyen |
| **SpotBugs** | Java | ✅ | ✅ | 🟢 Faible |
| **Bandit** | Python | ✅ | ✅ | 🟢 Faible |

---

## 🔄 Pipeline SAST complet

```yaml
# .gitlab-ci.yml
stages:
  - sast

variables:
  SAST_EXCLUDED_PATHS: "test/**,vendor/**,node_modules/**"

# Multi-langage avec SonarQube
sonarqube-sast:
  stage: sast
  image: sonarsource/sonar-scanner-cli:latest
  script:
    - sonar-scanner
      -Dsonar.projectKey=$CI_PROJECT_NAME
      -Dsonar.sources=.
      -Dsonar.host.url=$SONAR_HOST_URL
      -Dsonar.token=$SONAR_TOKEN
  only:
    - merge_requests
    - main

# Semgrep
semgrep-sast:
  stage: sast
  image: returntocorp/semgrep:latest
  script:
    - semgrep ci --config=auto --sarif > semgrep.sarif
  artifacts:
    reports:
      sast: semgrep.sarif
  allow_failure: false

# Template GitLab intégré
include:
  - template: Security/SAST.gitlab-ci.yml
```

---

## 🎯 Configuration par langage

### Java
```yaml
sast-java:
  stage: sast
  script:
    - mvn spotbugs:check
    - mvn pmd:check
```

### PHP
```yaml
sast-php:
  stage: sast
  script:
    - composer require --dev phpstan/phpstan
    - vendor/bin/phpstan analyse src --level=max
```

### JavaScript/Node.js
```yaml
sast-js:
  stage: sast
  script:
    - npm install
    - npm run lint
    - npx eslint src/ --ext .js,.ts
```

### Python
```yaml
sast-python:
  stage: sast
  script:
    - pip install bandit
    - bandit -r src/
```

---

## 🔐 Intégration des résultats

### Format SARIF (Standard)

```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "SemGrep"
        }
      },
      "results": [
        {
          "ruleId": "sql-injection",
          "message": {
            "text": "Potential SQL injection"
          },
          "level": "error"
        }
      ]
    }
  ]
}
```

### GitLab Security Dashboard

```yaml
artifacts:
  reports:
    sast: results.sarif
```

---

## 🎯 Meilleures pratiques

### 1. Scanner à chaque MR
```yaml
only:
  - merge_requests
```

### 2. Bloquer les critiques
```yaml
allow_failure: false
script:
  - semgrep ci --error
```

### 3. Exclure les fichiers inutiles
```properties
sonar.exclusions=**/test/**,**/vendor/**,**/node_modules/**
```

### 4. Règles personnalisées
```yaml
# .semgrep.yml
rules:
  - id: custom-rule
    pattern: dangerous_function(...)
    severity: ERROR
```

### 5. Scan incrémental
```bash
# Scanner uniquement les fichiers modifiés
semgrep ci --baseline=main
```

---

## 🆘 Troubleshooting

### Trop de faux positifs
```yaml
# Ajuster la sévérité
- semgrep ci --config=auto --severity=high
```

### Scan trop long
```yaml
# Parallélisation
parallel:
  matrix:
    - LANGUAGE: [java, javascript, python]
```

### Règles obsolètes
```bash
# Mettre à jour les règles
semgrep --update
```

---

## 📚 Ressources

- [OWASP SAST](https://owasp.org/www-community/Source_Code_Analysis_Tools)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Semgrep Registry](https://semgrep.dev/r)
- [SARIF Format](https://sarifweb.azurewebsites.net/)

---

**SAST analyse votre code source et détecte les vulnérabilités avant déploiement !** 🔍✅