# Event Sourcing

## Concept

**Event Sourcing** consiste à persister l'état d'une application sous forme d'une **séquence d'événements** plutôt que l'état actuel. Chaque changement est capturé comme un événement immuable.

:::tip Principe
Au lieu de sauvegarder "Compte = 100€", on sauvegarde : "Crédit 50€", "Débit 20€", "Crédit 70€"
:::

## 🎯 Comparaison

### Approche traditionnelle (CRUD)

```sql
-- État actuel seulement
UPDATE accounts SET balance = 100 WHERE id = 123;
```

**Perte d'information :** On ne sait pas comment on est arrivé à 100€

### Event Sourcing

```javascript
events = [
  { type: 'AccountCreated', amount: 0, timestamp: '2024-01-01' },
  { type: 'MoneyDeposited', amount: 150, timestamp: '2024-01-02' },
  { type: 'MoneyWithdrawn', amount: 50, timestamp: '2024-01-03' }
];

// Balance actuelle = somme des événements
balance = events.reduce((sum, e) => {
  if (e.type === 'MoneyDeposited') return sum + e.amount;
  if (e.type === 'MoneyWithdrawn') return sum - e.amount;
  return sum;
}, 0); // = 100
```

## 🏗️ Architecture

### Event Store

Base de données append-only qui stocke les événements

```javascript
class EventStore {
  async append(streamId, event) {
    await db.events.insert({
      streamId: streamId,
      eventType: event.type,
      data: event.data,
      timestamp: new Date(),
      version: await this.getNextVersion(streamId)
    });
  }
  
  async getEvents(streamId, fromVersion = 0) {
    return db.events.find({
      streamId: streamId,
      version: { $gte: fromVersion }
    }).sort({ version: 1 });
  }
}
```

### Reconstruction de l'état

```javascript
class Account {
  constructor() {
    this.balance = 0;
    this.version = 0;
  }
  
  // Appliquer un événement
  apply(event) {
    switch(event.type) {
      case 'MoneyDeposited':
        this.balance += event.amount;
        break;
      case 'MoneyWithdrawn':
        this.balance -= event.amount;
        break;
    }
    this.version = event.version;
  }
  
  // Rehydrater depuis l'Event Store
  static async load(accountId, eventStore) {
    const account = new Account();
    const events = await eventStore.getEvents(`account-${accountId}`);
    events.forEach(e => account.apply(e));
    return account;
  }
}
```

## ✅ Avantages

### 1. Audit trail complet

Historique immuable de tous les changements

```javascript
// Qui a fait quoi et quand ?
events.forEach(e => {
  console.log(`${e.timestamp}: ${e.type} by ${e.userId}`);
});
```

### 2. Temporal queries

Reconstruire l'état à n'importe quel moment

```javascript
// État du compte au 01/01/2024 ?
const pastState = events
  .filter(e => e.timestamp <= '2024-01-01')
  .reduce(applyEvent, initialState);
```

### 3. Event replay

Rejouer les événements pour :
- Corriger des bugs
- Migrer vers nouveau modèle
- Analytics

### 4. Multiple projections

Créer différentes vues des mêmes données

```javascript
// Projection 1: Solde actuel
const balance = computeBalance(events);

// Projection 2: Transactions par catégorie
const categories = groupByCategory(events);

// Projection 3: Graphe temporel
const timeSeriesData = aggregateByMonth(events);
```

## ⚠️ Inconvénients

### 1. Complexité

Plus difficile à comprendre que CRUD

### 2. Performance en lecture

Besoin de reconstruire l'état → utiliser des **snapshots**

```javascript
// Snapshot tous les 100 événements
if (version % 100 === 0) {
  await snapshotStore.save(accountId, currentState, version);
}

// Chargement optimisé
const snapshot = await snapshotStore.getLatest(accountId);
const events = await eventStore.getEvents(accountId, snapshot.version + 1);
const state = events.reduce(applyEvent, snapshot.state);
```

### 3. Évolution du schéma

Gérer la compatibilité des anciens événements

```javascript
// Upcasting : transformer vieux événements
const upcast = (event) => {
  if (event.version === 1) {
    // V1: { type: 'Deposit', amount: 100 }
    // V2: { type: 'Deposit', amount: 100, currency: 'EUR' }
    return { ...event, currency: 'EUR' };
  }
  return event;
};
```

## 🔧 Technologies

### EventStoreDB

Base de données dédiée à l'Event Sourcing

```javascript
const { EventStoreDBClient } = require('@eventstore/db-client');

const client = EventStoreDBClient.connectionString(
  'esdb://localhost:2113?tls=false'
);

// Append
await client.appendToStream('account-123', [
  {
    type: 'MoneyDeposited',
    data: { amount: 100 }
  }
]);

// Read
const events = client.readStream('account-123');
for await (const event of events) {
  console.log(event);
}
```

### Axon Framework (Java)

```java
@Aggregate
public class Account {
    @AggregateIdentifier
    private String accountId;
    private BigDecimal balance;
    
    @CommandHandler
    public Account(CreateAccountCommand cmd) {
        apply(new AccountCreatedEvent(cmd.getAccountId()));
    }
    
    @CommandHandler
    public void handle(DepositMoneyCommand cmd) {
        apply(new MoneyDepositedEvent(cmd.getAmount()));
    }
    
    @EventSourcingHandler
    public void on(MoneyDepositedEvent event) {
        this.balance = this.balance.add(event.getAmount());
    }
}
```

### Kafka comme Event Store

```javascript
// Publier événement
await producer.send({
  topic: 'account-events',
  messages: [{
    key: accountId,
    value: JSON.stringify({
      type: 'MoneyDeposited',
      amount: 100
    })
  }]
});

// Consommer et reconstruire état
consumer.on('message', (message) => {
  const event = JSON.parse(message.value);
  projection.apply(event);
});
```

## 🎨 Patterns combinés

### Event Sourcing + CQRS

- **Write side** : Event Store
- **Read side** : Projections optimisées (SQL, Elasticsearch, etc.)

```javascript
// Write: Append event
await eventStore.append('order-123', new OrderPlacedEvent(...));

// Read: Projection précalculée
const order = await readModel.getOrder('order-123'); // Instantané
```

### Event Sourcing + Saga

Les événements déclenchent les étapes de saga

```javascript
eventBus.subscribe('OrderPlaced', async (event) => {
  await saga.start(new ReserveInventorySagaStep(event.orderId));
});
```

## ✅ Bonnes pratiques

1. **Événements immuables** : jamais modifier un événement publié
2. **Événements métier** : nommer selon le langage du domaine
3. **Idempotence** : supporter le replay sans effets de bord
4. **Versioning** : inclure version dans l'événement
5. **Snapshots** : optimiser les reconstructions longues
6. **Projections asynchrones** : découpler lecture/écriture

## 📊 Quand utiliser ?

### ✅ Cas appropriés

- Audit légal obligatoire
- Domaines complexes (finance, e-commerce)
- Besoin d'historique complet
- Analytics temporels

### ❌ Éviter si

- CRUD simple suffit
- Équipe sans expertise
- Contraintes de performance strictes
- Données peu événementielles

## Ressources

- [Event Sourcing - Martin Fowler](https://martinfowler.com/eaaDev/EventSourcing.html)
- [EventStoreDB](https://www.eventstore.com/)
- [Implementing Domain-Driven Design (Book)](https://www.amazon.com/Implementing-Domain-Driven-Design-Vaughn-Vernon/dp/0321834577)