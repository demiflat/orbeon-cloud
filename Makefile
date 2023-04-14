####################################################### 
# orbeon build:
# requires gnu make
# uses gmsl: https://sourceforge.net/projects/gmsl/
# inspired by: https://tech.davis-hansson.com/p/make/
####################################################### 
include gmsl/gmsl
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >
####################################################### 

.PHONY: build
build: build/.build-container compile
#build: build/.build-container.almalinux build/.build-container.fedora build/.build-container.rocky build/.build-container.ubuntu
#fedora is the smallest:
#localhost/orbeon-build-fedora               latest         d209a94e1347   49 seconds ago   1.36 GB
#localhost/orbeon-build-ubuntu               latest         96216a82b5f9   8 minutes ago    2.21 GB
#localhost/orbeon-build-rocky                latest         6f4b7ad3b6fa   10 minutes ago   1.49 GB
#localhost/orbeon-build-almalinux            latest         7d2d13973669   11 minutes ago   1.91 GB

build/.build-container.almalinux:
> buildah build -f build/CONTAINERFILE.almalinux -t orbeon-build-almalinux
> @touch build/.build-container.almalinux

build/.build-container.fedora:
> buildah build -f build/CONTAINERFILE.fedora -t orbeon-build-fedora
> @touch build/.build-container.fedora

build/.build-container.rocky:
> buildah build -f build/CONTAINERFILE.rocky -t orbeon-build-rocky
> @touch build/.build-container.rocky

build/.build-container.ubuntu:
> buildah build -f build/CONTAINERFILE.ubuntu -t orbeon-build-ubuntu
> @touch build/.build-container.ubuntu

build/.build-container: build/.build-container.ubuntu
> buildah tag orbeon-build-ubuntu orbeon-build

# token comes from environment
GH_TOKEN=$(GITHUB_TOKEN)
.PHONY: compile
compile:
> podman run -it --rm --volume ./orbeon-forms:/orbeon:z -eGITHUB_TOKEN=$(GH_TOKEN) orbeon-build

.PHONY: clean
clean: clean-images
> @rm -f build/.build-container.almalinux
> @rm -f build/.build-container.fedora
> @rm -f build/.build-container.rocky
> @rm -f build/.build-container.ubuntu

.PHONY: clean-images
clean-images:
> @podman rmi -i localhost/orbeon-build-almalinux
> @podman rmi -i localhost/orbeon-build-fedora
> @podman rmi -i localhost/orbeon-build-rocky
> @podman rmi -i localhost/orbeon-build-ubuntu
> @podman rmi -i localhost/orbeon-build