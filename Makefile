NAME        = inception
COMPOSE     = docker compose -f srcs/docker-compose.yml
DATA_DIR    = /home/haboucha/data

all: up

# Cree les dossiers des volumes, construit les images et lance les conteneurs
up:
	@mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	$(COMPOSE) up -d --build

# Arrete et supprime les conteneurs (les donnees restent)
down:
	$(COMPOSE) down

# Met en pause les conteneurs sans les supprimer
stop:
	$(COMPOSE) stop

# Relance des conteneurs deja crees
start:
	$(COMPOSE) start

# Affiche l'etat des conteneurs
ps:
	$(COMPOSE) ps

# Affiche les logs en direct (Ctrl+C pour quitter)
logs:
	$(COMPOSE) logs -f

# Supprime les conteneurs et les volumes Docker (donnees du dossier data conservees)
clean:
	$(COMPOSE) down -v

# Nettoyage total : conteneurs, volumes, images ET donnees sur le disque
fclean: clean
	@images="$$(docker images -q)"; \
	if [ -n "$$images" ]; then \
		docker rmi -f $$images; \
	else \
		echo "Aucune image Docker a supprimer."; \
	fi
	sudo rm -rf $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb


# Tout supprimer puis tout reconstruire
re: fclean up

.PHONY: all up down stop start ps logs clean fclean re