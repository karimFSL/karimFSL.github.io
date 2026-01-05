---
sidebar_position: 3
---
# Liquibase avec Spring Boot

## Qu'est-ce que Liquibase ?

Liquibase est un outil open-source de gestion de versions pour bases de données. Il s'intègre nativement avec Spring Boot pour automatiser les migrations de schéma au démarrage de l'application.

## Installation

### Maven

```xml
<dependency>
    <groupId>org.liquibase</groupId>
    <artifactId>liquibase-core</artifactId>
</dependency>
```

### Gradle

```gradle
implementation 'org.liquibase:liquibase-core'
```

Spring Boot gère automatiquement la version de Liquibase compatible.

## Configuration application.yml

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb
    username: user
    password: pass
    
  liquibase:
    enabled: true
    change-log: classpath:db/changelog/db.changelog-master.xml
    contexts: dev
    default-schema: public
    liquibase-schema: public
    drop-first: false
```

### Options principales

- `enabled`: Active/désactive Liquibase (true par défaut)
- `change-log`: Chemin vers le changelog master
- `contexts`: Contextes à exécuter (dev, test, prod)
- `default-schema`: Schéma par défaut pour les changements
- `drop-first`: Supprime le schéma avant migration (dev uniquement)
- `user/password`: Credentials spécifiques (optionnel)

## Structure d'un Changelog

### Fichier master (XML)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.24.xsd">

    <include file="db/changelog/changes/001-create-user-table.xml"/>
    <include file="db/changelog/changes/002-add-email-column.xml"/>
</databaseChangeLog>
```

### Exemple de changeset

```xml
<databaseChangeLog>
    <changeSet id="001" author="dev">
        <createTable tableName="user">
            <column name="id" type="bigint" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="username" type="varchar(50)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="created_at" type="timestamp" defaultValueComputed="CURRENT_TIMESTAMP"/>
        </createTable>
    </changeSet>
</databaseChangeLog>
```

## Intégration Spring Boot

### Exécution automatique

Spring Boot exécute automatiquement Liquibase au démarrage de l'application. Aucune configuration supplémentaire n'est nécessaire.

### Configuration programmatique

```java
@Configuration
public class LiquibaseConfig {
    
    @Bean
    public SpringLiquibase liquibase(DataSource dataSource) {
        SpringLiquibase liquibase = new SpringLiquibase();
        liquibase.setDataSource(dataSource);
        liquibase.setChangeLog("classpath:db/changelog/db.changelog-master.xml");
        liquibase.setContexts("dev");
        liquibase.setShouldRun(true);
        return liquibase;
    }
}
```

### Désactiver pour les tests

```java
@SpringBootTest
@TestPropertySource(properties = {
    "spring.liquibase.enabled=false"
})
class MyServiceTest {
    // Tests sans exécution de Liquibase
}
```

### Utilisation de profils

```yaml
spring:
  config:
    activate:
      on-profile: dev
  liquibase:
    contexts: dev
    drop-first: true
---
spring:
  config:
    activate:
      on-profile: prod
  liquibase:
    contexts: prod
    drop-first: false
```

## Formats supportés

- **XML** : Format le plus complet
- **YAML** : Plus lisible
- **JSON** : Pour l'intégration avec d'autres outils
- **SQL** : SQL natif avec métadonnées Liquibase

Exemple YAML :

```yaml
databaseChangeLog:
  - changeSet:
      id: 001
      author: dev
      changes:
        - createTable:
            tableName: user
            columns:
              - column:
                  name: id
                  type: bigint
                  autoIncrement: true
                  constraints:
                    primaryKey: true
```

## Commandes Maven/Gradle

### Maven

```bash
# Mettre à jour la base de données
mvn liquibase:update

# Voir le statut
mvn liquibase:status

# Rollback
mvn liquibase:rollback -Dliquibase.rollbackCount=1

# Générer un changelog depuis une DB existante
mvn liquibase:generateChangeLog
```

Configuration dans `pom.xml` :

```xml
<plugin>
    <groupId>org.liquibase</groupId>
    <artifactId>liquibase-maven-plugin</artifactId>
    <configuration>
        <propertyFile>src/main/resources/liquibase.properties</propertyFile>
    </configuration>
</plugin>
```

### Gradle

```bash
# Mettre à jour la base de données
./gradlew update

# Voir le statut
./gradlew status
```

Configuration dans `build.gradle` :

```gradle
plugins {
    id 'org.liquibase.gradle' version '2.2.0'
}

liquibase {
    activities {
        main {
            changelogFile 'src/main/resources/db/changelog/db.changelog-master.xml'
            url 'jdbc:postgresql://localhost:5432/mydb'
            username 'user'
            password 'pass'
        }
    }
}
```

## Bonnes pratiques

