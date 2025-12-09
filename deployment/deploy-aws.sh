#!/bin/bash

# Script de déploiement Docusaurus sur AWS (S3 + CloudFront)
# Simple et rapide - pas de Kubernetes

set -e

# Configuration
PROJECT_NAME="docusaurus-docs"
AWS_REGION="eu-west-1"
BUCKET_NAME="${PROJECT_NAME}-$(date +%s)"

echo "🚀 Déploiement de Docusaurus sur AWS"
echo "======================================"
echo ""

# Étape 1 : Build du projet
echo "📦 Build de la documentation..."
npm run build

echo "✅ Build terminé"
echo ""

# Étape 2 : Création du bucket S3
echo "🪣 Création du bucket S3: ${BUCKET_NAME}"
aws s3 mb s3://${BUCKET_NAME} --region ${AWS_REGION}

# Étape 3 : Activation du chiffrement
echo "🔐 Activation du chiffrement AES-256..."
aws s3api put-bucket-encryption \
    --bucket ${BUCKET_NAME} \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            },
            "BucketKeyEnabled": true
        }]
    }'

# Étape 4 : Blocage de l'accès public
echo "🔒 Blocage de l'accès public..."
aws s3api put-public-access-block \
    --bucket ${BUCKET_NAME} \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Étape 5 : Upload des fichiers
echo "⬆️  Upload des fichiers vers S3..."
aws s3 sync build/ s3://${BUCKET_NAME}/ \
    --delete \
    --cache-control "public, max-age=3600" \
    --metadata-directive REPLACE

echo "✅ Fichiers uploadés"
echo ""

# Étape 6 : Création de l'Origin Access Control
echo "🔑 Création de l'Origin Access Control..."
OAC_ID=$(aws cloudfront create-origin-access-control \
    --origin-access-control-config "{
        \"Name\": \"${PROJECT_NAME}-oac\",
        \"SigningProtocol\": \"sigv4\",
        \"SigningBehavior\": \"always\",
        \"OriginAccessControlOriginType\": \"s3\"
    }" \
    --query 'OriginAccessControl.Id' \
    --output text)

echo "OAC ID: ${OAC_ID}"
echo ""

# Étape 7 : Création de la distribution CloudFront
echo "☁️  Création de la distribution CloudFront..."
CALLER_REF="docs-$(date +%s)"
DISTRIBUTION_ID=$(aws cloudfront create-distribution \
    --distribution-config "{
        \"CallerReference\": \"${CALLER_REF}\",
        \"Comment\": \"${PROJECT_NAME} documentation\",
        \"DefaultRootObject\": \"index.html\",
        \"Origins\": {
            \"Quantity\": 1,
            \"Items\": [{
                \"Id\": \"S3-${BUCKET_NAME}\",
                \"DomainName\": \"${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com\",
                \"S3OriginConfig\": {
                    \"OriginAccessIdentity\": \"\"
                },
                \"OriginAccessControlId\": \"${OAC_ID}\"
            }]
        },
        \"DefaultCacheBehavior\": {
            \"TargetOriginId\": \"S3-${BUCKET_NAME}\",
            \"ViewerProtocolPolicy\": \"redirect-to-https\",
            \"AllowedMethods\": {
                \"Quantity\": 2,
                \"Items\": [\"GET\", \"HEAD\"],
                \"CachedMethods\": {
                    \"Quantity\": 2,
                    \"Items\": [\"GET\", \"HEAD\"]
                }
            },
            \"Compress\": true,
            \"MinTTL\": 0,
            \"DefaultTTL\": 3600,
            \"MaxTTL\": 86400,
            \"ForwardedValues\": {
                \"QueryString\": false,
                \"Cookies\": {\"Forward\": \"none\"}
            },
            \"TrustedSigners\": {
                \"Enabled\": false,
                \"Quantity\": 0
            }
        },
        \"Enabled\": true,
        \"ViewerCertificate\": {
            \"CloudFrontDefaultCertificate\": true,
            \"MinimumProtocolVersion\": \"TLSv1.2_2021\"
        },
        \"CustomErrorResponses\": {
            \"Quantity\": 2,
            \"Items\": [{
                \"ErrorCode\": 404,
                \"ResponsePagePath\": \"/index.html\",
                \"ResponseCode\": \"200\",
                \"ErrorCachingMinTTL\": 300
            }, {
                \"ErrorCode\": 403,
                \"ResponsePagePath\": \"/index.html\",
                \"ResponseCode\": \"200\",
                \"ErrorCachingMinTTL\": 300
            }]
        }
    }" \
    --query 'Distribution.Id' \
    --output text)

echo "Distribution ID: ${DISTRIBUTION_ID}"
echo ""

# Étape 8 : Mise à jour de la politique S3
echo "📝 Mise à jour de la politique du bucket..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${DISTRIBUTION_ID}"
                }
            }
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket ${BUCKET_NAME} \
    --policy file:///tmp/bucket-policy.json

echo "✅ Politique mise à jour"
echo ""

# Étape 9 : Récupération de l'URL CloudFront
CLOUDFRONT_URL=$(aws cloudfront get-distribution \
    --id ${DISTRIBUTION_ID} \
    --query 'Distribution.DomainName' \
    --output text)

echo ""
echo "✨ Déploiement terminé avec succès !"
echo "======================================"
echo ""
echo "📋 Informations de déploiement:"
echo "  - Bucket S3: ${BUCKET_NAME}"
echo "  - Distribution CloudFront: ${DISTRIBUTION_ID}"
echo "  - URL: https://${CLOUDFRONT_URL}"
echo ""
echo "⏳ La distribution CloudFront prend 15-20 minutes pour être disponible"
echo ""
echo "🔄 Pour mettre à jour la documentation:"
echo "  1. npm run build"
echo "  2. aws s3 sync build/ s3://${BUCKET_NAME}/ --delete"
echo "  3. aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths '/*'"
echo ""

# Sauvegarde des informations
cat > deployment-info.txt << EOF
Bucket: ${BUCKET_NAME}
Distribution: ${DISTRIBUTION_ID}
URL: https://${CLOUDFRONT_URL}
Region: ${AWS_REGION}
Date: $(date)
EOF

echo "💾 Informations sauvegardées dans deployment-info.txt"
