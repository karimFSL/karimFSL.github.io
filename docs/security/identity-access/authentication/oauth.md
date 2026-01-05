---
sidebar_position: 1
---
# OAuth 2.0

## Introduction

OAuth 2.0 est un protocole d'autorisation qui permet à des applications tierces d'accéder aux ressources d'un utilisateur sans exposer ses identifiants. Il est devenu le standard de facto pour l'autorisation sur le web.

## Concepts Clés

### Les Acteurs (Roles)

- **Resource Owner** : L'utilisateur qui possède les données
- **Client** : L'application qui souhaite accéder aux ressources
- **Authorization Server** : Le serveur qui authentifie l'utilisateur et délivre les tokens
- **Resource Server** : Le serveur qui héberge les ressources protégées

### Les Tokens

#### Access Token
Token utilisé pour accéder aux ressources protégées. Il a une durée de vie limitée (généralement courte).

#### Refresh Token
Token optionnel utilisé pour obtenir un nouvel access token sans ré-authentification. Plus longue durée de vie.

### Les Scopes

Les scopes définissent les permissions accordées. Exemples : `read:user`, `write:posts`, `admin:all`

## Les Flux d'Autorisation (Grant Types)

### Authorization Code Flow

**Cas d'usage** : Applications web avec backend sécurisé, applications mobiles natives

**Avantages** : Le plus sécurisé, le client ne voit jamais les credentials de l'utilisateur

```mermaid
sequenceDiagram
    participant U as User
    participant C as Client App
    participant AS as Authorization Server
    participant RS as Resource Server

    U->>C: 1. Demande d'accès
    C->>AS: 2. Redirection vers /authorize
    AS->>U: 3. Page de login/consentement
    U->>AS: 4. Authentification + accord
    AS->>C: 5. Redirection avec code
    C->>AS: 6. Échange code contre tokens<br/>(+ client_secret)
    AS->>C: 7. Access token + refresh token
    C->>RS: 8. Requête avec access token
    RS->>C: 9. Ressource protégée
```

**Étapes détaillées** :

1. L'utilisateur clique sur "Se connecter avec..."
2. Redirection vers l'authorization server avec les paramètres :
   - `response_type=code`
   - `client_id`
   - `redirect_uri`
   - `scope`
   - `state` (protection CSRF)
3. L'utilisateur s'authentifie et autorise l'application
4. Redirection vers le client avec un code d'autorisation
5. Le client échange le code contre un access token (requête backend)
6. Le client peut maintenant accéder aux ressources

---

### Client Credentials Flow

**Cas d'usage** : Communication machine-to-machine, services backend, jobs automatisés

**Avantages** : Simple, pas d'interaction utilisateur nécessaire

```mermaid
sequenceDiagram
    participant C as Client App
    participant AS as Authorization Server
    participant RS as Resource Server

    C->>AS: 1. POST /token<br/>grant_type=client_credentials<br/>client_id + client_secret
    AS->>AS: 2. Vérification des credentials
    AS->>C: 3. Access token
    C->>RS: 4. Requête avec access token
    RS->>C: 5. Ressource protégée
```

**Étapes détaillées** :

1. Le client envoie directement ses credentials (`client_id` + `client_secret`)
2. L'authorization server vérifie les credentials
3. Un access token est retourné (pas de refresh token généralement)
4. Le client utilise l'access token pour accéder aux ressources

**Exemple de requête** :
```http
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id=my_client_id
&client_secret=my_client_secret
&scope=api:read
```

---

### Resource Owner Password Credentials (ROPC)

**Cas d'usage** : Applications de première partie (first-party), migration depuis systèmes legacy

**⚠️ Attention** : Déconseillé car le client manipule directement les credentials de l'utilisateur

```mermaid
sequenceDiagram
    participant U as User
    participant C as Client App (trusted)
    participant AS as Authorization Server
    participant RS as Resource Server

    U->>C: 1. Entre username + password
    C->>AS: 2. POST /token<br/>grant_type=password<br/>username + password + client_id
    AS->>AS: 3. Vérification credentials
    AS->>C: 4. Access token + refresh token
    C->>RS: 5. Requête avec access token
    RS->>C: 6. Ressource protégée
```

**Étapes détaillées** :

1. L'utilisateur entre ses identifiants directement dans l'application
2. Le client envoie les credentials à l'authorization server
3. Si valides, un access token (et éventuellement refresh token) est retourné
4. Le client utilise l'access token normalement

**Exemple de requête** :
```http
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=password
&username=user@example.com
&password=secret123
&client_id=my_client_id
&scope=read write
```

