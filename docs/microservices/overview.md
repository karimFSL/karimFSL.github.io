---
sidebar_position: 1
---

# Concepts Microservices

## 🔁 DRY (Don't Repeat Yourself)

Principe partagé par l'Agilité et la programmation orientée objet.

**Objectif :** éviter la duplication de code → créer des composants réutilisables.

:::warning Attention
Trop de factorisation (ex : classes utilitaires globales) peut casser le découplage entre modules. En microservices, **la modularité et l'indépendance priment sur la factorisation extrême**.
:::

## 🧩 Principes des Microservices

### ✅ Principes fondamentaux

- **Minimal mais complet** : Chaque microservice couvre une fonction métier précise ou une préoccupation transverse
- **Autonome & indépendant** : Développement et déploiement séparés
- **Scalable automatiquement** : Mise à l'échelle facilitée
- **Exposition d'une API simple** : Communication claire entre microservices
- **Résilient** : Faible couplage – une panne ne bloque pas l'ensemble du système

### Organisation du développement

**Répartition par domaines fonctionnels :** Un service = un processus métier

**Équipes alignées avec l'architecture :**
- Déploiements indépendants
- Cycles courts de développement
- Isolation des bugs
- Testabilité accrue

## 📡 Communication entre services

### Types de communication

- **Synchrone** : REST, gRPC, Thrift
- **Asynchrone** : AMQP, Kafka, STOMP

### Formats de données

- **Texte** : JSON/XML (lisibles, mais plus lourds)
- **Binaire** : Avro/Protobuf (compacts et performants)

## 🗃 Gestion des Bases de Données

### ✅ Principe fondamental

:::tip Règle d'or
Chaque microservice doit posséder **sa propre base de données** et ne jamais accéder directement à celle d'un autre service.
:::

### 🎯 Pourquoi une base par microservice ?

#### 🔗 1. Découplage fort

- Si deux microservices partagent une base, ils deviennent étroitement liés
- Une modification de schéma pour un service peut casser l'autre service
- **Résultat** : les déploiements doivent être coordonnés, ce qu'on veut éviter en microservices

#### ⚙️ 2. Polyglot Persistence

- Chaque service peut choisir le type de base de données adapté à son besoin (SQL, NoSQL, Graph, etc.)
- Plus besoin de faire des compromis technologiques entre services

#### 🚀 3. Performance & scalabilité

- Chaque base peut être hébergée et optimisée indépendamment
- Meilleure répartition de charge et montée en charge plus fine

### 🧱 Niveaux de séparation possibles

| Architecture | Avantages | Inconvénients |
|-------------|-----------|---------------|
| **1 base / microservice** | Indépendance, cohérence métier | Complexité de synchronisation, pas d'ACID global |
| **BDD partagée** | Simplicité d'accès concurrent | Couplage fort, goulot d'étranglement |

| Niveau de séparation | Description | Avantages | Inconvénients |
|---------------------|-------------|-----------|---------------|
| **Schéma par service** | Schéma dédié dans une même BDD | Facile à mettre en place | Risque d'accès non contrôlé entre schémas |
| **BDD par service** | Chaque service a sa propre base sur le même serveur | Meilleure séparation logique | Couplage physique possible |
| **Serveur BDD par service** | Base + serveur dédiés par service | Isolation maximale, performance | Coût et complexité accrus |

### 🛠 Patterns utiles

- **Saga Pattern**
- **CQRS** (Command Query Responsibility Segregation)
- **Eventual Consistency**

## 🚀 Indicateurs DORA

Les 4 métriques clés pour mesurer la performance DevOps :

1. **Fréquence de déploiement**
2. **Lead Time for Changes**
3. **Taux d'échec des déploiements**
4. **Temps de restauration de service**

🔄 **Objectif** : améliorer la rapidité, la stabilité et la résilience des livraisons logicielles.

### 💡 Conditions pour la performance d'équipe

- Développement, test et déploiement indépendants entre équipes
- Boucles de feedback rapides et pipelines de déploiement efficaces
- Adoption facilitée de technologies variées selon les sous-domaines
- Possibilité de faire évoluer les stacks techniques par microservice

## 🧱 Limites des monolithes

- **Complexité croissante** → difficile à maintenir, démarrage lent
- **Déploiements lourds** → pas de déploiement partiel
- **Manque de scalabilité fine** → Mauvais ajustement aux infrastructures spécifiques
- **Faible fiabilité** → Un bug dans un module peut faire planter tout le système
- **Verrou technologique** → migration difficile

## 🧩 Avantages des microservices

### 🔹 Modularité & simplicité
- Développement par domaine métier
- Maintenance ciblée et simplifiée

### 🔹 Indépendance technologique
- Chaque service choisit sa stack (polyglot persistence)

### 🔹 Déploiement indépendant
- Favorise l'intégration continue et l'A/B testing

### 🔹 Scalabilité spécifique
- Chaque service peut être optimisé matériellement

## ⚠️ Inconvénients des microservices

### 🔸 Complexité accrue
- Tests plus complexes
- Coordination multi-services difficile (nécessite API Gateway, Service Discovery pour gérer dynamiquement les adresses réseau)

