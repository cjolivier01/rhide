# Copyright (C) 1996-1998 Robert H�hne, see COPYING.RH for details 
# This file is part of RHIDE. 
#

.SUFFIXES: .mak .gpr

all::

ifeq ($(strip $(list_file)),)
list_file=list
endif

ifeq ($(strip $(po_list)),)
po_list=po_list
endif

ifeq ($(strip $(logfile)),)
logfile=logfile
endif

# I have changed data/locale to share/locale !!!!!!!!!!!!!!!!!!

locale_dir=$(prefix)/share/locale
PACKAGE=rhide
# for the DJGPP archives $(PACKAGE_FILE)$(FILE_VERSION) must not
# exceed 8 characters, the well known DOS limitation :-(
PACKAGE_FILE=rhid
PACKAGE_DIR=rhide
VERSION=1.4.8
RHIDE_MAJOR=$(word 1,$(subst ., ,$(VERSION)))
RHIDE_MINOR=$(subst $(RHIDE_MAJOR),,$(VERSION))
# for the DJGPP archives
FILE_VERSION=$(subst .,,$(VERSION))
DIR_VERSION_Linux=-$(VERSION)
# for the DJGPP directories
DIR_VERSION_DJGPP=-$(RHIDE_MAJOR).$(subst .,,$(RHIDE_MINOR))
DIR_VERSION=$(DIR_VERSION_$(rhide_OS))

DJP=
use_djp=no

setgid=
setuid=
SETGID=
SETUID=
SETMODE=0

ifneq ($(setgid),)
SETGID=-g $(setgid)
SETMODE=2
endif

ifneq ($(setuid),)
SETUID=-o $(setuid)
SETMODE=4
endif

EXEC_MODE=-m $(SETMODE)755
DATA_MODE=-m 0644


ifneq ($(strip $(DJDIR)),)
export rhide_OS:=DJGPP
INSTALL_DIR=ginstall -d -m 0755
INSTALL_DATA=ginstall $(DATA_MODE)
INSTALL_PROGRAM=ginstall -s $(EXEC_MODE) $(SETUID) $(SETGID)
DJP=djp
use_djp=yes
endif

ifeq ($(strip $(rhide_OS)),)
export rhide_OS:=$(shell uname)
endif

ifeq ($(rhide_OS),DJGPP)
exe=.exe
else
exe=
endif

SETMODE=0
setgid=
setuid=
ifeq ($(strip $(rhide_OS)),Linux)
INSTALL_DIR=install -d -m 0755
INSTALL_DATA=install $(DATA_MODE)
INSTALL_PROGRAM=install -s $(EXEC_MODE) $(SETUID) $(SETGID)
endif

# This makes top_dir as a relative path to srcdir
empty=
space=$(empty) $(empty)
top_dir:=$(strip $(subst $(RHIDESRC),,$(srcdir)))
ifeq ($(top_dir),)
top_dir:=.
else
top_dir:=$(subst /, ,$(top_dir))
top_dir:=$(patsubst %,../,$(top_dir))
top_dir:=$(subst $(space),,$(top_dir))
top_dir:=$(patsubst %/,%,$(top_dir))
endif

ifeq ($(top_dir),.)
_top_dir=
else
_top_dir=$(top_dir)/
endif

obj_dir:=$(shell pwd)
ifeq ($(top_obj_dir),)
ifeq ($(strip $(rhide_OS)),DJGPP)
export top_obj_dir:=$(shell cd $(top_dir); pwd; cd $(obj_dir))
else
export top_obj_dir:=$(shell cd $(top_dir); pwd; cd $(obj_dir))
endif
endif

update_src_file=echo
update_gpr_file=echo

ifeq ($(copyrite.exe),)
export copyrite.exe:=$(top_obj_dir)/copyrite.exe
endif

ifeq ($(strip $(rhide_OS)),Linux)
move-if-change=$(SHELL) $(RHIDESRC)/moveifch
else
move-if-change=$(RHIDESRC)/moveifch
endif

gpr2mak:=$(wildcard $(top_dir)/gpr2mak.exe)

ifeq ($(strip $(prefix)),)
ifeq ($(rhide_OS),DJGPP)
prefix=$(DJDIR)
else
prefix=/usr/local
endif
endif

install_datadir=share/$(PACKAGE)
install_docdir=doc/$(PACKAGE)
install_infodir=info
install_bindir=bin
install_localedir=share/locale

rhideb=$(PACKAGE_FILE)$(FILE_VERSION)b
rhides=$(PACKAGE_FILE)$(FILE_VERSION)s
rhide=$(PACKAGE_DIR)$(DIR_VERSION)

ifeq ($(rhide_OS),DJGPP)
copy_dir=/_
else
copy_dir=/tmp/_
endif

