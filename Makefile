# Makefile for building the Jellyfin QPKG using QDK (qbuild)

.PHONY: all qpkg clean

all: qpkg

qpkg:
	qbuild

clean:
	rm -rf build
