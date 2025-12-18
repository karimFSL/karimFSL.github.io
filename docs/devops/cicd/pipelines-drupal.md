---
sidebar_position: 2
---

# 🔷 Pipeline Drupal - GitLab CI

Pipeline CI/CD complet pour applications Drupal avec Composer sur GitLab CI.

## 🎯 Architecture du Pipeline GitLab CI Drupal

```mermaid
graph LR
    subgraph "Stages GitLab CI"
        BUILD[📦 Build]
        QUALITY[📊 Quality]
        TEST[🧪 Test]
        SECURITY[🔒 Security]
        DOCKER[🐳 Docker]
        DEPLOY_DEV[🔧 Deploy Dev]
        DEPLOY_STAGING[🎭 Deploy Staging]
        DEPLOY_PROD[🚀 Deploy Prod]
    end
    
    BUILD --> QUALITY
    QUALITY --> TEST
    TEST --> SECURITY
    SECURITY --> DOCKER
    DOCKER --> DEPLOY_DEV
    DEPLOY_DEV --> DEPLOY_STAGING
    DEPLOY_STAGING --> DEPLOY_PROD
    
    subgraph "Outils"
        COMPOSER[📦 Composer]
        PHPCS[📋 PHPCS]
        PHPSTAN[🔍 PHPStan]
        PHPUNIT[🧪 PHPUnit]
        BEHAT[🎯 Behat]
        TRIVY[🔍 Trivy]
        DRUSH[🔧 Drush]
    end
    
    BUILD --> COMPOSER
    QUALITY --> PHPCS
    QUALITY --> PHPSTAN
    TEST --> PHPUNIT
    TEST --> BEHAT
    SECURITY --> TRIVY
    DEPLOY_PROD --> DRUSH
```

## 📋 Pipeline GitLab CI Complet

