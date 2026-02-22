#!/usr/bin/env bash
# Test Exercise 1 — Nginx Anatomy
# Verifies Nginx is running and configuration structure is correct.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 1 — Nginx Anatomy${RESET}"
echo ""

# 1.1 Nginx service is running
status=$(ssh_vm "systemctl is-active nginx")
assert_contains "Nginx service is active" "$status" "^active$"

# 1.2 Configuration directory structure
config_ls=$(ssh_vm "ls /etc/nginx/")
assert_contains "nginx.conf exists" "$config_ls" "nginx.conf"
assert_contains "sites-available exists" "$config_ls" "sites-available"
assert_contains "sites-enabled exists" "$config_ls" "sites-enabled"

# 1.3 Main config file has key directives
main_conf=$(ssh_vm "cat /etc/nginx/nginx.conf")
assert_contains "Config has worker_processes" "$main_conf" "worker_processes"
assert_contains "Config includes sites-enabled" "$main_conf" "include.*sites-enabled"

# 1.4 Default site is enabled
assert "Default site exists in sites-available" ssh_vm "test -f /etc/nginx/sites-available/default"
assert "Default site is enabled (symlink in sites-enabled)" ssh_vm "test -e /etc/nginx/sites-enabled/default"

# 1.5 Default page is served
page=$(ssh_vm "curl -s localhost")
assert_contains "Default page returns content" "$page" "<html|<h1|nginx|Hello"

report_results "Exercise 1"
