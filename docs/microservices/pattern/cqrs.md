# CQRS (Command Query Responsibility Segregation)

## Concept

**CQRS** sépare les opérations de **lecture** (Query) et d'**écriture** (Command) en utilisant des modèles de données différents.

:::tip Principe
Un modèle optimisé pour l'écriture, un autre pour la lecture.
:::

## 🎯 Problème résolu

### Approche traditionnelle

```
┌──────────────────┐
│  API Controller  │
└────────┬─────────┘
         │
    ┌────▼────┐
    │ Service │
    └────┬────┘
         │
    ┌────▼────┐
    │   BDD   │  ◄── Même modèle lecture/écriture
    └─────────┘
```

**Problèmes :**
- Modèle de données compromis entre lecture et écriture
- Requêtes complexes avec JOINs multiples
- Scaling difficile (même BDD pour tout)

### Avec CQRS

```
Commands (Write)          Queries (Read)
     │                         │
┌────▼─────┐            ┌─────▼────┐
│ Write DB │ ─Events─→  │ Read DB  │
│ (Normal) │            │ (Dénom.) │
└──────────┘            └──────────┘
```

**Avantages :**
- Modèles optimisés séparément
- Scalabilité indépendante
- Lecture ultra-rapide (données dénormalisées)

## 🏗️ Architecture

### Séparation Command/Query

```javascript
// ============ COMMANDS (Write Side) ============

class CreateOrderCommand {
  constructor(userId, items) {
    this.userId = userId;
    this.items = items;
  }
}

class OrderCommandHandler {
  async handle(command) {
    // Validation métier
    if (command.items.length === 0) {
      throw new Error('Order must have items');
    }
    
    // Écrire dans Write DB (normalisé)
    const order = await Order.create({
      userId: command.userId,
      status: 'PENDING'
    });
    
    await OrderItem.bulkCreate(
      command.items.map(item => ({
        orderId: order.id,
        productId: item.productId,
        quantity: item.quantity
      }))
    );
    
    // Publier événement pour synchronisation
    eventBus.publish('OrderCreated', { orderId: order.id });
    
    return order.id;
  }
}

// ============ QUERIES (Read Side) ============

class GetOrderDetailsQuery {
  constructor(orderId) {
    this.orderId = orderId;
  }
}

class OrderQueryHandler {
  async handle(query) {
    // Lecture depuis Read DB (dénormalisé, pré-jointé)
    return await OrderReadModel.findOne({
      where: { orderId: query.orderId }
    });
    
    // Retourne directement:
    // {
    //   orderId: '123',
    //   userName: 'John Doe',     // Dénormalisé
    //   userEmail: 'john@...',    // Dénormalisé
    //   items: [                   // Pré-jointé
    //     { productName: '...', price: ... }
    //   ],
    //   totalAmount: 150
    // }
  }
}
```

### Synchronisation Read Model

```javascript
// Projector : écoute les événements et met à jour Read DB
eventBus.subscribe('OrderCreated', async (event) => {
  const order = await Order.findByPk(event.orderId, {
    include: [User, OrderItems]
  });
  
  // Créer vue dénormalisée
  await OrderReadModel.create({
    orderId: order.id,
    userName: order.user.name,
    userEmail: order.user.email,
    items: order.items.map(item => ({
      productName: item.product.name,
      quantity: item.quantity,
      price: item.price
    })),
    totalAmount: order.totalAmount,
    status: order.status
  });
});
```

## 💻 Implémentation

### API REST

```javascript
// ===== COMMANDS =====
router.post('/orders', async (req, res) => {
  const command = new CreateOrderCommand(
    req.user.id,
    req.body.items
  );
  
  const orderId = await commandBus.dispatch(command);
  
  res.status(202).json({ orderId }); // 202 Accepted
});

// ===== QUERIES =====
router.get('/orders/:id', async (req, res) => {
  const query = new GetOrderDetailsQuery(req.params.id);
  
  const order = await queryBus.dispatch(query);
  
  res.json(order);
});
```

### Technologies Read DB

| Use Case | Write DB | Read DB |
|----------|----------|---------|
| **Simple** | PostgreSQL | PostgreSQL (vues matérialisées) |
| **Analytics** | PostgreSQL | Elasticsearch |
| **High read load** | PostgreSQL | Redis (cache) |
| **Complex queries** | PostgreSQL | PostgreSQL (schéma dénormalisé) |
| **Full-text search** | MongoDB | Elasticsearch |

## 🔄 Eventual Consistency

Le Read Model est **éventuellement cohérent** avec le Write Model.

```javascript
// T0: Command exécutée
POST /orders → { orderId: '123' }

// T1: Événement publié et traité (~10-100ms)
Event: OrderCreated

// T2: Read Model mis à jour
GET /orders/123 → { order details }

// ⚠️ Entre T0 et T2 : Read Model pas encore à jour
```

### Gérer l'UI