```yaml title=".gitlab-ci.yml"
# GitLab CI Pipeline pour Drupal 10
# Version: 1.0
# Description: Pipeline DevSecOps complet pour Drupal

variables:
  # PHP
  PHP_VERSION: "8.2"
  
  # Composer
  COMPOSER_CACHE_DIR: "${CI_PROJECT_DIR}/.composer-cache"
  COMPOSER_ALLOW_SUPERUSER: "1"
  COMPOSER_MEMORY_LIMIT: "-1"
  
  # Docker
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  REGISTRY: $CI_REGISTRY
  IMAGE_NAME: $CI_REGISTRY_IMAGE
  
  # Application
  APP_NAME: "my-drupal-site"
  DRUPAL_ROOT: "/var/www/html/web"
  
  # Database
  MYSQL_ROOT_PASSWORD: "root"
  MYSQL_DATABASE: "drupal"
  MYSQL_USER: "drupal"
  MYSQL_PASSWORD: "drupal"
  
  # Kubernetes
  KUBE_NAMESPACE_DEV: "dev"
  KUBE_NAMESPACE_STAGING: "staging"
  KUBE_NAMESPACE_PROD: "production"

# Cache Composer
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .composer-cache/
    - vendor/
    - web/core/
    - web/modules/contrib/
    - web/themes/contrib/

# Stages
stages:
  - build
  - quality
  - test
  - security
  - package
  - deploy-dev
  - deploy-staging
  - deploy-prod

# Templates
.php_template: &php_template
  image: php:${PHP_VERSION}-cli
  before_script:
    - apt-get update -qq
    - apt-get install -y -qq git unzip libzip-dev libpng-dev libpq-dev libicu-dev
    - docker-php-ext-install zip gd pdo pdo_mysql intl
    - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    - composer --version
    - php --version

.docker_template: &docker_template
  image: docker:24-dind
  services:
    - docker:24-dind
  before_script:
    - docker info
    - echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY

# ============================================
# Stage 1: BUILD
# ============================================
build:composer:
  <<: *php_template
  stage: build
  script:
    - echo "📦 Installing dependencies with Composer..."
    - composer validate --no-check-all --strict
    - composer install --prefer-dist --no-progress --no-interaction --optimize-autoloader
    - echo "✅ Dependencies installed"
    - ls -la vendor/
  artifacts:
    paths:
      - vendor/
      - web/core/
      - web/modules/contrib/
      - web/themes/contrib/
      - composer.lock
    expire_in: 1 hour
  only:
    - branches
    - merge_requests

# ============================================
# Stage 2: QUALITY
# ============================================
quality:phpcs:
  <<: *php_template
  stage: quality
  dependencies:
    - build:composer
  script:
    - echo "📋 Running PHP Code Sniffer..."
    - ./vendor/bin/phpcs --standard=Drupal --extensions=php,module,inc,install,test,profile,theme,css,info,txt,md,yml
        --report=full
        --report-file=phpcs-report.txt
        web/modules/custom/ web/themes/custom/ || true
    - ./vendor/bin/phpcs --standard=DrupalPractice --extensions=php,module,inc,install,test,profile,theme
        --report=full
        --report-file=phpcs-practice-report.txt
        web/modules/custom/ web/themes/custom/ || true
    - cat phpcs-report.txt
    - cat phpcs-practice-report.txt
  artifacts:
    when: always
    paths:
      - phpcs-report.txt
      - phpcs-practice-report.txt
    expire_in: 1 week
  allow_failure: true
  only:
    - branches
    - merge_requests

quality:phpstan:
  <<: *php_template
  stage: quality
  dependencies:
    - build:composer
  script:
    - echo "🔍 Running PHPStan static analysis..."
    - ./vendor/bin/phpstan analyse web/modules/custom/ web/themes/custom/
        --level=6
        --error-format=table
        --no-progress
        --memory-limit=1G || true
  artifacts:
    when: always
    paths:
      - phpstan-report.txt
    expire_in: 1 week
  allow_failure: true
  only:
    - branches
    - merge_requests

quality:phpmd:
  <<: *php_template
  stage: quality
  dependencies:
    - build:composer
  script:
    - echo "📊 Running PHP Mess Detector..."
    - ./vendor/bin/phpmd web/modules/custom/,web/themes/custom/
        text
        cleancode,codesize,controversial,design,naming,unusedcode || true
  allow_failure: true
  only:
    - branches
    - merge_requests

quality:phpcpd:
  <<: *php_template
  stage: quality
  dependencies:
    - build:composer
  script:
    - echo "🔍 Running PHP Copy/Paste Detector..."
    - ./vendor/bin/phpcpd web/modules/custom/ web/themes/custom/ || true
  allow_failure: true
  only:
    - branches
    - merge_requests

quality:sonarqube:
  image: sonarsource/sonar-scanner-cli:latest
  stage: quality
  dependencies:
    - build:composer
    - test:phpunit
  variables:
    SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar"
    GIT_DEPTH: "0"
  cache:
    key: "${CI_JOB_NAME}"
    paths:
      - .sonar/cache
  script:
    - echo "📊 Running SonarQube analysis..."
    - sonar-scanner
        -Dsonar.projectKey=$CI_PROJECT_PATH_SLUG
        -Dsonar.projectName="$CI_PROJECT_NAME"
        -Dsonar.sources=web/modules/custom,web/themes/custom
        -Dsonar.host.url=$SONAR_HOST_URL
        -Dsonar.login=$SONAR_TOKEN
        -Dsonar.php.coverage.reportPaths=coverage/clover.xml
        -Dsonar.qualitygate.wait=true
  allow_failure: true
  only:
    - branches
    - merge_requests

# ============================================
# Stage 3: TEST
# ============================================
test:phpunit:
  <<: *php_template
  stage: test
  services:
    - name: mysql:8.0
      alias: mysql
      command: ["--default-authentication-plugin=mysql_native_password"]
  dependencies:
    - build:composer
  variables:
    SIMPLETEST_BASE_URL: "http://localhost:8080"
    SIMPLETEST_DB: "mysql://drupal:drupal@mysql:3306/drupal"
    MINK_DRIVER_ARGS_WEBDRIVER: '["chrome", {"browserName":"chrome","chromeOptions":{"args":["--disable-gpu","--headless"]}}, "http://localhost:4444"]'
  script:
    - echo "🧪 Running PHPUnit tests..."
    - |
      # Start PHP built-in server
      php -S localhost:8080 -t web &
      PHP_PID=$!
    - sleep 5
    - |
      # Run PHPUnit tests
      ./vendor/bin/phpunit
        --configuration=web/core/phpunit.xml.dist
        --testsuite=unit
        --coverage-clover=coverage/clover.xml
        --coverage-html=coverage/html
        --log-junit=junit.xml
        web/modules/custom/ || true
    - kill $PHP_PID || true
  artifacts:
    when: always
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/clover.xml
    paths:
      - coverage/
      - junit.xml
    expire_in: 1 week
  coverage: '/^\s*Lines:\s*\d+\.\d+\%/'
  only:
    - branches
    - merge_requests

test:behat:
  <<: *php_template
  stage: test
  services:
    - name: mysql:8.0
      alias: mysql
      command: ["--default-authentication-plugin=mysql_native_password"]
    - name: selenium/standalone-chrome:latest
      alias: selenium
  dependencies:
    - build:composer
  variables:
    BEHAT_PARAMS: '{"extensions":{"Behat\\MinkExtension":{"base_url":"http://localhost:8080"},"Drupal\\DrupalExtension":{"drupal":{"drupal_root":"web"},"drush":{"root":"web"}}}}'
  script:
    - echo "🎯 Running Behat tests..."
    - |
      # Install Drupal for testing
      cd web
      ../vendor/bin/drush site:install standard
        --db-url=mysql://drupal:drupal@mysql:3306/drupal
        --site-name="Test Site"
        --account-name=admin
        --account-pass=admin
        --yes
      cd ..
    - |
      # Start PHP server
      php -S localhost:8080 -t web &
      PHP_PID=$!
    - sleep 10
    - |
      # Run Behat
      ./vendor/bin/behat --format=pretty --out=std --format=junit --out=behat-results || true
    - kill $PHP_PID || true
  artifacts:
    when: always
    paths:
      - behat-results/
    expire_in: 1 week
  allow_failure: true
  only:
    - branches
    - merge_requests

# ============================================
# Stage 4: SECURITY
# ============================================
security:drupal-check:
  <<: *php_template
  stage: security
  dependencies:
    - build:composer
  script:
    - echo "🔐 Checking Drupal security advisories..."
    - |
      cd web
      ../vendor/bin/drush pm:security --format=json > ../security-report.json || true
      cat ../security-report.json
    - |
      # Check if there are any security issues
      SECURITY_COUNT=$(cat ../security-report.json | grep -c "\"is_security\":true" || echo "0")
      if [ "$SECURITY_COUNT" -gt "0" ]; then
        echo "❌ Found $SECURITY_COUNT security advisories!"
        cat ../security-report.json
        exit 1
      else
        echo "✅ No security advisories found"
      fi
  artifacts:
    when: always
    paths:
      - security-report.json
    expire_in: 1 week
  allow_failure: false
  only:
    - branches
    - merge_requests

security:composer-audit:
  <<: *php_template
  stage: security
  dependencies:
    - build:composer
  script:
    - echo "🔍 Running Composer audit..."
    - composer audit --format=json > composer-audit.json || true
    - composer audit --format=table || true
  artifacts:
    when: always
    paths:
      - composer-audit.json
    expire_in: 1 week
  allow_failure: false
  only:
    - branches
    - merge_requests

security:trivy-fs:
  image: aquasec/trivy:latest
  stage: security
  script:
    - echo "🔍 Scanning filesystem with Trivy..."
    - trivy fs --security-checks vuln,secret,config
        --severity CRITICAL,HIGH
        --format json
        --output trivy-fs-report.json
        .
    - trivy fs --security-checks vuln,secret,config
        --severity CRITICAL,HIGH
        --format template
        --template "@/contrib/html.tpl"
        --output trivy-fs-report.html
        .
  artifacts:
    when: always
    paths:
      - trivy-fs-report.json
      - trivy-fs-report.html
    reports:
      container_scanning: trivy-fs-report.json
    expire_in: 1 week
  allow_failure: false
  only:
    - branches
    - merge_requests

security:gitleaks:
  image: zricethezav/gitleaks:latest
  stage: security
  script:
    - echo "🔐 Scanning for secrets with Gitleaks..."
    - gitleaks detect --source . --report-format json --report-path gitleaks-report.json --verbose
  artifacts:
    when: always
    paths:
      - gitleaks-report.json
    expire_in: 1 week
  allow_failure: false
  only:
    - branches
    - merge_requests

security:sbom-generate:
  <<: *php_template
  stage: security
  dependencies:
    - build:composer
  script:
    - echo "📋 Generating SBOM with CycloneDX..."
    - ./vendor/bin/cyclonedx-php composer
        --output-format=json
        --output-file=sbom-cyclonedx.json
    - ./vendor/bin/cyclonedx-php composer
        --output-format=xml
        --output-file=sbom-cyclonedx.xml
    - echo "📋 Generating SBOM with Syft..."
    - curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
    - syft packages dir:. -o cyclonedx-json=sbom-syft.json
    - syft packages dir:. -o spdx-json=sbom-spdx.json
  artifacts:
    paths:
      - sbom-cyclonedx.json
      - sbom-cyclonedx.xml
      - sbom-syft.json
      - sbom-spdx.json
    expire_in: 1 month
  only:
    - branches
    - merge_requests

security:sbom-scan:
  image: anchore/grype:latest
  stage: security
  dependencies:
    - security:sbom-generate
  script:
    - echo "🔍 Scanning SBOM with Grype..."
    - grype sbom:sbom-syft.json -o json --file grype-report.json
    - grype sbom:sbom-syft.json -o table
    - |
      CRITICAL=$(cat grype-report.json | jq '[.matches[] | select(.vulnerability.severity=="Critical")] | length')
      HIGH=$(cat grype-report.json | jq '[.matches[] | select(.vulnerability.severity=="High")] | length')
      echo "Critical: $CRITICAL, High: $HIGH"
      if [ "$CRITICAL" -gt "0" ]; then
        echo "❌ Critical vulnerabilities found!"
        exit 1
      fi
  artifacts:
    when: always
    paths:
      - grype-report.json
    expire_in: 1 week
  allow_failure: false
  only:
    - branches
    - merge_requests

# ============================================
# Stage 5: PACKAGE
# ============================================
package:docker:
  <<: *docker_template
  stage: package
  dependencies:
    - build:composer
  script:
    - echo "🐳 Building Docker image..."
    - |
      if [ "$CI_COMMIT_TAG" != "" ]; then
        TAG="$CI_COMMIT_TAG"
      else
        TAG="$CI_COMMIT_SHORT_SHA"
      fi
    - echo "Tag: $TAG"
    - docker build -t $IMAGE_NAME:$TAG -t $IMAGE_NAME:latest .
    - echo "🔍 Scanning image with Trivy..."
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image
        --severity CRITICAL,HIGH
        --exit-code 1
        --no-progress
        $IMAGE_NAME:$TAG
    - echo "✍️ Signing image with Cosign..."
    - apk add --no-cache cosign
    - echo "$COSIGN_PRIVATE_KEY" > cosign.key
    - cosign sign --key cosign.key --yes $IMAGE_NAME:$TAG
    - rm cosign.key
    - echo "📤 Pushing image..."
    - docker push $IMAGE_NAME:$TAG
    - docker push $IMAGE_NAME:latest
    - echo "✅ Docker image pushed: $IMAGE_NAME:$TAG"
  only:
    - branches
    - merge_requests
    - tags

# ============================================
# Stage 6: DEPLOY DEV
# ============================================
deploy:dev:
  image: bitnami/kubectl:latest
  stage: deploy-dev
  environment:
    name: development
    url: https://dev.example.com
    on_stop: stop:dev
  script:
    - echo "🚀 Deploying to Development..."
    - kubectl config use-context $KUBE_CONTEXT_DEV
    - |
      if [ "$CI_COMMIT_TAG" != "" ]; then
        TAG="$CI_COMMIT_TAG"
      else
        TAG="$CI_COMMIT_SHORT_SHA"
      fi
    - kubectl set image deployment/$APP_NAME
        $APP_NAME=$IMAGE_NAME:$TAG
        -n $KUBE_NAMESPACE_DEV
    - kubectl rollout status deployment/$APP_NAME -n $KUBE_NAMESPACE_DEV --timeout=5m
    - echo "🔧 Running Drush commands..."
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_DEV -- drush updatedb --yes
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_DEV -- drush config:import --yes
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_DEV -- drush cache:rebuild
    - echo "✅ Deployment to Dev successful"
  only:
    - branches
    - merge_requests
  except:
    - tags

stop:dev:
  image: bitnami/kubectl:latest
  stage: deploy-dev
  environment:
    name: development
    action: stop
  script:
    - echo "🛑 Stopping Development environment..."
    - kubectl scale deployment/$APP_NAME --replicas=0 -n $KUBE_NAMESPACE_DEV
  when: manual
  only:
    - branches

# ============================================
# Stage 7: DEPLOY STAGING
# ============================================
deploy:staging:
  image: bitnami/kubectl:latest
  stage: deploy-staging
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - echo "🚀 Deploying to Staging..."
    - kubectl config use-context $KUBE_CONTEXT_STAGING
    - TAG="$CI_COMMIT_SHORT_SHA"
    - kubectl set image deployment/$APP_NAME
        $APP_NAME=$IMAGE_NAME:$TAG
        -n $KUBE_NAMESPACE_STAGING
    - kubectl rollout status deployment/$APP_NAME -n $KUBE_NAMESPACE_STAGING --timeout=5m
    - echo "🔧 Running Drush commands..."
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_STAGING -- drush updatedb --yes
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_STAGING -- drush config:import --yes
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_STAGING -- drush cache:rebuild
    - echo "✅ Deployment to Staging successful"
  only:
    - main
    - develop
  when: manual

# ============================================
# Stage 8: DEPLOY PRODUCTION
# ============================================
deploy:production:
  image: bitnami/kubectl:latest
  stage: deploy-prod
  environment:
    name: production
    url: https://www.example.com
  script:
    - echo "🚀 Deploying to Production..."
    - kubectl config use-context $KUBE_CONTEXT_PROD
    - |
      if [ "$CI_COMMIT_TAG" != "" ]; then
        TAG="$CI_COMMIT_TAG"
      else
        echo "❌ Production deployment requires a tag"
        exit 1
      fi
    - echo "Deploying version: $TAG"
    - echo "🔄 Enabling maintenance mode..."
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_PROD -- drush state:set system.maintenance_mode 1 --yes || true
    - kubectl set image deployment/$APP_NAME
        $APP_NAME=$IMAGE_NAME:$TAG
        -n $KUBE_NAMESPACE_PROD
    - kubectl rollout status deployment/$APP_NAME -n $KUBE_NAMESPACE_PROD --timeout=10m
    - echo "🔧 Running Drush commands..."
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_PROD -- drush updatedb --yes
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_PROD -- drush config:import --yes
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_PROD -- drush cache:rebuild
    - echo "🔄 Disabling maintenance mode..."
    - kubectl exec deployment/$APP_NAME -n $KUBE_NAMESPACE_PROD -- drush state:set system.maintenance_mode 0 --yes
    - echo "✅ Deployment to Production successful"
    - echo "🧪 Running smoke tests..."
    - sleep 30
    - kubectl run curl-test --rm -i --restart=Never --image=curlimages/curl:latest
        -n $KUBE_NAMESPACE_PROD
        -- curl -f https://www.example.com || exit 1
  only:
    - tags
  when: manual

# ============================================
# Scheduled Jobs
# ============================================
security:scheduled-scan:
  <<: *php_template
  stage: security
  dependencies:
    - build:composer
  script:
    - echo "🔍 Running scheduled security scan..."
    - cd web
    - ../vendor/bin/drush pm:security --format=json > ../scheduled-security.json
    - cat ../scheduled-security.json
  artifacts:
    when: always
    paths:
      - scheduled-security.json
    expire_in: 1 month
  only:
    - schedules
```