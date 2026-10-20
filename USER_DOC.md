# User Documentation

This document explains how to use and administer the Inception stack, without needing to know how it is built. For technical details, see `DEV_DOC.md`.

## 1. Services provided

| Service | What it does | How you reach it |
|---|---|---|
| **NGINX** | Secure entry point of the whole stack (HTTPS only) | `https://haboucha.42.fr` (port 443) |
| **WordPress** | The website and its administration panel | `https://haboucha.42.fr` |
| **MariaDB** | Database storing the WordPress content | Internal only (not reachable from outside) |
| **Redis** | Cache that speeds up WordPress | Internal only |
| **Adminer** | Web page to browse and manage the database | Through NGINX (see section 3) |
| **Static website** | A simple static page | Through NGINX (see section 3) |
| **FTP** | File transfer access to the WordPress files | FTP client on port 21 |
| **Advisor** | Small page listing the services, with a health check | `https://haboucha.42.fr/advisor/` |

Only port **443** (HTTPS) is used for the web services. The FTP service also uses ports **21** and **40000-40010**.

## 2. Start and stop the project

All commands are run from the root of the repository.

**Start** (builds the images if needed and starts everything in the background):

```bash
make
```

**Stop** (removes the containers, keeps your data):

```bash
docker compose -f srcs/docker-compose.yml down
```

**Restart** after a stop: run `make` again. Your website content and database are kept, because they are stored on the host in `/home/haboucha/data`.

If the Makefile has other targets (for example to stop or fully clean the project), they are listed in `DEV_DOC.md`.

## 3. Access the website and the administration panel

Your computer must resolve the domain name to the machine running the stack. On the machine itself, add this line to `/etc/hosts`:

```
127.0.0.1   haboucha.42.fr
```

| What | Address |
|---|---|
| Website | `https://haboucha.42.fr` |
| WordPress administration panel | `https://haboucha.42.fr/wp-admin` |
| Adminer (database) | `https://haboucha.42.fr/adminer/` (adjust if your NGINX uses another path) |
| Static website | See the NGINX configuration for its path |
| Advisor | `https://haboucha.42.fr/advisor/` |

The security certificate is self-signed, so the browser shows a **"Not Secure"** warning. This is expected: accept the exception to continue.

To log in to Adminer, use the database server name `mariadb`, together with the database name, user and password defined in the `.env` file.

## 4. Locate and manage credentials

All credentials are stored in a single file:

```
srcs/.env
```

It contains, among others:

- the database name, user and password (and the database root password);
- the WordPress administrator account and the second WordPress user;
- the FTP user and password;
- the domain name.

Rules to follow:

- This file is **private**: it must never be committed to Git or shared. It is listed in `.gitignore`.
- To change a password, edit `srcs/.env`, then rebuild and restart the stack.
- Some values (database password, WordPress admin) are applied only the first time the data is created. After that they are stored in the database. To change them on an existing installation, change them from WordPress or Adminer, or erase the data and start again (see `DEV_DOC.md`).

## 5. Check that the services are running correctly

**Containers state:**

```bash
docker compose -f srcs/docker-compose.yml ps
```

Every service must be `Up`. MariaDB should also show `healthy`.

**Quick web checks:**

```bash
curl -k https://haboucha.42.fr/advisor/health
```

Expected answer: `{"service":"advisor","status":"healthy"}`.

Then open `https://haboucha.42.fr` in a browser: the WordPress site must appear.

**If something does not work:**

```bash
docker compose -f srcs/docker-compose.yml logs
docker logs <container_name>
```

Container names are: `mariadb`, `wordpress`, `nginx`, `redis`, `adminer`, `static`, `ftp`, `advisor`.

| Symptom | Likely cause |
|---|---|
| The site does not open | Domain missing from `/etc/hosts`, or NGINX not running |
| 502 Bad Gateway | The service behind NGINX is not running yet or has crashed |
| WordPress shows a database error | MariaDB is not healthy yet, or the credentials in `.env` are wrong |
| Browser warning about the certificate | Normal (self-signed certificate) |