####################################################### 
# orbeon build:
####################################################### 
# build requires: 
#   gnu make (https://www.gnu.org/software/make/)
#   gnu bash (https://www.gnu.org/software/bash/)
#   podman   (https://podman.io/)
# kubernetes functions require:
#   kubectl  (https://kubernetes.io/docs/home/)
#   kind     (https://kind.sigs.k8s.io/docs/user/rootless/)
# uses gmsl: (https://sourceforge.net/projects/gmsl/)
# inspired by: (https://tech.davis-hansson.com/p/make/)
# makefile graph:
#   makefile2graph (https://github.com/lindenb/makefile2graph)
#   graphviz (https://graphviz.org/)
####################################################### 
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
GH_TOKEN := $(GITHUB_TOKEN)
# push registry url comes from environment
PUSH_URL := $(ORBEON_REGISTRY_PUSH_URL)
####################################################### 
# build variables
####################################################### 
KIND_KUBE_CONFIG := $(CURDIR)/kube/.kind.kubeconfig
KUBECONFIG = $(KIND_KUBE_CONFIG)
KUBECTL = kubectl --kubeconfig=$(KUBECONFIG)
####################################################### 
# utilities
####################################################### 
include gmsl/gmsl
####################################################### 
# define standard colors
####################################################### 
BLACK        := $(shell tput -Txterm setaf 0)
RED          := $(shell tput -Txterm setaf 1)
GREEN        := $(shell tput -Txterm setaf 2)
YELLOW       := $(shell tput -Txterm setaf 3)
LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
PURPLE       := $(shell tput -Txterm setaf 5)
BLUE         := $(shell tput -Txterm setaf 6)
WHITE        := $(shell tput -Txterm setaf 7)
RESET        := $(shell tput -Txterm sgr0)
####################################################### 
# debug variables
#######################################################
.PHONY: printvars
printvars:
>$(foreach V,
>    $(sort $(.VARIABLES)),
>  $(if 
>      $(filter-out environment% default automatic,
>        $(origin $V)),
>      $(warning $V=$($V) ($(value $V)))
>    )
>  )
####################################################### 
# graph dependencies
####################################################### 
.PHONY: diagram
diagram: diagram/build-container.png diagram/publish.png diagram/kind-deploy.png
diagram/build-container.png:
> make -Bnd build-container | make2graph | dot -Tpng -o diagram/build-container.png
diagram/publish.png:
> make -Bnd publish | make2graph | dot -Tpng -o diagram/publish.png
diagram/kind-deploy.png:
> make -Bnd kind-deploy | make2graph | dot -Tpng -o diagram/kind-deploy.png
####################################################### 
# build targets
####################################################### 
.PHONY: default
default: print-targets
.DEFAULT_GOAL := default
####################################################### 
# define standard colors
####################################################### 
BLACK        := $(shell tput -Txterm setaf 0)
RED          := $(shell tput -Txterm setaf 1)
GREEN        := $(shell tput -Txterm setaf 2)
YELLOW       := $(shell tput -Txterm setaf 3)
LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
PURPLE       := $(shell tput -Txterm setaf 5)
BLUE         := $(shell tput -Txterm setaf 6)
WHITE        := $(shell tput -Txterm setaf 7)
RESET        := $(shell tput -Txterm sgr0)
####################################################### 
# help message
####################################################### 
.PHONY: print-targets
print-targets: banner
> $(info $(YELLOW)orbean-build $(GREEN)make targets:$(RESET))
> $(info $(WHITE)     build-container: $(BLUE)make build container$(RESET))
> $(info $(WHITE)     build-container-inspect: $(BLUE)inspect build container contents$(RESET))
> $(info $(WHITE)     compile: $(BLUE)compile orbeon using build container$(RESET))
> $(info $(WHITE)     staging: $(BLUE)prepare contents for deployment container in $(LIGHTPURPLE)package/staging/orbeon-exploded$(RESET))
> $(info $(WHITE)     package: $(BLUE)make deployment container for tomcat$(RESET))
> $(info $(WHITE)     package-inspect: $(BLUE)inspect tomcat deployment container contents$(RESET))
> $(info $(WHITE)     start-tomcat: $(BLUE)start tomcat container; CTRL-C to quit$(RESET))
> $(info $(WHITE)     simple-pod: $(BLUE)start tomcat container as a pod$(RESET))
> $(info $(WHITE)     simple-pod-clean: $(BLUE)teardown simple tomcat pod$(RESET))
> $(info $(WHITE)     publish: $(BLUE)publish container image to "$$ORBEON_REGISTRY_PUSH_URL"$(RESET))
> $(info $(WHITE)     clean: $(BLUE)clean everything$(RESET))
> $(info $(WHITE)     staging-clean: $(BLUE)clean staging area$(RESET))
> $(info $(WHITE)     clean-images: $(BLUE)clean local images$(RESET))
####################################################### 
# banner
#######################################################
.PHONY: banner
banner:
> @cat .banner
####################################################### 
# build build-container
#######################################################
.PHONY: build-container
build-container: build/.build-container
####################################################### 
# build all build-containers
#######################################################
.PHONY: build-container-all
build-container-all: build/.build-container.almalinux build/.build-container.almalinux.jdk17 build/.build-container.fedora build/.build-container.fedora.jdk17 build/.build-container.rocky build/.build-container.rocky.jdk17 build/.build-container.ubuntu build/.build-container.ubuntu.jdk17
####################################################### 
# build almalinux build-container
#######################################################
build/.build-container.almalinux:
> podman build -f build/CONTAINERFILE.almalinux -t orbeon-build-almalinux
> @touch build/.build-container.almalinux
####################################################### 
# build almalinux jdk17 build-container
#######################################################
build/.build-container.almalinux.jdk17:
> podman build -f build/CONTAINERFILE.almalinux.jdk17 -t orbeon-build-almalinux.jdk17
> @touch build/.build-container.almalinux.jdk17
####################################################### 
# build fedora build-container
#######################################################
build/.build-container.fedora:
> podman build -f build/CONTAINERFILE.fedora -t orbeon-build-fedora
> @touch build/.build-container.fedora
####################################################### 
# build fedora jdk17 build-container
#######################################################
build/.build-container.fedora.jdk17:
> podman build -f build/CONTAINERFILE.fedora.jdk17 -t orbeon-build-fedora.jdk17
> @touch build/.build-container.fedora.jdk17
####################################################### 
# build rocky build-container
#######################################################
build/.build-container.rocky:
> podman build -f build/CONTAINERFILE.rocky -t orbeon-build-rocky
> @touch build/.build-container.rocky
####################################################### 
# build rocky jdk17 build-container
#######################################################
build/.build-container.rocky.jdk17:
> podman build -f build/CONTAINERFILE.rocky.jdk17 -t orbeon-build-rocky.jdk17
> @touch build/.build-container.rocky.jdk17
####################################################### 
# build ubuntu build-container
#######################################################
build/.build-container.ubuntu:
> podman build -f build/CONTAINERFILE.ubuntu -t orbeon-build-ubuntu
> @touch build/.build-container.ubuntu
####################################################### 
# build ubuntu jdk17 build-container
#######################################################
build/.build-container.ubuntu.jdk17:
> podman build -f build/CONTAINERFILE.ubuntu.jdk17 -t orbeon-build-ubuntu.jdk17
> @touch build/.build-container.ubuntu.jdk17
####################################################### 
# tag build-container
#   choose canonical build container
#######################################################
build/.build-container: build/.build-container.ubuntu
> podman tag orbeon-build-ubuntu orbeon-build
####################################################### 
# build-container-inspect
#   inspect the build environment used for compilation
#######################################################
.PHONY: build-container-inspect
build-container-inspect: package
> podman run -it --rm --entrypoint /bin/bash orbeon-build 
####################################################### 
# compile
#   implicit dependency on build-container
#     but we don't want to unnecessarily rebuild
#     the build-container everytime we want to compile
#######################################################
.PHONY: compile
compile:
> podman run -it --rm --volume ./orbeon-forms:/orbeon:z -eGITHUB_TOKEN=$(GH_TOKEN) orbeon-build
####################################################### 
# package
#   build the deployment orbean container
#   first stage everything (staging)
#   then package it (build-deploy-container)
#   from the staging environment
#######################################################
.PHONY: package
package: staging build-deploy-container
####################################################### 
# build-deploy-container
#   build the actual container
#######################################################
.PHONY: build-deploy-container
build-deploy-container:
> podman build -f package/CONTAINERFILE.tomcat -t orbeon-tomcat:test
####################################################### 
# package-inspect
#   inspect the deployment environment container
#######################################################
.PHONY: package-inspect
package-inspect: package
> podman run -it --rm --entrypoint /bin/bash orbeon-tomcat 
####################################################### 
# start-tomcat
#   start the container as part of development
#######################################################
.PHONY: start-tomcat
start-tomcat: package
> podman run -it --rm -p 8080:8080 orbeon-tomcat
####################################################### 
# staging
#   create the staging environment
#   for everything that will go into the container
#######################################################
.PHONY: staging
staging: package/staging/orbeon-exploded
####################################################### 
# package/staging/orbeon-exploded
#   create staging exploded war for adding artifacts
#   to deployment container
#######################################################
package/staging/orbeon-exploded: package/staging/orbeon
> unzip package/staging/orbeon/orbeon.war -d package/staging/orbeon-exploded
####################################################### 
# package/staging/orbeon:
#   unzip build
#   this has an implicit dependency on compile
#   although we don't need to recompile unless there
#   has been a change
#######################################################
package/staging/orbeon:
> unzip orbeon-forms/build/distrib/orbeon-2*-CE.zip -d package/staging
> cd package/staging && ln -s orbeon-* orbeon
####################################################### 
# staging-clean
#  cleanup our mess
#######################################################
.PHONY: staging-clean
staging-clean:
> @rm -rf package/staging/*;
####################################################### 
# publish
#   publish deployment image to remote repository
#######################################################
.PHONY: publish
publish: package
> podman push orbeon-tomcat $(PUSH_URL)
####################################################### 
# simple-pod
#   run single instance pod in podman
#######################################################
.PHONY: simple-pod
simple-pod: package
> podman kube play kube/tomcat-single-pod.yaml
####################################################### 
# simple-pod-clean
#   delete single instance pod
#######################################################
.PHONY: simple-pod-clean
simple-pod-clean: 
> podman kube down kube/tomcat-single-pod.yaml
####################################################### 
# kind-cluster
#   create kubernetes test cluster using kind
#######################################################
.PHONY: kind-cluster
kind-cluster:
> KIND_EXPERIMENTAL_PROVIDER=podman systemd-run --scope --user --property=Delegate=yes kind create cluster --name orbeon-test
####################################################### 
# kube/.kind.kubeconfig
#   save kind kubeconfig to disk
#   KUBECONFIG should point to this
#   kind also saves to .kube/config (clobbers existing)
#######################################################
kube/.kind.kubeconfig:
> kind get kubeconfig --name orbeon-test > kube/.kind.kubeconfig
> $(info KIND_KUBE_CONFIG is $(KIND_KUBE_CONFIG))
> $(info KUBECONFIG is $(KUBECONFIG))
> $(info KUBECONFIG $(origin KUBECONFIG))
####################################################### 
# kind-load-image
#   copy local image into kind cluster
#   this has an implicit dependency on package
#   although it isn't necessary to rebuild the
#   container everytime
#######################################################
.PHONY: kind-load-image
kind-load-image:
> kind load docker-image localhost/orbeon-tomcat:test --name orbeon-test -v 10
####################################################### 
# kind-deploy
#######################################################
.PHONY: kind-deploy
kind-deploy: kind-load-image
> $(KUBECTL) create deployment orbeon-tomcat --image=localhost/orbeon-tomcat:test
####################################################### 
# kind-undeploy
#######################################################
.PHONY: kind-undeploy
kind-undeploy: 
> $(KUBECTL) delete deployment orbeon-tomcat
####################################################### 
# kube-pods
#######################################################
.PHONY: kube-pods
kube-pods: 
> $(KUBECTL) get pods
####################################################### 
# kube-logs
#######################################################
.PHONY: kube-logs
kube-logs: 
> $(KUBECTL) logs -f deployment/orbeon-tomcat
####################################################### 
# kind-delete
#######################################################
.PHONY: kind-delete
kind-delete:
> kind delete cluster --name orbeon-test
####################################################### 
# kind-clean
#######################################################
.PHONY: kind-clean
kind-clean: kind-delete
> @rm -f kube/.kind.kubeconfig
####################################################### 
# clean everything
#######################################################
.PHONY: clean
clean: clean-images staging-clean kind-clean
> @rm -f build/.build-container.almalinux
> @rm -f build/.build-container.fedora
> @rm -f build/.build-container.rocky
> @rm -f build/.build-container.ubuntu
> @rm -f build/.build-container.ubuntu
####################################################### 
# clean-images from local image cache
#######################################################
.PHONY: clean-images
clean-images:
> @podman rmi -i localhost/orbeon-build-almalinux
> @podman rmi -i localhost/orbeon-build-fedora
> @podman rmi -i localhost/orbeon-build-rocky
> @podman rmi -i localhost/orbeon-build-ubuntu
> @podman rmi -i localhost/orbeon-build