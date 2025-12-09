# Guide de déploiement Docusaurus sur AWS

Ce guide vous montre comment déployer votre documentation Docusaurus sur AWS de la manière la plus simple possible.

## 🎯 Solution recommandée : S3 + CloudFront

C'est la solution la plus simple, économique et performante. Pas de serveur à gérer.

### Prérequis

```bash
# Installer AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurer AWS CLI
aws configure
# AWS Access Key ID: [VOTRE_CLE]
# AWS Secret Access Key: [VOTRE_SECRET]
# Default region name: eu-west-1
# Default output format: json
```

### Déploiement automatique (recommandé)

Utilisez le script fourni :

```bash
chmod +x deploy-aws.sh
./deploy-aws.sh
```

Le script va :
1. ✅ Builder votre documentation
2. ✅ Créer un bucket S3 avec chiffrement AES-256
3. ✅ Bloquer l'accès public au bucket
4. ✅ Uploader les fichiers
5. ✅ Créer une distribution CloudFront avec HTTPS
6. ✅ Vous donner l'URL publique

**Durée : ~15-20 minutes** (délai de propagation CloudFront)

### Mise à jour de la documentation

Après modifications, mettez à jour avec :

```bash
# Build
npm run build

# Upload vers S3
aws s3 sync build/ s3://VOTRE-BUCKET/ --delete

# Invalider le cache CloudFront (pour voir les changements immédiatement)
aws cloudfront create-invalidation \
  --distribution-id VOTRE-DISTRIBUTION-ID \
  --paths "/*"
```

## 🔐 Sécurité

### Chiffrement

Le script active automatiquement :
- ✅ Chiffrement AES-256 côté serveur
- ✅ HTTPS obligatoire via CloudFront (TLS 1.2+)
- ✅ Blocage de l'accès public direct au bucket S3

### Permissions minimales

Créez un utilisateur IAM avec uniquement ces permissions :

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:PutBucketEncryption",
                "s3:PutBucketPolicy",
                "s3:PutPublicAccessBlock"
            ],
            "Resource": [
                "arn:aws:s3:::docusaurus-docs-*",
                "arn:aws:s3:::docusaurus-docs-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateDistribution",
                "cloudfront:CreateOriginAccessControl",
                "cloudfront:GetDistribution",
                "cloudfront:CreateInvalidation"
            ],
            "Resource": "*"
        }
    ]
}
```

## 💰 Coûts

Pour une documentation de 100 MB avec 1000 visiteurs/mois :

- **S3 stockage** : ~0,02€/mois
- **CloudFront transfert** : ~0,85€/mois
- **Requêtes** : ~0,01€/mois

**Total : ~1€/mois** ✨

## 🚀 Déploiement CI/CD avec GitHub Actions

1. Créez ces secrets dans votre repo GitHub :
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `S3_BUCKET_NAME`
   - `CLOUDFRONT_DISTRIBUTION_ID`
   - `CLOUDFRONT_URL`

2. Le workflow `.github/workflows/deploy.yml` est déjà configuré

3. Push sur `main` → déploiement automatique ! 🎉

## 🔧 Alternative : AWS Amplify Hosting

Pour un déploiement encore plus simple (mais légèrement plus cher) :

```bash
chmod +x deploy-amplify.sh
./deploy-amplify.sh
```

**Avantages** :
- Configuration automatique
- Certificat SSL automatique
- CI/CD intégré
- Preview des branches

**Coût** : ~15€/mois pour 15 GB de transfert

## 📊 Monitoring

### Vérifier le déploiement

```bash
# Vérifier que le bucket existe
aws s3 ls | grep docusaurus

# Vérifier la distribution CloudFront
aws cloudfront list-distributions \
  --query 'DistributionList.Items[?Comment==`docusaurus-docs documentation`]'
```

### Logs CloudFront

Activez les logs pour suivre le trafic :

```bash
aws cloudfront update-distribution \
  --id VOTRE-DISTRIBUTION-ID \
  --logging-config \
    Enabled=true,IncludeCookies=false,\
    Bucket=logs-bucket.s3.amazonaws.com,\
    Prefix=cloudfront/
```

## 🐛 Dépannage

### La distribution CloudFront retourne 403

**Cause** : La politique du bucket S3 n'autorise pas CloudFront

**Solution** : 
```bash
# Vérifier la politique
aws s3api get-bucket-policy --bucket VOTRE-BUCKET

# Si elle est incorrecte, le script deploy-aws.sh la recréera
```

### Les modifications ne sont pas visibles

**Cause** : Cache CloudFront

**Solution** :
```bash
aws cloudfront create-invalidation \
  --distribution-id VOTRE-DISTRIBUTION-ID \
  --paths "/*"
```

### Erreur 404 sur les sous-pages

**Cause** : Docusaurus utilise le routing côté client

**Solution** : Déjà configuré dans le script avec CustomErrorResponses qui redirige 404 → index.html

## 🎨 Personnalisation de Docusaurus

### Modifier le thème

Éditez `docusaurus.config.ts` :

```typescript
export default {
  themeConfig: {
    colorMode: {
      defaultMode: 'light',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Ma Documentation',
      logo: {
        alt: 'Logo',
        src: 'img/logo.svg',
      },
    },
  },
}
```

### Ajouter du contenu

```bash
# Nouvelle page doc
docs/
  ├── intro.md
  ├── guide/
  │   ├── installation.md
  │   └── configuration.md
  └── api/
      └── reference.md
```

Éditez `sidebars.ts` pour la navigation.

## 📚 Ressources

- [Documentation Docusaurus](https://docusaurus.io)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)

## ✅ Checklist de déploiement

- [ ] AWS CLI installé et configuré
- [ ] Node.js 18+ installé
- [ ] Projet Docusaurus créé
- [ ] Build local testé (`npm run build && npm run serve`)
- [ ] Script de déploiement exécuté
- [ ] URL CloudFront accessible
- [ ] HTTPS fonctionne
- [ ] CI/CD configuré (optionnel)

---

**Besoin d'aide ?** Créez une issue sur GitHub ou contactez l'équipe DevOps.
