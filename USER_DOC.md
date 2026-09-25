# User Documentation

## Services Provided

This project provides a WordPress website served securely over HTTPS, backed by a database. It is made of three services, each running in its own container:

- **NGINX** — the web server. It receives requests from the browser and serves the website securely over HTTPS (on port 443). It is the only way into the infrastructure from outside.
- **WordPress (with php-fpm)** — the website itself. It generates the web pages and handles the site content, such as posts, pages, and users.
- **MariaDB** — the database. It stores all of the WordPress data (posts, users, settings) so that it is saved and available whenever the site runs.

Together, these services let a user visit the website in a browser, view its content, and (as an administrator) manage it through the WordPress admin panel.

## Starting and Stopping the Project

All commands must be run from the **root of the project** (the folder containing the `Makefile`).

- **Start the project:**

make

This builds the images (if needed) and starts all three services. After a short moment, the website becomes available.

- **Stop the project:**

make down

This stops and removes the containers, but keeps the saved data (the website and database are preserved for next time).

- **Full reset:**

make clean

This stops the containers and also removes the volumes and images. The saved data is deleted, so the next `make` starts the project completely fresh.

- **Rebuild from scratch:**

make re

This performs a full reset and then starts the project again.

## Accessing the Website and Admin Panel

### The website

Once the project is running, the website is available in a browser at:
https://mosokina.42.fr

The connection uses HTTPS with a self-signed certificate, so the browser will show a security warning the first time. This is expected for this project — you can safely accept it (for example, "Advanced" → "Accept the risk and continue") to reach the site.

### The admin panel

The WordPress administration panel is available at:
https://mosokina.42.fr/wp-admin

From here, an administrator can log in and manage the site (create posts and pages, manage users, change settings, and so on).

### Users

The WordPress site has two users:

- **supervisor** — the administrator, with full access to the admin panel.
- **guest** — a regular (non-administrator) user with limited permissions.

Their passwords are stored in the credentials secret file (see "Managing Credentials" below).

## Managing Credentials

### Where credentials are stored

Sensitive credentials (passwords) are kept in the `secrets/` folder at the root of the project, in three files:

- `db_password.txt` — the password of the WordPress database user.
- `db_root_password.txt` — the root (administrator) password of the MariaDB database.
- `credentials.txt` — the passwords of the two WordPress users. The first line is the administrator's password, and the second line is the regular user's password.

Non-sensitive configuration (such as the domain name, database name, user names, and emails) is stored in the `srcs/.env` file.

For security, both the `secrets/` folder and the `.env` file are **ignored by git**, so they are never uploaded to the repository. They exist only locally on the machine.

### Changing a password

To change a password:

1. Edit the relevant file in `secrets/` (or `credentials.txt` for the WordPress users).
2. Rebuild the project so the new password is applied:
make clean
make


A full rebuild is needed because the passwords are set when the database and WordPress are first initialised. Note that `make clean` removes the existing data, so the site is set up again from scratch with the new credentials.

## Checking the Services Are Running

There are a few simple ways to verify that everything is working correctly.

### Check the containers

From the root of the project, run:
docker compose -f srcs/docker-compose.yml ps

This lists the three containers (`mariadb`, `wordpress`, and `nginx`). They should all show the status **Up**. If a container is missing or shows "Exited", that service is not running correctly.

### Check the logs

To see what a specific service is doing (useful if something is not working), view its logs:
docker compose -f srcs/docker-compose.yml logs nginx

Replace `nginx` with `wordpress` or `mariadb` to check the other services. The logs show whether the service started correctly or reported any errors.

### Check the website

The simplest check is to open the website in a browser:
https://mosokina.42.fr

If the WordPress site loads, then all three services are working together correctly — NGINX is serving the page, WordPress is generating it, and MariaDB is providing the data.



