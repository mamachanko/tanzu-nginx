SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

VERSION := $(shell git describe --tags --dirty | sed 's/^v//')
GIT_SHA := $(shell git rev-parse --short @)

NEXT_VERSION ?= $(VERSION)

RELEASE_NOTES ?= No release notes
export RELEASE_NOTES

IMAGE_REPOSITORY := mamachanko
IMAGE_PACKAGE_NAME := tanzu-nginx
IMAGE_REPOSITORY_NAME := tanzu-nginx-repo

##
##@ Building
##

.PHONY: build
build: package repo

.PHONY: package
package: package-build package-push

.PHONY: repo
repo: repo-build repo-push

.PHONY: package-build
package-build:
	rm -rf build/package build/package.zip
	mkdir -p build
	cp -R package build/
	ytt --file package/ \
	  | kbld \
	    --file - \
	    --imgpkg-lock-output build/package/.imgpkg/images.yml
	zip -r build/package build/package

.PHONY: package-push
package-push:
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:${GIT_SHA} \
	  --file build/package

.PHONY: repo-build
repo-build:
	rm -rf build/package_repository build/package_repository.zip
	mkdir -p \
	  build/package_repository/.imgpkg \
	  build/package_repository/packages/nginx.mamachanko.com
	ytt \
	  --file package_repository/packages/nginx.mamachanko.com/version.yml \
	  --data-value version="$(VERSION)" \
	  --data-value package_tag="$(GIT_SHA)" \
	  --data-value released_at="$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")" \
	  --data-value release_notes="$$RELEASE_NOTES" \
	  >"build/package_repository/packages/nginx.mamachanko.com/$(VERSION).yml"
	cp \
	  package_repository/packages/nginx.mamachanko.com/metadata.yml \
	  build/package_repository/packages/nginx.mamachanko.com/
	kbld \
	  --file build/package_repository/packages \
	  --imgpkg-lock-output build/package_repository/.imgpkg/images.yml
	zip -r build/package_repository build/package_repository

.PHONY: repo-push
repo-push:
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx-repo:${GIT_SHA} \
	  --file build/package_repository
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx-repo:${VERSION} \
	  --file build/package_repository

##
##@ Release
##

release-verify:
	imgpkg tag resolve \
	  --image ${IMAGE_REPOSITORY}/tanzu-nginx:${GIT_SHA}

release-prepare:
	mkdir -p build/package
	imgpkg pull \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:$(GIT_SHA) \
	  --output build/package
	zip -r build/package build/package
	$(MAKE) -e repo-build VERSION=$(NEXT_VERSION)

.PHONY: release
release:
	npx \
	  --yes \
	  --package semantic-release@18.0.0 \
	  --package @semantic-release/exec@6.0.2 \
	  -- \
	  semantic-release --no-ci $(SEMANTIC_RELEASE_EXTRA_FLAGS)

.PHONY: release-publish
release-publish: package-publish repo-push

.PHONY: package-publish
package-publish:
	rm -rf build/publish/package
	mkdir -p build/publish/package
	imgpkg pull --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:$(GIT_SHA) --output build/publish/package
	imgpkg push --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:$(NEXT_VERSION) --file build/publish/package

.PHONY: release-list
release-list: ## List all releases
	@echo Get remote tags
	git fetch
	@echo List all tags
	git tag --list | cat
	@echo List all releases on GitHub
	gh release list
	@echo View the latest release on GitHub
	gh release view

.PHONY: release-reset
release-reset: ## (Danger zone) Delete all releases and tags
	@echo Get remote tags
	git fetch
	@echo Delete all release on GitHub
	gh release list | awk '{print $$1}' | xargs -n1 gh release delete --yes
	@echo Delete all remote tags
	git tag --list | xargs -n 1 git push --delete origin
	@echo Delete all local tags
	git tag --list | xargs git tag --delete

##
##@ Installation
##

.PHONY: install
install: repo-install package-install

.PHONY: uninstall
uninstall: repo-uninstall package-uninstall

.PHONY: repo-install
repo-install:
	tanzu package repository add nginx-repo \
	  --url ${IMAGE_REPOSITORY}/tanzu-nginx-repo:${VERSION}

.PHONY: repo-uninstall
repo-uninstall:
	tanzu package repository delete nginx-repo --yes

.PHONY: package-install
package-install:
	tanzu package install nginx \
	  --package-name nginx.mamachanko.com \
	  --version ${VERSION} \
	  --values-file sample-values.yml

.PHONY: package-uninstall
package-uninstall:
	tanzu package installed delete nginx --yes

.PHONY: secret-install
secret-install:
	@read -r -p 'Please, enter your index.docker.io username: ' DOCKERHUB_USERNAME && \
	read -r -s -p 'Please, enter your index.docker.io password: ' DOCKERHUB_PASSWORD && \
	tanzu secret registry add dockerhub \
	  --server index.docker.io \
	  --username $$DOCKERHUB_USERNAME \
	  --password $$DOCKERHUB_PASSWORD \
	  --export-to-all-namespaces \
	  --yes

.PHONY: secret-uninstall
secret-uninstall:
	tanzu secret registry delete dockerhub \
	  --yes