### 🔸 Gestion des pannes
- Services distants → timeouts, défaillances partielles

**Solutions :**
- Timeout, limites de requêtes
- Circuit breaker (ex: Hystrix, resilience4j)
- Fallbacks (cache, valeurs par défaut)

## 🔌 Inter-Process Communication (IPC)

Dans un système distribué, chaque microservice est un processus indépendant. Il faut donc choisir un mécanisme de communication entre services (IPC).

### 🧭 Deux dimensions

#### 1. Relation
- **Un-à-un** : une requête → un service
- **Un-à-plusieurs** : une requête → plusieurs services

#### 2. Type
- **Synchrone** : le client attend la réponse
- **Asynchrone** : le client n'attend pas, la réponse peut arriver plus tard

### 📬 Types d'interactions

| Type | Description |
|------|-------------|
| **Request/Response** | Le client envoie une requête et attend une réponse |
| **Notification** | Envoi sans réponse attendue (fire and forget) |
| **Request/Async Response** | Requête envoyée, réponse reçue plus tard sans bloquer le client |
| **Publish/Subscribe** | Diffusion d'un message à plusieurs services abonnés |
| **Publish/Async Response** | Le client attend des réponses de plusieurs services pendant un temps donné |

### Exemple d'usage

Un smartphone demande un trajet :

1. Il notifie le service de gestion des trajets
2. Celui-ci appelle (en request/response) le service passager pour vérifier le compte
3. Puis il publie une demande de prise en charge → notification aux services de dispatch

### 🧰 Technologies IPC

| Type | Exemples | Description |
|------|----------|-------------|
| **Synchrone** | REST, gRPC, Thrift | Appels immédiats, simples à implémenter |
| **Asynchrone** | AMQP, Kafka, STOMP | Pour les événements, meilleure résilience |

## 🔄 Évolution des APIs

### 1. Complexité liée à l'évolution

- **Monolithe** : simple → on met à jour une seule base de code
- **Microservices** : complexe → services versionnés, clients multiples, déploiements progressifs

### 2. Compatibilité ascendante (Backward Compatibility)

➕ Ajout d'attributs dans une requête ou réponse existante

**Règles :**
- Les clients doivent ignorer les champs inconnus
- Les services doivent fournir des valeurs par défaut pour les champs manquants

:::tip Principe de robustesse (Postel's law)
« Sois tolérant en réception, strict en émission. »
:::

### 3. Changements incompatibles

**Exemple :** suppression ou modification d'un champ obligatoire

**🎯 Solution : versionnement de l'API**
- Ex : `/v1/products`, `/v2/products`

Un service peut :
- Gérer plusieurs versions en parallèle
- Ou déployer plusieurs instances spécialisées par version

## ❌ Gestion des défaillances partielles (Partial Failures)

Un microservice peut ne pas répondre. Sans précaution, cela plante tout le système.

### Stratégies de résilience

| Stratégie | Description |
|-----------|-------------|
| **⏳ Timeouts** | Ne jamais attendre indéfiniment une réponse |
| **🚫 Limites de requêtes** | Bloquer de nouvelles requêtes si un service est saturé |
| **💥 Circuit Breaker** | Couper automatiquement les appels vers un service en échec répétitif |
| **🧰 Fallbacks** | Utiliser des données en cache ou des valeurs par défaut en cas d'échec |

### Détail des stratégies

#### 1. Timeout réseau

❌ Ne jamais bloquer indéfiniment  
✅ Toujours définir un timeout  
🧵 Évite de saturer les threads d'exécution

#### 2. Limite de requêtes simultanées

- Mettre un quota de requêtes en vol par client ou service
- Ne pas envoyer une requête si on sait qu'elle va échouer (file pleine)

#### 3. Circuit Breaker Pattern

⛔ Trop d'échecs → on coupe temporairement l'accès au service  
🔁 Après une durée, on réessaye  
✅ Si succès, on réouvre le circuit

**📦 Outils :** Hystrix (JVM) ou équivalent dans d'autres stacks (ex: resilience4j, Polly, Istio...)

#### 4. Fallbacks

🔙 Fournir une valeur de secours

**Exemple :** Si le service de recommandations est en panne :
- Retourner une liste vide au lieu de bloquer toute la page produit
- Utiliser des données en cache
- Afficher un message d'erreur simple

## 🗄 Comparaison : Monolithe vs Microservices

### 🏢 Architecture Monolithe

- 1 seule BDD relationnelle
- Accès ACID classique avec transactions :
  - **A**tomicité
  - **C**ohérence
  - **I**solation
  - **D**urabilité

### 🧩 Architecture Microservices

Chaque service a sa propre base privée (pas d'accès partagé)

**Avantages :**
- Faible couplage
- Autonomie
- Meilleure scalabilité

**Inconvénients :**
- Transactions distribuées difficiles (pas de 2PC dans NoSQL)
- Requêtes inter-services complexes

---

## Ressources complémentaires

- [Pattern: Database per service](https://microservices.io/patterns/data/database-per-service.html)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [DORA Metrics](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)