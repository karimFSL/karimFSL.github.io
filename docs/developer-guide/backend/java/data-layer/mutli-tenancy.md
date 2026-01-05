---
sidebar_position: 1
---

# Multi-Tenancy (Multi-Locataire)

Le multi-tenancy permet d'héberger une application unique pour plusieurs clients (tenants/locataires) tout en garantissant l'isolation de leurs données. Chaque tenant dispose de son propre espace isolé au sein de la même infrastructure.

## Cas d'usage

Vous développez une application SaaS que vous souhaitez proposer à plusieurs entreprises clientes. Chaque entreprise doit :
- Accéder à ses propres données de manière isolée
- Ne jamais voir les données des autres clients
- Bénéficier d'une expérience personnalisée

## Stratégies de Multi-Tenancy

### 1. Base de données par tenant (Database-per-tenant)

Chaque tenant possède sa propre base de données dédiée.

**Isolation** : ⭐⭐⭐⭐⭐ Maximale

**Fonctionnement** :
```
Tenant A → Database A
Tenant B → Database B  
Tenant C → Database C
```

**Avantages** :
- Isolation complète des données (sécurité maximale)
- Facilité de sauvegarde/restauration par tenant
- Migration simple d'un tenant vers une autre infrastructure
- Performance prévisible par tenant
- Personnalisation possible par client (versions de schéma différentes)

**Inconvénients** :
- Coût de maintenance élevé (multiplication des bases)
- Complexité de gestion avec un grand nombre de tenants
- Gestion des connexions complexe
- Migrations de schéma à répéter sur toutes les bases
- Coût d'infrastructure plus élevé

**Quand l'utiliser** :
- Petit nombre de tenants (< 100)
- Clients nécessitant une isolation stricte (banques, santé)
- Besoins de personnalisation forte par client

---

### 2. Schéma par tenant (Schema-per-tenant)

Une base de données unique avec un schéma distinct par tenant.

**Isolation** : ⭐⭐⭐⭐ Élevée

**Fonctionnement** :
```
Database unique
├── Schema tenant_a (tables users, orders...)
├── Schema tenant_b (tables users, orders...)
└── Schema tenant_c (tables users, orders...)
```

**Avantages** :
- Bon compromis isolation/performance
- Gestion simplifiée par rapport au database-per-tenant
- Une seule connexion à la base de données
- Backup centralisé possible
- Meilleure utilisation des ressources

**Inconvénients** :
- Complexité croissante avec le nombre de schémas
- Migrations de schéma à gérer pour chaque tenant
- Risque d'erreur de contexte (mauvais schéma)
- Limite du nombre de schémas selon le SGBD

**Quand l'utiliser** :
- Nombre moyen de tenants (100-1000)
- Besoin d'isolation sans coût d'infrastructure trop élevé
- PostgreSQL ou bases supportant bien les schémas multiples

---

### 3. Colonne discriminante (Shared Database with Discriminator)

Tous les tenants partagent les mêmes tables avec une colonne `tenant_id`.

**Isolation** : ⭐⭐ Logique uniquement

**Fonctionnement** :
```sql
Table users:
| id | name    | email          | tenant_id |
|----|---------|----------------|-----------|
| 1  | Alice   | a@tenant-a.com | tenant_a  |
| 2  | Bob     | b@tenant-b.com | tenant_b  |
| 3  | Charlie | c@tenant-a.com | tenant_a  |
```

**Avantages** :
- Simplicité de mise en œuvre
- Excellente scalabilité (milliers de tenants)
- Une seule base et un seul schéma
- Migrations simples
- Coût d'infrastructure minimal
- Requêtes cross-tenant possibles (analytics)

**Inconvénients** :
- Isolation faible (risque de fuite de données)
- Performance dégradée avec gros volume de données
- Index et requêtes plus complexes
- Nécessite une rigueur extrême dans le code
- Backup/restauration par tenant impossible
- Personnalisation par tenant limitée

**Implémentation critique** :
```java
// ❌ DANGER : Requête sans filtre tenant
@Query("SELECT u FROM User u")
List<User> findAll();

// ✅ OBLIGATOIRE : Toujours filtrer par tenant
@Query("SELECT u FROM User u WHERE u.tenantId = :tenantId")
List<User> findAllByTenant(@Param("tenantId") String tenantId);
```

**Quand l'utiliser** :
- Grand nombre de tenants (> 1000)
- Données similaires entre tenants
- Priorité à la scalabilité et au coût
- Application avec mesures de sécurité strictes au niveau code

---

## Tableau comparatif

| Critère | Database-per-tenant | Schema-per-tenant | Discriminator |
|---------|---------------------|-------------------|---------------|
| **Isolation** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Scalabilité** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Coût** | Élevé | Moyen | Faible |
| **Complexité** | Élevée | Moyenne | Faible |
| **Nb tenants max** | < 100 | 100-1000 | > 1000 |
| **Performance** | Excellente | Bonne | Variable |

## Recommandations

**Choisissez Database-per-tenant si** :
- Vous avez < 50 clients avec gros volumes de données
- Compliance stricte requise (RGPD, HIPAA)
- Budget infrastructure disponible

**Choisissez Schema-per-tenant si** :
- Vous avez 100-1000 clients
- Bon compromis isolation/coût recherché
- Vous utilisez PostgreSQL

**Choisissez Discriminator si** :
- Vous avez > 1000 clients
- Startups/MVP avec croissance rapide
- Coût d'infrastructure prioritaire
- Équipe mature en développement sécurisé

## Bonnes pratiques communes

1. **Identifiez le tenant dès l'authentification** et stockez-le dans le contexte de sécurité
2. **Utilisez des intercepteurs** pour injecter automatiquement le tenant dans les requêtes
3. **Testez l'isolation** avec des tests automatisés multi-tenants
4. **Auditez les accès** pour détecter les fuites de données potentielles
5. **Documentez** clairement la stratégie choisie pour toute l'équipe