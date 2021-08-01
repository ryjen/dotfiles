.PHONY: setup motd install minimal basic extra config show show-config show-config-prompt show-groups

# packages that must be installed before others
REQUIRED := stow.pkg

# a list of packages to install, can be set by user
PACKAGES ?= $(sort $(dir $(wildcard */)))

MINIMAL_PACKAGES := stow coreutils git zsh ssh tmux neovim input vimdiff lsd

BASIC_PACKAGES := taskwarrior asdf bat less ctags fzf gpg rsync fortune jrnl byobu direnv docker golang oh-my-zsh

EXTRA_PACKAGES := $(filter-out $(MINIMAL_PACKAGES) $(BASIC_PACKAGES), $(patsubst %/, %, $(PACKAGES)))

# a list of packages as makefile targets
PACKAGE_TARGETS := $(filter-out $(REQUIRED), $(patsubst %/, %.pkg, $(PACKAGES)))

# configuration of package files
CONFIGURE_EXAMPLES := $(shell find . -mindepth 3 -name "*.example" | xargs)

CONFIGURE_FILES := $(shell echo $(CONFIGURE_EXAMPLES) | tr ' ' '\n' | cut -d'/' -f3-)

all:
	@echo "Commands:"
	@echo ""
	@echo "  install   install all packages"
	@echo "  uninstall uninstall all packages"
	@echo ""
	@echo "  Groups:"
	@echo "    minimal   install minimal packages"
	@echo "    basic     install basic packages"
	@echo "    extra     install extra packages"
	@echo ""
	@echo "  Other:"
	@echo "    motd      install motd (admin privileges)"
	@echo "    show      show packages in groups and files that need configuration"
	@echo "    config    edit files that need manual configuration"
	@echo ""
	@echo "  Use PACKAGES environment to control package installs (default all)"
	@echo ""

setup:
	@echo "--target=$(HOME)" > $(HOME)/.stowrc

install: setup $(REQUIRED) $(PACKAGE_TARGETS) show-config

uninstall: $(patsubst %.pkg, %.rmpkg, $(PACKAGE_TARGETS) $(REQUIRED))

minimal: $(patsubst %, %.pkg, $(MINIMAL_PACKAGES)) show-config

basic: $(patsubst %, %.pkg, $(BASIC_PACKAGES)) show-config

extra: $(patsubst %, %.pkg, $(EXTRA_PACKAGES)) show-config

show-groups:
	@echo "Minimal Packages:"
	@echo ""
	@echo "  $(MINIMAL_PACKAGES)"
	@echo ""
	@echo "Basic Packages:"
	@echo ""
	@echo "  $(BASIC_PACKAGES)"
	@echo ""
	@echo "Extra Packages:"
	@echo ""
	@echo "  $(EXTRA_PACKAGES)"

show: show-groups show-config

show-config-prompt:
	@echo ""
	@echo "Files to manually configure:"
	@echo ""

show-config: show-config-prompt $(patsubst %.example, %.remind, $(CONFIGURE_FILES))
	@echo ""
	@echo "Use 'make config' to copy and edit"

config: $(patsubst %.example, %.config, $(CONFIGURE_EXAMPLES))
	@$(EDITOR) $(patsubst %.example, $(HOME)/%, $(CONFIGURE_FILES))

motd:
	@sudo cp motd /etc/motd

%.pkg:
	@echo "installing $*"
	@stow $*

%.rmpkg:
	@echo "uninstall $*"
	@stow -D $*

%.config: %.example
	$(eval CONFIG_FILE := $(HOME)/$(shell echo $* | cut -d'/' -f2-))
	@test -f $(CONFIG_FILE) || cp $< $(CONFIG_FILE)

%.remind:
	@echo "  ~/$*"