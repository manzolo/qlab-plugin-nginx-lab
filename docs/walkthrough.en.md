---
kicker: QLab · nginx-lab
title: |
  One server,
  many sites
subtitle: >
  Nginx as it ships, then as the exercises leave it. Every block below came out
  of a running lab: the process tree, the sockets it holds, the config it will
  accept, and the requests it answered.
facts:
  - [Command, "`qlab run nginx-lab`"]
  - [VM, "`nginx-lab`, port 80 forwarded to a dynamic host port"]
  - [Credentials, "`labuser` / `labpass`"]
  - [Outcome, "`qlab test nginx-lab` → 6 exercises, 36 checks, all passed"]
---

## 1. What is running

{{evidence:version as=shell}}

{{evidence:processes}}

Two processes, and the split between them is the whole architecture. The
**master** runs as `root` — it has to, because binding port 80 requires
privilege and because it is the one that re-reads the configuration. The
**worker** runs as `www-data` and is the process that actually talks to the
network. A flaw in request handling therefore lands in an unprivileged process,
which is the entire point of the arrangement.

That is also why `systemctl reload nginx` is not the same as `restart`: the
master keeps the listening sockets and hands the workers a new configuration,
so no connection is dropped.

{{evidence:listening}}

## 2. The site it boots with

{{evidence:sites}}

`sites-available` holds what exists; `sites-enabled` holds what is switched on,
as symlinks. Disabling a site is removing a link, not deleting a file — which is
why the two directories exist at all.

{{evidence:default-site}}

Three things are worth naming here. `default_server` makes this the site that
answers when nothing else matches. `server_name _` is not a wildcard with
meaning — it is deliberately an invalid hostname, so this block only ever gets
requests by being the default. And `try_files $uri $uri/ =404` says: try the
file, then the directory, then give up honestly, rather than falling through to
something unintended.

## 3. Nginx will not load a configuration it dislikes

{{evidence:configtest as=shell}}

`nginx -t` parses the whole tree and answers before anything is live. It is the
command to run before every reload; the failure mode it prevents is a typo that
takes the server down at the moment you reload it.

## 4. Requests, and where an unknown name lands

{{evidence:request as=shell}}

The second request is the interesting one. It asks for `mysite.local`, a name
this server has no site for — the exercises create that virtual host and then
remove it again. With no match, the request is answered by the block marked
`default_server`, which is why it returns the default page instead of an error.

On a real server that is a trap worth knowing: a hostname pointed at your
address that you never configured does not get refused, it gets whatever your
default site serves.

{{evidence:logs}}

Every line in `access.log` is one request: address, time, request line, status,
bytes, referrer and user agent. The format is set by `log_format` and the
default is called `combined`.

## 5. Verification

{{evidence:qlab-test grep="Exercise [0-9]+:|Exercises |All exercises" as=shell}}

The six exercises build and tear down what this document only shows at rest: a
second virtual host, a reverse proxy in front of a local application, log
analysis, and the security headers.

## 6. What to take away

- Master as root, workers as `www-data`: privilege only where it is needed.
- `reload` re-reads the configuration without dropping connections; `restart`
  drops them.
- `sites-available` and `sites-enabled` separate *existing* from *enabled*, with
  a symlink as the switch.
- `default_server` catches every name you did not configure. It is not an error
  path, it is a fallback — check what it serves.
- Run `nginx -t` before every reload.

`guide.md` in the plugin carries the exercises: virtual hosts, reverse proxying,
reading the logs, and the first security headers.
