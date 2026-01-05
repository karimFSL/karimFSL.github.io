---
sidebar_position: 2
---

# 🌐 DAST - Dynamic Application Security Testing

**DAST** (Test de sécurité dynamique) teste une application en cours d'exécution pour détecter vulnérabilités exploitables sans accès au code source (black-box).

## 🎯 Pourquoi DAST ?

- ✅ **Runtime** : Teste l'application déployée
- ✅ **Black-box** : Pas besoin du code source
- ✅ **Vulnérabilités réelles** : Détecte ce qui est exploitable
- ✅ **Configuration** : Trouve les erreurs de config
- ❌ **Plus lent** : Nécessite l'application en cours d'exécution
- ❌ **Détection tardive** : Après le développement

## 🔧 Meilleurs outils DAST

### 1. OWASP ZAP (Recommandé - Open-source)

**Type** : Scanner de vulnérabilités web

**Installation** :
```bash
docker pull zaproxy/zap-stable
```

**GitLab CI** :
```yaml
# .gitlab-ci.yml
zap-scan:
  stage: dast
  image: zaproxy/zap-stable
  script:
    - zap-baseline.py -t https://app.example.com -r zap-report.html
  artifacts:
    paths:
      - zap-report.html
    reports:
      dast: gl-dast-report.json
  only:
    - schedules
```

**Scan avancé** :
```bash
# Scan complet
docker run -v $(pwd):/zap/wrk:rw -t zaproxy/zap-stable \
  zap-full-scan.py -t https://app.example.com -r report.html

# API scan
docker run -t zaproxy/zap-stable \
  zap-api-scan.py -t https://api.example.com/openapi.json -f openapi -r report.html

# Baseline (rapide)
docker run -t zaproxy/zap-stable \
  zap-baseline.py -t https://app.example.com
```

**Configuration** :
```yaml
# zap-config.yaml
rules:
  - id: 10096
    name: Timestamp Disclosure
    threshold: LOW
  - id: 40012
    name: Cross Site Scripting
    threshold: MEDIUM
```

---

### 2. Nuclei (Moderne - Open-source)

**Type** : Scanner de vulnérabilités avec templates

**Installation** :
```bash
# Linux/macOS
curl -sL https://nuclei.sh | sh

# Docker
docker pull projectdiscovery/nuclei:latest
```

**GitLab CI** :
```yaml
nuclei-scan:
  stage: dast
  image: projectdiscovery/nuclei:latest
  script:
    - nuclei -u https://app.example.com -t cves/ -t vulnerabilities/ -o results.txt
  artifacts:
    paths:
      - results.txt
```

**Utilisation** :
```bash
# Scan avec templates
nuclei -u https://app.example.com

# Scan CVEs uniquement
nuclei -u https://app.example.com -t cves/

# Scan avec custom templates
nuclei -u https://app.example.com -t custom-templates/

# Scan avec liste d'URLs
nuclei -l urls.txt -t vulnerabilities/
```

**Template personnalisé** :
```yaml
# custom-xss.yaml
id: custom-xss-check

info:
  name: XSS Detection
  severity: high

requests:
  - method: GET
    path:
      - "{{BaseURL}}/search?q=<script>alert(1)</script>"
    matchers:
      - type: word
        words:
          - "<script>alert(1)</script>"
```

---

### 3. Burp Suite (Enterprise)

**Type** : Suite complète de test de sécurité

**GitLab CI** :
```yaml
burp-scan:
  stage: dast
  script:
    - |
      curl -X POST "$BURP_API_URL/scan" \
        -H "Authorization: Bearer $BURP_API_KEY" \
        -d '{"urls":["https://app.example.com"]}'
  only:
    - schedules
```

---

### 4. Arachni (Open-source)

**Type** : Scanner web de vulnérabilités

```bash
# Installation
docker pull arachni/arachni

# Scan
docker run arachni/arachni \
  arachni https://app.example.com --report-save-path=report.afr
```

```yaml
# .gitlab-ci.yml
arachni-scan:
  stage: dast
  image: arachni/arachni
  script:
    - arachni https://app.example.com --report-save-path=report.afr
  artifacts:
    paths:
      - report.afr
```

---

### 5. Nikto (Web server scanner)

**Type** : Scanner de serveur web

```yaml
nikto-scan:
  stage: dast
  image: sullo/nikto
  script:
    - nikto -h https://app.example.com -o nikto-report.html -Format html
  artifacts:
    paths:
      - nikto-report.html
```

```bash
# Scan basique
nikto -h https://app.example.com

# Scan avec plugins
nikto -h https://app.example.com -Plugins @@ALL

# Scan SSL
nikto -h https://app.example.com -ssl
```

---

### 6. Acunetix (Enterprise)

**Type** : Scanner commercial avancé

```yaml
acunetix-scan:
  stage: dast
  script:
    - |
      curl -X POST "$ACUNETIX_API/scans" \
        -H "X-Auth: $ACUNETIX_TOKEN" \
        -d '{"target_id":"xxx","profile_id":"yyy"}'
```

---

## 📊 Comparaison des outils

| Outil | Type | Gratuit | CI/CD | Vitesse | Précision |
|-------|------|---------|-------|---------|-----------|
| **OWASP ZAP** | Web | ✅ | ✅ | 🟡 Moyen | 🟢 Bonne |
| **Nuclei** | Multi | ✅ | ✅ | 🟢 Rapide | 🟢 Bonne |
| **Burp Suite** | Web | ❌ | ✅ | 🟡 Moyen | 🟢 Excellente |
| **Arachni** | Web | ✅ | ✅ | 🟡 Moyen | 🟢 Bonne |
| **Nikto** | Server | ✅ | ✅ | 🟢 Rapide | 🟡 Moyenne |
| **Acunetix** | Web | ❌ | ✅ | 🟢 Rapide | 🟢 Excellente |

