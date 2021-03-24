.PHONY: setup motd install

PACKAGES ?= $(sort $(patsubst %/,%.pkg,$(dir $(wildcard */))))

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

install: setup $(PACKAGES)

uninstall: $(patsubst %.pkg,%.rmpkg,$(PACKAGES))

motd:
	@sudo cp motd /etc/motd

%.pkg:
	@echo "installing $*"
	@stow $*

%.rmpkg:
	@echo "uninstall $*"
	@stow -D $*