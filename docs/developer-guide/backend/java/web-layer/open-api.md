---
sidebar_position: 2
---

# Génération API & DTO avec OpenAPI en Java

## Introduction

OpenAPI permet de générer automatiquement du code Java (APIs et DTOs) à partir d'une spécification OpenAPI, garantissant la cohérence entre documentation et implémentation.

## Outils principaux

- **OpenAPI Generator** : outil de génération de code multi-langage
- **Swagger Codegen** : alternative pour la génération de code

## Configuration Maven

```xml
<plugin>
    <groupId>org.openapitools</groupId>
    <artifactId>openapi-generator-maven-plugin</artifactId>
    <version>7.0.1</version>
    <executions>
        <execution>
            <goals>
                <goal>generate</goal>
            </goals>
            <configuration>
                <inputSpec>${project.basedir}/src/main/resources/openapi.yaml</inputSpec>
                <generatorName>spring</generatorName>
                <apiPackage>com.example.api</apiPackage>
                <modelPackage>com.example.dto</modelPackage>
                <configOptions>
                    <interfaceOnly>true</interfaceOnly>
                    <useSpringBoot3>true</useSpringBoot3>
                </configOptions>
            </configuration>
        </execution>
    </executions>
</plugin>
```

## Configuration Gradle

```gradle
plugins {
    id "org.openapi.generator" version "7.0.1"
}

openApiGenerate {
    generatorName = "spring"
    inputSpec = "$rootDir/src/main/resources/openapi.yaml"
    outputDir = "$buildDir/generated"
    apiPackage = "com.example.api"
    modelPackage = "com.example.dto"
    configOptions = [
        interfaceOnly: "true",
        useSpringBoot3: "true"
    ]
}
```

## Exemple de spécification OpenAPI

```yaml
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
paths:
  /users/{id}:
    get:
      tags:
        - user
      operationId: getUser
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
            format: int64
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
components:
  schemas:
    User:
      type: object
      required:
        - id
        - name
      properties:
        id:
          type: integer
          format: int64
        name:
          type: string
          maxLength: 100
        email:
          type: string
          format: email
```

## Code généré - Interface API

```java
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen")
@Validated
@Tag(name = "user", description = "the user API")
public interface UserApi {

    @Operation(
        operationId = "getUser",
        summary = "",
        tags = { "user" },
        responses = {
            @ApiResponse(responseCode = "200", description = "User found", 
                content = @Content(schema = @Schema(implementation = User.class)))
        }
    )
    @RequestMapping(
        method = RequestMethod.GET,
        value = "/users/{id}",
        produces = { "application/json" }
    )
    ResponseEntity<User> getUser(
        @Parameter(name = "id", required = true) 
        @PathVariable("id") Long id
    );
}
```

## Code généré - DTO

```java
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen")
@Schema(name = "User", description = "")
public class User {

    @NotNull
    private Long id;

    @NotNull
    @Size(max = 100)
    private String name;

    @Email
    private String email;

    // Getters et Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    // ... autres getters/setters
}
```

## Implémentation dans votre contrôleur

```java
@RestController
public class UserController implements UserApi {
    
    @Override
    public ResponseEntity<User> getUser(Long id) {
        // Votre logique métier
        return ResponseEntity.ok(userService.findById(id));
    }
}
```

## Annotations principales générées

Les annotations Swagger/OpenAPI générées incluent :

- `@Generated` : Indique que le code est généré automatiquement
- `@Schema` : Documentation du modèle pour Swagger UI
- `@Operation` : Documentation de l'opération API
- `@ApiResponse` : Documentation des réponses possibles
- `@Parameter` : Documentation des paramètres
- `@Tag` : Regroupement des endpoints

Ces annotations permettent la génération automatique de la documentation Swagger UI.

## Options de configuration utiles

| Option | Description |
|--------|-------------|
| `interfaceOnly` | Génère uniquement les interfaces API |
| `useTags` | Groupe les APIs par tags OpenAPI |
| `dateLibrary` | Bibliothèque pour les dates (`java8`, `legacy`) |
| `serializationLibrary` | Jackson, Gson, etc. |

## Commandes

**Maven** : `mvn clean generate-sources`

**Gradle** : `./gradlew openApiGenerate`

## Bonnes pratiques

1. **Versionnez** votre fichier OpenAPI dans le projet
2. **Ignorez** le code généré dans `.gitignore`
3. **N'éditez jamais** le code généré directement
4. **Régénérez** à chaque modification du contrat OpenAPI
5. Utilisez `interfaceOnly=true` pour séparer contrat et implémentation

## Structure du projet

```
src/
├── main/
│   ├── resources/
│   │   └── openapi.yaml          # Spécification OpenAPI
│   └── java/
│       └── com/example/
│           ├── controller/        # Implémentations
│           └── service/           # Logique métier
└── target/generated-sources/      # Code généré (ignoré par Git)
    └── openapi/
        ├── api/                   # Interfaces API
        └── model/                 # DTOs
```

## Ressources

- [OpenAPI Generator Documentation](https://openapi-generator.tech/)
- [OpenAPI Specification](https://swagger.io/specification/)