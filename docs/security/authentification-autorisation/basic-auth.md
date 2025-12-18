---
sidebar_position: 4
---
# Basic Authentication

## Introduction

Basic Authentication (ou HTTP Basic Auth) est la méthode d'authentification la plus simple du protocole HTTP. Elle consiste à envoyer un nom d'utilisateur et un mot de passe encodés en Base64 dans le header `Authorization` de chaque requête.

:::warning
Basic Auth est simple mais **peu sécurisé** si utilisé sans HTTPS. Les credentials sont simplement encodés, pas chiffrés.
:::

## Principe de Fonctionnement

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Serveur

    C->>S: 1. GET /api/resource
    S->>C: 2. 401 Unauthorized<br/>WWW-Authenticate: Basic realm="API"
    C->>C: 3. Encode(username:password) en Base64
    C->>S: 4. GET /api/resource<br/>Authorization: Basic dXNlcjpwYXNz
    S->>S: 5. Décode et vérifie credentials
    S->>C: 6. 200 OK + Ressource
```

**Étapes détaillées** :

1. Le client fait une requête sans authentification
2. Le serveur répond `401 Unauthorized` et demande l'authentification
3. Le client encode `username:password` en Base64
4. Le client renvoie la requête avec le header `Authorization`
5. Le serveur décode, vérifie les credentials
6. Si valide : accès accordé, sinon : 401 ou 403

## Concepts Clés

### Realm (Domaine)

Le `realm` définit une zone de protection. Il permet de :
- Grouper des ressources protégées
- Afficher un message personnalisé dans le navigateur
- Gérer différents espaces d'authentification

Exemple : `realm="Admin Area"` ou `realm="API Access"`

### Encodage Base64

**Important** : Base64 est un **encodage**, pas un **chiffrement** !

```
username:password → dXNlcm5hbWU6cGFzc3dvcmQ=
```

:::danger
Base64 peut être décodé instantanément. N'importe qui interceptant la requête peut lire les credentials.
**HTTPS est absolument obligatoire** avec Basic Auth.
:::

### Format du Header

```
Authorization: Basic <base64(username:password)>
```

## Exemples de Requêtes HTTP

### Première Requête (sans authentification)

```http
GET /api/users HTTP/1.1
Host: api.example.com
```

**Réponse du serveur** :
```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="API Access Required"
Content-Type: application/json

{
  "error": "Authentication required"
}
```

---

### Requête avec Basic Auth

```http
GET /api/users HTTP/1.1
Host: api.example.com
Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
```

**Calcul du header** :
1. Username : `username`
2. Password : `password`
3. Concaténation : `username:password`
4. Encodage Base64 : `dXNlcm5hbWU6cGFzc3dvcmQ=`

**Réponse en cas de succès** :
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "users": [
    {"id": 1, "name": "John Doe"},
    {"id": 2, "name": "Jane Smith"}
  ]
}
```

**Réponse en cas d'échec** :
```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="API Access Required"

{
  "error": "Invalid credentials"
}
```

---

### POST avec Basic Auth

```http
POST /api/users HTTP/1.1
Host: api.example.com
Authorization: Basic YWRtaW46c2VjcmV0MTIz
Content-Type: application/json

{
  "name": "Alice Johnson",
  "email": "alice@example.com"
}
```

**Réponse** :
```http
HTTP/1.1 201 Created
Location: /api/users/3
Content-Type: application/json

{
  "id": 3,
  "name": "Alice Johnson",
  "email": "alice@example.com"
}
```

---

### PUT avec Basic Auth

```http
PUT /api/users/3 HTTP/1.1
Host: api.example.com
Authorization: Basic YWRtaW46c2VjcmV0MTIz
Content-Type: application/json

{
  "name": "Alice Johnson-Smith",
  "email": "alice.smith@example.com"
}
```

---

### DELETE avec Basic Auth

```http
DELETE /api/users/3 HTTP/1.1
Host: api.example.com
Authorization: Basic YWRtaW46c2VjcmV0MTIz
```

**Réponse** :
```http
HTTP/1.1 204 No Content
```

---

## Encodage/Décodage Base64

### Encodage manuel

**Linux/Mac (terminal)** :
```bash
echo -n "username:password" | base64
# Résultat : dXNlcm5hbWU6cGFzc3dvcmQ=
```

**Windows (PowerShell)** :
```powershell
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("username:password"))
```

### Décodage manuel

**Linux/Mac (terminal)** :
```bash
echo "dXNlcm5hbWU6cGFzc3dvcmQ=" | base64 -d
# Résultat : username:password
```

