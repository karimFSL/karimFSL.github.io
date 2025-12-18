---
sidebar_position: 1
---

# 🔄 Renovate - Automatisation des dépendances

**Renovate** automatise la mise à jour des dépendances de vos projets. C'est essentiel pour maintenir la sécurité et la fraîcheur de votre stack.

## 🎯 Pourquoi Renovate ?

- ✅ **Automatique** : Créeation automatique de PR
- ✅ **Multi-langage** : Java, PHP, Node.js, Python, Docker, Terraform
- ✅ **Flexible** : Configuration fine par projet
- ✅ **Sécurité** : Intégration avec scanners de vulnérabilités
- ✅ **Gratuit** : Pour projets open-source

## 🚀 Installation

### GitHub App (Recommandé)

1. Installer l'app : https://github.com/apps/renovate
2. Autoriser sur votre organisation
3. Ajouter un fichier `renovate.json` au projet

### Self-hosted

```bash
# Docker
docker run -e RENOVATE_TOKEN=$GITHUB_TOKEN renovate/renovate

# npm
npm install -g renovate
renovate --token=$GITHUB_TOKEN votre-org/votre-repo
```

## 📝 Configuration de base

```json title="renovate.json"
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended"
  ],
  "schedule": ["before 3am on Monday"],
  "timezone": "Europe/Paris",
  "labels": ["dependencies"],
  "assignees": ["@devops-team"],
  "reviewers": ["@tech-leads"],
  "prConcurrentLimit": 5,
  "prHourlyLimit": 2
}
```

## ⚙️ Configuration Java/Maven

```json title="renovate.json"
{
  "extends": ["config:recommended"],
  "packageRules": [
    {
      "matchManagers": ["maven"],
      "matchUpdateTypes": ["minor", "patch"],
      "groupName": "Spring Boot dependencies",
      "matchPackagePatterns": ["^org.springframework.boot"],
      "schedule": ["before 3am on Monday"]
    },
    {
      "matchManagers": ["maven"],
      "matchUpdateTypes": ["major"],
      "enabled": false,
      "description": "Require manual approval for major updates"
    },
    {
      "matchManagers": ["maven"],
      "matchDepTypes": ["test"],
      "automerge": true,
      "automergeType": "pr"
    }
  ],
  "maven": {
    "fileMatch": ["(^|/)pom\\.xml$"],
    "versioning": "maven"
  }
}
```

## 🔷 Configuration Drupal/Composer

```json title="renovate.json"
{
  "extends": ["config:recommended"],
  "packageRules": [
    {
      "matchManagers": ["composer"],
      "matchPackagePatterns": ["^drupal/"],
      "groupName": "Drupal core and modules",
      "schedule": ["before 3am on Tuesday"],
      "commitMessagePrefix": "[DRUPAL]"
    },
    {
      "matchManagers": ["composer"],
      "matchDepTypes": ["require-dev"],
      "automerge": true
    },
    {
      "matchManagers": ["composer"],
      "matchPackageNames": ["drupal/core"],
      "enabled": true,
      "major": {
        "enabled": false
      }
    }
  ],
  "composer": {
    "fileMatch": ["(^|/)composer\\.json$"]
  }
}
```

## 🐳 Configuration Docker

```json title="renovate.json"
{
  "docker": {
    "enabled": true,
    "major": {
      "enabled": false
    }
  },
  "packageRules": [
    {
      "matchDatasources": ["docker"],
      "matchUpdateTypes": ["major"],
      "enabled": false
    },
    {
      "matchDatasources": ["docker"],
      "matchPackageNames": [
        "eclipse-temurin",
        "maven",
        "php"
      ],
      "groupName": "Base images",
      "schedule": ["before 3am on Wednesday"]
    }
  ]
}
```

## 🎯 Stratégies avancées

### Groupement intelligent

```json
{
  "packageRules": [
    {
      "groupName": "All non-major dependencies",
      "groupSlug": "all-minor-patch",
      "matchPackagePatterns": ["*"],
      "matchUpdateTypes": ["minor", "patch"],
      "schedule": ["before 3am on Monday"]
    },
    {
      "groupName": "Test dependencies",
      "matchDepTypes": ["test", "devDependencies"],
      "automerge": true,
      "automergeType": "branch"
    }
  ]
}
```

### Vulnérabilités en priorité

```json
{
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security"],
    "assignees": ["@security-team"],
    "prPriority": 10
  },
  "osvVulnerabilityAlerts": true
}
```

### Auto-merge sélectif

```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "matchCurrentVersion": "!/^0/",
      "automerge": true,
      "automergeType": "pr",
      "automergeStrategy": "squash",
      "requiredStatusChecks": [
        "ci/build",
        "ci/test",
        "security/trivy"
      ]
    }
  ]
}
```

## 🔒 Sécurité et conformité

### Vérification de signatures

```json
{
  "packageRules": [
    {
      "matchDatasources": ["docker"],
      "postUpgradeTasks": {
        "commands": [
          "cosign verify --key cosign.pub {{{depName}}}:{{{newVersion}}}"
        ],
        "fileFilters": ["**/*"],
        "executionMode": "branch"
      }
    }
  ]
}
```

