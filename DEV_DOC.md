# Developer Documentation

## Setting Up the Environment from Scratch

### Prerequisites

To set up and run this project, a developer needs:

- A **Linux virtual machine** (this project was developed and tested on Debian).
- **Docker Engine** — to build the images and run the containers.
- **Docker Compose** — to manage the multi-container setup from `docker-compose.yml`.
- **make** — to run the project through the `Makefile`.
- **git** — to clone the repository.

The project must be run inside a virtual machine, as required by the subject. All three services are built from the `debian:bookworm` base image, so no other language runtimes or databases need to be installed on the host — everything runs inside the containers.

### Configuration file (.env)

The `.env` file holds the non-sensitive configuration and must be created at `srcs/.env`. It is ignored by git, so it is not included in the repository and has to be created manually.

It must contain the following variables:

```
DOMAIN_NAME=mosokina.42.fr

# Database
DB_NAME=wordpress
DB_USER=wp_user
DB_HOST=mariadb

# WordPress admin (the user name must NOT contain "admin")
WP_TITLE=Inception
WP_ADMIN_USER=supervisor
WP_ADMIN_EMAIL=supervisor@example.com

# WordPress second user
WP_USER=guest
WP_USER_EMAIL=guest@example.com
```

### Secret files

Passwords are stored as Docker secrets in the `secrets/` folder at the root of the project. Like the `.env` file, this folder is ignored by git and is not included in the repository, so the files must be created manually.

Three files are required:

- `secrets/db_password.txt` — the password of the WordPress database user (`DB_USER`). One line.
- `secrets/db_root_password.txt` — the root (administrator) password of MariaDB. One line.
- `secrets/credentials.txt` — the passwords of the two WordPress users, on two lines:
  - line 1 — the WordPress administrator's password
  - line 2 — the second (non-administrator) user's password

Example of creating the files:

```
echo "your_db_user_password" > secrets/db_password.txt
echo "your_root_password" > secrets/db_root_password.txt
printf "your_wp_admin_password\nyour_wp_user_password\n" > secrets/credentials.txt
```

At runtime, Docker mounts these files into the containers under `/run/secrets/`, and the startup scripts read the passwords from there. This way, no password is ever written in a Dockerfile, baked into an image, or committed to git.

### Host configuration

The domain used by the project must point to the local machine. Add the following line to `/etc/hosts` on the host:

```
127.0.0.1 mosokina.42.fr
```

This makes the browser (and tools like `curl`) resolve `mosokina.42.fr` to the local machine, where NGINX is serving the site. It can be added with:

```
echo "127.0.0.1 mosokina.42.fr" | sudo tee -a /etc/hosts
```

## Building and Launching the Project

The project is built and run through the `Makefile` at the root, which wraps Docker Compose (pointing to `srcs/docker-compose.yml`). The available targets are:

- **`make`** (default) — creates the data directories on the host, then runs `docker compose up -d --build`. This builds the three images from their Dockerfiles and starts all the containers in the background.
- **`make down`** — stops and removes the containers (`docker compose down`), keeping the volumes and data.
- **`make clean`** — stops the containers and removes the volumes and images as well, for a full teardown.
- **`make re`** — runs a full clean and then rebuilds and starts the project again.

### Build and startup process

When `make` runs, Docker Compose builds each service from its own Dockerfile (all based on `debian:bookworm`) and starts the containers on the shared `inception` bridge network, attaching the named volumes and mounting the secrets.

The services start in a defined order using `depends_on`: MariaDB first, then WordPress, then NGINX. However, `depends_on` only waits for a container to *start*, not for the service inside to be *ready*. Because of this, the WordPress startup script waits in a loop until MariaDB is actually accepting connections before it installs and configures WordPress. This ensures the services connect correctly even though they start at nearly the same time.

## Managing Containers and Volumes

The following commands are useful for inspecting and debugging the running project. They are run from the root of the project.

### Containers

```
docker compose -f srcs/docker-compose.yml ps
```
Lists the project's containers and their status.

```
docker compose -f srcs/docker-compose.yml logs <service>
```
Shows the logs of a service (`mariadb`, `wordpress`, or `nginx`). Useful for finding why a service failed to start.

```
docker exec -it <container> bash
```
Opens a shell inside a running container (for example `docker exec -it mariadb bash`), which is useful for debugging — checking files, configuration, or running commands inside the container. Type `exit` to leave.

### Volumes and networks

```
docker volume ls
```
Lists the named volumes (the WordPress database and website-file volumes).

```
docker volume inspect srcs_mariadb_data
```
Shows the details of a volume, including its `Mountpoint` — the actual location of the data on the host.

```
docker network ls
```
Lists the Docker networks, including the project's `inception` bridge network.

## Data Storage and Persistence

### Where the data is stored

The project uses two named volumes for persistent data, both stored under `/home/mosokina/data` on the host:

- `/home/mosokina/data/mariadb` — the MariaDB database files.
- `/home/mosokina/data/wordpress` — the WordPress website files.

These are defined as named volumes in `docker-compose.yml`, using driver options (`type: none`, `o: bind`, `device: ...`) so that their data is stored in the required host location instead of Docker's internal directory.

### How persistence works

Because the data lives in these volumes on the host, it is independent of the containers:

- `make down` stops and removes the containers, but the volumes and their data remain, so the next `make` starts with the existing database and site intact.
- `make clean` removes the volumes as well, which deletes the data. The next `make` then sets everything up from scratch.

### First run vs. restart

Each service's startup script checks whether it has already been initialised before doing any setup:

- **MariaDB** checks whether its data directory already exists. If not, it initialises the database and creates the WordPress database and user. If it already exists, it skips setup and just starts the server.
- **WordPress** checks whether `wp-config.php` already exists. If not, it downloads and installs WordPress and creates the two users. If it exists, it skips setup and just starts php-fpm.

This makes the setup safe to run repeatedly: the project is configured only on the first run, and on later restarts the existing data is reused without being overwritten.
