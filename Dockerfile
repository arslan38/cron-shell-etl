FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cron \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Copy data
COPY data/ /data/

# Copy crontab
COPY crontab /etc/cron.d/etl-cron
RUN chmod 0644 /etc/cron.d/etl-cron

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create log directory
RUN mkdir -p /var/log/etl

ENTRYPOINT ["/entrypoint.sh"]