1. **Un changeset = une modification atomique** : Facilite les rollbacks
2. **ID uniques** : Utiliser des préfixes (ex: `001-`, `002-`)
3. **Ne jamais modifier un changeset déployé** : Créer un nouveau changeset
4. **Utiliser des contextes** : Différencier dev/test/prod
5. **Inclure des rollback** : Pour les changesets complexes
6. **Structure de dossiers** : Organiser par version ou fonctionnalité

```
src/main/resources/
└── db/
    └── changelog/
        ├── db.changelog-master.xml
        └── changes/
            ├── v1.0/
            │   ├── 001-create-user-table.xml
            │   └── 002-create-order-table.xml
            └── v1.1/
                └── 003-add-user-email.xml
```

### Exemple avec rollback

```xml
<changeSet id="003" author="dev">
    <addColumn tableName="user">
        <column name="phone" type="varchar(20)"/>
    </addColumn>
    <rollback>
        <dropColumn tableName="user" columnName="phone"/>
    </rollback>
</changeSet>
```

## Utilisation des contextes

Les contextes permettent d'exécuter des changesets spécifiques selon l'environnement :

```xml
<changeSet id="004" author="dev" context="dev">
    <insert tableName="user">
        <column name="username" value="test_user"/>
    </insert>
</changeSet>

<changeSet id="005" author="dev" context="prod">
    <sql>GRANT SELECT ON user TO readonly_user;</sql>
</changeSet>
```

Configuration par profil :

```yaml
spring:
  profiles:
    active: dev
  liquibase:
    contexts: ${spring.profiles.active}
```

## Tables techniques

Liquibase crée deux tables automatiquement :

- **DATABASECHANGELOG** : Historique des changesets exécutés
- **DATABASECHANGELOGLOCK** : Gestion des verrous concurrents

## Intégration CI/CD avec Spring Boot

### Validation avant déploiement

```java
@Component
public class LiquibaseValidator implements ApplicationRunner {
    
    @Autowired
    private SpringLiquibase liquibase;
    
    @Override
    public void run(ApplicationArguments args) throws Exception {
        // Validation au démarrage
        liquibase.afterPropertiesSet();
    }
}
```

### Exécution conditionnelle

```java
@Configuration
public class LiquibaseConfig {
    
    @Value("${app.liquibase.enabled:true}")
    private boolean liquibaseEnabled;
    
    @Bean
    @ConditionalOnProperty(name = "app.liquibase.enabled", havingValue = "true")
    public SpringLiquibase liquibase(DataSource dataSource) {
        SpringLiquibase liquibase = new SpringLiquibase();
        liquibase.setDataSource(dataSource);
        liquibase.setChangeLog("classpath:db/changelog/db.changelog-master.xml");
        return liquibase;
    }
}
```

### Docker avec Spring Boot

```dockerfile
FROM eclipse-temurin:17-jre-alpine
COPY target/myapp.jar app.jar

# Liquibase s'exécute au démarrage de l'application
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

### GitLab CI

```yaml
stages:
  - build
  - migrate
  - deploy

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"

cache:
  paths:
    - .m2/repository
    - target/

build:
  stage: build
  image: maven:3.9-eclipse-temurin-17
  script:
    - mvn clean package -DskipTests
  artifacts:
    paths:
      - target/*.jar
    expire_in: 1 hour

migrate:
  stage: migrate
  image: maven:3.9-eclipse-temurin-17
  only:
    - main
    - develop
  script:
    - mvn liquibase:update
  environment:
    name: $CI_COMMIT_REF_NAME
  variables:
    SPRING_DATASOURCE_URL: $DB_URL
    SPRING_DATASOURCE_USERNAME: $DB_USER
    SPRING_DATASOURCE_PASSWORD: $DB_PASSWORD

deploy:
  stage: deploy
  image: docker:latest
  services:
    - docker:dind
  only:
    - main
  script:
    - docker build -t myapp:latest .
    - docker push myapp:latest
```

Configuration des variables dans GitLab : Settings > CI/CD > Variables
- `DB_URL`
- `DB_USER`
- `DB_PASSWORD` (masqué)

## Dépannage

### Liquibase ne s'exécute pas

Vérifier que la dépendance est présente et que `spring.liquibase.enabled=true`.

### Erreur de checksum

Un changeset a été modifié après déploiement. Options :
- Ajouter `<validCheckSum>ANY</validCheckSum>` (déconseillé)
- Utiliser `mvn liquibase:clearCheckSums` en dev

### Conflits de lock

```sql
-- Libérer le verrou manuellement
DELETE FROM DATABASECHANGELOGLOCK WHERE ID = 1;
```

Liquibase avec Spring Boot offre une solution complète et automatisée pour gérer l'évolution des schémas de base de données dans vos applications Java.