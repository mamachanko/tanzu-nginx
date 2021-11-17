SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

VERSION=0.0.1
IMAGE_REPOSITORY=mamachanko

##
##@ Building
##

build: package-build repo-build

.PHONY: package-build
package-build:
	ytt --file package/ | kbld --file - --imgpkg-lock-output package/.imgpkg/images.yml
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:${VERSION} \
	  --file package

.PHONY: repo-build
repo-build:
	scratch="$$(mktemp -d /tmp/tanzu-nginx.package_repository.${VERSION}.XXXXXX)"
	mkdir -p \
	  $${scratch}/.imgpkg \
	  $${scratch}/packages/nginx.mamachanko.com
	now_utc_iso8601="$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")"
	ytt \
	  --file package_repository/packages/nginx.mamachanko.com/version.yml \
	  --data-value version="${VERSION}" \
	  --data-value released_at=$$now_utc_iso8601 \
	  >"$$scratch/packages/nginx.mamachanko.com/${VERSION}.yml"
	cp \
	  package_repository/packages/nginx.mamachanko.com/metadata.yml \
	  $${scratch}/packages/nginx.mamachanko.com/
	kbld \
	  --file $${scratch}/packages \
	  --imgpkg-lock-output $${scratch}/.imgpkg/images.yml
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx-repo:${VERSION} \
	  --file $$scratch
	echo "Pushed $$scratch."

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

##
##@ Release engineering
##

# TODO .PHONY: release
release:
	@tag="v$$(gitversion | jq -r '.MajorMinorPatch')"
	@echo "Tagging with $$tag"
	git tag $$tag

bump-patch:
	echo bumping patch to

bump-minor:
	echo create next branch
	echo push next branch

bump-major:

some-change:
	echo $$RANDOM > afile
	git add afile
	git commit --message 'Changed a file'
