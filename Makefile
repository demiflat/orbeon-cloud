####################################################### 
# orbeon build:
# requires gnu make, podman
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
# environment parameters
####################################################### 
# token comes from environment
GH_TOKEN=$(GITHUB_TOKEN)
# push registry url comes from environment
PUSH_URL := $(ORBEON_REGISTRY_PUSH_URL)
####################################################### 

.PHONY: default
default: print-targets

# define standard colors
ifneq (,$(findstring xterm,${TERM}))
	BLACK        := $(shell tput -Txterm setaf 0)
	RED          := $(shell tput -Txterm setaf 1)
	GREEN        := $(shell tput -Txterm setaf 2)
	YELLOW       := $(shell tput -Txterm setaf 3)
	LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
	PURPLE       := $(shell tput -Txterm setaf 5)
	BLUE         := $(shell tput -Txterm setaf 6)
	WHITE        := $(shell tput -Txterm setaf 7)
	RESET := $(shell tput -Txterm sgr0)
else
	BLACK        := ""
	RED          := ""
	GREEN        := ""
	YELLOW       := ""
	LIGHTPURPLE  := ""
	PURPLE       := ""
	BLUE         := ""
	WHITE        := ""
	RESET        := ""
endif

.PHONY: print-targets
print-targets: banner
> $(info $(YELLOW)orbean-build $(GREEN)make targets:$(RESET))
> $(info $(WHITE)     build: $(BLUE)make build container$(RESET))
> $(info $(WHITE)     build-container-inspect: $(BLUE)inspect build container contents$(RESET))
> $(info $(WHITE)     compile: $(BLUE)compile orbeon using build container$(RESET))
> $(info $(WHITE)     staging: $(BLUE)prepare contents for deployment container in $(LIGHTPURPLE)package/staging/orbeon-exploded$(RESET))
> $(info $(WHITE)     package: $(BLUE)make deployment container for tomcat$(RESET))
> $(info $(WHITE)     package-inspect: $(BLUE)inspect tomcat deployment container contents$(RESET))
> $(info $(WHITE)     start-tomcat: $(BLUE)start tomcat container$(RESET))
> $(info $(WHITE)     simple-pod: $(BLUE)start tomcat container as a pod$(RESET))
> $(info $(WHITE)     push-image: $(BLUE)push container image to "$$ORBEON_REGISTRY_PUSH_URL"$(RESET))
> $(info $(WHITE)     clean: $(BLUE)clean everything$(RESET))
> $(info $(WHITE)     staging-clean: $(BLUE)clean staging area$(RESET))
> $(info $(WHITE)     clean-images: $(BLUE)clean local images$(RESET))

banner:
> @cat .banner

.PHONY: build
build: build/.build-container compile package
#build-all: build/.build-container.almalinux build/.build-container.fedora build/.build-container.rocky build/.build-container.ubuntu

build/.build-container.almalinux:
> podman build -f build/CONTAINERFILE.almalinux -t orbeon-build-almalinux
> @touch build/.build-container.almalinux

build/.build-container.fedora:
> podman build -f build/CONTAINERFILE.fedora -t orbeon-build-fedora
> @touch build/.build-container.fedora

build/.build-container.rocky:
> podman build -f build/CONTAINERFILE.rocky -t orbeon-build-rocky
> @touch build/.build-container.rocky

build/.build-container.ubuntu:
> podman build -f build/CONTAINERFILE.ubuntu -t orbeon-build-ubuntu
> @touch build/.build-container.ubuntu

# canonical build container
build/.build-container: build/.build-container.ubuntu
> podman tag orbeon-build-ubuntu orbeon-build

.PHONY: build-container-inspect
build-container-inspect: package
> podman run -it --rm --entrypoint /bin/bash orbeon-build 

.PHONY: compile
compile:
> podman run -it --rm --volume ./orbeon-forms:/orbeon:z -eGITHUB_TOKEN=$(GH_TOKEN) orbeon-build

.PHONY: package
package: staging package-deploy-container

.PHONY: package-deploy-container
package-deploy-container:
> podman build -f package/CONTAINERFILE.tomcat -t orbeon-tomcat

.PHONY: package-inspect
package-inspect: package
> podman run -it --rm --entrypoint /bin/bash orbeon-tomcat 

.PHONY: start-tomcat
start-tomcat: package
> podman run -it --rm -p 8080:8080 orbeon-tomcat

.PHONY: staging
staging: package/staging/orbeon-exploded

package/staging/orbeon-exploded: package/staging/orbeon
> unzip package/staging/orbeon/orbeon.war -d package/staging/orbeon-exploded

package/staging/orbeon:
> unzip orbeon-forms/build/distrib/orbeon-2*-CE.zip -d package/staging
> cd package/staging && ln -s orbeon-* orbeon

.PHONY: staging-clean
staging-clean:
> @rm -rf package/staging/*;

.PHONY: push-image
push-image: package
> podman push orbeon-tomcat $(PUSH_URL)

.PHONY: simple-pod
simple-pod:
> podman kube play kube/tomcat-single-pod.yaml

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