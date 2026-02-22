#!/usr/bin/env bash
# Test Exercise 4 — Logs and Monitoring
# Verifies logging and diagnostic capabilities.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 4 — Logs and Monitoring${RESET}"
echo ""

# 4.1 Access log exists
assert "Access log file exists" ssh_vm "test -f /var/log/nginx/access.log"

# 4.2 Error log exists
assert "Error log file exists" ssh_vm "test -f /var/log/nginx/error.log"

# 4.3 Generate a request and check access log
ssh_vm "curl -s localhost >/dev/null"
sleep 1
access_log=$(ssh_vm "sudo tail -5 /var/log/nginx/access.log")
assert_contains "Access log records requests" "$access_log" "GET / HTTP"

# 4.4 Generate a 404 and check it's logged
ssh_vm "curl -s localhost/test_404_page >/dev/null"
sleep 1
access_log_404=$(ssh_vm "sudo tail -5 /var/log/nginx/access.log")
assert_contains "404 requests are logged" "$access_log_404" "404"

# 4.5 Config validation works
config_test=$(ssh_vm "sudo nginx -t 2>&1")
assert_contains "nginx -t validates successfully" "$config_test" "syntax is ok"

# 4.6 Nginx processes are running
ps_output=$(ssh_vm "ps aux | grep '[n]ginx'")
assert_contains "Master process is running" "$ps_output" "nginx: master process"
assert_contains "Worker process is running" "$ps_output" "nginx: worker process"

report_results "Exercise 4"
