# nginx-lab — Nginx Web Server Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://github.com/manzolo/qlab)

A [QLab](https://github.com/manzolo/qlab) plugin that boots a virtual machine with Nginx installed and configured as a web server.

## Objectives

- Learn how to provision packages via cloud-init
- Understand how Nginx serves web content
- Practice port forwarding to access services inside a VM
- Test HTTP responses using curl from the host

## How It Works

1. **Cloud image**: Downloads a minimal Ubuntu 22.04 cloud image (~250MB)
2. **Cloud-init**: Creates `user-data` with Nginx package installation and custom index page
3. **ISO generation**: Packs cloud-init files into a small ISO (cidata)
4. **Overlay disk**: Creates a COW disk on top of the base image (original stays untouched)
5. **QEMU boot**: Starts the VM in background with SSH and HTTP port forwarding

## Credentials

- **Username:** `labuser`
- **Password:** `labpass`

## Ports

| Service | Host Port | VM Port |
|---------|-----------|---------|
| SSH     | 2223      | 22      |
| HTTP    | 8080      | 80      |

## Usage

```bash
# Install the plugin
qlab install nginx-lab

# Run the lab
qlab run nginx-lab

# Wait ~60s for boot and package installation, then:

# Test the web server
curl http://localhost:8080

# Connect via SSH
qlab shell nginx-lab

# Inside the VM, you can:
#   - Edit /var/www/html/index.html
#   - Check nginx status: systemctl status nginx
#   - View nginx logs: tail -f /var/log/nginx/access.log

# Stop the VM
qlab stop nginx-lab
```

## Exercises

1. **Verify Nginx is running**: SSH into the VM and check `systemctl status nginx`
2. **Modify the web page**: Edit `/var/www/html/index.html` and refresh from the host
3. **Check access logs**: Run `tail -f /var/log/nginx/access.log` inside the VM, then curl from the host
4. **Create a virtual host**: Configure a new site in `/etc/nginx/sites-available/`

## Resetting

To start fresh, stop and re-run:

```bash
qlab stop nginx-lab
qlab run nginx-lab
```

Or reset the entire workspace:

```bash
qlab reset
```
