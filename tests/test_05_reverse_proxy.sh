#!/usr/bin/env bash
# Test Exercise 5 — Reverse Proxy
# Verifies Nginx can proxy requests to a backend application.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 5 — Reverse Proxy${RESET}"
echo ""

# 5.1 Start a backend server
ssh_vm "sudo systemctl stop test-backend 2>/dev/null; sudo systemctl reset-failed test-backend 2>/dev/null; true"
ssh_vm "mkdir -p /tmp/backend && echo '{\"status\":\"ok\"}' > /tmp/backend/index.html"
ssh_vm "sudo systemd-run --quiet --unit=test-backend python3 -m http.server 8080 --directory /tmp/backend"

# Wait for the server to be ready (poll up to 10 seconds)
for _i in $(seq 1 10); do
    if ssh_vm "curl -s --max-time 1 localhost:8080" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# 5.2 Backend is reachable directly
backend=$(ssh_vm "curl -s --max-time 5 localhost:8080" 2>/dev/null) || true
assert_contains "Backend server responds on port 8080" "$backend" "status"

# 5.3 Configure reverse proxy
ssh_vm "sudo tee /etc/nginx/sites-available/proxy.conf > /dev/null << 'PROXYEOF'
server {
    listen 8081;
    server_name localhost;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
PROXYEOF"

ssh_vm "sudo ln -sf /etc/nginx/sites-available/proxy.conf /etc/nginx/sites-enabled/"

# 5.4 Config validates
config_test=$(ssh_vm "sudo nginx -t 2>&1")
assert_contains "Proxy config validates" "$config_test" "syntax is ok"

# 5.5 Reload
assert "Nginx reload with proxy config" ssh_vm "sudo systemctl reload nginx"
sleep 1

# 5.6 Proxy forwards requests
proxy_response=$(ssh_vm "curl -s --max-time 5 localhost:8081" 2>/dev/null) || true
assert_contains "Proxy returns backend response" "$proxy_response" "status"

# Cleanup
ssh_vm "sudo systemctl stop test-backend 2>/dev/null; sudo rm -f /etc/nginx/sites-enabled/proxy.conf /etc/nginx/sites-available/proxy.conf; sudo systemctl reload nginx; rm -rf /tmp/backend" >/dev/null 2>&1 || true

report_results "Exercise 5"
