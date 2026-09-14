---
kicker: QLab · nginx-lab
title: |
  Un solo server,
  molti siti
subtitle: >
  Nginx com'è appena installato, e come lo lasciano gli esercizi. Ogni blocco
  qui sotto viene da un lab acceso: l'albero dei processi, i socket che tiene,
  la configurazione che accetta e le richieste a cui ha risposto.
facts:
  - [Comando, "`qlab run nginx-lab`"]
  - [VM, "`nginx-lab`, porta 80 inoltrata su una porta host dinamica"]
  - [Credenziali, "`labuser` / `labpass`"]
  - [Esito, "`qlab test nginx-lab` → 6 esercizi, 36 controlli, tutti superati"]
---

## 1. Cosa sta girando

{{evidence:version as=shell}}

{{evidence:processes}}

Due processi, e la divisione fra loro è tutta l'architettura. Il **master** gira
come `root` — deve, perché legarsi alla porta 80 richiede privilegi ed è lui a
rileggere la configurazione. Il **worker** gira come `www-data` ed è il processo
che parla davvero con la rete. Un difetto nella gestione delle richieste finisce
quindi in un processo senza privilegi, ed è esattamente il senso di questa
divisione.

È anche il motivo per cui `systemctl reload nginx` non è come `restart`: il
master tiene i socket in ascolto e passa ai worker una configurazione nuova,
senza far cadere nessuna connessione.

{{evidence:listening}}

## 2. Il sito con cui si avvia

{{evidence:sites}}

`sites-available` contiene ciò che esiste; `sites-enabled` ciò che è acceso,
sotto forma di collegamenti simbolici. Disattivare un sito è togliere un link,
non cancellare un file — ed è il motivo per cui le due cartelle esistono.

{{evidence:default-site}}

Qui vanno nominate tre cose. `default_server` fa di questo il sito che risponde
quando nient'altro corrisponde. `server_name _` non è un carattere jolly con un
significato: è deliberatamente un hostname non valido, così questo blocco riceve
richieste solo in quanto predefinito. E `try_files $uri $uri/ =404` dice: prova
il file, poi la directory, poi arrenditi onestamente, invece di ripiegare su
qualcosa di non voluto.

## 3. Nginx non carica una configurazione che non gli piace

{{evidence:configtest as=shell}}

`nginx -t` analizza l'intero albero e risponde prima che qualcosa vada in
produzione. È il comando da lanciare prima di ogni reload; il guasto che
previene è il refuso che manda giù il server nel momento in cui si ricarica.

## 4. Le richieste, e dove finisce un nome sconosciuto

{{evidence:request as=shell}}

La seconda richiesta è quella interessante. Chiede `mysite.local`, un nome per
cui questo server non ha alcun sito — gli esercizi creano quel virtual host e
poi lo rimuovono. Non trovando corrispondenza, la richiesta viene servita dal
blocco marcato `default_server`, ed è per questo che torna la pagina predefinita
invece di un errore.

Su un server vero è una trappola da conoscere: un hostname puntato al vostro
indirizzo che non avete mai configurato non viene rifiutato, riceve quello che
serve il vostro sito predefinito.

{{evidence:logs}}

Ogni riga di `access.log` è una richiesta: indirizzo, ora, riga di richiesta,
stato, byte, referrer e user agent. Il formato lo decide `log_format` e quello
predefinito si chiama `combined`.

## 5. Verifica

{{evidence:qlab-test grep="Exercise [0-9]+:|Exercises |All exercises" as=shell}}

I sei esercizi costruiscono e smontano ciò che questo documento mostra solo a
riposo: un secondo virtual host, un reverse proxy davanti a un'applicazione
locale, l'analisi dei log e le prime intestazioni di sicurezza.

## 6. Cosa portarsi via

- Master come root, worker come `www-data`: privilegi solo dove servono.
- `reload` rilegge la configurazione senza far cadere connessioni; `restart` le
  fa cadere.
- `sites-available` e `sites-enabled` separano ciò che *esiste* da ciò che è
  *attivo*, con un symlink come interruttore.
- `default_server` raccoglie ogni nome che non avete configurato. Non è un
  percorso d'errore, è un ripiego: guardate cosa serve.
- Lanciate `nginx -t` prima di ogni reload.

`guide.md` del plugin porta gli esercizi: virtual host, reverse proxy, lettura
dei log e le prime intestazioni di sicurezza.
