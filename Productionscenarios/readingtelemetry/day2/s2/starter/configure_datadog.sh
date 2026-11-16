#!/usr/bin/env bash
# Installs/points the Datadog Agent at YOUR Datadog org, names the host prod-worker-02,
# enables APM + log collection of /var/log/checkout/checkout.json.
# Usage:  sudo DD_API_KEY=<key from YOUR org> DD_SITE=datadoghq.com bash configure_datadog.sh
# IMPORTANT: the API key must come from the same Datadog org you log into in the browser
# (Organization Settings -> API Keys), otherwise hosts/services/logs land in another account.
set -euo pipefail
: "${DD_API_KEY:?set DD_API_KEY}"; DD_SITE="${DD_SITE:-datadoghq.com}"
CFG=/etc/datadog-agent/datadog.yaml

if ! command -v datadog-agent >/dev/null && [ ! -x /opt/datadog-agent/bin/agent/agent ]; then
  DD_API_KEY="$DD_API_KEY" DD_SITE="$DD_SITE" bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"
fi

# remove any previous values for the keys we manage, then append clean ones
python3 - "$CFG" "$DD_API_KEY" "$DD_SITE" <<'EOF'
import sys, re
p, key, site = sys.argv[1:]
lines = open(p).read().splitlines()
out, skip = [], False
for l in lines:
    if re.match(r'^(api_key|site|hostname|logs_enabled):', l): continue
    if re.match(r'^apm_config:', l): skip = True; continue
    if skip and (l.startswith(' ') or l.strip()=='' ): continue
    skip = False; out.append(l)
out += [f"api_key: {key}", f"site: {site}", "hostname: prod-worker-02", "logs_enabled: true", "apm_config:", "  enabled: true"]
open(p, "w").write("\n".join(out) + "\n")
EOF

mkdir -p /etc/datadog-agent/conf.d/checkout.d
cat > /etc/datadog-agent/conf.d/checkout.d/conf.yaml <<'EOF'
logs:
  - type: file
    path: /var/log/checkout/checkout.json
    service: checkout-api
    source: python
EOF
chown -R dd-agent:dd-agent /etc/datadog-agent/conf.d/checkout.d 2>/dev/null || true
systemctl restart datadog-agent
sleep 20
/opt/datadog-agent/bin/agent/agent status | grep -E 'API Key|Hostname:|checkout' | head
