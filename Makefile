## GNU Make operational configuration

MAKEFLAGS += --warn-undefined-variables --no-builtin-rules
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

.DELETE_ON_ERROR:
.ONESHELL:


## Required parameters

ifndef AZ_RESOURCE_GROUP
  AZ_RESOURCE_GROUP = $(error The AZ_RESOURCE_GROUP variable must be defined)
endif

ifndef AZ_STORAGE_ACCOUNT
  AZ_STORAGE_ACCOUNT = $(error The AZ_STORAGE_ACCOUNT variable must be defined)
endif

ifndef AZ_DEPLOYMENT_NAME
  AZ_DEPLOYMENT_NAME = $(error The AZ_DEPLOYMENT_NAME variable must be defined)
endif


## Target parameters

RUBY_VERSION ?= 2.6.5
BUNDLER_VERSION ?= 2.0.2
JEKYLL ?= bundle exec jekyll
MAX_AGE ?= 86400

CACHE_HEADERS := public,max-age=$(MAX_AGE)


## External target definitions

serve: deps
	$(JEKYLL) server --config _config/base.yml,_config/dev.yml
.PHONY: serve

publish: deps infra build .tmp/site_published
.PHONY: publish

infra: deps .tmp/infra_deployed
.PHONY: infra

build: deps .tmp/production_build
.PHONY: build

deps: .tmp/dependencies_installed
.PHONY: deps

clean:
	rm -rf _site .tmp/production_build
.PHONY: clean


## Internal target definitions

.tmp:
	mkdir -p .tmp

.tmp/site_published: .tmp/production_build | .tmp
	az storage blob sync -c '$$web' --account-name "$(AZ_STORAGE_ACCOUNT)" -s _site
	az storage blob list -c '$$web' --account-name "$(AZ_STORAGE_ACCOUNT)" > .tmp/blobdata
	jq -rf cache.filter .tmp/blobdata | xargs -t -P4 -I% \
		az storage blob update -c '$$web' --account-name "$(AZ_STORAGE_ACCOUNT)" -n '%' \
			--content-cache-control '$(CACHE_HEADERS)'
	touch $@

.tmp/production_build: $(shell find _posts -type f -name '*.md') | .tmp
	rm -rf _site
	JEKYLL_ENV=production $(JEKYLL) build --config _config/base.yml,_config/prod.yml
	touch $@

.tmp/infra_deployed: .tmp/az_resource_group .tmp/az_infra_json | .tmp
	touch $@

.tmp/az_resource_group: | .tmp
	az group create -l westus2 -n "$(AZ_RESOURCE_GROUP)"
	touch $@

.tmp/az_infra_json: infra.json .tmp/myip | .tmp
	az group deployment create -g "$(AZ_RESOURCE_GROUP)" -n "$(AZ_DEPLOYMENT_NAME)" \
		--template-file infra.json --parameters \
			cidr="$$(cat .tmp/myip)" \
			storageAccountName="$(AZ_STORAGE_ACCOUNT)"
	touch $@

.tmp/myip: | .tmp
	dig @resolver1.opendns.com ANY myip.opendns.com +short -4 > $@

/usr/local/bin/az:
	brew install azure-cli

/usr/local/bin/jq:
	brew install jq

/usr/local/bin/rbenv:
	brew install rbenv

.ruby-version: /usr/local/bin/rbenv
	rbenv install -s $(RUBY_VERSION)
	rbenv local $(RUBY_VERSION)

.tmp/bundler_installed: .ruby-version | .tmp
	gem install bundler:$(BUNDLER_VERSION)
	touch $@

.tmp/dependencies_installed: .tmp/bundler_installed /usr/local/bin/az /usr/local/bin/jq Gemfile | .tmp
	bundle install
	touch $@
