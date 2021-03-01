# Portability: parse and run Makefile in POSIX-conforming mode
.POSIX:

# Don't print commands before executing them
.SILENT:

# Disable parallelism
.NOTPARALLEL:

# Clear all SUFFIXes
.SUFFIXES:

# Configure SHELL
SHELL := /usr/bin/env bash

## TARGETS

# Default target must be the first declared, invoked with `make`
.PHONY: default
default: all

# By convention, performs a complete run (in order)
.PHONY: all
all: | banner clean generate

# banner target
.PHONY: banner
banner:
	echo 'waltlenu.it - Static blog, powered by Hugo'
	hugo version
	echo

# generate target
.PHONY: generate
generate:
	hugo -D -E -F -d public --cleanDestinationDir

# clean target
.PHONY: clean
clean:
	echo -n 'Deleting: ./public ./resources/_gen ...'
	rm -rf ./public ./resources/_gen
	echo -e "\e[36m\e[1m Done!\e[0m"
	echo

# preview target
.PHONY: preview
preview:
	hugo server -D -E -F --disableFastRender --cleanDestinationDir

.PHONY: changelog
changelog:
	git-chglog -o CHANGELOG.md --next-tag `semtag final -s minor -o`

.PHONY: release
release:
	semtag final -s minor