**Windows (PowerShell)** :
```powershell
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("dXNlcm5hbWU6cGFzc3dvcmQ="))
```

---

## Configuration Postman

### Méthode 1 : Onglet Authorization

1. Sélectionner **Type** : `Basic Auth`
2. Entrer **Username** : `your_username`
3. Entrer **Password** : `your_password`
4. Postman génère automatiquement le header

### Méthode 2 : Header manuel

1. Onglet **Headers**
2. Key : `Authorization`
3. Value : `Basic dXNlcm5hbWU6cGFzc3dvcmQ=`

---

## Cas d'Usage

### ✅ Quand utiliser Basic Auth

- **APIs internes** : Communication entre services d'une même infrastructure
- **Prototypes et développement** : Tests rapides
- **Scripts et outils CLI** : Automatisation simple
- **Devices IoT** : Appareils avec capacités limitées
- **Webhooks simples** : Notifications entre services

### ❌ Quand ne PAS utiliser Basic Auth

- **APIs publiques** : Préférer OAuth 2.0 ou API Keys
- **Applications web grand public** : Utiliser session cookies ou JWT
- **Sans HTTPS** : JAMAIS (credentials en clair)
- **Besoins avancés** : Gestion de tokens, scopes, révocation

---

## Sécurité

### Vulnérabilités

#### 1. Transmission en clair (sans HTTPS)
```
❌ http://api.example.com
   Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
   → Interceptable par Man-in-the-Middle

✅ https://api.example.com
   Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
   → Chiffré par TLS
```

#### 2. Pas d'expiration
Les credentials sont valides indéfiniment jusqu'à changement de mot de passe.

#### 3. Pas de révocation
Impossible de révoquer un accès sans changer le mot de passe.

#### 4. Stockage dans le navigateur
Le navigateur peut mémoriser les credentials (cache, historique).

#### 5. Logs serveur
Les credentials peuvent apparaître dans les logs si mal configuré.

### Bonnes Pratiques

#### Obligatoires

- ✅ **TOUJOURS utiliser HTTPS** - Non négociable
- ✅ **Mots de passe forts** - Minimum 16 caractères, aléatoires
- ✅ **Hachage côté serveur** - Jamais stocker en clair (bcrypt, Argon2)
- ✅ **Rate limiting** - Limiter les tentatives de connexion
- ✅ **Monitoring** - Surveiller les échecs d'authentification

#### Recommandées

- ✅ **Comptes dédiés** - Un compte par service/application
- ✅ **Rotation des credentials** - Changement périodique
- ✅ **Least privilege** - Permissions minimales nécessaires
- ✅ **Timeouts** - Sessions avec durée limitée
- ✅ **Audit logs** - Tracer les accès

#### Avancées

- ✅ **IP whitelisting** - Limiter les IP autorisées
- ✅ **2FA si possible** - Authentification multi-facteurs
- ✅ **Alertes** - Notifier les accès suspects
- ✅ **Chiffrement des logs** - Protéger les logs d'accès

---

## Codes de Réponse HTTP

| Code | Signification | Description |
|------|---------------|-------------|
| **200** | OK | Authentification réussie |
| **201** | Created | Ressource créée avec succès |
| **204** | No Content | Opération réussie sans contenu |
| **401** | Unauthorized | Credentials manquants ou invalides |
| **403** | Forbidden | Authentifié mais pas autorisé |
| **429** | Too Many Requests | Rate limit dépassé |
| **500** | Internal Server Error | Erreur serveur |

---

## Comparaison avec d'autres méthodes

| Aspect | Basic Auth | API Key | OAuth 2.0 | JWT |
|--------|------------|---------|-----------|-----|
| **Complexité** | 🟢 Très simple | 🟢 Simple | 🔴 Complexe | 🟡 Moyenne |
| **Sécurité** | 🟡 Moyenne | 🟡 Moyenne | 🟢 Haute | 🟢 Haute |
| **Expiration** | ❌ Non | ❌ Non (sauf implémenté) | ✅ Oui | ✅ Oui |
| **Révocation** | ❌ Difficile | ✅ Facile | ✅ Facile | 🟡 Moyenne |
| **Granularité** | ❌ Tout ou rien | 🟡 Par clé | ✅ Scopes | ✅ Claims |
| **Use case** | APIs internes | APIs publiques | Auth utilisateur | Stateless auth |

---

## Exemples Avancés

### Basic Auth avec différents statuts

