*This project has been created as part of the 42 curriculum by haboucha.*

# Inception

## Description

Inception is a system administration project whose goal is to build a small web infrastructure with **Docker** and **Docker Compose**, inside a virtual machine. Every service runs in its own container, built from a dedicated Dockerfile based on Debian (no ready-made images pulled from Docker Hub), and all of them communicate through a private Docker network.

### Mandatory part

| Service | Role |
|---|---|
| **NGINX** | Only entry point of the infrastructure, reachable on port **443** over HTTPS (TLS) |
| **WordPress** (php-fpm) | The website, served through NGINX |
| **MariaDB** | Database used by WordPress |

Two persistent storages are used: the WordPress database and the WordPress website files.

### Bonus services

| Service | Role |
|---|---|
| **Redis** | Cache for WordPress |
| **Adminer** | Web interface to administer the MariaDB database |
| **Static website** | A simple static site served in its own container |
| **FTP** | FTP server giving access to the WordPress files volume |
| **Advisor** | Small Flask (Python) application that presents the services of the infrastructure and exposes a `/health` endpoint and a JSON API (`/api/services`) |

Adminer, the static site and Advisor are reached through NGINX (HTTPS, port 443) and do not publish their own ports. The FTP service publishes ports 21 and 40000-40010.

## Instructions

### Prerequisites

- A Linux virtual machine with **Docker** and **Docker Compose** installed
- `make`
- Your user must be allowed to run Docker (member of the `docker` group)
- The domain name must resolve to the machine, for example by adding this line to `/etc/hosts`:

```
127.0.0.1   haboucha.42.fr
```

### Configuration

Create the `srcs/.env` file with the variables required by the services (database name, database user and passwords, WordPress admin and user, domain name, FTP credentials...). This file is not committed to Git.

### Build and run

```bash
make
```

The Makefile creates the data directories `/home/haboucha/data/mariadb` and `/home/haboucha/data/wordpress`, builds the images and starts the containers in the background.

Useful commands:

```bash
docker compose -f srcs/docker-compose.yml ps        # state of the containers
docker compose -f srcs/docker-compose.yml logs -f   # follow the logs
docker compose -f srcs/docker-compose.yml down      # stop and remove the containers
docker volume inspect mariadb-data                  # check where the data is stored
```

### Access

| What | URL |
|---|---|
| WordPress | `https://haboucha.42.fr` |
| Adminer | see the NGINX configuration (path or sub-path chosen for Adminer) |
| Static website | see the NGINX configuration |
| Advisor | `https://haboucha.42.fr/advisor/` |
| Advisor health check | `https://haboucha.42.fr/advisor/health` |
| Advisor services list (JSON) | `https://haboucha.42.fr/advisor/api/services` |

The TLS certificate is self-signed, so the browser shows a "Not Secure" warning. This is expected.

## Project description

### Use of Docker and sources included

Each service has its own folder in `srcs/requirements/` (bonus services in `srcs/requirements/bonus/`) containing a Dockerfile and its configuration files or scripts. `srcs/docker-compose.yml` describes the services, the network and the volumes, and the `Makefile` at the root of the repository builds and starts everything.

