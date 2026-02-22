# Nginx Lab — Step-by-Step Guide

This guide walks you through understanding and configuring **Nginx**, one of the most popular web servers in the world. Nginx handles over 30% of all websites and is widely used as a web server, reverse proxy, and load balancer.

By the end of this lab you will understand how Nginx works internally, how to serve static content, configure virtual hosts, set up a reverse proxy, and implement basic security measures.

## Prerequisites

Start the lab and wait for the VM to finish booting (~60 seconds):

```bash
qlab run nginx-lab
```

Open a terminal and connect to the VM:

```bash
qlab shell nginx-lab
```

Make sure cloud-init has finished:

```bash
cloud-init status --wait
```

## Credentials

- **Username:** `labuser`
- **Password:** `labpass`
- **Sudo:** passwordless (`sudo` works without prompt)

## Ports

| Service | Host Port | VM Port |
|---------|-----------|---------|
| SSH     | dynamic   | 22      |
| HTTP    | dynamic   | 80      |

> Use `qlab ports` on the host to see the actual port mappings.

---

## Exercise 01 — Nginx Anatomy

**VM:** nginx-lab
**Goal:** Understand how Nginx is structured before changing anything.

Nginx uses an event-driven, asynchronous architecture that makes it efficient at handling thousands of concurrent connections. Unlike Apache, which typically spawns a new process or thread per connection, Nginx uses a single master process with multiple worker processes, each handling many connections.

### 1.1 Check Nginx is running

```bash
systemctl status nginx
```

**Expected output:**
```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; ...)
     Active: active (running) since ...
```

### 1.2 Explore the configuration structure

```bash
ls /etc/nginx/
```

**Expected output:**
```
conf.d          koi-utf     modules-available  proxy_params     snippets
fastcgi.conf    koi-win     modules-enabled    scgi_params      uwsgi_params
fastcgi_params  mime.types  nginx.conf         sites-available  win-utf
                                               sites-enabled
```

Key directories:
- `nginx.conf` — main configuration file
- `sites-available/` — virtual host configuration files (available but not necessarily active)
- `sites-enabled/` — symlinks to active sites in `sites-available/`
- `conf.d/` — additional configuration snippets

### 1.3 Read the main configuration file

```bash
cat /etc/nginx/nginx.conf
```

Key directives to notice:
- `worker_processes auto;` — number of worker processes (auto = one per CPU core)
- `events { worker_connections 768; }` — max connections per worker
- `include /etc/nginx/sites-enabled/*;` — loads all active virtual hosts

### 1.4 Check the default site configuration

```bash
cat /etc/nginx/sites-available/default
```

Notice the `server` block — this defines a virtual host:
- `listen 80 default_server;` — listen on port 80
- `root /var/www/html;` — document root
- `index index.html;` — default file to serve

### 1.5 Verify the default page works

```bash
curl -s localhost
```

You should see the HTML content of the default Nginx welcome page.

**Verification:** If `systemctl status nginx` shows `active (running)` and `curl localhost` returns HTML content, Nginx is working correctly.

---

## Exercise 02 — Serving Content

**VM:** nginx-lab
**Goal:** Learn how Nginx serves static files and how to customize web content.

Web servers are fundamentally file servers — they receive HTTP requests and respond with files from the filesystem. Understanding the document root and how Nginx maps URLs to files is essential for any web administrator.

### 2.1 View the current web page

```bash
curl -s localhost
```

### 2.2 Check the document root

```bash
ls -la /var/www/html/
```

**Expected output:**
```
total 12
drwxr-xr-x 2 root root 4096 ...
-rw-r--r-- 1 root root  ... index.html
```

### 2.3 Modify the default page

```bash
echo '<h1>Hello from nginx-lab!</h1><p>This page was modified by a student.</p>' | sudo tee /var/www/html/index.html
```

### 2.4 Verify the change

```bash
curl -s localhost
```

**Expected output:**
```html
<h1>Hello from nginx-lab!</h1><p>This page was modified by a student.</p>
```

Notice that you did **not** need to restart Nginx — static file changes are served immediately because Nginx reads files from disk on each request.

### 2.5 Create a subdirectory with content

```bash
sudo mkdir -p /var/www/html/docs
echo '<h1>Documentation</h1><p>This is the docs section.</p>' | sudo tee /var/www/html/docs/index.html
```

### 2.6 Access the subdirectory

```bash
curl -s localhost/docs/
```

