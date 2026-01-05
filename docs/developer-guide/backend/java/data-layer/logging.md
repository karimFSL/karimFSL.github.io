---
sidebar_position: 2
---

# Audit des entités

L'audit permet de tracer automatiquement les modifications sur vos entités : qui a créé/modifié l'entité, quand elle a été créée/modifiée, et gérer les conflits de versions lors de modifications concurrentes.

## Pourquoi auditer ?

- **Traçabilité** : Savoir qui a fait quoi et quand
- **Conformité** : Répondre aux exigences réglementaires (RGPD, SOX, etc.)
- **Débogage** : Comprendre l'historique des modifications
- **Sécurité** : Détecter des modifications suspectes
- **Gestion des conflits** : Éviter les écrasements de données

## Entité de base avec audit

La classe `BaseEntity` intègre tous les champs d'audit nécessaires :

```java
@Setter
@Getter
@SuperBuilder
@NoArgsConstructor
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public class BaseEntity {
    
    @Version
    private Long version;

    @CreationTimestamp
    @Column(updatable = false)
    private Timestamp createdDate;

    @UpdateTimestamp
    private Timestamp lastModifiedDate;

    @CreatedBy
    @Column(updatable = false)
    private String creator;

    @LastModifiedBy
    private String modifier;
}
```

**Usage** : Faites hériter vos entités de `BaseEntity` pour bénéficier automatiquement de l'audit.

```java
@Entity
@Table(name = "users")
public class User extends BaseEntity {
    
    private String name;
    private String email;
    
    // Les champs d'audit sont hérités automatiquement
}
```

---

## Annotations d'audit expliquées

### @Version - Verrouillage optimiste

**Rôle** : Prévient les conflits lors de modifications concurrentes.

**Fonctionnement** :
```java
@Version
private Long version;  // Incrémentée automatiquement à chaque update
```

**Scénario d'utilisation** :
```
1. User A lit l'entité (version = 1)
2. User B lit l'entité (version = 1)
3. User A modifie et sauvegarde → version = 2 ✅
4. User B tente de sauvegarder (version = 1) → OptimisticLockException ❌
```

**Gestion de l'exception** :
```java
try {
    userRepository.save(user);
} catch (OptimisticLockException e) {
    // Informer l'utilisateur que les données ont été modifiées
    // Proposer de rafraîchir ou fusionner les changements
    throw new ConflictException("Les données ont été modifiées par un autre utilisateur");
}
```

**Quand l'utiliser** :
- Modifications concurrentes possibles
- Données critiques (commandes, paiements, stocks)
- Interface web avec plusieurs utilisateurs simultanés

---

### @CreationTimestamp - Date de création

**Rôle** : Enregistre automatiquement la date de création de l'entité.

```java
@CreationTimestamp
@Column(updatable = false)  // Important : empêche les modifications
private Timestamp createdDate;
```

**Comportement** :
- Remplie automatiquement par Hibernate lors du `INSERT`
- Ne change **jamais**, même lors des `UPDATE`
- Utilise le fuseau horaire du serveur

**Alternatives** :
```java
// Avec Java 8 Time API
@CreationTimestamp
private Instant createdDate;

// Avec LocalDateTime
@CreationTimestamp
private LocalDateTime createdDate;
```

---

### @UpdateTimestamp - Date de modification

**Rôle** : Met à jour automatiquement la date à chaque modification.

```java
@UpdateTimestamp
private Timestamp lastModifiedDate;
```

**Comportement** :
- Remplie lors du `INSERT`
- Mise à jour automatiquement à chaque `UPDATE`
- Utile pour les mécanismes de cache et synchronisation

**Cas d'usage** :
```java
// Récupérer les entités modifiées depuis une date
@Query("SELECT e FROM Entity e WHERE e.lastModifiedDate > :since")
List<Entity> findModifiedSince(@Param("since") Timestamp since);
```

---

### @CreatedBy - Créateur

**Rôle** : Identifie automatiquement l'utilisateur qui a créé l'entité.

```java
@CreatedBy
@Column(updatable = false)
private String creator;  // UUID, username, ou email
```

**Comportement** :
- Remplie automatiquement via `AuditorAware`
- Ne change jamais après la création
- Nécessite une implémentation personnalisée (voir configuration)

---

### @LastModifiedBy - Modificateur

**Rôle** : Identifie le dernier utilisateur ayant modifié l'entité.

```java
@LastModifiedBy
private String modifier;  // UUID, username, ou email
```

**Comportement** :
- Remplie lors de la création (= creator)
- Mise à jour à chaque modification
- Nécessite une implémentation personnalisée (voir configuration)

---

## Configuration de l'audit

### 1. Implémenter AuditorAware

Cette interface fournit l'identité de l'utilisateur courant :

