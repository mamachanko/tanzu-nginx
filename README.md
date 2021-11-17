[![Build & push](https://github.com/mamachanko/tanzu-nginx/actions/workflows/build.yml/badge.svg)](https://github.com/mamachanko/tanzu-nginx/actions/workflows/build.yml)

# tanzu-nginx

> A demo Tanzu Nginx package

## Prerequisites

Make sure you have the following available:

* [ ] [kapp](https://carvel.dev/kapp/) (alternatively `kubectl`)
* [ ] [tanzu CLI](https://github.com/vmware-tanzu/tanzu-framework) (`>=0.8.0`) will all core plugins installed
* [ ] credentials for index.docker.io

## Prepare your cluster

Install `kapp-controller` and `secretgen-controller`:

```shell
kapp deploy \
  --app tanzu-components \
  --file https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml \
  --file https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/latest/download/release.yml 
```

## Provide registry credentials

In order to avoid index.docker.io's rate-limiting, we need to provide credentials:

```shell
tanzu secret registry add dockerhub \
  --server index.docker.io \
  --username <YOUR-DOCKER-HUB-USERNAME> \
  --password <YOUR-DOCKER-HUB-PASSWORD> \
  --export-to-all-namespaces
```

## Install the package repository

```shell
tanzu package repository add nginx-repo --url mamachanko/tanzu-nginx-repo:0.0.0
```
... or more conveniently
```shell
make repo-install
```

## Installation

```shell
tanzu package install nginx \
  --package-name nginx.mamachanko.com \
  --version <version> \
  --values-file sample-values.yml
```

## Cleanup

Uninstall the package with:
```shell
tanzu package installed delete nginx
```

Uninstall the package repository with:
```shell
tanzu package repository delete nginx-repo
```

Uninstall Tanzu components with:

```shell
kapp delete --app tanzu-components --yes
```
