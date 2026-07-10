*This project has been created as part of the 42 curriculum by mosokina.*

# Inception

## Description

This 42 project "Inception" is a small Docker infrastructure with the goal of learning system administration with Docker. The whole project runs inside a virtual machine, and each service is built from its own Dockerfile and runs in its own container.

The infrastructure includes three services, each running in its own Docker container:

- **NGINX** as the web server and the only entry point into the infrastructure, accessible only on port 443. The connection is encrypted over the Transport Layer Security protocol (TLS 1.2 or 1.3), which makes the connection HTTPS.
- **WordPress with php-fpm** as the website, served over HTTPS.
- **MariaDB** as the database for WordPress.

The services communicate over a dedicated Docker bridge network, and the WordPress database and website files are stored in persistent named volumes.

## Instructions

### Prerequisites

- A Linux virtual machine with Docker and Docker Compose installed.
- The `srcs/.env` file, containing the non-sensitive configuration (domain name, database name and user, WordPress title, and the two WordPress user names and emails).
- The `secrets/` files, containing the passwords: `db_password.txt`, `db_root_password.txt`, and `credentials.txt`. These are ignored by git and must be created locally.
- An entry in `/etc/hosts` mapping the domain to localhost:

127.0.0.1 mosokina.42.fr


### Build and run

From the root of the project, run:

make

This creates the data directories, builds the three Docker images, and starts all the containers.

### Access

Once running, the website is available at:
https://mosokina.42.fr

The WordPress admin panel is at `https://mosokina.42.fr/wp-admin`. Because the TLS certificate is self-signed, the browser will show a security warning that can be safely accepted.

### Other commands

- `make down` — stop and remove the containers.
- `make clean` — stop the containers and remove the volumes and images.
- `make re` — rebuild the project from scratch.

### Further documentation

- **USER_DOC.md** — how to use and manage the running project (accessing the site, managing credentials, checking services).
- **DEV_DOC.md** — how to set up the project from scratch as a developer, including creating the `.env` and `secrets/` files, and managing containers and volumes.

## Project Description

### Virtual Machines vs Docker

A Docker container shares the host's kernel and is much lighter than a virtual machine, which runs its own kernel with a full OS on top. Docker also isolates each service using namespaces and cgroups, so each container has its own separate filesystem, network, and process space while still sharing the host kernel.

This gives good separation between services (NGINX, WordPress, MariaDB) without the overhead of running three full virtual machines. For this project, Docker is therefore a more reasonable approach than virtual machines.

### Secrets vs Environment Variables

In this project, environment variables and secrets are distinguished by the sensitivity of the data.

Environment variables are used for non-sensitive configuration: the domain name, database name, database user, and WordPress site title. These are stored in the `.env` file and passed to the containers through `docker-compose.yml`. Environment variables are not secure for storing passwords, as they can be accessed through commands like `docker inspect` or found in logs.

Docker secrets are used for sensitive data (the database passwords and the WordPress user passwords). These are kept in the `secrets/` folder (which is ignored by git). Docker mounts them into the containers as files under `/run/secrets/` only at runtime. The startup scripts then read the passwords from those files. This way, no password is ever hardcoded in a Dockerfile, baked into an image, or committed to git.

### Docker Network vs Host Network

In this project the three containers communicate through a user-defined Docker bridge network called `inception`.

A bridge network keeps the containers isolated from the host's own network and lets them reach each other by their service names. For example, WordPress connects to the database using the host name `mariadb`, and NGINX forwards requests to `wordpress`, without needing any IP addresses.

A host network, by contrast, would make the containers share the host machine's network stack directly, removing this isolation and exposing every container's ports on the host. Using the host network (as well as `--link` and `links:`) is forbidden by the subject, and it would also break the requirement that NGINX be the only entry point on port 443.

The bridge network avoids these problems: it keeps the containers isolated and lets them communicate by name, while only NGINX's port 443 is published to the host.

### Docker Volumes vs Bind Mounts

Docker offers two main ways to persist data outside a container:

- A **named volume** is fully managed by Docker and normally stored in Docker's own internal directory (`/var/lib/docker/volumes/`), which is root-owned and not easily accessible. You refer to it by name, and Docker manages its lifecycle.
- A **bind mount** maps a specific directory chosen on the host directly into the container. You choose and own the exact path, and Docker does not manage it as a separate object.

This project requires two persistent storages — one for the WordPress database and one for the WordPress website files. It asks for named volumes, but also requires their data to be stored in `/home/mosokina/data` on the host machine.

Since a plain named volume would keep its data in Docker's internal directory rather than that path, the two named volumes are defined with driver options (`type: none`, `o: bind`, `device: /home/mosokina/data/...`). This keeps them declared and managed as named volumes in `docker-compose.yml`, while making their data physically land in `/home/mosokina/data/mariadb` and `/home/mosokina/data/wordpress` on the host.

This approach was chosen to satisfy both requirements at once: using named volumes, and storing the data in the required host location. Storing the data in `/home/mosokina/data` also makes it easy to inspect and verify directly, without needing root access to Docker's internal directory.

## Resources

### Documentation and references

- Docker official documentation — https://docs.docker.com
- Docker Compose documentation — https://docs.docker.com/compose
- Dockerfile best practices — https://docs.docker.com/develop/develop-images/dockerfile_best-practices
- NGINX documentation — https://nginx.org/en/docs
- MariaDB documentation — https://mariadb.com/kb/en/documentation
- WordPress / WP-CLI documentation — https://developer.wordpress.org and https://wp-cli.org
- Debian documentation (base image) — https://www.debian.org/doc

### Use of AI

AI was used as a learning and debugging aid throughout this project.

Specifically, AI helped me:

- Understand the core concepts before building: PID 1 and foreground vs background processes, the difference between images and containers, Docker volumes, networks, and secrets.
- Understand the build-time vs run-time distinction in Dockerfiles (RUN vs ENTRYPOINT/CMD) and why services must run in the foreground.
- Structure the Dockerfiles and setup scripts for each service, which I then wrote, adjusted, and tested myself.
- Debug specific issues I encountered, by explaining the errors so I could fix them: the MariaDB socket-directory error, the `--skip-grant-tables` problem in bootstrap mode (solved with `--init-file`), the empty data-directory initialization logic, and the WordPress "wait for MariaDB to be ready" loop.
- Understand the reasoning behind the project's design choices (named volumes with bind options, secrets vs environment variables, the network model).

## Additional information

This project is configured for my login `mosokina`. To run it under a different login, replace `mosokina` with your own login in `srcs/.env` (`DOMAIN_NAME`) and in the volume device paths in `srcs/docker-compose.yml`, and update your `/etc/hosts` entry accordingly.


