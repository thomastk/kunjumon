#makefile to build the kunjumon tar ball
NAGIOS_DIR=/usr/local/nagios
INSTALL_DIR=$(NAGIOS_DIR)/kunjumon

all: src/*.pl src/*.pm config/*.xml
	cd ..
	tar cvzf kunjumon.tgz ../kunjumon/Makefile ../kunjumon/src/*.pm ../kunjumon/src/*.pl ../kunjumon/config/*.xml

install:
	mkdir -p $(INSTALL_DIR)/
	cp src/* $(INSTALL_DIR)/
	cp config/* $(INSTALL_DIR)/
	chown  -R nagios:nagios $(INSTALL_DIR)