**Expected output:**
```html
<h1>Documentation</h1><p>This is the docs section.</p>
```

Nginx automatically maps URL paths to filesystem directories relative to the document root.

**Verification:** `curl localhost` shows your custom content, and `curl localhost/docs/` shows the subdirectory page.

---

## Exercise 03 — Virtual Hosts

**VM:** nginx-lab
**Goal:** Serve multiple websites from a single Nginx instance using server blocks (virtual hosts).

Virtual hosts allow one web server to handle requests for different domain names, each with its own content and configuration. This is how shared hosting works — hundreds of websites on a single server.

### 3.1 Create a new site directory

```bash
sudo mkdir -p /var/www/mysite
echo '<h1>Welcome to mysite.local</h1>' | sudo tee /var/www/mysite/index.html
```

### 3.2 Create a virtual host configuration

```bash
sudo tee /etc/nginx/sites-available/mysite.conf << 'EOF'
server {
    listen 80;
    server_name mysite.local;
    root /var/www/mysite;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
```

### 3.3 Enable the site

```bash
sudo ln -s /etc/nginx/sites-available/mysite.conf /etc/nginx/sites-enabled/
```

### 3.4 Test the configuration

Always validate before reloading:

```bash
sudo nginx -t
```

**Expected output:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 3.5 Reload Nginx

```bash
sudo systemctl reload nginx
```

### 3.6 Test the virtual host

```bash
curl -s -H "Host: mysite.local" localhost
```

**Expected output:**
```html
<h1>Welcome to mysite.local</h1>
```

The `-H "Host: mysite.local"` header tells Nginx which virtual host to use. In production, DNS would resolve the domain name to the server's IP.

### 3.7 Disable the site

```bash
sudo rm /etc/nginx/sites-enabled/mysite.conf
sudo systemctl reload nginx
```

**Verification:** After enabling, `curl -H "Host: mysite.local" localhost` returns the mysite content. After disabling, it falls back to the default site.

---

## Exercise 04 — Logs and Monitoring

**VM:** nginx-lab
**Goal:** Understand Nginx logging and how to diagnose problems.

Logs are your primary diagnostic tool in production. Nginx writes two types of logs: access logs (every HTTP request) and error logs (problems and warnings). Reading logs effectively is a core sysadmin skill.

### 4.1 View the access log

```bash
sudo tail -5 /var/log/nginx/access.log
```

**Expected output (example):**
```
127.0.0.1 - - [21/Feb/2026:10:15:30 +0000] "GET / HTTP/1.1" 200 73 "-" "curl/7.81.0"
```

Each field: client IP, identity, user, timestamp, request, status code, bytes, referrer, user-agent.

### 4.2 View the error log

```bash
sudo tail -5 /var/log/nginx/error.log
```

### 4.3 Generate traffic and watch live

In one terminal, watch the log:

```bash
sudo tail -f /var/log/nginx/access.log
```

In another terminal (or from the host), generate requests:

```bash
curl -s localhost >/dev/null
curl -s localhost/nonexistent >/dev/null
```

### 4.4 Check for 404 errors

```bash
curl -s -o /dev/null -w "%{http_code}" localhost/nonexistent
```

**Expected output:**
```
404
```

### 4.5 Validate configuration

```bash
sudo nginx -t
```

This checks all configuration files for syntax errors without restarting Nginx. Always run this before reloading.

### 4.6 Check Nginx process info

```bash
ps aux | grep nginx
```

**Expected output:**
```
root       ... nginx: master process /usr/sbin/nginx ...
www-data   ... nginx: worker process
```

Notice the master process runs as root (to bind to port 80), while worker processes run as `www-data` for security.

**Verification:** You can read both access and error logs, and `nginx -t` reports no errors.

---

## Exercise 05 — Reverse Proxy

**VM:** nginx-lab
**Goal:** Configure Nginx as a reverse proxy to forward requests to a backend application.

A reverse proxy sits between clients and backend servers. Clients talk to Nginx, and Nginx forwards requests to the actual application. This is how most modern web applications are deployed — the application server (Node.js, Python, Java) runs on an internal port, and Nginx handles SSL, caching, and load balancing in front of it.

### 5.1 Start a simple backend application

```bash
mkdir -p /tmp/backend
echo '{"status": "ok", "message": "Hello from backend on port 8080"}' > /tmp/backend/index.html
sudo systemd-run --quiet --unit=test-backend python3 -m http.server 8080 --directory /tmp/backend
```

