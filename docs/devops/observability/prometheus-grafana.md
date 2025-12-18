---
sidebar_position: 1
---

# 📈 Prometheus & Grafana - Monitoring Complet

Stack de monitoring complète pour Java, Drupal, Angular et infrastructure.

## 🎯 Architecture de monitoring

```mermaid
graph TB
    subgraph "Applications"
        JAVA[☕ Spring Boot<br/>Micrometer]
        DRUPAL[🔷 Drupal<br/>PHP-FPM Exporter]
        ANGULAR[🅰️ Angular<br/>Real User Monitoring]
        NGINX[🌐 Nginx<br/>Exporter]
    end
    
    subgraph "Infrastructure"
        NODE[🖥️ Node Exporter]
        CADVISOR[🐳 cAdvisor<br/>Containers]
        KUBE[☸️ Kube State Metrics]
        POSTGRES[🐘 Postgres Exporter]
        REDIS[🔴 Redis Exporter]
    end
    
    subgraph "Collecte"
        PROM[📊 Prometheus]
        LOKI[📝 Loki<br/>Logs]
        TEMPO[🔍 Tempo<br/>Traces]
    end
    
    subgraph "Visualisation"
        GRAFANA[📊 Grafana]
        DASH1[Dashboard Java]
        DASH2[Dashboard Drupal]
        DASH3[Dashboard Angular]
        DASH4[Dashboard Infra]
    end
    
    subgraph "Alerting"
        ALERTMANAGER[🚨 Alertmanager]
        SLACK[💬 Slack]
        PAGERDUTY[📟 PagerDuty]
        EMAIL[📧 Email]
    end
    
    JAVA --> PROM
    DRUPAL --> PROM
    ANGULAR --> PROM
    NGINX --> PROM
    NODE --> PROM
    CADVISOR --> PROM
    KUBE --> PROM
    POSTGRES --> PROM
    REDIS --> PROM
    
    JAVA --> LOKI
    DRUPAL --> LOKI
    NGINX --> LOKI
    
    JAVA --> TEMPO
    DRUPAL --> TEMPO
    ANGULAR --> TEMPO
    
    PROM --> GRAFANA
    LOKI --> GRAFANA
    TEMPO --> GRAFANA
    
    GRAFANA --> DASH1
    GRAFANA --> DASH2
    GRAFANA --> DASH3
    GRAFANA --> DASH4
    
    PROM --> ALERTMANAGER
    ALERTMANAGER --> SLACK
    ALERTMANAGER --> PAGERDUTY
    ALERTMANAGER --> EMAIL
```

## 🚀 Installation Stack complète

### Docker Compose - Stack de monitoring

```yaml title="docker-compose-monitoring.yml"
version: '3.8'

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
  loki_data:
  tempo_data:

services:
  # Prometheus - Métriques
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alerts:/etc/prometheus/alerts
      - prometheus_data:/prometheus
    networks:
      - monitoring
    restart: unless-stopped

  # Grafana - Visualisation
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_INSTALL_PLUGINS=redis-datasource,grafana-piechart-panel
      - GF_AUTH_ANONYMOUS_ENABLED=false
      - GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/etc/grafana/provisioning/dashboards/home.json
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/etc/grafana/dashboards
    networks:
      - monitoring
    restart: unless-stopped
    depends_on:
      - prometheus

  # Loki - Logs
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml
      - loki_data:/loki
    networks:
      - monitoring
    restart: unless-stopped

  # Promtail - Collecteur de logs
  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers
      - ./promtail/promtail-config.yml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitoring
    restart: unless-stopped

  # Tempo - Traces
  tempo:
    image: grafana/tempo:latest
    container_name: tempo
    command: [ "-config.file=/etc/tempo.yaml" ]
    volumes:
      - ./tempo/tempo.yml:/etc/tempo.yaml
      - tempo_data:/tmp/tempo
    ports:
      - "3200:3200"   # tempo
      - "4317:4317"   # otlp grpc
      - "4318:4318"   # otlp http
    networks:
      - monitoring
    restart: unless-stopped

  # Alertmanager - Gestion des alertes
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    networks:
      - monitoring
    restart: unless-stopped

  # Node Exporter - Métriques système
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    networks:
      - monitoring
    restart: unless-stopped

  # cAdvisor - Métriques containers
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
      - /dev/disk:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg
    networks:
      - monitoring
    restart: unless-stopped

  # Redis Exporter
  redis-exporter:
    image: oliver006/redis_exporter:latest
    container_name: redis-exporter
    ports:
      - "9121:9121"
    environment:
      - REDIS_ADDR=redis:6379
    networks:
      - monitoring
    restart: unless-stopped

  # Postgres Exporter
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: postgres-exporter
    ports:
      - "9187:9187"
    environment:
      - DATA_SOURCE_NAME=postgresql://user:password@postgres:5432/dbname?sslmode=disable
    networks:
      - monitoring
    restart: unless-stopped

  # Nginx Exporter
  nginx-exporter:
    image: nginx/nginx-prometheus-exporter:latest
    container_name: nginx-exporter
    ports:
      - "9113:9113"
    command:
      - -nginx.scrape-uri=http://nginx:8080/stub_status
    networks:
      - monitoring
    restart: unless-stopped
```

