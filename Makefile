SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

VERSION=$(shell git describe --tags | sed 's/^v//')
GIT_SHA=$(shell git rev-parse --short @)

IMAGE_REPOSITORY := mamachanko
IMAGE_PACKAGE_NAME := tanzu-nginx
IMAGE_REPOSITORY_NAME := tanzu-nginx-repo

.PHONY: build
build: package-build repo-build

.PHONY: package-build
package-build:
	rm -rf build
	mkdir -p build
	cp -R package build/
	ytt --file package/ | kbld --file - --imgpkg-lock-output build/package/.imgpkg/images.yml
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:${GIT_SHA} \
	  --file build/package
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:${VERSION} \
	  --file build/package

.PHONY: repo-build
repo-build:
	rm -rf build/package_repository
	mkdir -p \
	  build/package_repository/.imgpkg \
	  build/package_repository/packages/nginx.mamachanko.com
	
	now_utc_iso8601="$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")"
	ytt \
	  --file package_repository/packages/nginx.mamachanko.com/version.yml \
	  --data-value version="${VERSION}" \
	  --data-value released_at=$$now_utc_iso8601 \
	  >"build/package_repository/packages/nginx.mamachanko.com/${VERSION}.yml"
	cp \
	  package_repository/packages/nginx.mamachanko.com/metadata.yml \
	  build/package_repository/packages/nginx.mamachanko.com/
	kbld \
	  --file build/package_repository/packages \
	  --imgpkg-lock-output build/package_repository/.imgpkg/images.yml
	echo "Built package_repository"
	
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx-repo:${GIT_SHA} \
	  --file build/package_repository
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx-repo:${VERSION} \
	  --file build/package_repository
	echo "Pushed build/package_repository"

.PHONY: release
release:
	npx \
	  --yes \
	  --package @semantic-release/exec \
	  --package semantic-release@18.0.0 \
	  -- \
	  semantic-release --no-ci $(SEMANTIC_RELEASE_EXTRA_FLAGS)

.PHONY: publish
publish: package-publish

.PHONY: package-publish
package-publish:
	imgpkg pull --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:$(GIT_SHA) --output publish
	imgpkg push --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:$(TO) --file publish
	rm -rf publish

.PHONY: repo-publish
repo-publish:
	imgpkg pull --bundle ${IMAGE_REPOSITORY}/tanzu-nginx-repo:$(GIT_SHA) --output publish
	imgpkg push --bundle ${IMAGE_REPOSITORY}/tanzu-nginx-repo:$(TO) --file publish
	rm -rf publish

.PHONY: reset
reset:
	git fetch
	gh release list | awk '{print $$1}' | xargs -n1 gh release delete --yes
	git tag -l | xargs -n 1 git push --delete origin
	git tag -l | xargs git tag -d

.PHONY: install
install: repo-install package-install

.PHONY: uninstall
uninstall: repo-uninstall package-uninstall

.PHONY: repo-install
repo-install: repo-build
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
