---
sidebar_position: 3
---

# Déploiement sur AWS

Guide complet pour déployer votre documentation Docusaurus sur AWS avec S3 et CloudFront.

## 🎯 Architecture

```mermaid
graph TB
    A[Développeur] -->|git push| B[GitHub]
    B -->|GitHub Actions| C[Build Docusaurus]
    C -->|Upload| D[S3 Bucket]
    D -->|Origin| E[CloudFront CDN]
    E -->|HTTPS| F[Utilisateurs]
    G[ACM Certificate] -->|SSL/TLS| E
    H[KMS] -->|Chiffrement| D
```

## 🚀 Déploiement rapide

### Option 1 : Script automatique (Recommandé)

Le moyen le plus simple :

```bash
# Donner les permissions d'exécution
chmod +x deploy-aws.sh

# Lancer le déploiement
./deploy-aws.sh
```

Le script va automatiquement :
- ✅ Builder la documentation
- ✅ Créer un bucket S3 sécurisé
- ✅ Activer le chiffrement AES-256
- ✅ Configurer CloudFront avec HTTPS
- ✅ Vous donner l'URL publique

**Temps d'attente** : 15-20 minutes pour la propagation CloudFront

### Option 2 : Commandes manuelles

Si vous préférez comprendre chaque étape :

#### 1. Build de la documentation

```bash
npm run build
```

Cela génère les fichiers statiques dans `build/`

#### 2. Créer le bucket S3

```bash
BUCKET_NAME="ma-doc-$(date +%s)"
aws s3 mb s3://${BUCKET_NAME} --region eu-west-1
```

#### 3. Activer le chiffrement

```bash
aws s3api put-bucket-encryption \
    --bucket ${BUCKET_NAME} \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'
```

#### 4. Bloquer l'accès public

```bash
aws s3api put-public-access-block \
    --bucket ${BUCKET_NAME} \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

#### 5. Upload des fichiers

```bash
aws s3 sync build/ s3://${BUCKET_NAME}/ \
    --delete \
    --cache-control "public, max-age=3600"
```

#### 6. Créer CloudFront

Voir le script `deploy-aws.sh` pour la configuration complète CloudFront.

## 🔐 Sécurité

### Chiffrement activé par défaut

- **Au repos** : AES-256 sur S3
- **En transit** : TLS 1.2+ via CloudFront
- **Accès** : Bucket privé, accessible uniquement via CloudFront

### Permissions IAM recommandées

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::ma-doc-*",
                "arn:aws:s3:::ma-doc-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🔄 Mise à jour de la documentation

Après avoir modifié votre documentation :

```bash
# 1. Rebuild
npm run build

# 2. Upload vers S3
aws s3 sync build/ s3://VOTRE-BUCKET/ --delete

# 3. Invalider le cache CloudFront (pour voir les changements immédiatement)
aws cloudfront create-invalidation \
    --distribution-id VOTRE-DISTRIBUTION-ID \
    --paths "/*"
```

:::tip Astuce CI/CD
Automatisez cela avec GitHub Actions ! Voir la section CI/CD ci-dessous.
:::

## 🤖 CI/CD avec GitHub Actions

Le workflow `.github/workflows/deploy.yml` est déjà configuré.

### Configuration des secrets GitHub

Dans votre repository GitHub, allez dans **Settings > Secrets and variables > Actions** et ajoutez :

| Secret | Description | Exemple |
|--------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | Clé d'accès AWS | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Secret AWS | `wJalrXUtnFEMI/K7MDENG/...` |
| `S3_BUCKET_NAME` | Nom du bucket S3 | `ma-doc-1234567890` |
| `CLOUDFRONT_DISTRIBUTION_ID` | ID CloudFront | `E1XXXXXXXXXXX` |
| `CLOUDFRONT_URL` | URL CloudFront | `d1234567890.cloudfront.net` |

### Workflow automatique

Une fois configuré, chaque push sur `main` déclenche :

1. ✅ Installation des dépendances
2. ✅ Build de la documentation
3. ✅ Upload vers S3
4. ✅ Invalidation du cache CloudFront

**Temps de déploiement** : ~2-3 minutes

## 💰 Coûts AWS

Estimation mensuelle pour une documentation standard :

| Service | Usage | Coût |
|---------|-------|------|
| S3 Storage | 100 MB | 0,02€ |
| S3 Requests | 10 000 GET | 0,01€ |
| CloudFront | 1 GB transfert | 0,09€ |
| CloudFront Requests | 10 000 | 0,01€ |
| **Total** | | **~0,13€/mois** |

Pour 10 000 visiteurs/mois : **~2-3€/mois**

:::info Niveau gratuit AWS
Les 12 premiers mois, vous bénéficiez du niveau gratuit AWS qui couvre largement ces usages.
:::

## 🌍 Configuration multi-région (optionnel)

Pour une latence mondiale optimale :

```bash
# Répliquer dans plusieurs régions
aws s3 sync s3://source-bucket s3://replica-eu-west-1 --source-region us-east-1
aws s3 sync s3://source-bucket s3://replica-ap-southeast-1 --source-region us-east-1

