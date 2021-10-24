[![Build & push](https://github.com/mamachanko/tanzu-nginx/actions/workflows/build.yml/badge.svg)](https://github.com/mamachanko/tanzu-nginx/actions/workflows/build.yml)

# tanzu-nginx

> A demo Tanzu Nginx package

## Prerequisites

Make sure you have the following available:

* [ ] [kapp](https://carvel.dev/kapp/) (alternatively `kubectl`)
* [ ] [tanzu CLI](https://github.com/vmware-tanzu/tanzu-framework) will all core plugins installed
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
tanzu imagepullsecret add dockerhub \
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

## Versions

There are two versions available.

Version `0.0.1` allows to configure replicas and a startup delay:

```shell
tanzu package available get nginx.mamachanko.com/0.0.1 --values-schema
| Retrieving package details for nginx.mamachanko.com/0.0.1...
  KEY       DEFAULT  TYPE  DESCRIPTION
  delay     3        int   The number of seconds to delay startup by.
  replicas  2        int   The number of Nginx replicas to spin up.
```

Version `0.0.2` adds configurable HTML content:

```shell
tanzu package available get nginx.mamachanko.com/0.0.2 --values-schema
| Retrieving package details for nginx.mamachanko.com/0.0.2...
  KEY       DEFAULT        TYPE    DESCRIPTION
  replicas  2              int     The number of Nginx replicas to spin up.
  delay     3              int     The number of seconds to delay startup by.
  html      Hello, there!  string  The HTML content that will be returned at "/".
```

## Installation

```shell
tanzu package install nginx \
  --package-name nginx.mamachanko.com \
  --version 0.0.1 \
  --values-file 0.0.1-values.yml
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
