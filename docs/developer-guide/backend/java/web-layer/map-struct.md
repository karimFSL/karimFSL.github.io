---
sidebar_position: 3
---

# MapStruct - Guide pratique

## Introduction

**MapStruct** est un générateur de code qui simplifie la conversion entre objets Java (Entités ↔ DTOs). Il génère le code de mapping au moment de la compilation, ce qui le rend performant et type-safe.

**Pourquoi MapStruct ?**
- ✅ Génération de code à la compilation (pas de réflexion)
- ✅ Performance optimale
- ✅ Type-safe (erreurs détectées à la compilation)
- ✅ Code lisible et debuggable
- ✅ Moins de code boilerplate

---

## Installation

### Dépendances Maven
```xml
<properties>
    <mapstruct.version>1.5.5.Final</mapstruct.version>
    <lombok.version>1.18.30</lombok.version>
</properties>

<dependencies>
    <!-- MapStruct -->
    <dependency>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct</artifactId>
        <version>${mapstruct.version}</version>
    </dependency>
</dependencies>

<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.11.0</version>
            <configuration>
                <source>17</source>
                <target>17</target>
                <annotationProcessorPaths>
                    <!-- MapStruct processor -->
                    <path>
                        <groupId>org.mapstruct</groupId>
                        <artifactId>mapstruct-processor</artifactId>
                        <version>${mapstruct.version}</version>
                    </path>
                    <!-- Lombok (si utilisé) -->
                    <path>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok</artifactId>
                        <version>${lombok.version}</version>
                    </path>
                    <!-- Binding Lombok + MapStruct -->
                    <path>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok-mapstruct-binding</artifactId>
                        <version>0.2.0</version>
                    </path>
                </annotationProcessorPaths>
            </configuration>
        </plugin>
    </plugins>
</build>
```

---

## Utilisation de base

### 1. Mapper simple
```java
package com.company.project.model.mapper;

import com.company.project.model.dto.UserDTO;
import com.company.project.model.entity.User;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface UserMapper {

    // Entité → DTO
    UserDTO toDTO(User entity);

    // DTO → Entité
    User toEntity(UserDTO dto);

    // Liste d'entités → Liste de DTOs
    List<UserDTO> toDTOList(List<User> entities);
}
```

**Utilisation dans un service :**
```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public UserDTO findById(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return userMapper.toDTO(user);
    }

    @Transactional
    public UserDTO create(UserDTO dto) {
        User entity = userMapper.toEntity(dto);
        User saved = userRepository.save(entity);
        return userMapper.toDTO(saved);
    }
}
```

---

## Mappings personnalisés

### 1. Champs avec noms différents
```java
@Mapper(componentModel = "spring")
public interface ProductMapper {

    @Mapping(source = "productName", target = "name")
    @Mapping(source = "productPrice", target = "price")
    ProductDTO toDTO(Product entity);
}
```

### 2. Ignorer certains champs
```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "password", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    User toEntity(UserDTO dto);
}
```

### 3. Valeurs par défaut
```java
@Mapper(componentModel = "spring")
public interface OrderMapper {

    @Mapping(target = "status", constant = "PENDING")
    @Mapping(target = "active", defaultValue = "true")
    Order toEntity(OrderDTO dto);
}
```

### 4. Expressions personnalisées
```java
@Mapper(componentModel = "spring", imports = {UUID.class, LocalDateTime.class})
public interface UserMapper {

    @Mapping(target = "id", expression = "java(UUID.randomUUID())")
    @Mapping(target = "createdAt", expression = "java(LocalDateTime.now())")
    User toEntity(UserDTO dto);
}
```

---

## Mappings de collections

### 1. Mapper des relations simples
```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    // MapStruct map automatiquement les collections
    @Mapping(target = "roleNames", source = "roles")
    UserDTO toDTO(User entity);

    // Méthode personnalisée pour mapper Role → String
    default String mapRole(Role role) {
        return role != null ? role.getName() : null;
    }
}
```

### 2. Utiliser d'autres mappers
```java
@Mapper(componentModel = "spring", uses = {AddressMapper.class, RoleMapper.class})
public interface UserMapper {

    // MapStruct utilise automatiquement AddressMapper et RoleMapper
    UserDTO toDTO(User entity);
}
```

---

## Mise à jour d'entités existantes

### @MappingTarget pour update
```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    UserDTO toDTO(User entity);

    User toEntity(UserDTO dto);

    // Mise à jour d'une entité existante
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "password", ignore = true)
    void updateEntityFromDTO(UserDTO dto, @MappingTarget User entity);
}
```

**Utilisation :**
```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    @Transactional
    public UserDTO update(UUID id, UserDTO dto) {
        User entity = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        // Met à jour l'entité existante
        userMapper.updateEntityFromDTO(dto, entity);
        
        User updated = userRepository.save(entity);
        return userMapper.toDTO(updated);
    }
}
```

---

## Méthodes personnalisées

### @Named pour réutiliser des méthodes
```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "roles", source = "roles", qualifiedByName = "mapRolesToStrings")
    UserDTO toDTO(User entity);

    @Named("mapRolesToStrings")
    default Set<String> mapRolesToStrings(Set<Role> roles) {
        if (roles == null) {
            return Collections.emptySet();
        }
        return roles.stream()
                .map(Role::getName)
                .collect(Collectors.toSet());
    }

    @Named("mapStringsToRoles")
    default Set<Role> mapStringsToRoles(Set<String> roleNames) {
        // Logique personnalisée
        return roleNames.stream()
                .map(name -> Role.builder().name(name).build())
                .collect(Collectors.toSet());
    }
}
```

