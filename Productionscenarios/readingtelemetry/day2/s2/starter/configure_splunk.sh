#!/usr/bin/env bash
# Configures an installed Splunk Enterprise (/opt/splunk) to ingest the checkout log:
# index=retail_prod  sourcetype=checkout:json  host=prod-worker-02
# Usage:  sudo SPLUNK_PASS='<admin password>' bash configure_splunk.sh
# (If Splunk is not installed: download the .deb from splunk.com -> Free Trial -> Linux,
#  sudo dpkg -i splunk*.deb, then run this with the password you want to seed.)
set -uo pipefail
: "${SPLUNK_PASS:?set SPLUNK_PASS}"
S=/opt/splunk/bin/splunk
mkdir -p /opt/splunk/etc/system/local
grep -q '^\[checkout:json\]' /opt/splunk/etc/system/local/props.conf 2>/dev/null || cat >> /opt/splunk/etc/system/local/props.conf <<'EOF'

[checkout:json]
INDEXED_EXTRACTIONS = json
TIMESTAMP_FIELDS = timestamp
TIME_FORMAT = %Y-%m-%dT%H:%M:%S.%3N%:z
KV_MODE = none
EOF
$S status >/dev/null 2>&1 || $S start --accept-license --answer-yes --no-prompt --seed-passwd "$SPLUNK_PASS" --run-as-root
$S add index retail_prod -auth "admin:$SPLUNK_PASS" 2>&1 | grep -v 'already exists' || true
touch /var/log/checkout/checkout.json
$S add monitor /var/log/checkout/checkout.json -index retail_prod -sourcetype checkout:json -hostname prod-worker-02 -auth "admin:$SPLUNK_PASS" 2>&1 || true
$S restart --run-as-root >/dev/null
echo "Splunk ready on :8000 (open via: ssh -L 8000:localhost:8000 <user>@<vm-ip>)"
