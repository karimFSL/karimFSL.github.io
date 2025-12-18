---
sidebar_position: 1
---
# 🔄 Renovate - Automatisation des dépendances

**Renovate** automatise la mise à jour des dépendances de vos projets pour maintenir sécurité et fraîcheur de votre stack.

## 🎯 Pourquoi Renovate ?

- ✅ **Automatique** : Création automatique de MR/PR
- ✅ **Multi-langage** : Java, PHP, Node.js, Python, Docker, Terraform, Go...
- ✅ **Flexible** : Configuration fine par projet
- ✅ **Sécurité** : Détection de vulnérabilités
- ✅ **Gratuit** : Open-source

## 🚀 Installation

### GitLab (Recommandé)

```yaml
# .gitlab-ci.yml
include:
  - project: 'renovate-bot/renovate-runner'
    file: '/templates/renovate.gitlab-ci.yml'

variables:
  RENOVATE_TOKEN: $GITLAB_TOKEN
  RENOVATE_PLATFORM: gitlab
```

### Self-hosted

```bash
# Docker
docker run -e RENOVATE_TOKEN=$GITLAB_TOKEN \
  -e RENOVATE_PLATFORM=gitlab \
  renovate/renovate

# npm
npm install -g renovate
renovate --platform=gitlab --token=$GITLAB_TOKEN
```

## 📝 Configuration de base

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "schedule": ["before 3am on Monday"],
  "timezone": "Europe/Paris",
  "labels": ["dependencies"],
  "assignees": ["@devops-team"],
  "prConcurrentLimit": 5,
  "prHourlyLimit": 2,
  "platformAutomerge": true
}
```

## 🔧 Configuration par langage

### Java/Maven

```json
{
  "packageRules": [
    {
      "matchManagers": ["maven"],
      "matchUpdateTypes": ["minor", "patch"],
      "groupName": "Spring Boot",
      "matchPackagePatterns": ["^org.springframework.boot"],
      "schedule": ["before 3am on Monday"]
    },
    {
      "matchManagers": ["maven"],
      "matchUpdateTypes": ["major"],
      "enabled": false
    },
    {
      "matchManagers": ["maven"],
      "matchDepTypes": ["test"],
      "automerge": true
    }
  ]
}
```

### PHP/Composer (Drupal, Symfony, Laravel)

```json
{
  "packageRules": [
    {
      "matchManagers": ["composer"],
      "matchPackagePatterns": ["^drupal/"],
      "groupName": "Drupal modules",
      "schedule": ["before 3am on Tuesday"]
    },
    {
      "matchManagers": ["composer"],
      "matchDepTypes": ["require-dev"],
      "automerge": true
    }
  ]
}
```

### Node.js/npm

```json
{
  "packageRules": [
    {
      "matchManagers": ["npm"],
      "matchUpdateTypes": ["minor", "patch"],
      "groupName": "npm dependencies",
      "automerge": true
    },
    {
      "matchManagers": ["npm"],
      "matchDepTypes": ["devDependencies"],
      "automerge": true
    }
  ]
}
```

### Docker

```json
{
  "docker": {
    "enabled": true,
    "major": { "enabled": false }
  },
  "packageRules": [
    {
      "matchDatasources": ["docker"],
      "matchPackageNames": ["eclipse-temurin", "maven", "php", "node"],
      "groupName": "Base images",
      "schedule": ["before 3am on Wednesday"]
    }
  ]
}
```

## 🎯 Configuration multi-projet

### Configuration globale

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "timezone": "Europe/Paris",
  "schedule": ["before 3am on Monday"],
  "labels": ["dependencies"],
  "prConcurrentLimit": 5,
  "prHourlyLimit": 2,
  
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "groupName": "All non-major updates",
      "automerge": true,
      "automergeType": "pr"
    },
    {
      "matchUpdateTypes": ["major"],
      "enabled": false,
      "description": "Manual approval for major updates"
    },
    {
      "matchDepTypes": ["devDependencies", "test"],
      "automerge": true
    }
  ],
  
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security"],
    "assignees": ["@security-team"]
  }
}
```

