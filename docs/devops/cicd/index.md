---
sidebar_position: 1
---
# CI/CD


# Templates GitLab CI

Des templates sont accessibles sur le dépôt Git :

**🔗 Repository :** [https://github.com/karimFSL/gitlabci-templates](https://github.com/karimFSL/gitlabci-templates)

:::info Accès requis
Demandez les accès au repository si vous n'y avez pas encore accès.
:::

## Templates disponibles

| Template | Description |
|----------|-------------|
| **maven** | Maven build template |
| **npm** | NPM build template |
| **docker** | Docker build template |
| **helm** | Helm build template |
| **gitops** | Gitops deployment template |
| **sonar** | SonarQube analysis template |
| **task** | Taskfile template |
| **awx** | Ansible AWX template |
| **tag** | Tagging template |
| **vars** | Variables template |
| **python** | Python build template |
| **renovate** | Renovate template |
| **sbom** | Software Bill of Materials operations template |

## Utilisation

Pour utiliser un template dans votre pipeline GitLab CI, ajoutez l'include dans votre `.gitlab-ci.yml` :
```yaml
include:
  - project: 'karimFSL/gitlabci-templates'
    file: '/templates/nom-du-template.yml'
```

## Support

Pour toute question ou demande d'accès, contactez l'équipe DevOps.