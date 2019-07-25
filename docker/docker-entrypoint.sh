#!/usr/bin/env bash
set -e

echo "logs_enabled: true" >> /etc/datadog-agent/datadog.yaml && \
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