## ⚙️ Configuration Prometheus

```yaml title="prometheus/prometheus.yml"
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    region: 'eu-west-1'

# Règles d'alerting
rule_files:
  - '/etc/prometheus/alerts/*.yml'

# Configuration Alertmanager
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'alertmanager:9093'

# Scrape configs
scrape_configs:
  # Prometheus lui-même
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Applications Java (Spring Boot Actuator)
  - job_name: 'spring-boot-apps'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets:
          - 'java-app-1:8080'
          - 'java-app-2:8080'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '([^:]+).*'
        replacement: '${1}'

  # Drupal (PHP-FPM Exporter)
  - job_name: 'drupal-apps'
    static_configs:
      - targets:
          - 'phpfpm-exporter:9253'

  # Angular (via Nginx)
  - job_name: 'angular-apps'
    static_configs:
      - targets:
          - 'nginx-exporter:9113'

  # Infrastructure
  - job_name: 'node-exporter'
    static_configs:
      - targets:
          - 'node-exporter:9100'

  - job_name: 'cadvisor'
    static_configs:
      - targets:
          - 'cadvisor:8080'

  # Bases de données
  - job_name: 'postgres'
    static_configs:
      - targets:
          - 'postgres-exporter:9187'

  - job_name: 'redis'
    static_configs:
      - targets:
          - 'redis-exporter:9121'

  # Kubernetes (si applicable)
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__

# Remote write (optionnel - pour Thanos ou Cortex)
remote_write:
  - url: 'http://thanos-receive:19291/api/v1/receive'
    queue_config:
      capacity: 10000
      max_shards: 50
      min_shards: 1
```

## 🚨 Alerting Rules

```yaml title="prometheus/alerts/application-alerts.yml"
groups:
  - name: application_alerts
    interval: 30s
    rules:
      # Java Application - High Error Rate
      - alert: JavaHighErrorRate
        expr: |
          rate(http_server_requests_seconds_count{status=~"5.."}[5m]) 
          / 
          rate(http_server_requests_seconds_count[5m]) 
          > 0.05
        for: 5m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "High error rate on {{ $labels.instance }}"
          description: "Error rate is {{ $value | humanizePercentage }} (threshold: 5%)"

      # Java Application - High Latency
      - alert: JavaHighLatency
        expr: |
          histogram_quantile(0.95, 
            rate(http_server_requests_seconds_bucket[5m])
          ) > 1
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "High latency on {{ $labels.instance }}"
          description: "95th percentile latency is {{ $value }}s"

      # Java Application - Memory Usage
      - alert: JavaHighMemoryUsage
        expr: |
          (jvm_memory_used_bytes{area="heap"} 
          / 
          jvm_memory_max_bytes{area="heap"}) 
          > 0.90
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Heap memory usage is {{ $value | humanizePercentage }}"

      # Java Application - High GC Time
      - alert: JavaHighGCTime
        expr: |
          rate(jvm_gc_pause_seconds_sum[5m]) 
          / 
          rate(jvm_gc_pause_seconds_count[5m]) 
          > 0.1
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "High GC time on {{ $labels.instance }}"
          description: "Average GC pause is {{ $value }}s"

      # Drupal - PHP-FPM High Pool Usage
      - alert: PHPFPMHighPoolUsage
        expr: |
          (phpfpm_active_processes 
          / 
          phpfpm_max_children) 
          > 0.80
        for: 5m
        labels:
          severity: warning
          team: drupal
        annotations:
          summary: "High PHP-FPM pool usage"
          description: "Pool usage is {{ $value | humanizePercentage }}"

      # Drupal - Database Slow Queries
      - alert: DrupalSlowQueries
        expr: |
          rate(mysql_global_status_slow_queries[5m]) > 10
        for: 5m
        labels:
          severity: warning
          team: drupal
        annotations:
          summary: "High number of slow queries"
          description: "{{ $value }} slow queries per second"

      # Angular - High Client Errors
      - alert: AngularHighClientErrors
        expr: |
          rate(nginx_http_requests_total{status=~"4.."}[5m]) > 100
        for: 5m
        labels:
          severity: warning
          team: frontend
        annotations:
          summary: "High client error rate"
          description: "{{ $value }} 4xx errors per second"
```

