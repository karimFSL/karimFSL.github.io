---
sidebar_position: 1
---

# Guide de démarrage rapide

Bienvenue dans la documentation ! Ce guide vous aidera à démarrer rapidement.

## 🚀 Installation

### Prérequis

Avant de commencer, assurez-vous d'avoir :

- Node.js 18 ou supérieur
- npm ou yarn
- Git

### Installation du projet

```bash
# Cloner le repository
git clone https://github.com/votre-org/votre-projet.git
cd votre-projet

# Installer les dépendances
npm install

# Lancer en développement
npm start
```

## 📦 Structure du projet

```
mon-projet/
├── docs/              # Documentation Markdown
├── blog/              # Articles de blog (optionnel)
├── src/
│   ├── components/    # Composants React personnalisés
│   └── pages/         # Pages React personnalisées
├── static/            # Assets statiques
└── docusaurus.config.ts  # Configuration
```

## ⚙️ Configuration de base

Le fichier `docusaurus.config.ts` contient toute la configuration :

```typescript
export default {
  title: 'Ma Documentation',
  tagline: 'Documentation technique complète',
  url: 'https://docs.example.com',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  
  i18n: {
    defaultLocale: 'fr',
    locales: ['fr', 'en'],
  },
}
```

## 📝 Créer votre première page

Créez un fichier dans `docs/` :

```markdown title="docs/ma-premiere-page.md"
---
sidebar_position: 2
title: Ma première page
---

# Ma première page

Contenu de votre page en Markdown.

## Section 1

Votre contenu ici...
```

## 🎨 Personnalisation

### Changer les couleurs

Dans `src/css/custom.css` :

```css
:root {
  --ifm-color-primary: #2e8555;
  --ifm-color-primary-dark: #29784c;
  /* ... */
}
```

### Ajouter un logo

Placez votre logo dans `static/img/logo.svg` et référencez-le dans la configuration.

## 🔍 Recherche

La recherche est activée par défaut. Pour une recherche avancée, intégrez Algolia DocSearch (gratuit pour projets open-source).

## 📚 Prochaines étapes

- [Configuration avancée](./configuration.md)
- [Déploiement sur AWS](./deployment.md)
- [Personnalisation du thème](./theming.md)

## 💡 Astuces

:::tip Astuce
Utilisez les admonitions pour mettre en évidence des informations importantes !
:::

:::warning Attention
Les avertissements attirent l'attention sur des points critiques.
:::

:::danger Danger
Les erreurs courantes peuvent être mises en évidence ainsi.
:::

:::info Information
Informations supplémentaires utiles pour vos utilisateurs.
:::

## 🤝 Besoin d'aide ?

Consultez la [documentation officielle Docusaurus](https://docusaurus.io) ou contactez l'équipe.
