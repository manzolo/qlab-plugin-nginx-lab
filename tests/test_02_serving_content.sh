#!/usr/bin/env bash
# Test Exercise 2 — Serving Content
# Verifies Nginx serves static content and custom pages work.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

echo ""
echo "${BOLD}Exercise 2 — Serving Content${RESET}"
echo ""

# 2.1 Default page is served
page=$(ssh_vm "curl -s localhost")
assert_contains "Default page returns HTTP content" "$page" "<"

# 2.2 Document root exists
assert "Document root /var/www/html exists" ssh_vm "test -d /var/www/html"

# 2.3 Modify the default page
ssh_vm "echo '<h1>Test Page</h1>' | sudo tee /var/www/html/index.html" >/dev/null
modified=$(ssh_vm "curl -s localhost")
assert_contains "Modified page is served immediately" "$modified" "Test Page"

# 2.4 Create a subdirectory with content
ssh_vm "sudo mkdir -p /var/www/html/docs && echo '<h1>Docs</h1>' | sudo tee /var/www/html/docs/index.html" >/dev/null
docs=$(ssh_vm "curl -s localhost/docs/")
assert_contains "Subdirectory content is served" "$docs" "Docs"

# 2.5 HTTP status code for existing page
code=$(ssh_vm "curl -s -o /dev/null -w '%{http_code}' localhost")
assert_contains "Existing page returns 200" "$code" "200"

# 2.6 HTTP status code for missing page
code404=$(ssh_vm "curl -s -o /dev/null -w '%{http_code}' localhost/nonexistent")
assert_contains "Missing page returns 404" "$code404" "404"

# Cleanup
ssh_vm "sudo rm -rf /var/www/html/docs" >/dev/null 2>&1

report_results "Exercise 2"
