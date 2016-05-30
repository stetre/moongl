
default: build

build:
	@cd src;		$(MAKE) $@

install:
	@cd src;		$(MAKE) $@

uninstall:
	@cd src;		$(MAKE) $@

clean :
	@cd src;		$(MAKE) $@
#	@cd examples;	$(MAKE) $@
	@cd doc;		$(MAKE) $@
#	@cd tests;		$(MAKE) $@

cleanall: clean

backup: clean
