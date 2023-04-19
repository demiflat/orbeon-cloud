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
# notes:
#   - dependencies are to the sentinel file
#     to avoid doing extraneous work
#   - tested on fedora linux 38
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
KIND := $(shell which kind)
# KIND := $(shell type -P kind)
$(info using $(KIND))
####################################################### 
# utilities
####################################################### 
#include gmsl/gmsl
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
diagram: diagram/default.png diagram/build-container.png diagram/compile.png diagram/recompile.png diagram/publish.png diagram/tomcat.png diagram/kind-deploy.png diagram/kind-prepare-cluster.png
diagram/build-container.png:
> make -Bnd build-container | make2graph | dot -Tpng -o diagram/build-container.png
diagram/compile.png:
> make -Bnd compile | make2graph | dot -Tpng -o diagram/compile.png
diagram/recompile.png:
> make -Bnd recompile | make2graph | dot -Tpng -o diagram/recompile.png
diagram/tomcat.png:
> make -Bnd tomcat | make2graph | dot -Tpng -o diagram/tomcat.png
diagram/publish.png:
> make -Bnd publish | make2graph | dot -Tpng -o diagram/publish.png
diagram/kind-deploy.png:
> make -Bnd kind-deploy | make2graph | dot -Tpng -o diagram/kind-deploy.png
diagram/default.png:
> make -Bnd default | make2graph | dot -Tpng -o diagram/default.png
diagram/kind-prepare-cluster.png:
> make -Bnd kind-prepare-cluster | make2graph | dot -Tpng -o diagram/kind-prepare-cluster.png
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
> $(info $(WHITE)     recompile: $(BLUE)recompile orbeon during iterative development$(RESET))
> $(info $(WHITE)     staging: $(BLUE)prepare contents for deployment container in $(LIGHTPURPLE)package/staging/orbeon-exploded$(RESET))
> $(info $(WHITE)     staging-clean: $(BLUE)clean staging area$(RESET))
> $(info $(WHITE)     package: $(BLUE)make deployment container for tomcat$(RESET))
> $(info $(WHITE)     package-inspect: $(BLUE)inspect tomcat deployment container contents$(RESET))
> $(info $(WHITE)     tomcat: $(BLUE)start tomcat container; CTRL-C to quit$(RESET))
> $(info $(WHITE)     simple-pod: $(BLUE)start tomcat container as a pod$(RESET))
> $(info $(WHITE)     simple-pod-clean: $(BLUE)teardown simple tomcat pod$(RESET))
> $(info $(WHITE)     publish: $(BLUE)publish container image to "$$ORBEON_REGISTRY_PUSH_URL"$(RESET))
> $(info $(WHITE)     clean: $(BLUE)clean everything$(RESET))
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
build-container-all: build/.build-container-all
build/.build-container-all: build/.build-container.almalinux build/.build-container.almalinux.jdk17 build/.build-container.fedora build/.build-container.fedora.jdk17 build/.build-container.rocky build/.build-container.rocky.jdk17 build/.build-container.ubuntu build/.build-container.ubuntu.jdk17
####################################################### 
# build almalinux build-container
#######################################################
.PHONY: build-container-almalinux
build-container-almalinux: build/.build-container.almalinux
build/.build-container.almalinux:
> podman build -f build/CONTAINERFILE.almalinux -t build-container-almalinux
> @touch build/.build-container.almalinux
####################################################### 
# build almalinux jdk17 build-container
#######################################################
.PHONY: build-container-almalinux-jdk17
build-container-almalinux-jdk17: build/.build-container.almalinux.jdk17
build/.build-container.almalinux.jdk17:
> podman build -f build/CONTAINERFILE.almalinux.jdk17 -t build-container-almalinux-jdk17
> @touch build/.build-container.almalinux.jdk17
####################################################### 
# build fedora build-container
#######################################################
.PHONY: build-container.fedora
build-container-fedora: build/.build-container.fedora
build/.build-container.fedora:
> podman build -f build/CONTAINERFILE.fedora -t build-container.fedora
> @touch build/.build-container.fedora
####################################################### 
# build fedora jdk17 build-container
#######################################################
.PHONY: build-container.fedora-jdk17
build-container.fedora-jdk17: build/.build-container.fedora.jdk17
build/.build-container.fedora.jdk17:
> podman build -f build/CONTAINERFILE.fedora.jdk17 -t build-container.fedora-jdk17
> @touch build/.build-container.fedora.jdk17
####################################################### 
# build rocky build-container
#######################################################
.PHONY: build-container-rocky
build-container-rocky: build/.build-container.rocky
build/.build-container.rocky:
> podman build -f build/CONTAINERFILE.rocky -t build-container-rocky
> @touch build/.build-container.rocky
####################################################### 
# build rocky jdk17 build-container
#######################################################
.PHONY: build-container.rocky.jdk17
build-container-rocky-jdk17: build/.build-container.rocky.jdk17
build/.build-container.rocky.jdk17:
> podman build -f build/CONTAINERFILE.rocky.jdk17 -t build-container.rocky.jdk17
> @touch build/.build-container.rocky.jdk17
####################################################### 
# build ubuntu build-container
#######################################################
.PHONY: build-container-ubuntu
build-container-ubuntu: build/.build-container.ubuntu
build/.build-container.ubuntu:
> podman build -f build/CONTAINERFILE.ubuntu -t build-container-ubuntu
> @touch build/.build-container.ubuntu
####################################################### 
# build ubuntu jdk17 build-container
#######################################################
.PHONY: build-container-ubuntu-jdk17
build-container-ubuntu-jdk17: build/.build-container.ubuntu.jdk17
build/.build-container.ubuntu.jdk17:
> podman build -f build/CONTAINERFILE.ubuntu.jdk17 -t build-container-ubuntu-jdk17
> @touch build/.build-container.ubuntu.jdk17
####################################################### 
# tag build-container
#   choose canonical build container
#######################################################
.PHONY: build-container
build-container: build/.build-container
build/.build-container: build-container-almalinux-jdk17
> podman tag build-container-almalinux-jdk17 build-container
> @touch build/.build-container
####################################################### 
# build-container-inspect
#   inspect the build environment used for compilation
#######################################################
.PHONY: build-container-inspect
build-container-inspect: build-container package 
> podman run -it --rm --entrypoint /bin/bash build-container 
####################################################### 
# compile
#######################################################
.PHONY: compile
compile: build-container package/staging/.compile.complete
package/staging/.compile.complete:
> podman run -it --rm --volume ./orbeon-forms:/orbeon:z -eGITHUB_TOKEN=$(GH_TOKEN) build-container
> @touch package/staging/.compile.complete
####################################################### 
# recompile
#######################################################
.PHONY: recompile
recompile: remove-compile-sentinel compile
remove-compile-sentinel:
> @rm package/staging/.compile.complete
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
# tomcat
#   start the container as part of development
#######################################################
.PHONY: tomcat
tomcat: package
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
#######################################################
package/staging/orbeon: compile
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
#   uses default credentials
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
# kind-single-node
#   create kubernetes test cluster using kind
#######################################################
.PHONY: kind-single-node
kind-single-node: kube/.kind.single.node.created
kube/.kind.single.node.created:
> KIND_EXPERIMENTAL_PROVIDER=podman systemd-run --scope --user --property=Delegate=yes kind create cluster --name orbeon-test --config kube/kind-simple.yaml
#######################################################
# if you don't want kind to clobber $HOME/kube/config then use this line instead:
#> KIND_EXPERIMENTAL_PROVIDER=podman systemd-run --scope --user --property=Delegate=yes kind create cluster --name orbeon-test --config kube/kind-simple.yaml --kubeconfig $(KUBECONFIG)
> @touch kube/.kind.single.node.created
####################################################### 
# kind-cluster
#   create kubernetes test cluster using kind
#######################################################
.PHONY: kind-cluster
kind-cluster: kube/.kind.cluster.created
kube/.kind.cluster.created:
# > sudo KIND_EXPERIMENTAL_PROVIDER=podman systemd-run --scope --user --property=Delegate=yes $(KIND) create cluster --name orbeon-test-cluster --config kube/kind-cluster.yaml
> sudo $(KIND) create cluster --name orbeon-test-cluster --config kube/kind-cluster.yaml -kubeconfig $(KUBECONFIG)
> sudo chmod 666 $(KUBECONFIG)
> @touch kube/.kind.cluster.created
####################################################### 
# kind-kubeconfig
#   save kind kubeconfig to disk
#   KUBECONFIG should point to this
#   kind also saves to .kube/config (clobbers existing)
#######################################################
.PHONY: kind-kubeconfig
kind-kubeconfig: kube/.kind.kubeconfig
kube/.kind.kubeconfig:
> $(KIND) get kubeconfig --name orbeon-test > kube/.kind.kubeconfig
> @touch kube/.kind.kubeconfig
> $(info KUBECONFIG is $(KUBECONFIG))
####################################################### 
# kind-cluster-kubeconfig
#   save kind kubeconfig to disk
#   KUBECONFIG should point to this
#   kind also saves to .kube/config (clobbers existing)
#######################################################
.PHONY: kind-cluster-kubeconfig
kind-cluster-kubeconfig: kube/.kind.cluster.kubeconfig
kube/.kind.cluster.kubeconfig: kube/.kind.cluster.created
> sudo $(KIND) get kubeconfig --name orbeon-test-cluster > kube/.kind.cluster.kubeconfig
> sudo $(KIND) get kubeconfig --name orbeon-test-cluster > kube/.kind.kubeconfig
> $(info KUBECONFIG is $(KUBECONFIG))
####################################################### 
# kind-load-cluster-image
#   copy local image into kind cluster
#   this has an implicit dependency on package
#   although it isn't necessary to rebuild the
#   container everytime
#######################################################
.PHONY: kind-load-cluster-image
kind-load-cluster-image: kube/.kind.load.cluster.image
kube/.kind.load.cluster.image: kube/.kind.kubeconfig
> kind load docker-image localhost/orbeon-tomcat:test --name orbeon-test --verbosity 99
> @touch kube/.kind.load.cluster.image
####################################################### 
# kind-load-image
#   copy local image into kind cluster
#   this has an implicit dependency on package
#   although it isn't necessary to rebuild the
#   container everytime
#######################################################
.PHONY: kind-load-image
kind-load-image: kube/.kind.load.image
kube/.kind.load.image: kube/.kind.kubeconfig
> kind load docker-image localhost/orbeon-tomcat:test --name orbeon-test --verbosity 99
> @touch kube/.kind.load.image
####################################################### 
# kind-reload-image
#   copy local image into kind cluster
#######################################################
.PHONY: kind-reload-image
kind-reload-image: kube/.kind.kubeconfig kind-delete-image-sentinel kube/.kind.load.image
.PHONY: kind-delete-image-sentinel
kind-delete-image-sentinel:
> @rm kube/.kind.load.image
####################################################### 
# kind-deploy
#######################################################
.PHONY: kind-deploy
kind-deploy: kube/.kind.deploy.cluster
kube/.kind.deploy.single.node: kube/.kind.single.node.created kube/.kind.kubeconfig kube/.kind.load.image
> $(KUBECTL) create deployment orbeon-tomcat --image=localhost/orbeon-tomcat:test --port 8080
> @touch kube/.kind.deploy.single.node
####################################################### 
# kind-deploy-cluster
#######################################################
.PHONY: kind-deploy-cluster
kind-deploy-cluster: kube/.kind.deploy.cluster
kube/.kind.deploy.cluster: kube/.kind.cluster.created kube/.kind.cluster.kubeconfig kube/.kind.load.cluster.image
> $(KUBECTL) create deployment orbeon-tomcat --image=localhost/orbeon-tomcat:test --port 8080
> @touch kube/.kind.deploy.cluster
####################################################### 
# kind-expose-nodeport
#######################################################
.PHONY: kind-expose-nodeport
kind-expose-nodeport: kube/.kind.kubeconfig
> $(KUBECTL) expose deployment/orbeon-tomcat --type="NodePort" --port 8080
####################################################### 
# kind-port-forward
#######################################################
.PHONY: kind-port-forward
POD=$(shell kubectl get pods|grep orbeon|awk '{print $$1}')
kind-port-forward: kube/.kind.deploy.single.node kube/.kind.kubeconfig kube/.kind.load.image kube/.kind.deploy.single.node kind-expose-nodeport
> $(KUBECTL) port-forward $(POD) 8080:8080
####################################################### 
# kind-deploy-metallb
#######################################################
.PHONY: kind-deploy-metallb
kind-deploy-metallb: kube/.kind.kubeconfig kube/.kind-deploy-metallb
kube/.kind-deploy-metallb:
> $(KUBECTL) apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml 
> $(KUBECTL) wait --namespace metallb-system  --for=condition=ready pod --selector=app=metallb --timeout=90s
> @touch kube/.kind-deploy-metallb
####################################################### 
# kind-create-ip-pool
#######################################################
.PHONY: kind-create-ip-pool
kind-create-ip-pool: kube/.kind.kubeconfig
> $(KUBECTL) apply -f kube/kind-metallb.yaml
####################################################### 
# kind-expose-loadbalancer
#######################################################
.PHONY: kind-expose-loadbalancer
kind-expose-loadbalancer: kube/.kind.kubeconfig
> $(KUBECTL) expose deployment/orbeon-tomcat --type="LoadBalancer" --port 8080
#######################################################
# kind-prepare-cluster 
####################################################### 
.PHONY: kind-prepare-cluster 
kind-prepare-cluster: kube/.kind.cluster.created kube/.kind.load.cluster.image kube/.kind-deploy-metallb kind-create-ip-pool kube/.kind.deploy.cluster kube-info
####################################################### 
# kube-metallb-info
####################################################### 
.PHONY: kube-metallb-info
kube-metallb-info:
> kubectl get -A ipaddresspools.metallb.io -o wide
####################################################### 
# kind-undeploy
#######################################################
.PHONY: kind-undeploy
kind-undeploy: kube/.kind.kubeconfig
> $(KUBECTL) delete deployment orbeon-tomcat
####################################################### 
# kube-cluster-info
#######################################################
.PHONY: kube-cluster-info
kube-cluster-info: kube/.kind.kubeconfig 
> $(KUBECTL) cluster-info
####################################################### 
# kube-pods
#######################################################
.PHONY: kube-pods
kube-pods: kube/.kind.kubeconfig 
> $(KUBECTL) get pods
####################################################### 
# kube-logs
#######################################################
.PHONY: kube-logs
kube-logs: kube/.kind.kubeconfig
> $(KUBECTL) logs -f deployment/orbeon-tomcat
####################################################### 
# kube-info
#######################################################
.PHONY: kube-info
kube-info: kube/.kind.kubeconfig
> $(KUBECTL) get --all-namespaces all
####################################################### 
# kind-delete
#######################################################
.PHONY: kind-delete
kind-delete:
> kind delete cluster --name orbeon-test
> @rm -f kube/.kind.single.node.created
> @rm -f kube/.kind.load.image
> @rm -f kube/.kind.deploy.single.node
> @rm -f kube/.kind.kubeconfig
####################################################### 
# kind-cluster-delete
#######################################################
.PHONY: kind-cluster-delete
kind-cluster-delete:
> sudo $(KIND) delete cluster --name orbeon-test-cluster
> @rm -f kube/.kind.cluster.created
> @rm -f kube/.kind.load.image
> @rm -f kube/.kind.deploy.cluster
> @rm -f kube/.kind.kubeconfig
> @rm -f kube/.kind.cluster.kubeconfig
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
> @rm -f build/.build-container.almalinux.jdk17
> @rm -f build/.build-container.fedora.jdk17
> @rm -f build/.build-container.rocky.jdk17
> @rm -f build/.build-container.ubuntu.jdk17
> @rm -f build/.build-container
> @rm -f build/.build-container.all
> @rm -f kube/.kind.single.node.created
> @rm -f kube/.kind.cluster.created
> @rm -f kube/.kind.load.image
> @rm -f kube/.kind.deploy.single.node
> @rm -f kube/.kind.deploy.cluster
> @rm -f kube/.kind.kubeconfig
####################################################### 
# clean-images from local image cache
#######################################################
.PHONY: clean-images
clean-images:
> @podman rmi -i localhost/build-container-almalinux
> @podman rmi -i localhost/build-container-fedora
> @podman rmi -i localhost/build-container-rocky
> @podman rmi -i localhost/build-container-ubuntu
> @podman rmi -i localhost/build-container-almalinux-jdk17
> @podman rmi -i localhost/build-container-fedora-jdk17
> @podman rmi -i localhost/build-container-rocky-jdk17
> @podman rmi -i localhost/build-container-ubuntu-jdk17
> @podman rmi -i localhost/build-container
####################################################### 
# git-clean everything
#######################################################
.PHONY: git-clean
git-clean:
> git clean -xdf
#######################################################
# gitignore-update
#######################################################
.PHONY: gitignore-update
gitignore-update:
> @rm -f .gitignore;
> @grep touch Makefile|awk '{print $$3}'|grep -v touch > .gitignore
> @echo "package/staging/" >> .gitignore