```
.
├── Makefile
├── README.md
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

All images are built locally from Debian (`debian:bookworm`). Each container runs a single main process, and containers restart automatically (`restart: unless-stopped`) if they crash. Images are tagged with the name of their service (`mariadb:v1`, `wordpress:v1`, ...).

### Main design choices

- **One service per container**, each built from its own Dockerfile, to keep images small and responsibilities separated.
- **NGINX is the single public entry point** (port 443, TLS only). WordPress, MariaDB, Redis, Adminer, the static site and Advisor are only reachable on the internal Docker network, and the web ones are proxied by NGINX.
- **A user-defined bridge network** (`inception`) lets containers reach each other by service name.
- **Named volumes stored in `/home/haboucha/data`** for MariaDB and WordPress data, so the data survives container rebuilds.
- **A healthcheck on MariaDB**, so dependent services (such as Adminer) only start once the database accepts connections.
- **Configuration through a `.env` file**, kept out of the repository, so that no credential is written in the Dockerfiles.

### Virtual Machines vs Docker

| | Virtual Machine | Docker |
|---|---|---|
| Isolation | Full operating system with its own kernel, isolated by a hypervisor | Processes isolated by the host kernel (namespaces, cgroups) |
| Weight | Heavy (several GB, full OS) | Light (images of a few tens or hundreds of MB) |
| Startup | Tens of seconds to minutes | Seconds or less |
| Resource use | High, resources reserved for each VM | Low, resources shared with the host |
| Portability | Disk image tied to a hypervisor | Same image runs anywhere Docker runs |
| Security boundary | Stronger (separate kernel) | Weaker (shared kernel) |

Docker is well suited here because the infrastructure is made of several small services that must be built and started quickly and reproducibly. The VM is only used as the host that runs Docker.

### Secrets vs Environment Variables

- **Environment variables** are simple to use (`env_file`, `environment`) and are the standard way to configure a container. Their drawback is that they are visible with `docker inspect`, in the container's process environment, and can leak in logs or child processes.
- **Docker secrets** are mounted as files in `/run/secrets/<name>` inside the container, only for the services that need them. They are not shown in `docker inspect` and are better suited to passwords and keys.

This project loads its configuration through a `.env` file that is excluded from Git, which is simple and enough for a local development infrastructure. For a production setup, passwords should move to Docker secrets.

### Docker Network vs Host Network

- **Bridge (Docker) network**: containers get their own network namespace and private IP addresses on an isolated virtual network. They find each other by service name through Docker's internal DNS, and only the ports explicitly published (here `443`, plus the FTP ports) are exposed on the host.
- **Host network**: the container shares the network stack of the host. There is no isolation and no port mapping, and port conflicts with the host are possible.

A custom bridge network (`inception`) is used so that services stay isolated from the host and from the outside, and so that only NGINX is exposed for the web traffic.

### Docker Volumes vs Bind Mounts

- **Bind mount**: a path of the host is mounted directly in the container (`/host/path:/container/path`). It depends on the host's directory layout and permissions, and is managed outside of Docker.
- **Docker (named) volume**: created and managed by Docker, declared in the `volumes:` section, referenced by name and independent of the host layout. It is easier to back up, migrate and share between containers.

The project requires named volumes, so the volumes are declared as named volumes with the `local` driver and `driver_opts` pointing to `/home/haboucha/data/mariadb` and `/home/haboucha/data/wordpress`. They remain Docker named volumes (listed by `docker volume ls`, referenced by name in the services) while their data ends up in `/home/haboucha/data` on the host:

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

## Resources

### Documentation and references

- [Docker documentation](https://docs.docker.com/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WordPress developer resources](https://developer.wordpress.org/)
- [WP-CLI](https://wp-cli.org/)
- [Redis documentation](https://redis.io/docs/)
- [Adminer](https://www.adminer.org/)
- [Flask documentation](https://flask.palletsprojects.com/)

### Use of AI

AI (Claude) was used as a support tool for understanding and debugging, not to replace my own work. It helped with:

- Diagnosing file permission errors on `/home/haboucha/data` and understanding why Docker's `data-root` setting caused conflicts with the project data.
- Understanding how to configure named volumes with `driver_opts` so that data is stored in `/home/haboucha/data`, as required by the subject.
- Fixing syntax errors in a Dockerfile (line continuations, `COPY` destination, `pip` options) and an architecture error (`exec format error`).
- Debugging the NGINX reverse proxy configuration for the Advisor service (path prefix handling, relative links).
- Writing the Advisor bonus application and drafting this README.

All generated suggestions were read, tested and adapted by me, and I am able to explain every part of the project.