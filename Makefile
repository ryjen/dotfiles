.PHONY: setup motd install

PACKAGES = $(sort $(patsubst %/,%.pkg,$(dir $(wildcard */))))

all:
	@echo "Commands:"
	@echo "  setup     perform pre-install tasks"
	@echo "  motd      install motd (admin privileges)"
	@echo "  install   install all packages" 
	@echo ""

setup:
	@echo "--target=$(HOME)" > $(HOME)/.stowrc

install: setup $(PACKAGES)

motd:
	@sudo cp motd /etc/motd

%.pkg:
	@echo "installing $*"
	@stow $*