### Tests obligatoires

```json
{
  "prCreation": "not-pending",
  "packageRules": [
    {
      "matchPackagePatterns": ["*"],
      "stabilityDays": 3,
      "minimumReleaseAge": "3 days"
    }
  ]
}
```

## 🔄 Intégration CI/CD

### GitHub Actions validation

```yaml title=".github/workflows/renovate-validate.yml"
name: Validate Renovate Config

on:
  pull_request:
    paths:
      - 'renovate.json'
      - '.github/renovate.json'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate Renovate config
        uses: rinchsan/renovate-config-validator@v0.1.0
        with:
          pattern: 'renovate.json'
```

### Self-hosted avec GitHub Actions

```yaml title=".github/workflows/renovate.yml"
name: Renovate

on:
  schedule:
    - cron: '0 2 * * 1'  # Monday 2 AM
  workflow_dispatch:

jobs:
  renovate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Self-hosted Renovate
        uses: renovatebot/github-action@v40.0.0
        with:
          configurationFile: renovate.json
          token: ${{ secrets.RENOVATE_TOKEN }}
        env:
          LOG_LEVEL: debug
          RENOVATE_REPOSITORIES: ${{ github.repository }}
```

## 📊 Dashboard et métriques

### Dependency Dashboard

```json
{
  "dependencyDashboard": true,
  "dependencyDashboardTitle": "📊 Dependency Updates Dashboard",
  "dependencyDashboardLabels": ["dependencies", "renovate"],
  "dependencyDashboardFooter": "Managed by Renovate Bot 🤖"
}
```

### Notifications Slack

```json
{
  "onboarding": false,
  "platform": "github",
  "repositories": ["votre-org/votre-repo"],
  "notifications": {
    "slack": {
      "enabled": true,
      "webhookUrl": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL",
      "channel": "#devops-updates"
    }
  }
}
```

## 🎯 Configuration complète par stack

### Stack Java complète

```json title="renovate-java.json"
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "timezone": "Europe/Paris",
  "schedule": ["before 3am on Monday"],
  "labels": ["dependencies", "java"],
  "assignees": ["@java-team"],
  
  "packageRules": [
    {
      "matchManagers": ["maven"],
      "matchPackagePatterns": ["^org.springframework"],
      "groupName": "Spring Framework",
      "schedule": ["before 3am on Monday"]
    },
    {
      "matchManagers": ["maven"],
      "matchPackageNames": ["org.springframework.boot:spring-boot-starter-parent"],
      "versioning": "maven"
    },
    {
      "matchManagers": ["maven"],
      "matchUpdateTypes": ["major"],
      "enabled": false
    },
    {
      "matchManagers": ["maven"],
      "matchDepTypes": ["test"],
      "automerge": true,
      "automergeType": "branch"
    }
  ],
  
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security", "vulnerability"],
    "assignees": ["@security-team"]
  },
  
  "prConcurrentLimit": 5,
  "prHourlyLimit": 2,
  "minimumReleaseAge": "3 days",
  "stabilityDays": 3
}
```

### Stack Drupal complète

```json title="renovate-drupal.json"
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "timezone": "Europe/Paris",
  "schedule": ["before 3am on Tuesday"],
  "labels": ["dependencies", "drupal"],
  
  "packageRules": [
    {
      "matchManagers": ["composer"],
      "matchPackageNames": ["drupal/core-recommended"],
      "groupName": "Drupal Core",
      "major": {
        "enabled": false
      }
    },
    {
      "matchManagers": ["composer"],
      "matchPackagePatterns": ["^drupal/"],
      "excludePackageNames": ["drupal/core-recommended"],
      "groupName": "Drupal Modules",
      "schedule": ["before 3am on Tuesday"]
    },
    {
      "matchManagers": ["composer"],
      "matchDepTypes": ["require-dev"],
      "automerge": true,
      "labels": ["dev-dependencies"]
    }
  ],
  
  "composer": {
    "ignorePlugins": ["dealerdirect/phpcodesniffer-composer-installer"]
  },
  
  "postUpgradeTasks": {
    "commands": [
      "composer normalize",
      "drush updatedb --no-interaction",
      "drush cache:rebuild"
    ],
    "fileFilters": ["composer.json", "composer.lock"]
  }
}
```

## 🔧 Troubleshooting

### Renovate ne crée pas de PR

```json
{
  "logLevel": "debug",
  "printConfig": true
}
```

### Trop de PR créées

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
  "automerge": false,
  "rebaseWhen": "behind-base-branch",
  "conflictResolution": "auto"
}
```

## 📚 Ressources

- [Documentation Renovate](https://docs.renovatebot.com/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Presets](https://docs.renovatebot.com/presets-default/)
- [Examples](https://github.com/renovatebot/renovate/tree/main/examples)

---

**Renovate maintient automatiquement vos dépendances à jour et sécurisées !** 🔄✨
