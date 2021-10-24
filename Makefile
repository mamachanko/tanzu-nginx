VERSION=0.0.1
IMAGE_REPOSITORY=mamachanko

all: 0.0.1 0.0.2 package_repository

.PHONY: 0.0.1 0.0.2
0.0.1 0.0.2:
	ytt -f $@/config/ | kbld -f- --imgpkg-lock-output $@/.imgpkg/images.yml
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx:$@ \
	  --file $@

.PHONY: package_repository
package_repository:
	kbld -f package_repository/packages --imgpkg-lock-output package_repository/.imgpkg/images.yml
	imgpkg push \
	  --bundle ${IMAGE_REPOSITORY}/tanzu-nginx-repo:0.0.0 \
	  --file package_repository

.PHONY: repo-install
repo-install:
	tanzu package repository add nginx-repo \
	  --url ${IMAGE_REPOSITORY}/tanzu-nginx-repo:0.0.0

.PHONY: repo-uninstall
repo-uninstall:
	tanzu package repository delete nginx-repo --yes

.PHONY: package-install
package-install:
	tanzu package install nginx \
	  --package-name nginx.mamachanko.com \
	  --version ${VERSION} \
	  --values-file ${VERSION}-values.yml

.PHONY: package-uninstall
package-uninstall:
	tanzu package installed delete nginx --yes
