---
sidebar_position: 3
---

# Installation et utilisation de Keycloak

## Introduction

Keycloak est une solution open-source de gestion d'identité et d'accès (IAM) qui permet d'ajouter l'authentification et l'autorisation à vos applications.

Ce guide couvre l'installation locale de Keycloak avec Docker Compose et la configuration des principaux flows OAuth2/OpenID Connect.

---

## Prérequis

- Docker et Docker Compose installés
- WSL2 (si vous êtes sur Windows)
- Un navigateur web
- curl ou Postman pour tester les APIs

---

## Installation avec Docker Compose

### 1. Créer le fichier docker-compose.yml

Créez un fichier `docker-compose.yml` dans votre répertoire de projet :
```yaml
version: '3.8'

services:
  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    container_name: keycloak-local
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: keycloak
      KC_HOSTNAME: localhost
      KC_HOSTNAME_PORT: 8080
      KC_HOSTNAME_STRICT: false
      KC_HTTP_ENABLED: true
      KC_HEALTH_ENABLED: true
    command:
      - start-dev
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    networks:
      - keycloak-network

  postgres:
    image: postgres:15
    container_name: postgres-keycloak
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: keycloak
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - keycloak-network

volumes:
  postgres-data:

networks:
  keycloak-network:
    driver: bridge
```

### 2. Démarrer Keycloak
```bash
docker-compose up -d
```

### 3. Vérifier le démarrage
```bash
# Vérifier les logs
docker-compose logs -f keycloak

# Vérifier que les conteneurs sont actifs
docker-compose ps
```

### 4. Accéder à la console d'administration

Ouvrez votre navigateur et accédez à :
```
http://localhost:8080
```

**Identifiants par défaut :**
- **Username :** admin
- **Password :** admin

---

## Configuration initiale

### 1. Créer un Realm

Un Realm est un espace isolé pour gérer vos utilisateurs, applications et configurations.

1. Connectez-vous à la console d'administration
2. Survolez **Master** en haut à gauche
3. Cliquez sur **Create Realm**
4. Entrez le nom : `dev-realm`
5. Cliquez sur **Create**

### 2. Créer un utilisateur de test

1. Dans le menu de gauche, cliquez sur **Users**
2. Cliquez sur **Add user**
3. Remplissez les informations :
   - **Username :** testuser
   - **Email :** testuser@example.com
   - **First name :** Test
   - **Last name :** User
   - **Email verified :** ON
4. Cliquez sur **Create**
5. Allez dans l'onglet **Credentials**
6. Cliquez sur **Set password**
7. Entrez : `password123`
8. Désactivez **Temporary**
9. Cliquez sur **Save**

---

## Configuration des Clients OAuth2

### Client 1 : Authorization Code Flow (Application Web)

Le flow Authorization Code est utilisé pour les applications web avec backend.

#### Création du client

1. Allez dans **Clients** → **Create client**
2. Configuration :
   - **Client type :** OpenID Connect
   - **Client ID :** `web-app`
3. Cliquez sur **Next**
4. Configuration des capacités :
   - **Client authentication :** ON
   - **Authorization :** ON
   - **Standard flow :** ON (Authorization Code)
   - **Direct access grants :** OFF
5. Cliquez sur **Next**
6. Configuration des URLs :
   - **Root URL :** `http://localhost:3000`
   - **Valid redirect URIs :** `http://localhost:3000/callback`
   - **Valid post logout redirect URIs :** `http://localhost:3000`
   - **Web origins :** `http://localhost:3000`
7. Cliquez sur **Save**

#### Récupérer le Client Secret

1. Allez dans l'onglet **Credentials**
2. Copiez le **Client secret**

