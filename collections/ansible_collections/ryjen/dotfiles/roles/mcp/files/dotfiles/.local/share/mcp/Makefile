
# -----------------------------------------
# Makefile for MCP Server Profiles
# -----------------------------------------

COMPOSE = docker compose

# Default target
.DEFAULT_GOAL := help

# -----------------------------------------
# Profiles
# -----------------------------------------

dev:
	$(COMPOSE) --profile dev up -d

ai:
	$(COMPOSE) --profile ai-tools up -d

mobile:
	$(COMPOSE) --profile mobile up -d

all:
	$(COMPOSE) --profile all up -d

# -----------------------------------------
# Utility Commands
# -----------------------------------------

generate:
	scripts/generate


up: all

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) down
	$(COMPOSE) --profile all up -d

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down -v

# -----------------------------------------
# Help
# -----------------------------------------

help:
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  make dev        - Start dev tools (filesystem, git, shell, sqlite, browser)"
	@echo "  make ai         - Start AI tools (skillz, sequential-thinking, memory-bank, commits)"
	@echo "  make mobile     - Start mobile MCP server"
	@echo "  make all        - Start ALL MCP servers"
	@echo ""
	@echo "  make generate   - Generate compose and gateway config"
	@echo "  make down       - Stop all containers"
	@echo "  make restart    - Restart everything"
	@echo "  make logs       - Follow logs"
	@echo "  make ps         - Show running containers"
	@echo "  make clean      - Stop and remove volumes"
	@echo ""