```yaml title="prometheus/alerts/infrastructure-alerts.yml"
groups:
  - name: infrastructure_alerts
    interval: 30s
    rules:
      # Node - High CPU
      - alert: HostHighCPU
        expr: |
          100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          team: devops
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}%"

      # Node - High Memory
      - alert: HostHighMemory
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: critical
          team: devops
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value }}%"

      # Node - Disk Space
      - alert: HostLowDiskSpace
        expr: |
          (node_filesystem_avail_bytes{mountpoint="/"} 
          / 
          node_filesystem_size_bytes{mountpoint="/"}) 
          * 100 < 10
        for: 5m
        labels:
          severity: critical
          team: devops
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Only {{ $value }}% disk space remaining"

      # Container - High CPU
      - alert: ContainerHighCPU
        expr: |
          rate(container_cpu_usage_seconds_total{container!=""}[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
          team: devops
        annotations:
          summary: "High CPU on container {{ $labels.container }}"
          description: "CPU usage is {{ $value }}%"

      # Container - OOM Killed
      - alert: ContainerOOMKilled
        expr: |
          increase(container_oom_events_total[5m]) > 0
        labels:
          severity: critical
          team: devops
        annotations:
          summary: "Container {{ $labels.container }} OOM killed"
          description: "Container was killed due to out of memory"

      # Database - High Connections
      - alert: PostgresHighConnections
        expr: |
          (pg_stat_database_numbackends 
          / 
          pg_settings_max_connections) 
          > 0.80
        for: 5m
        labels:
          severity: warning
          team: database
        annotations:
          summary: "High Postgres connections"
          description: "{{ $value | humanizePercentage }} of max connections used"

      # Redis - High Memory
      - alert: RedisHighMemory
        expr: |
          (redis_memory_used_bytes 
          / 
          redis_memory_max_bytes) 
          > 0.90
        for: 5m
        labels:
          severity: warning
          team: cache
        annotations:
          summary: "High Redis memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }}"
```

## 📧 Configuration Alertmanager

```yaml title="alertmanager/alertmanager.yml"
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

# Templates
templates:
  - '/etc/alertmanager/templates/*.tmpl'

# Routes
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  
  routes:
    # Critical alerts -> PagerDuty
    - match:
        severity: critical
      receiver: 'pagerduty'
      continue: true
    
    # Critical alerts -> Slack
    - match:
        severity: critical
      receiver: 'slack-critical'
    
    # Warning alerts -> Slack
    - match:
        severity: warning
      receiver: 'slack-warning'
    
    # Team-specific routes
    - match:
        team: backend
      receiver: 'slack-backend'
    
    - match:
        team: frontend
      receiver: 'slack-frontend'
    
    - match:
        team: drupal
      receiver: 'slack-drupal'

# Inhibition rules
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']

# Receivers
receivers:
  - name: 'default'
    email_configs:
      - to: 'devops@example.com'
        send_resolved: true

  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
        description: '{{ .GroupLabels.alertname }}'

  - name: 'slack-critical'
    slack_configs:
      - channel: '#alerts-critical'
        title: '🚨 CRITICAL ALERT'
        text: >-
          {{ range .Alerts }}
            *Alert:* {{ .Labels.alertname }}
            *Summary:* {{ .Annotations.summary }}
            *Description:* {{ .Annotations.description }}
            *Severity:* {{ .Labels.severity }}
          {{ end }}
        send_resolved: true

  - name: 'slack-warning'
    slack_configs:
      - channel: '#alerts-warning'
        title: '⚠️ WARNING ALERT'
        text: >-
          {{ range .Alerts }}
            *Alert:* {{ .Labels.alertname }}
            *Summary:* {{ .Annotations.summary }}
          {{ end }}

  - name: 'slack-backend'
    slack_configs:
      - channel: '#team-backend'
        title: '☕ Backend Alert'

  - name: 'slack-frontend'
    slack_configs:
      - channel: '#team-frontend'
        title: '🅰️ Frontend Alert'

  - name: 'slack-drupal'
    slack_configs:
      - channel: '#team-drupal'
        title: '🔷 Drupal Alert'
```