#### Test avec curl
```bash
# Étape 1 : Obtenir le code d'autorisation
# Ouvrez cette URL dans votre navigateur
http://localhost:8080/realms/dev-realm/protocol/openid-connect/auth?client_id=web-app&redirect_uri=http://localhost:3000/callback&response_type=code&scope=openid

# Après connexion, vous serez redirigé vers :
# http://localhost:3000/callback?code=AUTHORIZATION_CODE

# Étape 2 : Échanger le code contre un token
curl -X POST http://localhost:8080/realms/dev-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "client_id=web-app" \
  -d "client_secret=VOTRE_CLIENT_SECRET" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=http://localhost:3000/callback"
```

---

### Client 2 : Resource Owner Password Credentials (Password Grant)

Le Password Grant est utilisé pour les applications de confiance (à éviter en production).

#### Création du client

1. Allez dans **Clients** → **Create client**
2. Configuration :
   - **Client type :** OpenID Connect
   - **Client ID :** `mobile-app`
3. Cliquez sur **Next**
4. Configuration des capacités :
   - **Client authentication :** ON
   - **Authorization :** OFF
   - **Standard flow :** OFF
   - **Direct access grants :** ON (Resource Owner Password)
5. Cliquez sur **Next**
6. Cliquez sur **Save**

#### Test avec curl
```bash
curl -X POST http://localhost:8080/realms/dev-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=mobile-app" \
  -d "client_secret=VOTRE_CLIENT_SECRET" \
  -d "username=testuser" \
  -d "password=password123" \
  -d "scope=openid"
```

**Réponse attendue :**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "not-before-policy": 0,
  "session_state": "d1c8e0e5-...",
  "scope": "openid profile email"
}
```

---

### Client 3 : Client Credentials (Machine-to-Machine)

Le Client Credentials flow est utilisé pour l'authentification service-to-service.

#### Création du client

1. Allez dans **Clients** → **Create client**
2. Configuration :
   - **Client type :** OpenID Connect
   - **Client ID :** `backend-service`
3. Cliquez sur **Next**
4. Configuration des capacités :
   - **Client authentication :** ON
   - **Authorization :** OFF
   - **Standard flow :** OFF
   - **Direct access grants :** OFF
   - **Service accounts roles :** ON
5. Cliquez sur **Next**
6. Cliquez sur **Save**

#### Configuration des rôles (optionnel)

1. Allez dans l'onglet **Service account roles**
2. Cliquez sur **Assign role**
3. Sélectionnez les rôles nécessaires

#### Test avec curl
```bash
curl -X POST http://localhost:8080/realms/dev-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=backend-service" \
  -d "client_secret=VOTRE_CLIENT_SECRET"
```

**Réponse attendue :**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "refresh_expires_in": 0,
  "token_type": "Bearer",
  "not-before-policy": 0,
  "scope": "profile email"
}
```

---

## Utilisation des Tokens

### Vérifier un Access Token
```bash
curl -X POST http://localhost:8080/realms/dev-realm/protocol/openid-connect/token/introspect \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=VOTRE_ACCESS_TOKEN" \
  -d "client_id=web-app" \
  -d "client_secret=VOTRE_CLIENT_SECRET"
```

### Rafraîchir un Access Token
```bash
curl -X POST http://localhost:8080/realms/dev-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "client_id=web-app" \
  -d "client_secret=VOTRE_CLIENT_SECRET" \
  -d "refresh_token=VOTRE_REFRESH_TOKEN"
```

### Déconnecter un utilisateur
```bash
curl -X POST http://localhost:8080/realms/dev-realm/protocol/openid-connect/logout \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=web-app" \
  -d "client_secret=VOTRE_CLIENT_SECRET" \
  -d "refresh_token=VOTRE_REFRESH_TOKEN"
```

### Utiliser un Access Token dans vos requêtes API
```bash
curl -X GET http://localhost:8081/api/protected-resource \
  -H "Authorization: Bearer VOTRE_ACCESS_TOKEN"
```

---

## Décoder un JWT Token

