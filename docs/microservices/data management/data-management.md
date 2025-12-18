---
sidebar_position: 4
---
# Data Management

## Introduction

La gestion des données dans une architecture microservices est un défi majeur. Contrairement aux monolithes avec une seule base de données, les microservices nécessitent des stratégies spécifiques pour maintenir la cohérence tout en préservant l'autonomie des services.

## 🎯 Principe fondamental

:::tip Database per Service
Chaque microservice possède sa **propre base de données** et ne doit jamais accéder directement à celle d'un autre service.
:::

## 🔗 Pourquoi séparer les bases de données ?

### 1. Découplage

- **Schéma indépendant** : modifications sans coordination entre équipes
- **Déploiements autonomes** : pas de migration BDD bloquante
- **Évolution technologique** : chaque service choisit sa stack

### 2. Scalabilité

- **Performance ciblée** : optimisation par service
- **Charge distribuée** : pas de goulot d'étranglement unique
- **Scaling indépendant** : dimensionnement adapté aux besoins

### 3. Résilience

- **Isolation des pannes** : une BDD en panne n'affecte qu'un service
- **Blast radius limité** : corruption de données localisée

## 🗄️ Stratégies de séparation

| Niveau | Description | Avantages | Inconvénients |
|--------|-------------|-----------|---------------|
| **Schéma dédié** | Schémas différents, même serveur BDD | Simple, coût réduit | Accès non contrôlés possibles |
| **Base par service** | Bases séparées, serveur partagé | Séparation logique claire | Couplage physique |
| **Serveur par service** | Base + serveur dédiés | Isolation maximale | Coût et complexité élevés |

## 🧩 Polyglot Persistence

Chaque service peut choisir la technologie de base de données la plus adaptée à son besoin.

### Exemples

| Service | Type de données | Technologie recommandée |
|---------|----------------|-------------------------|
| **Catalogue produits** | Documents structurés | MongoDB, PostgreSQL (JSONB) |
| **Panier** | Cache temporaire, TTL | Redis, Memcached |
| **Recommandations** | Graphe de relations | Neo4j, Amazon Neptune |
| **Transactions** | ACID strict | PostgreSQL, MySQL |
| **Logs/Metrics** | Time-series | InfluxDB, TimescaleDB |
| **Search** | Full-text search | Elasticsearch, OpenSearch |

## ⚠️ Défis et solutions

### 1. Transactions distribuées

**Problème :** Pas de transaction ACID globale entre services

**Solutions :**
- [Saga Pattern](../patterns/saga.md) - Compensation en cas d'échec
- [Event Sourcing](../patterns/event-sourcing.md) - Source de vérité unique
- Eventual Consistency - Accepter la cohérence différée

### 2. Requêtes multi-services

**Problème :** Impossible de faire un JOIN entre bases

**Solutions :**

#### API Composition
Le service agrégateur interroge plusieurs services
```python
def get_order_details(order_id):
    order = order_service.get(order_id)
    user = user_service.get(order.user_id)
    products = product_service.get_many(order.product_ids)
    return aggregate(order, user, products)
```

#### CQRS (Command Query Responsibility Segregation)
Vues matérialisées en lecture
- Base d'écriture normalisée par service
- Base de lecture dénormalisée pour requêtes complexes

#### Data Duplication
Dupliquer les données essentielles
```json
{
  "order_id": "123",
  "user_id": "456",
  "user_name": "John Doe",  // Dupliqué du user service
  "user_email": "john@example.com"  // Dupliqué
}
```

### 3. Cohérence des données

**Problème :** Données synchronisées entre services

**Solutions :**

#### Event-Driven Updates
```javascript
// User Service publie un événement
eventBus.publish('user.updated', {
  user_id: '456',
  name: 'Jane Doe',
  email: 'jane@example.com'
});

// Order Service écoute et met à jour sa copie
eventBus.subscribe('user.updated', (event) => {
  updateUserInfoInOrders(event.user_id, event);
});
```

#### Change Data Capture (CDC)
- Debezium capture les changements dans la BDD
- Publie automatiquement les événements
- Services consommateurs se synchronisent

## 🔄 Patterns de cohérence

### Eventual Consistency

Accepter que les données soient temporairement incohérentes

**Avantages :**
- Haute disponibilité
- Meilleure performance
- Scalabilité

**Inconvénients :**
- Complexité métier
- UI doit gérer l'état transitoire

**Exemple :** Système bancaire
```
1. Débit compte A → succès
2. Crédit compte B → succès (avec délai)
3. État transitoire visible pendant quelques secondes
```

### Strong Consistency

Cohérence immédiate (2PC, Saga synchrone)

**Usage :** Transactions critiques uniquement (paiements, stocks)

## 📊 Monitoring et observabilité

### Métriques importantes

- **Replication lag** : délai de synchronisation
- **Consistency violations** : incohérences détectées
- **Query performance** : temps de réponse inter-services
- **Database connection pool** : saturation

### Outils

- **Distributed Tracing** : Jaeger, Zipkin
- **Logs centralisés** : ELK Stack, Splunk
- **Métriques** : Prometheus, Grafana

## ✅ Bonnes pratiques

1. **Commencer simple** : une base partagée initialement, puis séparer progressivement
2. **Définir les boundaries** : aligner les services avec les domaines métier (DDD)
3. **Accepter la duplication** : préférer la duplication au couplage
4. **Eventual consistency by default** : cohérence forte seulement si nécessaire
5. **Versionner les schémas** : migrations sans downtime
6. **Audit trail** : traçabilité des changements critiques

## Ressources

- [Pattern: Database per service](https://microservices.io/patterns/data/database-per-service.html)
- [Martin Fowler - Polyglot Persistence](https://martinfowler.com/bliki/PolyglotPersistence.html)
- [Event-Driven Architecture](https://martinfowler.com/articles/201701-event-driven.html)