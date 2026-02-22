#!/usr/bin/env bash
# Test Exercise 6 — Security Basics
# Verifies basic authentication and access control.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 6 — Security Basics${RESET}"
echo ""

# 6.1 Install apache2-utils for htpasswd
ssh_vm "sudo apt-get install -y apache2-utils" >/dev/null 2>&1
assert "htpasswd is available" ssh_vm "which htpasswd"

# 6.2 Create password file and protected directory
ssh_vm "sudo htpasswd -cb /etc/nginx/.htpasswd admin secret123" >/dev/null 2>&1
assert "Password file created" ssh_vm "test -f /etc/nginx/.htpasswd"

ssh_vm "sudo mkdir -p /var/www/html/secret && echo '<h1>Secret</h1>' | sudo tee /var/www/html/secret/index.html" >/dev/null

# 6.3 Configure basic auth
ssh_vm "sudo tee /etc/nginx/sites-available/secure.conf > /dev/null << 'EOF'
server {
    listen 8082;
    root /var/www/html;
    location /secret/ {
        auth_basic \"Restricted\";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
EOF"

ssh_vm "sudo ln -sf /etc/nginx/sites-available/secure.conf /etc/nginx/sites-enabled/"
ssh_vm "sudo nginx -t && sudo systemctl reload nginx" >/dev/null 2>&1
sleep 1

# 6.4 Unauthenticated request returns 401
code_noauth=$(ssh_vm "curl -s -o /dev/null -w '%{http_code}' localhost:8082/secret/")
assert_contains "Unauthenticated request returns 401" "$code_noauth" "401"

# 6.5 Correct credentials return 200
code_auth=$(ssh_vm "curl -s -o /dev/null -w '%{http_code}' -u admin:secret123 localhost:8082/secret/")
assert_contains "Correct credentials return 200" "$code_auth" "200"

# 6.6 Authenticated request returns content
content=$(ssh_vm "curl -s -u admin:secret123 localhost:8082/secret/")
assert_contains "Authenticated request returns protected content" "$content" "Secret"

# 6.7 Wrong credentials return 401
code_wrong=$(ssh_vm "curl -s -o /dev/null -w '%{http_code}' -u admin:wrongpass localhost:8082/secret/")
assert_contains "Wrong credentials return 401" "$code_wrong" "401"

# Cleanup
ssh_vm "sudo rm -f /etc/nginx/sites-enabled/secure.conf /etc/nginx/sites-available/secure.conf /etc/nginx/.htpasswd; sudo rm -rf /var/www/html/secret; sudo systemctl reload nginx" >/dev/null 2>&1

report_results "Exercise 6"