---

## 🔄 Pipeline DAST complet

```yaml
# .gitlab-ci.yml
stages:
  - build
  - deploy-staging
  - dast
  - deploy-prod

variables:
  STAGING_URL: "https://staging.app.example.com"
  DAST_EXCLUDED_URLS: "logout,admin"

deploy-staging:
  stage: deploy-staging
  script:
    - deploy_to_staging.sh
  environment:
    name: staging
    url: $STAGING_URL

# ZAP Baseline
zap-baseline:
  stage: dast
  image: zaproxy/zap-stable
  script:
    - zap-baseline.py -t $STAGING_URL -r zap-baseline.html
  artifacts:
    paths:
      - zap-baseline.html
  dependencies:
    - deploy-staging

# Nuclei CVE scan
nuclei-cve:
  stage: dast
  image: projectdiscovery/nuclei:latest
  script:
    - nuclei -u $STAGING_URL -t cves/ -o nuclei-cves.txt
  artifacts:
    paths:
      - nuclei-cves.txt
  allow_failure: true

# Nikto web server scan
nikto-scan:
  stage: dast
  image: sullo/nikto
  script:
    - nikto -h $STAGING_URL -o nikto-report.json -Format json
  artifacts:
    paths:
      - nikto-report.json

# Template GitLab intégré
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_WEBSITE: $STAGING_URL
    DAST_FULL_SCAN_ENABLED: "true"
```

---

## 🎯 Types de scans

### 1. Baseline Scan (Rapide - 1-5 min)
```bash
# ZAP
zap-baseline.py -t https://app.example.com

# Nuclei
nuclei -u https://app.example.com -t technologies/
```

### 2. Full Scan (Complet - 30 min - 2h)
```bash
# ZAP
zap-full-scan.py -t https://app.example.com

# Nuclei
nuclei -u https://app.example.com -t cves/ -t vulnerabilities/ -t exposures/
```

### 3. API Scan
```bash
# ZAP avec OpenAPI
zap-api-scan.py -t https://api.example.com/openapi.json -f openapi

# Nuclei avec fichier YAML
nuclei -u https://api.example.com -t api-templates/
```

### 4. Authenticated Scan
```bash
# ZAP avec authentification
zap-full-scan.py -t https://app.example.com -z "-config auth.method=form"
```

---

## 🔐 Vulnérabilités détectées

### OWASP Top 10
- ✅ SQL Injection
- ✅ XSS (Cross-Site Scripting)
- ✅ CSRF (Cross-Site Request Forgery)
- ✅ Authentication issues
- ✅ Security misconfigurations
- ✅ Sensitive data exposure
- ✅ XML External Entities (XXE)
- ✅ Broken Access Control

### Autres
- ✅ CVEs connus
- ✅ Outdated libraries
- ✅ SSL/TLS issues
- ✅ Header security
- ✅ Cookie security

---

## 🎯 Configuration avancée

### ZAP avec authentification

```yaml
# zap-auth.yaml
env:
  contexts:
    - name: "Application Context"
      urls:
        - "https://app.example.com.*"
      authentication:
        method: "form"
        parameters:
          loginUrl: "https://app.example.com/login"
          loginRequestData: "username={%username%}&password={%password%}"
        verification:
          method: "response"
          loggedInRegex: "\\Qlogout\\E"
          loggedOutRegex: "\\Qlogin\\E"
      users:
        - name: "test-user"
          credentials:
            username: "testuser"
            password: "testpass"
```

### Nuclei avec rate limiting

```bash
nuclei -u https://app.example.com \
  -rate-limit 10 \
  -bulk-size 25 \
  -timeout 10
```

---

## 🆘 Troubleshooting

### Trop de faux positifs
```bash
# ZAP - Réduire la sensibilité
zap-baseline.py -t https://app.example.com -c zap-config.yaml

# Nuclei - Filtrer par sévérité
nuclei -u https://app.example.com -severity high,critical
```

### Scan bloqué par WAF
```bash
# Réduire le taux de requêtes
nuclei -u https://app.example.com -rate-limit 5

# User-Agent custom
nuclei -u https://app.example.com -H "User-Agent: Mozilla/5.0..."
```

### Timeout
```bash
# Augmenter le timeout
nuclei -u https://app.example.com -timeout 30
```

---

## 🎯 Meilleures pratiques

### 1. Scanner l'environnement de staging
```yaml
only:
  - schedules  # Nuit, pas à chaque commit
```

### 2. Authentification
```yaml
# Tester avec un utilisateur test
variables:
  DAST_USERNAME: "test-user"
  DAST_PASSWORD: "test-pass"
```

### 3. Exclure les URLs sensibles
```yaml
variables:
  DAST_EXCLUDED_URLS: "logout,delete,admin"
```

### 4. Scan progressif
```bash
# 1. Baseline quotidien
# 2. Full scan hebdomadaire
# 3. Authenticated scan mensuel
```

### 5. Combiner avec SAST
```yaml
stages:
  - sast
  - dast
```

---

## 📚 Ressources

- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [Nuclei Templates](https://github.com/projectdiscovery/nuclei-templates)
- [OWASP DAST](https://owasp.org/www-community/Vulnerability_Scanning_Tools)
- [GitLab DAST](https://docs.gitlab.com/ee/user/application_security/dast/)

---

**DAST teste votre application en production et détecte les vulnérabilités exploitables !** 🌐🔒