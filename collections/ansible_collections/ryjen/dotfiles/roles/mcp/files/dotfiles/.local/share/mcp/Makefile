.PHONY: dev ai mobile all context up down restart logs ps clean help

# -----------------------------------------
# Makefile for MCP Server Profiles
# -----------------------------------------

COMPOSE = docker compose
CONTEXT = mcp

# Default target
.DEFAULT_GOAL := help

# -----------------------------------------
# Profiles
# -----------------------------------------

dev:
	$(COMPOSE) --context $(CONTEXT) --profile dev up -d

ai:
	$(COMPOSE) --context $(CONTEXT) --profile ai-tools up -d

mobile:
	$(COMPOSE) --context $(CONTEXT) --profile mobile up -d

all:
	$(COMPOSE) --context $(CONTEXT) --profile all up -d

# -----------------------------------------
# Utility Commands
# -----------------------------------------

up: all

down:
	$(COMPOSE) --context $(CONTEXT) --profile all down

restart:
	$(COMPOSE) --context $(CONTEXT) --profile all down
	$(COMPOSE) --context $(CONTEXT) --profile all up -d

logs:
	$(COMPOSE) --context $(CONTEXT) --profile all logs -f

ps: context
	$(COMPOSE) --context $(CONTEXT) --profile all ps

clean:
	$(COMPOSE) --context $(CONTEXT) --profile all down -v

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
