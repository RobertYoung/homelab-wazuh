#!/bin/bash
set -euo pipefail

# Backup directory
BACKUP_DIR="/backup/temp/wazuh-backup"

# Create staging directory structure
mkdir -p "$BACKUP_DIR"/{manager,indexer,dashboard}
mkdir -p "$BACKUP_DIR/manager/var/ossec"/{etc,api/configuration,queue,logs}
mkdir -p "$BACKUP_DIR/manager/etc"

echo "Starting Wazuh backup at $(date)"

# ============================================================================
# PART 0: Host Information (per Wazuh documentation)
# ============================================================================
echo "Collecting host information..."

# Save system release information
cat /etc/*release* > "$BACKUP_DIR/system-release.txt"

# Save hostname and IP information
cat > "$BACKUP_DIR/host-info.txt" <<EOF
Backup Information
==================
Backup Date: $(date -Iseconds)
Backup Time (UTC): $(date -u)
Hostname: $(hostname)
FQDN: $(hostname -f)
IP Addresses: $(hostname -I)

System Information
==================
$(cat /etc/os-release)

Kernel: $(uname -r)
Architecture: $(uname -m)
Uptime: $(uptime)

Docker Information
==================
Docker Version: $(docker --version)
Docker Compose Version: $(docker compose version)

Wazuh Configuration
===================
Wazuh Version: ${WAZUH_VERSION}
Install Directory: ${WAZUH_INSTALL_DIR}
Domain: ${WAZUH_DOMAIN}

Container Status (before backup)
================================
$(docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' | grep wazuh)

Docker Volumes
==============
$(docker volume ls --format 'table {{.Name}}\t{{.Driver}}' | grep wazuh)

Disk Usage (Docker)
===================
$(docker system df -v | grep -A 20 "VOLUME NAME")
EOF

echo "Host information saved to host-info.txt and system-release.txt"

# ============================================================================
# PART 1: Wazuh Manager Backup
# ============================================================================
echo "Backing up Wazuh Manager..."

# Stop manager for database consistency
docker stop wazuh.manager

# Trap to ensure manager ALWAYS restarts, even on error
trap 'docker start wazuh.manager' EXIT

# Backup all required paths per Wazuh documentation
# https://documentation.wazuh.com/current/migration-guide/creating/wazuh-central-components.html#backing-up-the-wazuh-server

# 1. /var/ossec/etc/ (client.keys, sslmanager*, ossec.conf, internal_options, rules, decoders, shared/)
rsync -aEz /backup/volumes/wazuh_etc/ "$BACKUP_DIR/manager/var/ossec/etc/"

# 2. /var/ossec/api/configuration/
rsync -aEz /backup/volumes/wazuh_api_configuration/ "$BACKUP_DIR/manager/var/ossec/api/configuration/"

# 3. /var/ossec/queue/db/ - CRITICAL: Manager must be stopped for consistency
rsync -aEz /backup/volumes/wazuh_queue/db/ "$BACKUP_DIR/manager/var/ossec/queue/db/"

# 4. /var/ossec/queue/agentless/
rsync -aEz /backup/volumes/wazuh_queue/agentless/ "$BACKUP_DIR/manager/var/ossec/queue/agentless/" 2>/dev/null || true

# 5. /var/ossec/queue/agents-timestamp (file)
rsync -aEz /backup/volumes/wazuh_queue/agents-timestamp "$BACKUP_DIR/manager/var/ossec/queue/" 2>/dev/null || true

# 6. /var/ossec/queue/fts/
rsync -aEz /backup/volumes/wazuh_queue/fts/ "$BACKUP_DIR/manager/var/ossec/queue/fts/" 2>/dev/null || true

# 7. /var/ossec/queue/rids/
rsync -aEz /backup/volumes/wazuh_queue/rids/ "$BACKUP_DIR/manager/var/ossec/queue/rids/" 2>/dev/null || true

# 8. /var/ossec/logs/
rsync -aEz /backup/volumes/wazuh_logs/ "$BACKUP_DIR/manager/var/ossec/logs/" 2>/dev/null || true

# 9. /var/ossec/var/multigroups/
rsync -aEz /backup/volumes/wazuh_var_multigroups/ "$BACKUP_DIR/manager/var/ossec/var/multigroups/" 2>/dev/null || true

# 10. /var/ossec/stats/ (if it exists in logs volume)
rsync -aEz /backup/volumes/wazuh_logs/../stats/ "$BACKUP_DIR/manager/var/ossec/stats/" 2>/dev/null || true

# 11. /etc/filebeat/
rsync -aEz /backup/volumes/filebeat_etc/ "$BACKUP_DIR/manager/etc/filebeat/"

# Note: /etc/postfix/ is not applicable for Docker deployment

# Restart manager
docker start wazuh.manager

echo "Manager backup complete"

# ============================================================================
# PART 2: Wazuh Indexer Backup
# ============================================================================
echo "Backing up Wazuh Indexer..."

# Create indexer directories
mkdir -p "$BACKUP_DIR/indexer"/{certs,config,sysctl}

# 1. Indexer certificates from host mounts
rsync -aEz /backup/host/config/wazuh_indexer_ssl_certs/ "$BACKUP_DIR/indexer/certs/"

# 2. Indexer configuration from host mounts
rsync -aEz /backup/host/config/wazuh_indexer/ "$BACKUP_DIR/indexer/config/host-mounted/"

# 3. Extract complete indexer configuration from container
# This includes: jvm.options, jvm.options.d/, log4j2.properties, opensearch.yml,
# opensearch.keystore, opensearch-observability/, opensearch-reports-scheduler/, opensearch-security/
docker exec wazuh.indexer tar -cf - -C /usr/share/wazuh-indexer config 2>/dev/null | \
  tar -xf - -C "$BACKUP_DIR/indexer/" 2>/dev/null || true

# 4. Extract sysctl configuration from container
docker exec wazuh.indexer tar -cf - -C /usr/lib/sysctl.d wazuh-indexer.conf 2>/dev/null | \
  tar -xf - -C "$BACKUP_DIR/indexer/sysctl/" 2>/dev/null || true

# 5. Indexer data (optional - can be large, commented out by default)
# rsync -aEz /backup/volumes/wazuh-indexer-data/ "$BACKUP_DIR/indexer/data/" 2>/dev/null || true

echo "Indexer backup complete"

# ============================================================================
# PART 3: Wazuh Dashboard Backup
# ============================================================================
echo "Backing up Wazuh Dashboard..."

# Create dashboard directories
mkdir -p "$BACKUP_DIR/dashboard"/{certs,config,keystore,wazuh-config,wazuh-custom}

# 1. Dashboard certificates (/etc/wazuh-dashboard/certs/)
# Public HTTPS certificates (step-ca)
rsync -aEz /backup/host/certs/step-ca/ "$BACKUP_DIR/dashboard/certs/step-ca/"

# Internal CA certificate for backend communication
rsync -aEz /backup/host/config/wazuh_indexer_ssl_certs/root-ca.pem "$BACKUP_DIR/dashboard/certs/"

# 2. Dashboard configuration files from host mounts
# (opensearch_dashboards.yml, wazuh.yml)
rsync -aEz /backup/host/config/wazuh_dashboard/ "$BACKUP_DIR/dashboard/config/"

# 3. Extract opensearch_dashboards.keystore from container
docker exec wazuh.dashboard tar -cf - -C /usr/share/wazuh-dashboard/config opensearch_dashboards.keystore 2>/dev/null | \
  tar -xf - -C "$BACKUP_DIR/dashboard/keystore/" 2>/dev/null || true

# 4. Dashboard custom assets and data
rsync -aEz /backup/volumes/wazuh-dashboard-config/ "$BACKUP_DIR/dashboard/wazuh-config/" 2>/dev/null || true
rsync -aEz /backup/volumes/wazuh-dashboard-custom/ "$BACKUP_DIR/dashboard/wazuh-custom/" 2>/dev/null || true

echo "Dashboard backup complete"

# ============================================================================
# PART 4: Docker Compose and Environment Files
# ============================================================================
echo "Backing up Docker configuration..."

cp /backup/host/manager.env "$BACKUP_DIR/"
cp /backup/host/indexer.env "$BACKUP_DIR/"
cp /backup/host/dashboard.env "$BACKUP_DIR/"
cp /backup/host/docker-compose.yml "$BACKUP_DIR/"

echo "Docker configuration backup complete"

# Create tarball (NO timestamp in filename)
tar -czf /backup/temp/wazuh-latest.tar.gz -C /backup/temp wazuh-backup

# Upload to S3
aws s3 cp /backup/temp/wazuh-latest.tar.gz s3://${BUCKET_NAME}/wazuh/wazuh-latest.tar.gz

# MQTT notification
mosquitto_pub -h ${MQTT_HOST} -u ${MQTT_USERNAME} -P ${MQTT_PASSWORD} \
  -t "backup/wazuh/time" -m "$(date -Iseconds)" --retain

# Cleanup
rm -rf /backup/temp
