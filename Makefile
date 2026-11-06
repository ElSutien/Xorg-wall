#MAKEFILE for installing tools

BINPATH := /sbin

SCRIPTS = Xorg-wall
TARGETS = $(addprefix $(BINPATH)/,$(SCRIPTS))
SOURCES = $(addsuffix .sh,$(SCRIPTS))

SHELL = /bin/bash
PWD = $(shell pwd)



.PHONY:  all info help uninstall
default: install


all: install


install: $(TARGETS)


$(BINPATH)/% :  %.sh
	sudo cp $(<) $(@)
	sudo chmod +x $(@)



uninstall:
	@if [ -n "$(wildcard $(TARGETS))" ]; then \
		echo "Removing scripts from bin directory"; \
		echo "rm $(wildcard $(TARGETS))";\
		rm $(wildcard $(TARGETS));\
	else \
		echo "No installed scripts found"; \
	fi







info:
	$(info Shell: $(SHELL))
	$(info PWD: $(PWD))
	$(info Bin Path: $(BINPATH))
	$(info Scripts: $(SCRIPTS))
	$(info Sources: $(SOURCES))
	$(info Targets: $(TARGETS))




help:
	@ echo "Invoked help:"
	@ echo "  install            -  Install script on BIN path."
	@ echo "  uninstall          -  Remove script from BIN path."
	@ echo ""
	@ echo "  info               -  Show info about all config."
	@ echo ""
	@ echo "All targets require sudo to execute."