### Par stack technologique

```json
{
  "packageRules": [
    {
      "matchManagers": ["maven"],
      "matchPackagePatterns": ["^org.springframework"],
      "groupName": "Spring Framework"
    },
    {
      "matchManagers": ["composer"],
      "matchPackagePatterns": ["^drupal/"],
      "groupName": "Drupal modules"
    },
    {
      "matchManagers": ["npm"],
      "matchPackagePatterns": ["^@angular/"],
      "groupName": "Angular"
    },
    {
      "matchDatasources": ["docker"],
      "groupName": "Docker images"
    }
  ]
}
```

## 🔒 Sécurité

### Vulnérabilités en priorité

```json
{
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security", "vulnerability"],
    "assignees": ["@security-team"],
    "prPriority": 10
  },
  "osvVulnerabilityAlerts": true,
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "matchCurrentVersion": "!/^0/",
      "labels": ["security-patch"]
    }
  ]
}
```

### Tests obligatoires avant merge

```json
{
  "prCreation": "not-pending",
  "packageRules": [
    {
      "matchPackagePatterns": ["*"],
      "stabilityDays": 3,
      "minimumReleaseAge": "3 days",
      "requiredStatusChecks": [
        "ci/build",
        "ci/test",
        "security/trivy"
      ]
    }
  ]
}
```

## 🔄 Intégration GitLab CI

### Pipeline Renovate

```yaml
# .gitlab-ci.yml
stages:
  - dependencies

renovate:
  stage: dependencies
  image: renovate/renovate:latest
  script:
    - renovate --platform=gitlab --token=$GITLAB_TOKEN
  only:
    - schedules
  variables:
    RENOVATE_BASE_BRANCHES: main
    RENOVATE_GIT_AUTHOR: "Renovate Bot <bot@renovateapp.com>"
    LOG_LEVEL: info

# Validation de la config
renovate-validate:
  stage: dependencies
  image: renovate/renovate:latest
  script:
    - renovate-config-validator
  only:
    changes:
      - renovate.json
      - .gitlab/renovate.json
```

### Configuration des schedules

```yaml
# Dans GitLab CI/CD > Schedules
# Description: Renovate weekly run
# Interval: 0 2 * * 1 (Monday 2 AM)
# Target branch: main
# Variables:
#   RENOVATE_TOKEN: $GITLAB_TOKEN
```

## 📊 Dashboard et reporting

### Dependency Dashboard

```json
{
  "dependencyDashboard": true,
  "dependencyDashboardTitle": "📊 Dependency Updates",
  "dependencyDashboardLabels": ["dependencies"],
  "dependencyDashboardFooter": "Managed by Renovate 🤖"
}
```

### Groupement intelligent

```json
{
  "packageRules": [
    {
      "groupName": "All minor and patch",
      "matchUpdateTypes": ["minor", "patch"],
      "schedule": ["before 3am on Monday"]
    },
    {
      "groupName": "Test dependencies",
      "matchDepTypes": ["test", "devDependencies"],
      "automerge": true
    },
    {
      "groupName": "Security updates",
      "matchUpdateTypes": ["patch"],
      "matchCurrentVersion": "!/^0/",
      "labels": ["security"]
    }
  ]
}
```

## 🎯 Exemples complets

