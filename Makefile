# Portability: parse and run Makefile in POSIX-conforming mode
.POSIX:

# Don't print commands before executing them
.SILENT:

# Disable parallelism
.NOTPARALLEL:

# Clear all SUFFIXes
.SUFFIXES:

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

## TARGETS

# Default target must be the first declared, invoked with `make`
.PHONY: default
default: all

# By convention, performs a complete run (in order)
.PHONY: all
all: | banner clean generate

# Print a banner, binaries versions
.PHONY: banner
banner:
	echo 'waltlenu.it - Static blog, powered by Hugo'; echo
	hugo version
	echo

# Generate website
.PHONY: generate
generate:
	hugo -D -E -F -d public --cleanDestinationDir

# Clean generated output
.PHONY: clean
clean:
	echo 'Deleting generated output…'
	echo -n './public '; rm -rf ./public && echo '         ✅'
	echo -n './resource/_gen '; rm -rf ./resources/_gen && echo '  ✅'
	echo

# Generate and sever website locally
.PHONY: preview
preview:
	hugo server -D -E -F --disableFastRender --cleanDestinationDir

