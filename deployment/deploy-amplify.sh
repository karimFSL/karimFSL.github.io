#!/bin/bash

# Déploiement ultra-simple avec AWS Amplify Hosting
# Pas besoin de gérer S3, CloudFront, etc.

set -e

PROJECT_NAME="docusaurus-docs"
AMPLIFY_APP_NAME="${PROJECT_NAME}-$(date +%s)"

echo "🚀 Déploiement Docusaurus avec AWS Amplify"
echo "==========================================="
echo ""

# Build
echo "📦 Build de la documentation..."
npm run build
echo "✅ Build terminé"
echo ""

# Création d'un zip
echo "📦 Création du package de déploiement..."
cd build
zip -r ../deploy.zip . > /dev/null
cd ..
echo "✅ Package créé"
echo ""

# Création de l'application Amplify
echo "📱 Création de l'application Amplify..."
APP_ID=$(aws amplify create-app \
    --name ${AMPLIFY_APP_NAME} \
    --platform WEB \
    --query 'app.appId' \
    --output text)

echo "App ID: ${APP_ID}"
echo ""

# Création d'une branche
echo "🌿 Création de la branche principale..."
aws amplify create-branch \
    --app-id ${APP_ID} \
    --branch-name main \
    --enable-auto-build false

# Démarrer le déploiement
echo "🚀 Démarrage du déploiement..."
JOB_ID=$(aws amplify start-deployment \
    --app-id ${APP_ID} \
    --branch-name main \
    --source-url-type ZIP \
    --source-url file://deploy.zip \
    --query 'jobSummary.jobId' \
    --output text)

echo "Job ID: ${JOB_ID}"
echo ""

# Attendre que le déploiement soit terminé
echo "⏳ Déploiement en cours..."
aws amplify wait job-complete \
    --app-id ${APP_ID} \
    --branch-name main \
    --job-id ${JOB_ID}

# Récupérer l'URL
APP_URL=$(aws amplify get-app \
    --app-id ${APP_ID} \
    --query 'app.defaultDomain' \
    --output text)

echo ""
echo "✨ Déploiement terminé avec succès !"
echo "===================================="
echo ""
echo "📋 Informations:"
echo "  - App ID: ${APP_ID}"
echo "  - URL: https://main.${APP_URL}"
echo ""

# Sauvegarde
cat > deployment-amplify.txt << EOF
App ID: ${APP_ID}
URL: https://main.${APP_URL}
Date: $(date)
EOF

echo "💾 Informations sauvegardées dans deployment-amplify.txt"
