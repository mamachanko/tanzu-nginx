all: package package_repository

.PHONY: package
package:
	ytt -f package/config/ | kbld -f- --imgpkg-lock-output package/.imgpkg/images.yml
	imgpkg push --bundle "mamachanko/tanzu-nginx" --file package

.PHONY: package_repository
package_repository:
	kbld -f package_repository/packages --imgpkg-lock-output package_repository/.imgpkg/images.yml
	imgpkg push --bundle "mamachanko/tanzu-nginx-repo:0.0.0" --file package_repository
	imgpkg push --bundle "mamachanko/tanzu-nginx-repo:0.0.0-same" --file package_repository

.PHONY: repo-install
repo-install:
	tanzu package repository add nginx-repo --url "mamachanko/tanzu-nginx-repo:0.0.0" 

.PHONY: repo-uninstall
repo-uninstall:
	tanzu package repository delete nginx-repo --yes

.PHONY: package-install
package-install:
	tanzu package install nginx --package-name nginx.mamachanko.com --version 0.0.1

.PHONY: package-uninstall
package-uninstall:
	tanzu package installed delete nginx --yes