## 📊 Dashboards Grafana

### Dashboard Java/Spring Boot

```json title="grafana/dashboards/java-spring-boot.json"
{
  "dashboard": {
    "title": "Java Spring Boot Monitoring",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_server_requests_seconds_count[5m])"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_server_requests_seconds_count{status=~\"5..\"}[5m])"
          }
        ]
      },
      {
        "title": "Response Time (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))"
          }
        ]
      },
      {
        "title": "JVM Memory",
        "targets": [
          {
            "expr": "jvm_memory_used_bytes{area=\"heap\"}"
          },
          {
            "expr": "jvm_memory_max_bytes{area=\"heap\"}"
          }
        ]
      },
      {
        "title": "GC Activity",
        "targets": [
          {
            "expr": "rate(jvm_gc_pause_seconds_count[5m])"
          }
        ]
      },
      {
        "title": "Thread Count",
        "targets": [
          {
            "expr": "jvm_threads_live_threads"
          }
        ]
      },
      {
        "title": "Database Connections",
        "targets": [
          {
            "expr": "hikaricp_connections_active"
          },
          {
            "expr": "hikaricp_connections"
          }
        ]
      },
      {
        "title": "Top Slow Endpoints",
        "targets": [
          {
            "expr": "topk(10, histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])))"
          }
        ]
      }
    ]
  }
}
```

### Dashboard Drupal

```json title="grafana/dashboards/drupal-php.json"
{
  "dashboard": {
    "title": "Drupal & PHP-FPM Monitoring",
    "panels": [
      {
        "title": "PHP-FPM Active Processes",
        "targets": [
          {
            "expr": "phpfpm_active_processes"
          }
        ]
      },
      {
        "title": "PHP-FPM Pool Usage",
        "targets": [
          {
            "expr": "(phpfpm_active_processes / phpfpm_max_children) * 100"
          }
        ]
      },
      {
        "title": "PHP Memory Usage",
        "targets": [
          {
            "expr": "phpfpm_process_last_request_memory"
          }
        ]
      },
      {
        "title": "Nginx Request Rate",
        "targets": [
          {
            "expr": "rate(nginx_http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Database Query Time",
        "targets": [
          {
            "expr": "rate(mysql_global_status_queries[5m])"
          }
        ]
      },
      {
        "title": "Cache Hit Rate",
        "targets": [
          {
            "expr": "rate(redis_keyspace_hits_total[5m]) / (rate(redis_keyspace_hits_total[5m]) + rate(redis_keyspace_misses_total[5m]))"
          }
        ]
      },
      {
        "title": "Slow Queries",
        "targets": [
          {
            "expr": "rate(mysql_global_status_slow_queries[5m])"
          }
        ]
      }
    ]
  }
}
```

### Dashboard Angular

```json title="grafana/dashboards/angular-frontend.json"
{
  "dashboard": {
    "title": "Angular Frontend Monitoring",
    "panels": [
      {
        "title": "Page Load Time",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{path=\"/\"}[5m]))"
          }
        ]
      },
      {
        "title": "API Response Times",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{path=~\"/api/.*\"}[5m]))"
          }
        ]
      },
      {
        "title": "Error Rate by Status",
        "targets": [
          {
            "expr": "sum by(status) (rate(nginx_http_requests_total{status=~\"4..|5..\"}[5m]))"
          }
        ]
      },
      {
        "title": "Bandwidth Usage",
        "targets": [
          {
            "expr": "rate(nginx_http_response_size_bytes_sum[5m])"
          }
        ]
      },
      {
        "title": "Active Connections",
        "targets": [
          {
            "expr": "nginx_connections_active"
          }
        ]
      },
      {
        "title": "Request by Country",
        "targets": [
          {
            "expr": "sum by(country) (rate(nginx_http_requests_total[5m]))"
          }
        ]
      }
    ]
  }
}
```

Suite dans le prochain fichier... (Dashboard Infrastructure + Intégration applications)
