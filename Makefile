.PHONY: setup motd

all:
	@echo "Commands:"
	@echo "  setup     perform pre-install tasks"
	@echo "  motd      install motd (admin privileges)"
	@echo ""

setup:
	@mkdir -p $(HOME)/.config/{git,nvim,task,mutt,jrnl}
	@echo "--target=$(HOME)" > $(HOME)/.stowrc

motd:
	@sudo cp motd /etc/motd