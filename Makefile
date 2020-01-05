## GNU Make operational configuration

MAKEFLAGS += --warn-undefined-variables --no-builtin-rules
SHELL := bash
.RECIPEPREFIX := >
.SHELLFLAGS := -euc

.DELETE_ON_ERROR:
.ONESHELL:


## Target parameters

RUBY_VERSION ?= 2.6.5
BUNDLER_VERSION ?= 2.0.2
JEKYLL ?= bundle exec jekyll

DEPLOY_NAME = website-$(shell date +'%Y-%m-%dT%H-%M-%S')
STORAGE_ACCOUNT_PREFIX := website
RESOURCE_GROUP_PREFIX := tinychameleon-website

## External target definitions

serve: deps
> $(JEKYLL) server --config _config/base.yml,_config/dev.yml
.PHONY: serve

build: deps clean
> JEKYLL_ENV=production $(JEKYLL) build --config _config/base.yml,_config/prod.yml
.PHONY: build

infra: deps .tmp/az_resource_group .tmp/myip
> az group deployment create -g "tinychameleon-website" -n $(DEPLOY_NAME) \
	--template-file infra.json --parameters storagePrefix="$(STORAGE_ACCOUNT_PREFIX)" \
		cidr="$$(cat .tmp/myip)"
.PHONY: infra

deps: .tmp/dependencies_installed
.PHONY: deps

clean:
> rm -rf _site
.PHONY: clean


## Internal target definitions

.tmp/az_resource_group:
> hash_value="$$(dd bs=1 count=512 if=/dev/urandom 2>/dev/null | sha1sum | cut -f1 -d' ')"
> group_name="$(RESOURCE_GROUP_PREFIX)-$${hash_value:0:13}"
> az group create -l westus2 -n "$$group_name"
> echo "$$group_name" > $@

.tmp/myip:
> dig @resolver1.opendns.com ANY myip.opendns.com +short -4 > $@

.tmp:
> mkdir -p .tmp

.tmp/rbenv_installed: | .tmp
> brew install rbenv
> touch $@

.ruby-version: .tmp/rbenv_installed
> rbenv install -s $(RUBY_VERSION)
> rbenv local $(RUBY_VERSION)

.tmp/bundler_installed: .ruby-version
> gem install bundler:$(BUNDLER_VERSION)
> touch $@

/usr/local/bin/az:
> brew install azure-cli

.tmp/dependencies_installed: .tmp/bundler_installed /usr/local/bin/az Gemfile
> bundle install
> touch $@