```java
@Component
public class AuditorAwareImpl implements AuditorAware<String> {
    
    @Override
    public Optional<String> getCurrentAuditor() {
        // Récupérer l'utilisateur depuis le contexte de sécurité
        Authentication authentication = SecurityContextHolder
            .getContext()
            .getAuthentication();
        
        if (authentication == null || !authentication.isAuthenticated()) {
            return Optional.of("SYSTEM");  // Valeur par défaut
        }
        
        // Adapter selon votre modèle User
        return Optional.of(authentication.getName());
    }
}
```

**Avec Spring Security personnalisé** :
```java
@Component
public class AuditorAwareImpl implements AuditorAware<String> {
    
    @Override
    public Optional<String> getCurrentAuditor() {
        return Optional.ofNullable(
            SecurityUtils.getCurrentUserAccount()
                .map(UserAccount::getUuid)
                .orElse("SYSTEM")
        );
    }
}
```

### 2. Déclarer le Bean

```java
@Configuration
public class AuditConfig {
    
    @Bean
    public AuditorAware<String> auditorAware() {
        return new AuditorAwareImpl();
    }
}
```

### 3. Activer l'audit JPA

Dans votre classe principale :

```java
@SpringBootApplication
@EnableJpaAuditing(auditorAwareRef = "auditorAware")
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

**Options avancées** :
```java
@EnableJpaAuditing(
    auditorAwareRef = "auditorAware",
    dateTimeProviderRef = "dateTimeProvider",  // Provider de date personnalisé
    modifyOnCreate = true  // Active @LastModifiedBy à la création
)
```

---

## Cas d'usage avancés

### Audit avec différents types d'identifiants

```java
// Avec UUID
public class AuditorAwareImpl implements AuditorAware<UUID> {
    @Override
    public Optional<UUID> getCurrentAuditor() {
        return Optional.of(getCurrentUser().getId());
    }
}

// Avec objet User complet
public class AuditorAwareImpl implements AuditorAware<User> {
    @Override
    public Optional<User> getCurrentAuditor() {
        return Optional.of(getCurrentUser());
    }
}
```

### Audit avec fuseau horaire spécifique

```java
@Component
public class CustomDateTimeProvider implements DateTimeProvider {
    
    @Override
    public Optional<TemporalAccessor> getNow() {
        return Optional.of(
            ZonedDateTime.now(ZoneId.of("Europe/Paris"))
        );
    }
}
```

### Désactiver l'audit pour certaines opérations

```java
@Service
public class UserService {
    
    @Autowired
    private EntityManager entityManager;
    
    public void updateWithoutAudit(User user) {
        // Désactiver temporairement les listeners
        entityManager.detach(user);
        
        // Faire les modifications
        user.setEmail("new@email.com");
        
        // Persister sans déclencher l'audit
        entityManager.createQuery("UPDATE User u SET u.email = :email WHERE u.id = :id")
            .setParameter("email", user.getEmail())
            .setParameter("id", user.getId())
            .executeUpdate();
    }
}
```

---

## Bonnes pratiques

1. **Toujours utiliser `@Column(updatable = false)`** sur les champs de création pour éviter les modifications accidentelles

2. **Choisir le bon type pour les identifiants** : UUID pour la sécurité, String pour la flexibilité, Long pour la performance

3. **Gérer les valeurs par défaut** : Prévoir "SYSTEM" ou "ANONYMOUS" pour les opérations sans utilisateur authentifié

4. **Indexer les champs de date** si vous faites des requêtes temporelles fréquentes
```sql
CREATE INDEX idx_last_modified ON users(last_modified_date);
```

5. **Tester l'audit** dans vos tests unitaires :
```java
@Test
void testAuditFields() {
    User user = new User("John Doe");
    userRepository.save(user);
    
    assertNotNull(user.getCreatedDate());
    assertNotNull(user.getCreator());
    assertEquals(user.getCreator(), user.getModifier());
    assertEquals(1L, user.getVersion());
}
```

6. **Logger les OptimisticLockException** pour détecter les patterns de conflits

7. **Ne jamais exposer les champs d'audit en modification** dans vos APIs REST

---

## Dépannage

**Problème** : Les champs @CreatedBy/@LastModifiedBy restent null

**Solutions** :
- Vérifier que `@EnableJpaAuditing` est présent
- Vérifier que `AuditorAware` retourne bien une valeur
- S'assurer que `@EntityListeners(AuditingEntityListener.class)` est sur l'entité

**Problème** : OptimisticLockException fréquentes

**Solutions** :
- Réviser la logique métier pour réduire les accès concurrents
- Utiliser des verrous pessimistes pour les sections critiques
- Implémenter une stratégie de retry avec backoff exponentiel

**Problème** : Dates incorrectes (fuseau horaire)

**Solutions** :
- Utiliser `Instant` au lieu de `Timestamp`
- Configurer le fuseau horaire de la JVM : `-Duser.timezone=UTC`
- Stocker en UTC et convertir côté client