### Java Spring Boot

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "labels": ["dependencies", "java"],
  "schedule": ["before 3am on Monday"],
  
  "packageRules": [
    {
      "matchManagers": ["maven"],
      "matchPackagePatterns": ["^org.springframework"],
      "groupName": "Spring Framework"
    },
    {
      "matchManagers": ["maven"],
      "matchUpdateTypes": ["major"],
      "enabled": false
    },
    {
      "matchManagers": ["maven"],
      "matchDepTypes": ["test"],
      "automerge": true
    }
  ],
  
  "maven": {
    "fileMatch": ["(^|/)pom\\.xml$"]
  }
}
```

### Drupal

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "labels": ["dependencies", "drupal"],
  "schedule": ["before 3am on Tuesday"],
  
  "packageRules": [
    {
      "matchManagers": ["composer"],
      "matchPackageNames": ["drupal/core-recommended"],
      "groupName": "Drupal Core",
      "major": { "enabled": false }
    },
    {
      "matchManagers": ["composer"],
      "matchPackagePatterns": ["^drupal/"],
      "excludePackageNames": ["drupal/core-recommended"],
      "groupName": "Drupal Modules"
    }
  ],
  
  "postUpgradeTasks": {
    "commands": [
      "composer normalize",
      "drush updatedb --no-interaction"
    ]
  }
}
```

### Node.js/Angular

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "labels": ["dependencies", "nodejs"],
  
  "packageRules": [
    {
      "matchManagers": ["npm"],
      "matchPackagePatterns": ["^@angular/"],
      "groupName": "Angular"
    },
    {
      "matchManagers": ["npm"],
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    },
    {
      "matchManagers": ["npm"],
      "matchDepTypes": ["devDependencies"],
      "automerge": true
    }
  ]
}
```

## 🔧 Configuration avancée

### Auto-merge sélectif

```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true,
      "automergeType": "pr",
      "automergeStrategy": "squash",
      "platformAutomerge": true,
      "requiredStatusChecks": ["ci/test"]
    }
  ]
}
```

### Post-upgrade tasks

```json
{
  "postUpgradeTasks": {
    "commands": [
      "npm run lint --fix",
      "npm run format",
      "npm test"
    ],
    "fileFilters": ["**/*"],
    "executionMode": "branch"
  }
}
```

### Regex Manager personnalisé

```json
{
  "regexManagers": [
    {
      "fileMatch": ["^Dockerfile$"],
      "matchStrings": [
        "# renovate: datasource=(?<datasource>.*?) depName=(?<depName>.*?)\\s+ARG .*?_VERSION=(?<currentValue>.*)\\s"
      ],
      "datasourceTemplate": "docker"
    }
  ]
}
```

## 🆘 Troubleshooting

### Renovate ne crée pas de MR

```json
{
  "logLevel": "debug",
  "printConfig": true,
  "dryRun": "full"
}
```

### Trop de MR

```json
{
  "prConcurrentLimit": 3,
  "prHourlyLimit": 1,
  "branchConcurrentLimit": 5
}
```

### Erreurs de merge

```json
{
  "rebaseWhen": "behind-base-branch",
  "conflictResolution": "auto"
}
```

## 📈 Métriques

### Statistiques Renovate

```bash
# Nombre de MR par semaine
renovate --platform=gitlab --dry-run=true

# Temps moyen de merge
# Via GitLab Merge Request Analytics
```

## 🎯 Meilleures pratiques

### 1. Schedule adapté
```json
{
  "schedule": ["before 3am on Monday"],
  "timezone": "Europe/Paris"
}
```

### 2. Limiter les MR
```json
{
  "prConcurrentLimit": 5,
  "prHourlyLimit": 2
}
```

### 3. Grouper les updates
```json
{
  "packageRules": [
    {
      "groupName": "All non-major",
      "matchUpdateTypes": ["minor", "patch"]
    }
  ]
}
```

### 4. Auto-merge sécurisé
```json
{
  "packageRules": [
    {
      "automerge": true,
      "requiredStatusChecks": ["ci/test", "security/scan"]
    }
  ]
}
```

### 5. Stabilité avant merge
```json
{
  "stabilityDays": 3,
  "minimumReleaseAge": "3 days"
}
```

## 📚 Ressources

- [Documentation Renovate](https://docs.renovatebot.com/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Presets](https://docs.renovatebot.com/presets-default/)
- [GitLab Integration](https://docs.renovatebot.com/modules/platform/gitlab/)

---

**Renovate maintient automatiquement vos dépendances à jour et sécurisées !** 🔄✨