**Credentials invalides** :
```http
GET /api/admin HTTP/1.1
Host: api.example.com
Authorization: Basic d3JvbmdhY2NvdW50Ondyb25ncGFzcw==

→ HTTP/1.1 401 Unauthorized
```

**Utilisateur non autorisé** :
```http
GET /api/admin HTTP/1.1
Host: api.example.com
Authorization: Basic dXNlcjpwYXNzd29yZA==

→ HTTP/1.1 403 Forbidden
{
  "error": "Insufficient permissions",
  "message": "Admin access required"
}
```

**Rate limit dépassé** :
```http
GET /api/users HTTP/1.1
Host: api.example.com
Authorization: Basic dXNlcjpwYXNzd29yZA==

→ HTTP/1.1 429 Too Many Requests
Retry-After: 60
{
  "error": "Rate limit exceeded",
  "retry_after": 60
}
```

---

### Basic Auth avec paramètres de requête

```http
GET /api/users?page=2&limit=10&sort=name HTTP/1.1
Host: api.example.com
Authorization: Basic YWRtaW46c2VjcmV0MTIz
```

---

### Basic Auth avec headers personnalisés

```http
GET /api/users HTTP/1.1
Host: api.example.com
Authorization: Basic YWRtaW46c2VjcmV0MTIz
X-Request-ID: abc-123-def-456
X-Client-Version: 1.0.0
Accept: application/json
Accept-Language: fr-FR
```

---

### Authentification multi-niveaux

```http
GET /api/admin/critical HTTP/1.1
Host: api.example.com
Authorization: Basic c3VwZXJhZG1pbjpzdXBlcnNlY3JldA==
X-2FA-Token: 123456
```

---

## Configuration Serveur

### Apache (.htaccess)

```apache
AuthType Basic
AuthName "Restricted Area"
AuthUserFile /path/to/.htpasswd
Require valid-user
```

Création du fichier de mots de passe :
```bash
htpasswd -c /path/to/.htpasswd username
```

---

### Nginx

```nginx
location /api {
    auth_basic "API Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

---

### Headers de réponse typiques

**WWW-Authenticate** (lors d'un 401) :
```http
WWW-Authenticate: Basic realm="API Access", charset="UTF-8"
```

**Multiples realms** :
```http
WWW-Authenticate: Basic realm="Admin Area"
WWW-Authenticate: Basic realm="User Area"
```

---

## Migration vers des méthodes plus sécurisées

### De Basic Auth vers API Keys

**Avant** :
```http
Authorization: Basic dXNlcjpwYXNzd29yZA==
```

**Après** :
```http
X-API-Key: sk_live_test
```

### De Basic Auth vers Bearer Token

**Avant** :
```http
Authorization: Basic dXNlcjpwYXNzd29yZA==
```

**Après** :
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Dépannage

### Problème : 401 Unauthorized persistant

**Vérifications** :
1. ✅ Encodage Base64 correct ?
2. ✅ Format `username:password` respecté ?
3. ✅ Pas d'espaces superflus ?
4. ✅ Header `Authorization` présent ?
5. ✅ HTTPS activé ?

**Test de l'encodage** :
```bash
# Encoder
echo -n "admin:secret123" | base64
# YWRtaW46c2VjcmV0MTIz

# Décoder pour vérifier
echo "YWRtaW46c2VjcmV0MTIz" | base64 -d
# admin:secret123
```

### Problème : Caractères spéciaux dans le mot de passe

**Caractères à échapper** : `:`, `@`, `/`, etc.

Si le mot de passe contient `:`, cela pose problème car c'est le séparateur.

**Solution** : URL-encoder le mot de passe avant l'encodage Base64
```
Password: pass:word
→ pass%3Aword
→ username:pass%3Aword
→ Base64
```

---

## Glossaire

- **Base64** : Encodage (pas chiffrement) de données binaires en ASCII
- **Realm** : Zone de protection définie par le serveur
- **WWW-Authenticate** : Header indiquant le type d'authentification requis
- **Authorization** : Header contenant les credentials encodés
- **401 Unauthorized** : Authentification requise ou invalide
- **403 Forbidden** : Authentifié mais sans permission
- **Rate Limiting** : Limitation du nombre de requêtes par période

---

## Ressources Supplémentaires

- [RFC 7617 - HTTP Basic Authentication](https://datatracker.ietf.org/doc/html/rfc7617)
- [RFC 7235 - HTTP Authentication](https://datatracker.ietf.org/doc/html/rfc7235)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)