COMPOSE = docker compose -f srcs/docker-compose.yml
DATA = /home/mosokina/data

all: up

up:
	mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean: down
	$(COMPOSE) down --volumes --rmi all

re: clean up

.PHONY: all up down clean re

