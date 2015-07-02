CASK        ?= cask
EMACS       ?= emacs
DIST        ?= dist
EMACSFLAGS   = --batch -Q
EMACSBATCH   = $(EMACS) $(EMACSFLAGS)

VERSION     := $(shell EMACS=$(EMACS) $(CASK) version)
PKG_DIR     := $(shell EMACS=$(EMACS) $(CASK) package-directory)
PROJ_ROOT   := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

EMACS_D      = ~/.emacs.d
USER_ELPA_D  = $(EMACS_D)/elpa

SRCS         = $(filter-out %-pkg.el, $(wildcard *.el))
TESTS        = $(wildcard test/*.el)
TAR          = $(DIST)/multimu4e-$(VERSION).tar


.PHONY: all deps check install uninstall reinstall clean-all clean
all : deps $(TAR)

deps :
	# Horrible hack to depend on mu4e even if it is not packaged
	# in any repository
	git submodule init
	git submodule update
	# mu4e
	cp dependencies/mu/mu4e/mu4e-meta.el.in dependencies/mu/mu4e/mu4e-meta.el
	git config --global user.email "damien@cassou.me"
	git config --global user.name "Damien Cassou"
	git -C dependencies/mu checkout -b multimu4e-fake
	git -C dependencies/mu add -f mu4e/mu4e-meta.el
	git -C dependencies/mu commit -m 'Add generated files'
	# </horrible-hack> <-- not W3C compliant :-)
	$(CASK) install

check : deps
	$(CASK) exec $(EMACSBATCH)  \
	$(patsubst %,-l % , $(SRCS))\
	$(patsubst %,-l % , $(TESTS))\
	-f ert-run-tests-batch-and-exit

install : $(TAR)
	$(EMACSBATCH) -l package -f package-initialize \
	--eval '(package-install-file "$(PROJ_ROOT)/$(TAR)")'

uninstall :
	rm -rf $(USER_ELPA_D)/multimu4e-*

reinstall : clean uninstall install

clean-all : clean
	rm -rf $(PKG_DIR)

clean :
	rm -f *.elc
	rm -rf $(DIST)
	rm -f *-pkg.el

$(TAR) : $(DIST) $(SRCS)
	$(CASK) package $(DIST)

$(DIST) :
	mkdir $(DIST)
