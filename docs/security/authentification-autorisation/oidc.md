---
sidebar_position: 2
---
# OpenID Connect (OIDC)

## Introduction

OpenID Connect (OIDC) est une couche d'**identité** construite au-dessus d'OAuth 2.0. Alors qu'OAuth 2.0 gère l'**autorisation** (accès aux ressources), OIDC ajoute l'**authentification** (vérification de l'identité de l'utilisateur).

## OAuth 2.0 vs OIDC

| Aspect | OAuth 2.0 | OpenID Connect |
|--------|-----------|----------------|
| **Objectif** | Autorisation | Authentification + Autorisation |
| **Réponse** | Access token | Access token + **ID token** |
| **Use case** | "Accéder à mes photos" | "Qui suis-je ?" |
| **Information** | Permissions | Identité utilisateur |

:::tip
**En résumé** : OIDC = OAuth 2.0 + Authentification
:::

## Concepts Clés

### Les Acteurs

- **End User** : L'utilisateur final qui s'authentifie
- **Relying Party (RP)** : L'application cliente (équivalent du "Client" OAuth)
- **OpenID Provider (OP)** : Le serveur d'identité (équivalent de l'"Authorization Server")

### Les Tokens

#### ID Token
**Le cœur d'OIDC** : Un JWT signé contenant les informations d'identité de l'utilisateur.

Exemple de contenu :
```json
{
  "iss": "https://auth.example.com",
  "sub": "248289761001",
  "aud": "my_client_id",
  "exp": 1311281970,
  "iat": 1311280970,
  "name": "John Doe",
  "email": "john.doe@example.com",
  "email_verified": true,
  "picture": "https://example.com/avatar.jpg"
}
```

