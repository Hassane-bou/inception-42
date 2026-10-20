# Developer Documentation

This document explains how to set up, build, run and maintain the Inception project. For usage from an end-user point of view, see `USER_DOC.md`.

## 1. Set up the environment from scratch

### Prerequisites

- A Linux virtual machine (Debian in this project)
- **Docker** and the **Docker Compose** plugin
- `make` and `git`
- Your user in the `docker` group, so that Docker commands work without `sudo`:

```bash
sudo usermod -aG docker haboucha
```

Log out and log in again for this to take effect.

Docker must use its default storage location (`/var/lib/docker`). Check it with:

```bash
docker info | grep "Docker Root Dir"
```

If it points to `/home/haboucha/data`, remove the `data-root` entry from `/etc/docker/daemon.json` and restart Docker. Otherwise Docker's internal files would end up mixed with the project data.

### Domain name

Add the domain to the hosts file of the machine that opens the site:

```
127.0.0.1   haboucha.42.fr
```

### Configuration files and secrets

| File | Purpose |
|---|---|
| `srcs/.env` | Environment variables (database, WordPress, FTP, domain). Not committed to Git |
| `srcs/docker-compose.yml` | Services, network and volumes |
| `srcs/requirements/<service>/` | Dockerfile and configuration for each service |
| `Makefile` | Entry point to build and start the stack |

Create `srcs/.env` before the first launch, with every variable that the Dockerfiles, scripts and compose file expect (database name, `MYSQL_USER`, `MYSQL_PASSWORD`, root password, WordPress admin and user, FTP credentials, domain name). Never commit this file.

### Project structure

```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs
    ├── .env
    ├── docker-compose.yml
    └── requirements
        ├── mariadb
        ├── nginx
        ├── wordpress
        └── bonus
            ├── Adminer
            ├── FTP
            ├── Redis
            ├── advisor
            └── static
```

## 2. Build and launch

### With the Makefile

```bash
make
```

The `up` target (default target `all`) does three things:

1. creates the data directories `/home/haboucha/data/wordpress` and `/home/haboucha/data/mariadb` (`mkdir -p`);
2. builds the images;
3. starts the containers in the background (`docker compose up -d --build`).

The data directories must exist and belong to your user **before** Docker creates the volumes. Do not run `make` with `sudo`, otherwise the directories would belong to root.

### With Docker Compose directly

```bash
docker compose -f srcs/docker-compose.yml up -d --build   # build and start
docker compose -f srcs/docker-compose.yml down            # stop and remove containers
docker compose -f srcs/docker-compose.yml build --no-cache <service>   # rebuild one image from scratch
```

### Images and services

All images are built from `debian:bookworm`. Each image is tagged with its service name (`mariadb:v1`, `nginx:v1`, `advisor:v1`...). Containers use `restart: unless-stopped`. MariaDB has a healthcheck, and Adminer waits for it (`condition: service_healthy`).

## 3. Manage containers and volumes

### Containers

```bash
docker compose -f srcs/docker-compose.yml ps               # state
docker compose -f srcs/docker-compose.yml logs -f <service> # follow logs
docker logs <container>                                    # logs of one container
docker exec -it <container> bash                           # open a shell (use sh if bash is missing)
docker compose -f srcs/docker-compose.yml restart <service>
```

### Network

```bash
docker network inspect inception
```

All services are on the `inception` bridge network and reach each other by service name (for example `mariadb:3306`, `advisor:5000`). Only NGINX (443) and FTP (21, 40000-40010) publish ports on the host.

### Volumes

```bash
docker volume ls
docker volume inspect mariadb-data
docker volume inspect wordpress-data
```

The `Options` section of the inspect output must show `device: /home/haboucha/data/mariadb` (and `/wordpress`).

### Reset everything (erases all data)

```bash
docker compose -f srcs/docker-compose.yml down -v
docker volume rm mariadb-data wordpress-data
sudo rm -rf /home/haboucha/data/mariadb /home/haboucha/data/wordpress
make
```

Files created by the containers may belong to other users (such as `mysql` or `www-data`), which is why `sudo` is needed to delete them. Docker does not modify an existing volume: if you change the `volumes:` section of the compose file, remove the old volumes first, otherwise the change is ignored.

To remove unused images and cache as well:

```bash
docker system prune -a
```

## 4. Where the data is stored and how it persists

| Data | Container path | Docker volume | Host path |
|---|---|---|---|
| MariaDB database | `/var/lib/mysql` | `mariadb-data` | `/home/haboucha/data/mariadb` |
| WordPress files | `/var/www/html` | `wordpress-data` | `/home/haboucha/data/wordpress` |

Both are **Docker named volumes** declared with the `local` driver and `driver_opts` that point to the host directory:

```yaml
volumes:
  mariadb-data:
    name: mariadb-data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/haboucha/data/mariadb
```

Services reference the volumes by name (`mariadb-data:/var/lib/mysql`), never by host path.

**Persistence:** the data lives on the host, outside the containers. Stopping, removing or rebuilding the containers (`down`, `up --build`) does not delete it. It is only deleted if you remove the volumes and the host directories yourself (see "Reset everything").

The WordPress volume is shared: NGINX mounts it read-only to serve the files, and the FTP service mounts it read-write.

## 5. Troubleshooting

| Problem | Cause and fix |
|---|---|
| `mkdir: Permission denied` on `/home/haboucha/data` | The directory belongs to root. Run `sudo chown haboucha:haboucha /home/haboucha/data` |
| `Volume ... exists but doesn't match configuration` | An old volume with a different configuration exists. Answer `y` to recreate it (data is lost), or remove it with `docker volume rm` |
| `exec format error` in a container | A binary downloaded in a Dockerfile has the wrong CPU architecture (`amd64` vs `arm64`). Check with `uname -m` |
| Dockerfile `unknown instruction` | Missing `\` at the end of a line in a multi-line `RUN` |
| 404 from Flask on `/advisor/...` | The `proxy_pass` in NGINX must end with `/` (`proxy_pass http://advisor:5000/;`) so that the prefix is removed |
| `permission denied` on `/var/run/docker.sock` | The user is not in the `docker` group |