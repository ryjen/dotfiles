
CONFIGS := \
android \
asdf \
attic \
bat \
cheat \
clang-format \
coreutils \
ctags \
diff \
docker \
editor \
fortune \
git \
gopass \
gpg \
htop \
input \
jrnl \
micrantha \
micro \
mutt \
ncdu \
perl \
prettyping \
taskwarrior \
tmux \
tmuxinator \
tmuxp \
vim \
weechat \
xml \
yarn \
zsh

ifeq ($(OS),Windows_NT)     # is Windows_NT on XP, 2000, 7, Vista, 10...
    detected_OS := Windows
else
		detected_OS := $(shell uname 2>/dev/null || echo Unknown)
    detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
    detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
    detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
endif

ifeq ($(detected_OS),Darwin)
	OS_FOLDER := "@macos"
else
ifeq ($(detected_OS),Linux)
	OS_FOLDER := "@linux"
else
ifeq ($(detected_OS),Windows)
	OS_FOLDER := "@windows"
endif
endif
endif

TARGETS := $(patsubst %,%.conf,$(CONFIGS))
LISTABLE := $(patsubst %,%.list,$(CONFIGS))

.PHONY: all
all: help

.PHONY: help
help:
	@echo "Commands:"
	@echo "  list         list all installable items for your operating system"
	@echo "  min          do a minimal install"
	@echo "  full         do a full install"
	@echo "  setup        setup stow"
	@echo "  configs      all configurations"
	@echo "  packages     install package manager packages"

.PHONY: min
min: setup configs

.PHONY: full
full: setup packages configs

.PHONY: setup
setup:
	@echo "Setting up stow..."
	@./setup
	@echo "  stow configured."

.PHONY: os
os:
	@if [ -d $(OS_FOLDER) ]; then \
		echo "  installing base os configuration"; \
		stow $(OS_FOLDER); \
	fi

.PHONY: configs
configs: os $(TARGETS)
	@echo "Done."

.PHONY: packages
packages:
	@echo "Installing required programs..."
	@echo "  installing terminals..."
	@./_terminfo/install
ifeq ($(detected_OS),Darwin)
	@echo "  installing homebrew packages..."
	@./_homebrew/install
endif
ifeq ($(detected_OS),Linux)
	@echo "  installing debian packages..."
	@./_dpkg/install
endif
	@echo "  required programs installed."
	@echo "  installing asdf plugins..."
	@_asdf/install
	@echo "  installing yarn packages..."
	@_yarn/install
	@echo "  installing python packages..."
	@_pip/install

.PHONY: list
list: $(LISTABLE)
	@./_terminfo/list
ifeq ($(detected_OS),Darwin)
	@./_homebrew/list
endif
ifeq ($(detected_OS),Linux)
	@./_dpkg/list
endif
	@./_asdf/list
	@./_yarn/list
	@./_pip/list

%.conf: %
	@echo "  installing $? configuration..."
	@stow $?
	@if [ -d "$?/$(OS_FOLDER)" ]; then \
		echo "  installing $? os specific configuration..."; \
		cd $? && stow $(OS_FOLDER) && cd - >/dev/null; \
	fi

%.list: %
	@echo "config-$?"
	@find $? -not -path "*/@*" -not -name "*.md" -not -name "*.example" -exec echo "  - {}" \;
	@if [ -d "$?/$(OS_FOLDER)" ]; then \
		echo "config-$?-$(detected_OS)" | tr '[:upper:]' '[:lower:]'; \
		find "$?/$(OS_FOLDER)" -exec echo "  - {}" \;; \
	fi