Using `systemd-run` instead of `&` ensures the process runs reliably in the background as a systemd transient unit, which is especially important when running commands over SSH.

### 5.2 Verify the backend works directly

```bash
curl -s localhost:8080
```

**Expected output:**
```json
{"status": "ok", "message": "Hello from backend on port 8080"}
```

### 5.3 Configure Nginx as reverse proxy

```bash
sudo tee /etc/nginx/sites-available/proxy.conf << 'EOF'
server {
    listen 8081;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF
```

Key directives:
- `proxy_pass` — forward requests to this backend URL
- `proxy_set_header Host` — pass the original Host header to the backend
- `proxy_set_header X-Real-IP` — pass the client's real IP (not Nginx's IP)

### 5.4 Enable and reload

```bash
sudo ln -s /etc/nginx/sites-available/proxy.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### 5.5 Test the reverse proxy

```bash
curl -s localhost:8081
```

**Expected output:**
```json
{"status": "ok", "message": "Hello from backend on port 8080"}
```

The response comes from the backend on port 8080, but you accessed it via Nginx on port 8081. In production, Nginx would listen on port 80/443 and proxy to internal services.

### 5.6 Clean up

```bash
sudo systemctl stop test-backend  # stop the Python server
sudo rm /etc/nginx/sites-enabled/proxy.conf
sudo systemctl reload nginx
```

**Verification:** `curl localhost:8081` returns the backend response when the proxy is active, proving Nginx is forwarding requests.

---

## Exercise 06 — Security Basics

**VM:** nginx-lab
**Goal:** Implement basic security measures to protect web content.

Security is not optional — every web server exposed to the internet will be scanned and probed. Understanding basic access control mechanisms helps you protect sensitive content and limit abuse.

### 6.1 Install the htpasswd utility

```bash
sudo apt-get install -y apache2-utils
```

### 6.2 Create a password file

```bash
sudo htpasswd -cb /etc/nginx/.htpasswd admin secret123
```

This creates a file with the user `admin` and password `secret123` (hashed).

### 6.3 Create a protected directory

```bash
sudo mkdir -p /var/www/html/secret
echo '<h1>Secret Area</h1><p>You are authenticated!</p>' | sudo tee /var/www/html/secret/index.html
```

### 6.4 Configure basic auth

```bash
sudo tee /etc/nginx/sites-available/secure.conf << 'EOF'
server {
    listen 8082;
    root /var/www/html;

    location /secret/ {
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/secure.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### 6.5 Test without credentials

```bash
curl -s -o /dev/null -w "%{http_code}" localhost:8082/secret/
```

**Expected output:**
```
401
```

### 6.6 Test with credentials

```bash
curl -s -u admin:secret123 localhost:8082/secret/
```

**Expected output:**
```html
<h1>Secret Area</h1><p>You are authenticated!</p>
```

### 6.7 Test with wrong credentials

```bash
curl -s -o /dev/null -w "%{http_code}" -u admin:wrongpass localhost:8082/secret/
```

**Expected output:**
```
401
```

### 6.8 Clean up

```bash
sudo rm /etc/nginx/sites-enabled/secure.conf
sudo rm -f /etc/nginx/.htpasswd
sudo rm -rf /var/www/html/secret
sudo systemctl reload nginx
```

**Verification:** Unauthenticated requests return 401, correct credentials return 200 with content, wrong credentials return 401.

---

## Troubleshooting

### Nginx won't start
```bash
# Check for configuration errors
sudo nginx -t

# Check if port 80 is already in use
sudo ss -tlnp | grep ':80'

# Check the error log
sudo tail -20 /var/log/nginx/error.log
```

### "Address already in use" error
Another process is using the port. Find and stop it:
```bash
sudo ss -tlnp | grep ':80'
sudo kill <PID>
```

### Changes not taking effect
```bash
# Did you reload after config change?
sudo systemctl reload nginx

# Did you create the symlink in sites-enabled?
ls -la /etc/nginx/sites-enabled/
```

### Permission denied errors
```bash
# Check file ownership and permissions
ls -la /var/www/html/

# Nginx worker runs as www-data — files must be readable
sudo chown -R www-data:www-data /var/www/html/
```

### 502 Bad Gateway (reverse proxy)
The backend is not running or not reachable:
```bash
# Is the backend running?
curl localhost:8080

# Check Nginx error log for details
sudo tail -20 /var/log/nginx/error.log
```

### Packages not installed
Cloud-init may still be running:
```bash
cloud-init status --wait
```
