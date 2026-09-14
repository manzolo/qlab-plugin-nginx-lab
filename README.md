# nginx-lab — Nginx Web Server Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Walkthrough](https://img.shields.io/badge/walkthrough-EN%20%26%20IT-informational)](docs/walkthrough-en.pdf)

A single-VM [QLab](https://github.com/manzolo/qlab) lab with Nginx preinstalled and its
port forwarded to the host — for learning how a web server serves content, virtual hosts,
logs, reverse proxying and a few security basics, by configuring them yourself.

## Quick start

```bash
qlab install nginx-lab
qlab run nginx-lab       # boots 1 VM (~60s)
qlab shell nginx-lab     # log in: labuser / labpass
qlab test nginx-lab      # run the automated checks
qlab stop nginx-lab
```

Check the forwarded HTTP port with `qlab ports`, then `curl http://127.0.0.1:<port>/`.

## What's inside

| # | Exercise | What you do |
|---|----------|-------------|
| 1 | Nginx anatomy | installation, config files, running processes |
| 2 | Serving content | edit the default page, serve custom HTML |
| 3 | Virtual hosts | multiple sites with server blocks |
| 4 | Logs & monitoring | read access/error logs, watch traffic |
| 5 | Reverse proxy | put Nginx in front of a backend |
| 6 | Security basics | rate limiting and access restrictions |

## Access

| | |
|---|---|
| **SSH** | `labuser` / `labpass` |
| **Ports** | SSH + HTTP (80), dynamically allocated — see `qlab ports` |

## Learn more

- 📖 **[Step-by-step guide](guide.md)** — every exercise with full config examples
- 📄 **Illustrated walkthrough** — a real run, captured live: **[English](docs/walkthrough-en.pdf)** · **[Italiano](docs/walkthrough-it.pdf)**
- 🧩 **[QLab](https://github.com/manzolo/qlab)** — the plugin runner: how install, overlays and cloud-init work
