# ScratchBird Multi-Database Server
# Supports: Native (ScratchBird), PostgreSQL, MySQL, Firebird

FROM ubuntu:22.04

LABEL maintainer="Dalton Calford"
LABEL description="ScratchBird Database Server with optional PostgreSQL, MySQL, and Firebird"
LABEL version="1.0.0"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Build arguments with defaults
ARG SCRATCHBIRD_VERSION=1.0.0
ARG ENABLE_NATIVE=true
ARG ENABLE_POSTGRES=true
ARG ENABLE_MYSQL=true
ARG ENABLE_FIREBIRD=true

# Runtime configuration environment variables
ENV SB_IP=0.0.0.0
ENV SB_DATA_DIR=/var/lib/scratchbird/data
ENV SB_CONFIG_DIR=/etc/scratchbird
ENV SB_LOG_DIR=/var/log/scratchbird
ENV SB_TEMP_DIR=/var/tmp/scratchbird
ENV SB_MEMORY_LIMIT=2G
ENV SB_DISK_LIMIT=100G

# Database service ports (can be overridden)
# Standard ports:
# - ScratchBird Native: 3092
# - Firebird: 3050  
# - PostgreSQL: 5432
# - MySQL: 3306
ENV SB_NATIVE_PORT=3092
ENV SB_POSTGRES_PORT=5432
ENV SB_MYSQL_PORT=3306
ENV SB_FIREBIRD_PORT=3050

# Default database to open
ENV SB_DEFAULT_DATABASE=default

# Service enablement flags
ENV SB_ENABLE_NATIVE=${ENABLE_NATIVE}
ENV SB_ENABLE_POSTGRES=${ENABLE_POSTGRES}
ENV SB_ENABLE_MYSQL=${ENABLE_MYSQL}
ENV SB_ENABLE_FIREBIRD=${ENABLE_FIREBIRD}

# Performance settings
ENV SB_MAX_CONNECTIONS=100
ENV SB_SHARED_BUFFERS=256MB
ENV SB_WORK_MEM=64MB
ENV SB_MAINTENANCE_WORK_MEM=256MB
ENV SB_EFFECTIVE_CACHE_SIZE=1GB

# Security settings
ENV SB_SSL_MODE=prefer
ENV SB_SSL_CERT_PATH=/etc/scratchbird/ssl/server.crt
ENV SB_SSL_KEY_PATH=/etc/scratchbird/ssl/server.key
ENV SB_REQUIRE_AUTH=true

# Logging settings
ENV SB_LOG_LEVEL=INFO
ENV SB_LOG_ROTATION=daily
ENV SB_LOG_RETENTION_DAYS=30

# Backup settings
ENV SB_BACKUP_ENABLED=true
ENV SB_BACKUP_SCHEDULE=0 2 * * *
ENV SB_BACKUP_RETENTION_DAYS=7
ENV SB_BACKUP_DIR=/var/lib/scratchbird/backups

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Core utilities
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    # Build tools
    build-essential \
    cmake \
    git \
    # Runtime libraries
    libssl-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    # Monitoring
    htop \
    iotop \
    net-tools \
    procps \
    # Logging
    rsyslog \
    logrotate \
    # Cron for backups
    cron \
    # Process manager
    supervisor \
    # Health check
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Install PostgreSQL if enabled
RUN if [ "$ENABLE_POSTGRES" = "true" ]; then \
    apt-get update && apt-get install -y \
    postgresql-14 \
    postgresql-client-14 \
    postgresql-contrib-14 \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Install MySQL if enabled
RUN if [ "$ENABLE_MYSQL" = "true" ]; then \
    apt-get update && apt-get install -y \
    mysql-server-8.0 \
    mysql-client-8.0 \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Install Firebird if enabled
RUN if [ "$ENABLE_FIREBIRD" = "true" ]; then \
    apt-get update && apt-get install -y \
    firebird3.0-server \
    firebird3.0-utils \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Create directories
RUN mkdir -p \
    ${SB_DATA_DIR} \
    ${SB_CONFIG_DIR} \
    ${SB_LOG_DIR} \
    ${SB_TEMP_DIR} \
    ${SB_BACKUP_DIR} \
    /etc/scratchbird/ssl \
    /var/run/scratchbird \
    /docker-entrypoint-initdb.d

# Set up volumes
VOLUME ["${SB_DATA_DIR}", "${SB_CONFIG_DIR}", "${SB_LOG_DIR}", "${SB_BACKUP_DIR}"]

# Copy configuration templates
COPY config/ ${SB_CONFIG_DIR}/
COPY scripts/ /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
COPY supervisord.conf /etc/supervisor/conf.d/scratchbird.conf

# Make scripts executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    /usr/local/bin/*.sh

# Create scratchbird user
RUN groupadd -r scratchbird && \
    useradd -r -g scratchbird -d ${SB_DATA_DIR} -s /bin/bash scratchbird && \
    chown -R scratchbird:scratchbird \
        ${SB_DATA_DIR} \
        ${SB_CONFIG_DIR} \
        ${SB_LOG_DIR} \
        ${SB_TEMP_DIR} \
        ${SB_BACKUP_DIR} \
        /var/run/scratchbird

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Expose ports (can be mapped at runtime)
EXPOSE ${SB_NATIVE_PORT}    # ScratchBird Native (SBWP v1.1)
EXPOSE ${SB_POSTGRES_PORT}  # PostgreSQL
EXPOSE ${SB_MYSQL_PORT}     # MySQL
EXPOSE ${SB_FIREBIRD_PORT}  # Firebird
EXPOSE 8080  # Web admin interface
EXPOSE 9090  # Metrics/prometheus

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/scratchbird.conf"]
