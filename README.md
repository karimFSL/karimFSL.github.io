# 📚 Documentation Docusaurus - POC AWS

POC complet d'une documentation Docusaurus déployée sur AWS avec chiffrement et CI/CD.

## 🎯 Objectif

Déployer une documentation technique professionnelle sur AWS de manière **simple, sécurisée et économique**, sans Kubernetes.

## ✨ Caractéristiques

- ✅ **Documentation moderne** avec Docusaurus
- ✅ **Chiffrement** : AES-256 sur S3 + HTTPS/TLS 1.2+ sur CloudFront
- ✅ **Performance** : CDN global avec CloudFront
- ✅ **Économique** : ~1€/mois pour une utilisation standard
- ✅ **CI/CD** : Déploiement automatique avec GitHub Actions
- ✅ **Pas de serveur** : Architecture serverless (S3 + CloudFront)

## 🚀 Démarrage rapide

### 1. Prérequis

```bash
# Node.js 18+
node --version

# AWS CLI
aws --version

# Configurer AWS CLI
aws configure
```

### 2. Installation locale

```bash
# Installer les dépendances
npm install

# Lancer en développement
npm start
```

Accédez à `http://localhost:3000`

### 3. Build local

```bash
# Build pour production
npm run build

# Tester le build localement
npm run serve
```

## ☁️ Déploiement sur AWS

### Script automatique (Recommandé)

La manière la plus simple pour déployer :

```bash
# Rendre le script exécutable
chmod +x deploy-aws.sh

# Lancer le déploiement
./deploy-aws.sh
```

**Ce que fait le script :**
1. Build de la documentation
2. Création d'un bucket S3 avec chiffrement AES-256
3. Upload des fichiers
4. Création d'une distribution CloudFront avec HTTPS
5. Configuration de la sécurité (accès privé au bucket)
6. Vous donne l'URL publique

**Temps total : ~15-20 minutes** (délai de propagation CloudFront)

## 🔄 Mise à jour de la documentation

Après avoir modifié votre documentation :

```bash
# 1. Build
npm run build

# 2. Upload vers S3
aws s3 sync build/ s3://VOTRE-BUCKET/ --delete

# 3. Invalider le cache CloudFront
aws cloudfront create-invalidation \
    --distribution-id VOTRE-DISTRIBUTION-ID \
    --paths "/*"
```

## 🤖 CI/CD avec GitHub Actions

1. **Créez les secrets GitHub** dans `Settings > Secrets and variables > Actions`
2. **Le workflow est configuré** dans `.github/workflows/deploy.yml`
3. **Push sur main** → Déploiement automatique ! 🎉

## 🔐 Sécurité

- **Au repos** : Chiffrement AES-256 activé sur S3
- **En transit** : TLS 1.2+ obligatoire via CloudFront
- **Accès** : Bucket S3 privé, accessible uniquement via CloudFront

## 💰 Coûts estimés

Pour 1000 visiteurs/mois : **~0,12€/mois**
Pour 10 000 visiteurs/mois : **~2-3€/mois**

## 📁 Structure du projet

```
docusaurus-poc/
├── docs/                    # Documentation Markdown
├── blog/                    # Articles de blog
├── src/                     # Code source
├── static/                  # Assets statiques
├── deploy-aws.sh            # Script de déploiement
├── DEPLOYMENT.md            # Guide de déploiement complet
└── .github/workflows/       # CI/CD GitHub Actions
```

## 📝 Commandes utiles

```bash
npm start                    # Serveur de développement
npm run build               # Build pour production
npm run serve               # Serveur de test du build
./deploy-aws.sh             # Déploiement sur AWS
```

## 📚 Documentation complète

- **Guide de déploiement** : `DEPLOYMENT.md`
- **Documentation Docusaurus** : https://docusaurus.io
- **AWS Documentation** : voir les liens dans `DEPLOYMENT.md`

## ✅ Checklist de déploiement

- [ ] Tests locaux réussis
- [ ] AWS CLI configuré
- [ ] Script de déploiement testé
- [ ] URL CloudFront accessible
- [ ] HTTPS fonctionnel

---

**Développé avec ❤️ pour simplifier le déploiement de documentation sur AWS**
