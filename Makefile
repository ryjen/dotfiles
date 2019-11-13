
CONFIGS := android asdf \
attic bat \
byobu \
cheat \
clang-format \
coreutils \
ctags \
diff \
docker \
editor \
fortune \
git \
golang \
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
pip \
prettyping \
python \
rust \
taskwarrior \
thefuck \
tmux \
tmuxinator \
tmuxp \
vim \
weechat \
xml \
yarn \
zsh

TARGETS := $(patsubst %,%.conf,$(CONFIGS))

ifeq ($(OS),Windows_NT)     # is Windows_NT on XP, 2000, 7, Vista, 10...
    detected_OS := Windows
else
		detected_OS := $(shell uname 2>/dev/null || echo Unknown)
    detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
    detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
    detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
endif

all: setup defaults install configs

.PHONY: setup
setup:
	@echo "Setting up stow..."
	@./setup
	@echo "  stow configured."

.PHONY: defaults
defaults:
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

.PHONY: configs
configs: $(TARGETS)
	@echo "Done."

.PHONY: install
install:
	@echo "Installing configurations..."
# install OS specific
ifeq ($(detected_OS),Darwin)
	@echo "  installing default macos configuration..."
	@stow @macos
endif
ifeq ($(detected_OS),Linux)
	@echo "  installing default linux configuration..."
	@stow @linux
endif

%.conf: %
	@echo "  installing $? configuration..."
ifeq ($(detected_OS),Darwin)
	@if [ -d "$?/@macos" ]; then \
		echo "  installing $? macos configuration..."; \
		cd $? && stow @macos && cd - >/dev/null; \
	fi
endif
