.PHONY: setup motd install

# packages that must be installed before others
REQUIRED := stow.pkg

# a list of packages to install, can be set by user
PACKAGES ?= $(sort $(dir $(wildcard */)))

# a list of packages as makefile targets
PACKAGE_TARGETS := $(filter-out $(REQUIRED), $(patsubst %/, %.pkg, $(PACKAGES)))

all:
	@echo "Commands:"
	@echo "  setup     perform pre-install tasks"
	@echo "  motd      install motd (admin privileges)"
	@echo "  install   install packages"
	@echo "  uninstall uninstall packages"
	@echo ""
	@echo "  Use PACKAGES environment to control package installs (default all)"
	@echo ""

setup:
	@echo "--target=$(HOME)" > $(HOME)/.stowrc

install: setup $(REQUIRED) $(PACKAGE_TARGETS)

uninstall: $(patsubst %.pkg, %.rmpkg, $(PACKAGE_TARGETS) $(REQUIRED))

motd:
	@sudo cp motd /etc/motd

%.pkg:
	@echo "installing $*"
	@stow $*

%.rmpkg:
	@echo "uninstall $*"
	@stow -D $*