```javascript
// Option 1: Optimistic UI
// Afficher immédiatement avec données de la commande
const optimisticOrder = {
  id: orderId,
  status: 'PENDING',
  items: command.items
};

// Option 2: Polling
async function waitForOrder(orderId) {
  for (let i = 0; i < 10; i++) {
    const order = await getOrder(orderId);
    if (order) return order;
    await sleep(100);
  }
  throw new Error('Order not found');
}

// Option 3: WebSocket notification
eventBus.subscribe('OrderCreated', (event) => {
  websocket.send({ type: 'OrderReady', orderId: event.orderId });
});
```

## 🎨 Niveaux de CQRS

### Niveau 1 : Séparation logique

Même BDD, modèles différents

```javascript
// Write Model (ORM)
class Order {
  id: number;
  userId: number;
  items: OrderItem[];
}

// Read Model (DTO simple)
interface OrderDTO {
  orderId: number;
  userName: string;
  totalAmount: number;
}
```

### Niveau 2 : Séparation physique

BDD séparées, synchronisation événementielle

```javascript
// Write DB: PostgreSQL normalisé
// Read DB: PostgreSQL dénormalisé
// Sync: CDC (Change Data Capture) via Debezium
```

### Niveau 3 : Technologies différentes

Optimisation maximale

```javascript
// Write: PostgreSQL (ACID)
// Read: Elasticsearch (full-text search)
// Sync: Kafka events
```

## ✅ Avantages

### 1. Performance

- **Lecture** : données pré-calculées, pas de JOIN
- **Écriture** : pas de contraintes de lecture

### 2. Scalabilité

- Scaler Read/Write indépendamment
- Read replicas multiples

### 3. Optimisation ciblée

- Indexes adaptés par usage
- Caching agressif sur Read
- Sharding différent Read/Write

### 4. Flexibilité

- Plusieurs Read Models pour différents besoins
- Migration technologique facilitée

## ⚠️ Inconvénients

### 1. Complexité

Code plus complexe que CRUD simple

### 2. Eventual Consistency

UI doit gérer le délai de synchronisation

### 3. Duplication de données

Plus de stockage nécessaire

### 4. Synchronisation

Erreurs de sync à gérer

## 🛠️ Frameworks

### Axon Framework (Java)

```java
// Command
@CommandHandler
public OrderId handle(CreateOrderCommand command) {
    OrderId orderId = new OrderId();
    apply(new OrderCreatedEvent(orderId, command.getItems()));
    return orderId;
}

// Query
@QueryHandler
public OrderDetails handle(GetOrderDetailsQuery query) {
    return orderReadRepository.findById(query.getOrderId());
}

// Projection (mise à jour Read Model)
@EventHandler
public void on(OrderCreatedEvent event) {
    OrderDetails details = new OrderDetails(event.getOrderId());
    orderReadRepository.save(details);
}
```

### MediatR (.NET)

```csharp
// Command
public class CreateOrderCommand : IRequest<Guid>
{
    public List<OrderItem> Items { get; set; }
}

public class CreateOrderHandler : IRequestHandler<CreateOrderCommand, Guid>
{
    public async Task<Guid> Handle(CreateOrderCommand request, ...)
    {
        var order = new Order(request.Items);
        await _repository.SaveAsync(order);
        return order.Id;
    }
}

// Query
public class GetOrderQuery : IRequest<OrderDto>
{
    public Guid OrderId { get; set; }
}

public class GetOrderHandler : IRequestHandler<GetOrderQuery, OrderDto>
{
    public async Task<OrderDto> Handle(GetOrderQuery request, ...)
    {
        return await _readRepository.GetOrderAsync(request.OrderId);
    }
}
```

## 📊 Quand utiliser CQRS ?

### ✅ Cas appropriés

- Charge de lecture >> écriture (ratio 100:1 typique)
- Besoins de performance critiques
- Requêtes complexes avec agrégations
- Modèles de lecture multiples
- Domain-Driven Design

### ❌ Éviter si

- CRUD simple
- Charge équilibrée lecture/écriture
- Équipe sans expérience
- Cohérence immédiate obligatoire

## ✅ Bonnes pratiques

1. **Commencer simple** : CQRS logique avant physique
2. **Monitoring de sync** : latence Read Model
3. **Versioning** : gérer évolution des Read Models
4. **Idempotence** : projections rejouables
5. **Tests** : vérifier cohérence finale
6. **Documentation** : expliquer l'eventual consistency

## 🧪 Tests

```javascript
describe('CQRS Order Flow', () => {
  it('should eventually sync Read Model', async () => {
    // Command
    const orderId = await commandBus.dispatch(
      new CreateOrderCommand(userId, items)
    );
    
    // Wait for projection
    await waitFor(() => 
      queryBus.dispatch(new GetOrderQuery(orderId))
    );
    
    // Verify Read Model
    const order = await queryBus.dispatch(
      new GetOrderQuery(orderId)
    );
    expect(order.totalAmount).toBe(150);
  });
});
```

## Ressources

- [CQRS - Martin Fowler](https://martinfowler.com/bliki/CQRS.html)
- [Microsoft CQRS Pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs)
- [Greg Young - CQRS Documents](https://cqrs.files.wordpress.com/2010/11/cqrs_documents.pdf)