FLAGS_TO_PASS=\
	CFLAGS="$(CFLAGS)" \
	LDFLAGS="$(LDFLAGS)" \
	RHIDESRC="$(RHIDESRC)" \
	TVSRC="$(TVSRC)" \
	TVOBJ="$(TVOBJ)" \
	SETSRC="$(SETSRC)" \
	SETOBJ="$(SETOBJ)" \
	GDB_SRC="$(GDB_SRC)" \
	GDB_OBJ="$(GDB_OBJ)" \
	rhide_OS="$(rhide_OS)" \
	top_obj_dir="$(top_obj_dir)" \
	install_datadir=$(install_datadir) \
	install_docdir=$(install_docdir) \
	install_infodir=$(install_infodir) \
	install_bindir=$(install_bindir) \
	install_localedir=$(install_localedir) \
	DATA_MODE="$(DATA_MODE)" \
	EXEC_MODE="$(EXEC_MODE)" \
	SETUID="$(SETUID)" \
	SETGID="$(SETGID)" \
	prefix=$(prefix) \
	update_src_file="$(update_src_file)" \
	update_gpr_file="$(update_gpr_file)"

%.sub: Makefile
	@$(MAKE) -C $* $(FLAGS_TO_PASS) SUBDIR_TARGET=$(SUBDIR_TARGET) \
	  $(SUBDIR_TARGET) logfile=../__log__
	@touch __log__
	@cat __log__ >> $(logfile)
	@rm -f __log__

subdir_do: $(addsuffix .sub,$(sort $(subdirs)))

O_SRC_FILES=$(wildcard $(addprefix $(obj_dir)/,$(sort $(src_files))))
_O_SRC_FILES=$(subst $(obj_dir)/,,$(O_SRC_FILES))
__SRC_FILES=$(filter-out $(_O_SRC_FILES),$(sort $(src_files)))
S_SRC_FILES=$(wildcard $(addprefix $(srcdir)/,$(__SRC_FILES)))
_S_SRC_FILES=$(subst $(srcdir)/,,$(S_SRC_FILES))
_SRC_FILES=$(filter-out $(_O_SRC_FILES) $(_S_SRC_FILES),$(sort $(src_files)))
SRC_FILES=$(O_SRC_FILES) $(S_SRC_FILES) $(_SRC_FILES)

ifneq ($(strip $(subdirs)),)
copy_src_files:: $(addsuffix .cpy,$(sort $(subdirs)))

check_src_files:: $(addsuffix .chk,$(sort $(subdirs)))

update__srcdir:: $(addsuffix .sub,$(subdirs))
endif

check_src_files:: $(SRC_FILES)
	@echo > /dev/null

copy_src_files:: $(SRC_FILES)
ifneq ($(SRC_FILES),)
	@echo Copying files from $(srcdir)
	@$(INSTALL_DIR) $(prefix)
	@cp -p $(SRC_FILES) $(prefix)
	@echo $(addprefix $(list_prefix),$(sort $(src_files))) >> $(list_file)
endif

po_list:: $(po_files)
	@echo $(addprefix $(po_prefix),$(po_files) $(additional_po_files)) \
	 > $(po_list)
ifneq ($(strip $(po_subdirs)),)
# special case for po_subdirs=..
ifeq ($(strip $(po_subdirs)),..)
this_dir:=$(notdir $(shell pwd))
po_list::
	@$(MAKE) -C .. $(FLAGS_TO_PASS) po_list=$(this_dir)/$(this_dir).pst \
	  po_prefix=$(po_prefix)../ po_list
	@cat $(this_dir).pst >> $(po_list)
	@rm $(this_dir).pst
else
po_sub_files=$(addsuffix .pst,$(po_subdirs))
po_list:: $(po_sub_files)
	@cat $(po_sub_files) >> $(po_list)
	@rm $(po_sub_files)
endif
endif

%.pst: Makefile
	@$(MAKE) -C $* $(FLAGS_TO_PASS) po_list=../$@ \
	  po_prefix=$(po_prefix)$*/ po_list

%.cpy: Makefile
	@-mkdir -p $(prefix)/$*
	@-rm -f $*/$(list_file)
	@$(MAKE) -C $* $(FLAGS_TO_PASS) prefix=$(prefix)/$* \
	  --no-print-directory \
	  list_file=$(list_file) list_prefix=$(list_prefix)$*/ copy_src_files
	@cat $*/$(list_file) >> $(list_file)
	@-rm -f $*/$(list_file)

%.chk: Makefile
	@echo Checking in $(obj_dir)/$*
	@$(MAKE) -C $* $(FLAGS_TO_PASS) --no-print-directory \
	  check_src_files

ifneq ($(strip $(gpr2mak)),)
%.mak: %.gpr $(copyrite.exe)
	@$(update_gpr_file) $(notdir $<) > /dev/null