---

## Mappings bidirectionnels

### Gérer les relations parent-enfant
```java
@Mapper(componentModel = "spring")
public interface OrderMapper {

    @Mapping(target = "items", source = "items")
    OrderDTO toDTO(Order entity);

    @Mapping(target = "order", ignore = true) // Évite la boucle infinie
    OrderItemDTO itemToDTO(OrderItem item);
}
```

---

## Configuration avancée

### Stratégies de null
```java
@Mapper(
    componentModel = "spring",
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE,
    nullValueCheckStrategy = NullValueCheckStrategy.ALWAYS
)
public interface UserMapper {
    // Si un champ du DTO est null, il n'est pas mappé (garde la valeur existante)
    void updateEntityFromDTO(UserDTO dto, @MappingTarget User entity);
}
```

### Politique de mapping non défini
```java
@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE  // IGNORE, WARN, ou ERROR
)
public interface UserMapper {
    UserDTO toDTO(User entity);
}
```

---

## Exemples pratiques

### Mapper avec transformations
```java
@Mapper(componentModel = "spring")
public interface ProductMapper {

    @Mapping(target = "price", source = "priceInCents", qualifiedByName = "centsToEuros")
    @Mapping(target = "fullName", expression = "java(entity.getName() + \" - \" + entity.getCategory())")
    ProductDTO toDTO(Product entity);

    @Named("centsToEuros")
    default BigDecimal centsToEuros(Long cents) {
        return cents != null ? BigDecimal.valueOf(cents).divide(BigDecimal.valueOf(100)) : null;
    }
}
```

### Mapper avec dates
```java
@Mapper(componentModel = "spring")
public interface EventMapper {

    @Mapping(target = "eventDate", source = "date", dateFormat = "yyyy-MM-dd HH:mm:ss")
    EventDTO toDTO(Event entity);

    @Mapping(target = "date", source = "eventDate", dateFormat = "yyyy-MM-dd HH:mm:ss")
    Event toEntity(EventDTO dto);
}
```

---

## Génération et compilation

### Voir le code généré

Après compilation (`mvn compile`), les implémentations générées se trouvent dans :
```
target/generated-sources/annotations/com/company/project/model/mapper/UserMapperImpl.java
```

**Exemple de code généré :**
```java
@Component
public class UserMapperImpl implements UserMapper {

    @Override
    public UserDTO toDTO(User entity) {
        if (entity == null) {
            return null;
        }

        UserDTO.UserDTOBuilder userDTO = UserDTO.builder();

        userDTO.id(entity.getId());
        userDTO.email(entity.getEmail());
        userDTO.firstName(entity.getFirstName());
        userDTO.lastName(entity.getLastName());
        // ... autres champs

        return userDTO.build();
    }

    // ... autres méthodes
}
```

---

## Troubleshooting

### Problème : Mapper non injecté

**Erreur :** `No qualifying bean of type 'UserMapper'`

**Solution :** Vérifier que :
- `componentModel = "spring"` est présent dans `@Mapper`
- Le projet est bien compilé (`mvn clean compile`)
- Les annotation processors sont configurés dans le pom.xml

### Problème : Lombok + MapStruct

**Solution :** Ajouter le binding :
```xml
<path>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok-mapstruct-binding</artifactId>
    <version>0.2.0</version>
</path>
```

### Problème : IntelliJ ne reconnaît pas le mapper

**Solution :**
1. `File` → `Settings` → `Build, Execution, Deployment` → `Compiler` → `Annotation Processors`
2. Cocher "Enable annotation processing"
3. Rebuild le projet

---

## Bonnes pratiques

### ✅ À faire
```java
// Utiliser componentModel spring
@Mapper(componentModel = "spring")

// Créer des mappers dédiés par entité
UserMapper, ProductMapper, OrderMapper

// Ignorer les champs sensibles
@Mapping(target = "password", ignore = true)

// Utiliser @MappingTarget pour les updates
void updateEntityFromDTO(DTO dto, @MappingTarget Entity entity);

// Documenter les mappings complexes
@Mapping(target = "fullPrice", source = "price") // Price includes VAT
```

### ❌ À éviter
```java
// Ne pas mapper directement dans les services
// ❌ MAUVAIS
public UserDTO findById(UUID id) {
    User user = repository.findById(id).orElseThrow();
    UserDTO dto = new UserDTO();
    dto.setId(user.getId());
    dto.setEmail(user.getEmail());
    // ... laborieux et source d'erreurs
    return dto;
}

// ✅ BON
public UserDTO findById(UUID id) {
    User user = repository.findById(id).orElseThrow();
    return userMapper.toDTO(user);
}

// Ne pas mapper des entités JPA avec des relations LAZY non initialisées
// Utiliser JOIN FETCH dans les requêtes ou gérer les mappings spécifiquement
```

---

## Checklist

- [ ] Dépendances MapStruct ajoutées
- [ ] Annotation processors configurés
- [ ] Mapper créé avec `@Mapper(componentModel = "spring")`
- [ ] Mapper injecté dans les services avec `@RequiredArgsConstructor`
- [ ] Champs sensibles ignorés (password, etc.)
- [ ] Projet compilé : `mvn clean compile`
- [ ] Code généré vérifié dans `target/generated-sources`

---

## Ressources

- [Documentation officielle MapStruct](https://mapstruct.org/documentation/stable/reference/html/)
- [MapStruct Examples](https://github.com/mapstruct/mapstruct-examples)
- [Baeldung - MapStruct Guide](https://www.baeldung.com/mapstruct)