# CloudFront gère automatiquement le routage optimal
```

## 🔍 Monitoring

### CloudWatch Metrics

Activez les métriques CloudFront pour suivre :
- Nombre de requêtes
- Bande passante utilisée
- Erreurs 4xx/5xx
- Latence

```bash
# Voir les métriques
aws cloudwatch get-metric-statistics \
    --namespace AWS/CloudFront \
    --metric-name Requests \
    --dimensions Name=DistributionId,Value=VOTRE-ID \
    --start-time 2025-01-01T00:00:00Z \
    --end-time 2025-01-31T23:59:59Z \
    --period 3600 \
    --statistics Sum
```

### Alarmes

Créez des alarmes pour être notifié :

```bash
aws cloudwatch put-metric-alarm \
    --alarm-name docs-high-error-rate \
    --alarm-description "Taux d'erreur élevé sur la documentation" \
    --metric-name 5xxErrorRate \
    --namespace AWS/CloudFront \
    --statistic Average \
    --period 300 \
    --threshold 5 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2
```

## 🐛 Dépannage

### Problème : 403 Forbidden

**Cause** : La politique S3 n'autorise pas CloudFront

**Solution** :
```bash
# Vérifier la politique actuelle
aws s3api get-bucket-policy --bucket VOTRE-BUCKET

# Réexécuter le script de déploiement pour la recréer
./deploy-aws.sh
```

### Problème : Modifications non visibles

**Cause** : Cache CloudFront actif

**Solution** :
```bash
# Invalider tout le cache
aws cloudfront create-invalidation \
    --distribution-id VOTRE-ID \
    --paths "/*"
```

### Problème : 404 sur les sous-pages

**Cause** : Routing côté client de Docusaurus

**Solution** : Déjà géré dans le script avec CustomErrorResponses

## 📊 Performances

### Optimisations appliquées

- ✅ Compression Gzip/Brotli automatique
- ✅ Cache-Control headers optimisés
- ✅ CDN global avec CloudFront
- ✅ HTTP/2 et HTTP/3 activés

### Résultats attendus

- **Time to First Byte (TTFB)** : < 200ms
- **Largest Contentful Paint** : < 2s
- **PageSpeed Score** : 90+

## 🔗 Ressources complémentaires

- [Documentation AWS S3](https://docs.aws.amazon.com/s3/)
- [Documentation CloudFront](https://docs.aws.amazon.com/cloudfront/)
- [Best practices Docusaurus](https://docusaurus.io/docs/deployment)

## ✅ Checklist de déploiement

Avant de déployer en production :

- [ ] Tests locaux réussis (`npm run build && npm run serve`)
- [ ] AWS CLI configuré avec les bons credentials
- [ ] Bucket S3 créé avec chiffrement
- [ ] Distribution CloudFront configurée
- [ ] HTTPS fonctionnel
- [ ] Cache CloudFront testé et invalidé
- [ ] CI/CD GitHub Actions configuré
- [ ] Monitoring CloudWatch activé
- [ ] Documentation des credentials sauvegardée

---

**Besoin d'aide ?** Contactez l'équipe DevOps ou ouvrez une issue sur GitHub.