ifeq ($(rhide_OS),DJGPP)
	@$(gpr2mak) -d -r- -o - $(notdir $<) \
	  | sed -e 's,	$(DJDIR),	$$(DJDIR),g' \
	        -e '/^		$$(DJDIR).*\\$$/d' \
	        -e 's,^		$$(DJDIR)[^\\]*$$,,' \
	        -e 's,	$(RHIDESRC),	$$(RHIDESRC),g' \
		-e 's,^		$(obj_dir)/,		,' \
		-e 's,	$(top_obj_dir),	$$(top_obj_dir),g' \
	  $(USER_GPR2MAK_SEDS) > __tmp__.mak
else
	@$(gpr2mak) -d -r- -o - $(notdir $<) \
	  | sed -e 's,	$(RHIDESRC),	$$(RHIDESRC),g' \
	        -e 's,\([ 	]\)$(_top_dir)../../src/rhide,\1$$(RHIDESRC),g' \
	        -e 's,\([ 	]\)*[\./]*[^ ]*i486-pc-linux-[^ \\]*,\1$$(USRINC),g' \
	        -e 's,	/usr/lib/gcc-lib,	$$(USRINC),g' \
	        -e '/^[ 	]*$$(USRINC).*\\$$/d' \
	        -e 's,\([ 	]*\)$$(USRINC),\1,g' \
		-e 's,^		$(obj_dir)/,		,' \
		-e 's,	$(top_obj_dir),	$$(top_obj_dir),g' \
	  $(USER_GPR2MAK_SEDS) > __tmp__.mak
endif
	@$(copyrite.exe) __tmp__.mak > /dev/null
	@$(move-if-change) __tmp__.mak $@ > /dev/null
	@touch -r $@ $(notdir $<)
	@rm -f __tmp__.mak
	@$(update_src_file) $@ $(srcdir)/$(notdir $@) > /dev/null
	@$(update_src_file) $< $(srcdir)/$(notdir $<) > /dev/null
endif

ifneq ($(strip $(project)),)
-include $(addsuffix .mak,$(project))
endif

%.cfo: Makefile
	@-mkdir $*
	@$(MAKE) --no-print-directory -C $* -f $(srcdir)/$*/Makefile \
	         $(FLAGS_TO_PASS) config

.PHONY: config

config::
	@echo Configuring $(obj_dir) ...
	@cp -fp $(srcdir)/Makefile $(wildcard $(srcdir)/rhide.env) $(obj_dir)
ifneq ($(cfg_files),)
	@cp -fp $(addprefix $(srcdir)/,$(cfg_files)) $(obj_dir)
endif
ifneq ($(projects),)
	@cp -fp $(addprefix $(srcdir)/,$(addsuffix .gpr,$(projects))) $(obj_dir)
	@cp -fp $(addprefix $(srcdir)/,$(addsuffix .mak,$(projects))) $(obj_dir)
endif
ifneq ($(subdirs),)
config:: $(addsuffix .cfo,$(subdirs))
endif

install.data::
install.bin::
install.info::
install.doc::

install::
	@rm -f $(logfile) $(instfile)

ifneq ($(strip $(install_data_files)),)
install.data:: $(install_data_files)
	$(INSTALL_DIR) $(prefix)/$(install_datadir)
	$(INSTALL_DATA) $^ $(prefix)/$(install_datadir)
	@echo $(addprefix $(install_datadir)/,$(install_data_files)) >> $(logfile)
endif

ifneq ($(strip $(install_info_files)),)
install.info:: $(install_info_files)
	$(INSTALL_DIR) $(prefix)/$(install_infodir)
	$(INSTALL_DATA) $^ $(prefix)/$(install_infodir)
	@echo $(addprefix $(install_infodir)/,$(install_info_files)) >> $(logfile)
endif

ifneq ($(strip $(install_doc_files)),)
install.doc:: $(install_doc_files)
	$(INSTALL_DIR) $(prefix)/$(install_docdir)
	$(INSTALL_DATA) $^ $(prefix)/$(install_docdir)
	@echo $(addprefix $(install_docdir)/,$(install_doc_files)) >> $(logfile)
endif

ifneq ($(strip $(install_bin_files)),)
INSTALL_BIN_FILES=$(addsuffix $(exe),$(install_bin_files))
install.bin:: $(INSTALL_BIN_FILES)
	$(INSTALL_DIR) $(prefix)/$(install_bindir)
	$(INSTALL_PROGRAM) $^ $(prefix)/$(install_bindir)
ifeq ($(use_djp),yes)
	$(DJP) $(addprefix $(prefix)/$(install_bindir)/,$(INSTALL_BIN_FILES))
endif
	@echo $(addprefix $(install_bindir)/,$(INSTALL_BIN_FILES)) >> $(logfile)
endif

ifneq ($(SUBDIR_TARGET),)
install:: $(addsuffix .sub,$(subdirs))
endif

install:: install.data install.info install.doc install.bin

$(copyrite.exe): $(RHIDESRC)/copyrite.c
	gcc -o $@ -s -O $<