**Pourquoi c'est déconseillé** :
- Le client voit le mot de passe de l'utilisateur
- Pas de MFA possible
- Moins sécurisé que Authorization Code Flow

---

## Comparaison des Flux

| Flow | Interaction User | Sécurité | Cas d'usage typique |
|------|-----------------|----------|---------------------|
| **Authorization Code** | ✅ Oui | 🟢 Très haute | Apps web, mobiles |
| **Client Credentials** | ❌ Non | 🟢 Haute | Services backend |
| **Password Grant** | ✅ Oui | 🟡 Moyenne | Apps first-party (legacy) |

## Sécurité - Bonnes Pratiques

### Pour tous les flux

- ✅ Toujours utiliser HTTPS
- ✅ Valider les redirect URIs
- ✅ Implémenter une expiration des tokens
- ✅ Stocker les secrets de manière sécurisée

### Authorization Code Flow

- ✅ Utiliser le paramètre `state` pour prévenir CSRF
- ✅ Implémenter PKCE (Proof Key for Code Exchange) pour les apps mobiles
- ✅ Ne jamais exposer le `client_secret` côté client

### Client Credentials

- ✅ Rotation régulière des secrets
- ✅ Limiter les scopes au strict nécessaire
- ✅ Monitoring des accès

### Password Grant

- 🚫 À éviter si possible, préférer Authorization Code Flow
- ✅ Si utilisé : uniquement pour applications de confiance absolue
- ✅ Implémenter rate limiting pour prévenir brute force

## Refresh Token Flow

Lorsque l'access token expire, utilisez le refresh token :

```mermaid
sequenceDiagram
    participant C as Client App
    participant AS as Authorization Server

    C->>AS: POST /token<br/>grant_type=refresh_token<br/>refresh_token=...
    AS->>AS: Vérification refresh token
    AS->>C: Nouvel access token<br/>(+ nouveau refresh token optionnel)
```

## Exemples de Requêtes HTTP

### Authorization Code Flow

**Étape 1 : Redirection vers l'authorization server**

```
GET /authorize?response_type=code&client_id=my_app_id&redirect_uri=https://myapp.com/callback&scope=read:user%20write:posts&state=xyz123 HTTP/1.1
Host: auth.example.com
```

**Étape 2 : Échange du code contre un token**

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
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "tGzv3JOkF0XG5Qx2TlKWIA",
  "scope": "read:user write:posts"
}
```

---

### Client Credentials Flow

```http
POST /oauth/token HTTP/1.1
Host: auth.example.com
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id=service_app_id
&client_secret=service_app_secret
&scope=api:read api:write
```

**Réponse** :
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 7200,
  "scope": "api:read api:write"
}
```

---

### Password Grant Flow

```http
POST /oauth/token HTTP/1.1
Host: auth.example.com
Content-Type: application/x-www-form-urlencoded

grant_type=password
&username=user@example.com
&password=secret123
&client_id=trusted_app_id
&scope=read write
```

**Réponse** :
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "tGzv3JOkF0XG5Qx2TlKWIA",
  "scope": "read write"
}
```

---

### Refresh Token Flow

```http
POST /oauth/token HTTP/1.1
Host: auth.example.com
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=tGzv3JOkF0XG5Qx2TlKWIA
&client_id=my_app_id
&client_secret=my_app_secret
```

**Réponse** :
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "8xLOxBtZp8rrJnZ4GsdU3V"
}
```

---

### Utilisation de l'Access Token

**Requête authentifiée vers une API protégée** :

```http
GET /api/user/profile HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Réponse** :
```json
{
  "id": "123456",
  "name": "John Doe",
  "email": "john.doe@example.com"
}
```

---

### Révocation de Token

```http
POST /oauth/revoke HTTP/1.1
Host: auth.example.com
Content-Type: application/x-www-form-urlencoded

token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
&token_type_hint=access_token
&client_id=my_app_id
&client_secret=my_app_secret
```

## Ressources Supplémentaires

- [RFC 6749 - OAuth 2.0 Framework](https://datatracker.ietf.org/doc/html/rfc6749)
- [OAuth 2.0 Security Best Practices](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [OAuth 2.1 (draft)](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-07)

---

## Glossaire

- **PKCE** : Proof Key for Code Exchange - Extension de sécurité pour apps mobiles/SPA
- **CSRF** : Cross-Site Request Forgery - Attaque web
- **JWT** : JSON Web Token - Format courant pour les access tokens
- **Bearer Token** : Type de token transmis dans le header Authorization