Vous pouvez décoder vos tokens JWT sur [jwt.io](https://jwt.io) pour inspecter leur contenu.

**Exemple de payload d'un Access Token :**
```json
{
  "exp": 1703001234,
  "iat": 1703000934,
  "jti": "a1b2c3d4-...",
  "iss": "http://localhost:8080/realms/dev-realm",
  "aud": "account",
  "sub": "f47ac10b-...",
  "typ": "Bearer",
  "azp": "web-app",
  "session_state": "d1c8e0e5-...",
  "preferred_username": "testuser",
  "email": "testuser@example.com",
  "email_verified": true,
  "name": "Test User",
  "given_name": "Test",
  "family_name": "User",
  "scope": "openid profile email",
  "realm_access": {
    "roles": ["default-roles-dev-realm", "offline_access"]
  }
}
```

---

## Configuration avancée

### Augmenter la durée de vie des tokens

1. Allez dans **Realm settings** → **Tokens**
2. Modifiez les valeurs :
   - **Access Token Lifespan :** 5 minutes (par défaut) → 30 minutes
   - **Refresh Token Max Lifespan :** 30 minutes → 8 heures

### Ajouter des claims personnalisés

1. Allez dans **Client scopes** → **Create client scope**
2. Nom : `custom-claims`
3. Allez dans l'onglet **Mappers** → **Add mapper** → **By configuration** → **User Attribute**
4. Configuration :
   - **Name :** department
   - **User Attribute :** department
   - **Token Claim Name :** department
   - **Claim JSON Type :** String
   - **Add to ID token :** ON
   - **Add to access token :** ON
5. Associez ce scope à vos clients

### Configurer CORS

1. Allez dans votre client (ex: `web-app`)
2. Dans **Web origins**, ajoutez : `*` (pour le développement uniquement)
3. En production, spécifiez les domaines exacts

---

## Résumé des flows

| Flow | Usage | Sécurité | Client Authentication |
|------|-------|----------|----------------------|
| **Authorization Code** | Applications web avec backend | ✅ Haute | Oui (avec secret) |
| **Password Grant** | Applications de confiance | ⚠️ Moyenne | Oui |
| **Client Credentials** | Service-to-service (M2M) | ✅ Haute | Oui |

---

## Commandes utiles Docker
```bash
# Démarrer Keycloak
docker-compose up -d

# Arrêter Keycloak
docker-compose down

# Voir les logs
docker-compose logs -f keycloak

# Redémarrer Keycloak
docker-compose restart keycloak

# Supprimer tout (y compris les données)
docker-compose down -v

# Exporter la configuration du realm
docker exec -it keycloak-local /opt/keycloak/bin/kc.sh export --dir /tmp/export --realm dev-realm
docker cp keycloak-local:/tmp/export ./keycloak-export
```

---

## Troubleshooting

### Keycloak ne démarre pas
```bash
# Vérifier les logs
docker-compose logs keycloak

# Vérifier que PostgreSQL est bien démarré
docker-compose ps
```

### Erreur de connexion à la base de données
```bash
# Recréer les conteneurs
docker-compose down -v
docker-compose up -d
```

### Token invalide

- Vérifiez que le client_id et client_secret sont corrects
- Vérifiez que l'utilisateur existe et a un mot de passe
- Vérifiez les redirect_uris configurés

### CORS errors

- Ajoutez vos domaines dans **Web origins** du client
- En développement, vous pouvez utiliser `*`

---

## Ressources

- [Documentation officielle Keycloak](https://www.keycloak.org/documentation)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [OpenID Connect Specification](https://openid.net/connect/)
- [JWT.io - Decoder de tokens](https://jwt.io)

---

## Prochaines étapes

- Intégrer Keycloak dans votre application (Spring Boot, Node.js, React, etc.)
- Configurer des rôles et permissions
- Mettre en place la fédération d'identité (LDAP, Active Directory)
- Configurer le SSO (Single Sign-On)
- Migrer vers une configuration de production