**Claims standards** :
- `iss` : Issuer (qui a émis le token)
- `sub` : Subject (identifiant unique de l'utilisateur)
- `aud` : Audience (pour quelle application)
- `exp` : Expiration timestamp
- `iat` : Issued at (date d'émission)
- `nonce` : Protection contre les attaques replay

#### Access Token
Identique à OAuth 2.0, utilisé pour accéder aux ressources protégées.

#### Refresh Token
Identique à OAuth 2.0, permet d'obtenir de nouveaux tokens.

### Les Scopes OIDC

OIDC définit des scopes standards :

- `openid` : **Obligatoire** - Active OIDC et retourne l'ID token
- `profile` : Infos de profil (name, family_name, given_name, picture, etc.)
- `email` : Adresse email et statut de vérification
- `address` : Adresse postale
- `phone` : Numéro de téléphone

### UserInfo Endpoint

Endpoint standard pour récupérer des informations supplémentaires sur l'utilisateur.

## Les Flux OIDC

### Authorization Code Flow

**Cas d'usage** : Applications web avec backend, le plus sécurisé

**Particularité OIDC** : Retourne un ID token en plus de l'access token

```mermaid
sequenceDiagram
    participant U as End User
    participant RP as Relying Party (App)
    participant OP as OpenID Provider
    participant UI as UserInfo Endpoint

    U->>RP: 1. Clic "Se connecter"
    RP->>OP: 2. GET /authorize<br/>scope=openid profile email
    OP->>U: 3. Page de login
    U->>OP: 4. Authentification
    OP->>RP: 5. Redirect avec code
    RP->>OP: 6. POST /token<br/>échange code
    OP->>RP: 7. ID token + Access token + Refresh token
    RP->>RP: 8. Validation ID token (JWT)
    RP->>UI: 9. GET /userinfo (optionnel)
    UI->>RP: 10. Informations utilisateur
    RP->>U: 11. Session établie
```

**Étapes détaillées** :

1. L'utilisateur clique sur "Se connecter"
2. Redirection vers l'OP avec `scope=openid` (obligatoire)
3. L'utilisateur s'authentifie auprès de l'OP
4. Retour avec un authorization code
5. Échange du code contre les tokens
6. **Validation de l'ID token** (signature, expiration, issuer, audience)
7. Extraction des informations d'identité
8. Optionnel : appel à `/userinfo` pour plus de détails

---

### Implicit Flow

**Cas d'usage** : Applications SPA (Single Page Applications) - **Déprécié, utiliser Authorization Code + PKCE**

**⚠️ Déconseillé** : Moins sécurisé car les tokens transitent par l'URL

```mermaid
sequenceDiagram
    participant U as End User
    participant RP as Relying Party (SPA)
    participant OP as OpenID Provider

    U->>RP: 1. Clic "Se connecter"
    RP->>OP: 2. GET /authorize<br/>response_type=id_token token
    OP->>U: 3. Authentification
    OP->>RP: 4. Redirect avec ID token + Access token<br/>(dans le fragment URL #)
    RP->>RP: 5. Validation ID token
    RP->>U: 6. Session établie
```

:::warning
L'Implicit Flow est **déprécié**. Utilisez Authorization Code Flow + PKCE à la place.
:::

---

### Hybrid Flow

**Cas d'usage** : Applications nécessitant un accès immédiat à l'identité + sécurité backend

**Particularité** : Combine Authorization Code et Implicit Flow

```mermaid
sequenceDiagram
    participant U as End User
    participant RP as Relying Party
    participant OP as OpenID Provider

    U->>RP: 1. Demande d'authentification
    RP->>OP: 2. GET /authorize<br/>response_type=code id_token
    OP->>U: 3. Authentification
    OP->>RP: 4. Redirect avec code + ID token
    RP->>RP: 5. Validation ID token (frontend)
    RP->>OP: 6. Échange code (backend)
    OP->>RP: 7. Access token + Refresh token
```

**Response types disponibles** :
- `code id_token` : Code + ID token
- `code token` : Code + Access token
- `code id_token token` : Les trois

---

## Comparaison des Flux

| Flow | Tokens retournés | Sécurité | Recommandation |
|------|-----------------|----------|----------------|
| **Authorization Code** | Tous via /token | 🟢 Très haute | ✅ Recommandé |
| **Implicit** | Tous via URL fragment | 🔴 Faible | ❌ Déprécié |
| **Hybrid** | Mix des deux | 🟡 Moyenne | 🟡 Cas spécifiques |

## Exemples de Requêtes HTTP

### Authorization Code Flow

**Étape 1 : Redirection vers l'OpenID Provider**

```http
GET /authorize?response_type=code&client_id=my_app_id&redirect_uri=https://myapp.com/callback&scope=openid%20profile%20email&state=xyz123&nonce=abc789 HTTP/1.1
Host: auth.example.com
```

**Paramètres importants** :
- `scope=openid` : **Obligatoire** pour activer OIDC
- `nonce` : Valeur aléatoire pour lier la requête à l'ID token

**Étape 2 : Échange du code contre les tokens**

```http
POST /oauth/token HTTP/1.1
Host: auth.example.com
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=SplxlOBeZQQYbYS6WxSbIA
&client_id=my_app_id
&client_secret=my_app_secret
&redirect_uri=https://myapp.com/callback
```

**Réponse** :
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "tGzv3JOkF0XG5Qx2TlKWIA",
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2F1dGguZXhhbXBsZS5jb20iLCJzdWIiOiIyNDgyODk3NjEwMDEiLCJhdWQiOiJteV9hcHBfaWQiLCJleHAiOjEzMTEyODE5NzAsImlhdCI6MTMxMTI4MDk3MCwibm9uY2UiOiJhYmM3ODkiLCJuYW1lIjoiSm9obiBEb2UiLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWV9...",
  "scope": "openid profile email"
}
```

---

### Appel au UserInfo Endpoint

```http
GET /oauth/userinfo HTTP/1.1
Host: auth.example.com
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Réponse** :
```json
{
  "sub": "248289761001",
  "name": "John Doe",
  "given_name": "John",
  "family_name": "Doe",
  "email": "john.doe@example.com",
  "email_verified": true,
  "picture": "https://example.com/avatar.jpg",
  "locale": "fr-FR",
  "updated_at": 1311280970
}
```

---

### Implicit Flow (Déprécié)

```http
GET /authorize?response_type=id_token%20token&client_id=my_app_id&redirect_uri=https://myapp.com/callback&scope=openid%20profile&state=xyz123&nonce=abc789 HTTP/1.1
Host: auth.example.com
```

**Réponse** : Redirection vers
```
https://myapp.com/callback#
  id_token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
  &access_token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
  &token_type=Bearer
  &expires_in=3600
  &state=xyz123
```

---

### Hybrid Flow

```http
GET /authorize?response_type=code%20id_token&client_id=my_app_id&redirect_uri=https://myapp.com/callback&scope=openid%20profile%20email&state=xyz123&nonce=abc789 HTTP/1.1
Host: auth.example.com
```

**Réponse** : Redirection vers
```
https://myapp.com/callback?
  code=SplxlOBeZQQYbYS6WxSbIA
  &state=xyz123
#id_token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

### Décodage d'un ID Token

Un ID token est un JWT en 3 parties : `header.payload.signature`

**Header** (Base64 décodé) :
```json
{
  "alg": "RS256",
  "typ": "JWT",
  "kid": "key-id-123"
}
```

**Payload** (Base64 décodé) :
```json
{
  "iss": "https://auth.example.com",
  "sub": "248289761001",
  "aud": "my_app_id",
  "exp": 1735476000,
  "iat": 1735472400,
  "nonce": "abc789",
  "name": "John Doe",
  "email": "john.doe@example.com",
  "email_verified": true
}
```

**Signature** : Vérifiée avec la clé publique de l'OP

---

### Discovery Endpoint

OIDC fournit un endpoint de découverte automatique :

```http
GET /.well-known/openid-configuration HTTP/1.1
Host: auth.example.com
```

**Réponse** :
```json
{
  "issuer": "https://auth.example.com",
  "authorization_endpoint": "https://auth.example.com/authorize",
  "token_endpoint": "https://auth.example.com/oauth/token",
  "userinfo_endpoint": "https://auth.example.com/oauth/userinfo",
  "jwks_uri": "https://auth.example.com/.well-known/jwks.json",
  "response_types_supported": [
    "code",
    "token",
    "id_token",
    "code token",
    "code id_token",
    "token id_token",
    "code token id_token"
  ],
  "subject_types_supported": ["public"],
  "id_token_signing_alg_values_supported": ["RS256"],
  "scopes_supported": ["openid", "profile", "email", "address", "phone"],
  "claims_supported": [
    "sub",
    "iss",
    "aud",
    "exp",
    "iat",
    "name",
    "email",
    "email_verified"
  ]
}
```

---

### Récupération des clés publiques (JWKS)

```http
GET /.well-known/jwks.json HTTP/1.1
Host: auth.example.com
```

**Réponse** :
```json
{
  "keys": [
    {
      "kty": "RSA",
      "kid": "key-id-123",
      "use": "sig",
      "alg": "RS256",
      "n": "0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx...",
      "e": "AQAB"
    }
  ]
}
```

Ces clés permettent de **valider la signature des ID tokens**.

---

## Validation de l'ID Token

**Étapes critiques** :

1. ✅ Vérifier la signature JWT avec la clé publique de l'OP
2. ✅ Vérifier l'`iss` (issuer) correspond à l'OP attendu
3. ✅ Vérifier l'`aud` (audience) correspond au `client_id`
4. ✅ Vérifier que le token n'est pas expiré (`exp`)
5. ✅ Vérifier le `nonce` correspond à celui envoyé
6. ✅ Optionnel : vérifier l'`iat` (issued at)

:::danger
Ne **jamais** faire confiance à un ID token sans valider sa signature !
:::

## Sécurité - Bonnes Pratiques

### Toujours

- ✅ Valider la signature de l'ID token
- ✅ Utiliser HTTPS uniquement
- ✅ Vérifier tous les claims critiques (iss, aud, exp, nonce)
- ✅ Utiliser des `state` et `nonce` aléatoires et uniques
- ✅ Implémenter PKCE pour les applications publiques

### Authorization Code Flow

- ✅ Stocker le `client_secret` de manière sécurisée (backend uniquement)
- ✅ Valider le `redirect_uri`
- ✅ Ne jamais exposer l'ID token côté client si sensible

### Implicit Flow (à éviter)

- 🚫 Ne plus utiliser, préférer Authorization Code + PKCE
- ⚠️ Si utilisé : durée de vie très courte des tokens

### UserInfo

- ✅ Toujours utiliser HTTPS
- ✅ Comparer le `sub` du UserInfo avec celui de l'ID token

## OIDC vs OAuth 2.0 - Quand utiliser quoi ?

### Utiliser OAuth 2.0 pur quand :
- ❌ Vous n'avez pas besoin de connaître l'identité de l'utilisateur
- ✅ Vous voulez uniquement accéder à des ressources (API, données)
- ✅ Exemple : "Publier sur mon compte Twitter"

### Utiliser OIDC quand :
- ✅ Vous avez besoin d'authentifier l'utilisateur
- ✅ Vous voulez connaître "qui" est l'utilisateur
- ✅ Vous construisez un système de SSO (Single Sign-On)
- ✅ Exemple : "Se connecter avec Google"

### Utiliser les deux :
- ✅ Authentification de l'utilisateur (OIDC)
- ✅ + Accès à ses ressources (OAuth 2.0)
- ✅ Exemple : "Se connecter avec Google et accéder à Google Drive"

## Claims Standards

### Claims du profil (`profile` scope)

| Claim | Description | Exemple |
|-------|-------------|---------|
| `name` | Nom complet | "John Doe" |
| `given_name` | Prénom | "John" |
| `family_name` | Nom de famille | "Doe" |
| `middle_name` | Deuxième prénom | "William" |
| `nickname` | Surnom | "Johnny" |
| `preferred_username` | Nom d'utilisateur | "johndoe" |
| `profile` | URL du profil | "https://example.com/johndoe" |
| `picture` | URL de l'avatar | "https://example.com/avatar.jpg" |
| `website` | Site web | "https://johndoe.com" |
| `gender` | Genre | "male" / "female" |
| `birthdate` | Date de naissance | "1990-01-15" |
| `zoneinfo` | Fuseau horaire | "Europe/Paris" |
| `locale` | Langue | "fr-FR" |
| `updated_at` | Dernière MAJ | 1311280970 |

### Claims de l'email (`email` scope)

| Claim | Description | Exemple |
|-------|-------------|---------|
| `email` | Adresse email | "john@example.com" |
| `email_verified` | Email vérifié | true / false |

### Claims de l'adresse (`address` scope)

| Claim | Description |
|-------|-------------|
| `address` | Objet JSON contenant : `formatted`, `street_address`, `locality`, `region`, `postal_code`, `country` |

### Claims du téléphone (`phone` scope)

| Claim | Description | Exemple |
|-------|-------------|---------|
| `phone_number` | Numéro | "+33612345678" |
| `phone_number_verified` | Vérifié | true / false |

## Logout

### RP-Initiated Logout

L'application demande la déconnexion de l'utilisateur :

```http
GET /logout?id_token_hint=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...&post_logout_redirect_uri=https://myapp.com/goodbye&state=xyz123 HTTP/1.1
Host: auth.example.com
```

**Paramètres** :
- `id_token_hint` : L'ID token de l'utilisateur
- `post_logout_redirect_uri` : Où rediriger après logout
- `state` : Valeur de sécurité

### Front-Channel Logout

L'OP notifie toutes les applications que l'utilisateur s'est déconnecté via des iframes.

### Back-Channel Logout

L'OP envoie des notifications serveur-à-serveur aux applications.

## Ressources Supplémentaires

- [OpenID Connect Core Spec](https://openid.net/specs/openid-connect-core-1_0.html)
- [OpenID Connect Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html)
- [JWT.io](https://jwt.io) - Décoder et déboguer les JWT

---

## Glossaire

- **RP** : Relying Party - L'application cliente
- **OP** : OpenID Provider - Le serveur d'identité
- **JWT** : JSON Web Token - Format des ID tokens
- **JWK** : JSON Web Key - Clés publiques pour valider les JWT
- **JWKS** : JSON Web Key Set - Ensemble de clés publiques
- **SSO** : Single Sign-On - Authentification unique
- **Claims** : Attributs de l'utilisateur (nom, email, etc.)
- **Nonce** : Number used once - Protection contre replay attacks