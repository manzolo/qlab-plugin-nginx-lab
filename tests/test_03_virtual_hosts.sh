#!/usr/bin/env bash
# Test Exercise 3 — Virtual Hosts
# Verifies virtual host creation and management.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 3 — Virtual Hosts${RESET}"
echo ""

# 3.1 Create a virtual host
ssh_vm "sudo mkdir -p /var/www/mysite && echo '<h1>mysite</h1>' | sudo tee /var/www/mysite/index.html" >/dev/null

ssh_vm "sudo tee /etc/nginx/sites-available/mysite.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name mysite.local;
    root /var/www/mysite;
    index index.html;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF"

# 3.2 Enable the site
ssh_vm "sudo ln -sf /etc/nginx/sites-available/mysite.conf /etc/nginx/sites-enabled/"

# 3.3 Validate config
config_test=$(ssh_vm "sudo nginx -t 2>&1")
assert_contains "Config validation passes" "$config_test" "syntax is ok|test is successful"

# 3.4 Reload Nginx
assert "Nginx reload succeeds" ssh_vm "sudo systemctl reload nginx"

# 3.5 Virtual host responds to correct Host header
vhost_page=$(ssh_vm "curl -s -H 'Host: mysite.local' localhost")
assert_contains "Virtual host serves correct content" "$vhost_page" "mysite"

# 3.6 Default site still works
default_page=$(ssh_vm "curl -s localhost")
assert_contains "Default site still responds" "$default_page" "<"

# 3.7 Disable the site
ssh_vm "sudo rm -f /etc/nginx/sites-enabled/mysite.conf && sudo systemctl reload nginx" >/dev/null

# Cleanup
ssh_vm "sudo rm -f /etc/nginx/sites-available/mysite.conf && sudo rm -rf /var/www/mysite" >/dev/null 2>&1

report_results "Exercise 3"
