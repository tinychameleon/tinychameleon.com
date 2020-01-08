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


## Executable parameters

RUBY_VERSION ?= 2.6.5
BUNDLER_VERSION ?= 2.0.2
JEKYLL ?= bundle exec jekyll
BREW_BIN ?= $(shell brew --prefix)/bin
AZ ?= $(BREW_BIN)/az
DIRENV ?= $(BREW_BIN)/direnv
JQ ?= $(BREW_BIN)/jq
RBENV ?= $(BREW_BIN)/rbenv


## Target parameters

MAX_AGE ?= 86400
CACHE_HEADERS := public,max-age=$(MAX_AGE)


## External target definitions

serve: deps
	$(JEKYLL) server --config _config/base.yml,_config/dev.yml
.PHONY: serve

deploy: deps infra build _tmp/site_published
.PHONY: publish

infra: deps _tmp/infra_deployed
.PHONY: infra

build: deps _tmp/production_build
.PHONY: build

deps: _tmp/dependencies_installed
.PHONY: deps

clean:
	rm -rf _site _tmp/production_build
.PHONY: clean


## Internal target definitions

_tmp:
	mkdir -p _tmp

_tmp/site_published: _tmp/production_build | _tmp
	$(AZ) storage blob sync -c '$$web' --account-name "$(AZ_STORAGE_ACCOUNT)" -s _site
	$(AZ) storage blob list -c '$$web' --account-name "$(AZ_STORAGE_ACCOUNT)" > _tmp/blobdata
	$(JQ) -rf cache.filter _tmp/blobdata | xargs -t -P4 -I% \
		$(AZ) storage blob update -c '$$web' --account-name "$(AZ_STORAGE_ACCOUNT)" -n '%' \
			--content-cache-control '$(CACHE_HEADERS)'
	touch $@

_tmp/production_build: $(shell find _posts -type f -name '*.md') | _tmp
	rm -rf _site
	JEKYLL_ENV=production $(JEKYLL) build --config _config/base.yml,_config/prod.yml
	touch $@

_tmp/infra_deployed: _tmp/az_resource_group _tmp/az_infra_json | _tmp
	touch $@

_tmp/az_resource_group: | _tmp
	$(AZ) group create -l westus2 -n "$(AZ_RESOURCE_GROUP)"
	touch $@

_tmp/az_infra_json: infra.json _tmp/myip | _tmp
	$(AZ) group deployment create -g "$(AZ_RESOURCE_GROUP)" -n "$(AZ_DEPLOYMENT_NAME)" \
		--template-file infra.json --parameters \
			cidr="$$(cat _tmp/myip)" \
			storageAccountName="$(AZ_STORAGE_ACCOUNT)"
	touch $@

_tmp/myip: | _tmp
	dig @resolver1.opendns.com ANY myip.opendns.com +short -4 > $@

$(AZ):
	brew install azure-cli

$(DIRENV):
	brew install direnv

$(JQ):
	brew install jq

$(RBENV):
	brew install rbenv

.ruby-version: $(RBENV)
	rbenv install -s $(RUBY_VERSION)
	rbenv local $(RUBY_VERSION)

_tmp/bundler_installed: .ruby-version | _tmp
	gem install bundler:$(BUNDLER_VERSION)
	touch $@

_tmp/dependencies_installed: Gemfile $(AZ) $(DIRENV) $(JQ) $(RBENV) _tmp/bundler_installed | _tmp
	bundle install
	touch $@
