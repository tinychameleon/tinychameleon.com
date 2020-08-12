# GNU Make Configuration
SHELL := /bin/sh
.ONESHELL:
.DELETE_ON_ERROR:
.DEFAULT_GOAL := server


# Required parameters
ifndef AZ_RESOURCE_GROUP
  AZ_RESOURCE_GROUP = $(error The AZ_RESOURCE_GROUP variable must be defined)
endif

ifndef AZ_STORAGE_ACCOUNT
  AZ_STORAGE_ACCOUNT = $(error The AZ_STORAGE_ACCOUNT variable must be defined)
endif

ifndef AZ_DEPLOYMENT_NAME
  AZ_DEPLOYMENT_NAME = $(error The AZ_DEPLOYMENT_NAME variable must be defined)
endif


# Executable Variables
BREW_BIN ?= $(shell brew --prefix)/bin
AZ ?= $(BREW_BIN)/az
DIRENV ?= $(BREW_BIN)/direnv


# Recipe Variables
HUGO_VERSION ?= 0.74.3
HUGO_IMAGE ?= tc_hugo

MAX_AGE ?= 86400
CACHE_HEADERS := public,max-age=$(MAX_AGE)


# External Recipes
.PHONY: deps
deps: tmp/dependencies_installed

.PHONY: server
server: deps 
	hugo server -DF --bind 0.0.0.0 -p 1313

.PHONY: deploy
deploy: deps clean tmp/site_published

.PHONY: infra
infra: deps tmp/infra_deployed

.PHONY: clean
clean:
	rm -rf public tmp/build


# Internal Recipes
tmp:
	mkdir $@

tmp/hugo_$(HUGO_VERSION):
	touch $@

tmp/$(HUGO_IMAGE): Dockerfile tmp/hugo_$(HUGO_VERSION) | tmp
	docker build --build-arg version=$(HUGO_VERSION) -t $(HUGO_IMAGE) .
	touch $@

$(AZ):
	brew install azure-cli

$(DIRENV):
	brew install direnv

tmp/dependencies_installed: tmp/$(HUGO_IMAGE) $(AZ) $(DIRENV) | tmp
	touch $@

tmp/infra_deployed: tmp/az_resource_group tmp/az_infra_json | tmp
	touch $@

tmp/az_resource_group: | tmp
	$(AZ) group create -l westus2 -n "$(AZ_RESOURCE_GROUP)"
	touch $@

tmp/az_infra_json: infra.json tmp/myip | tmp
	$(AZ) group deployment create -g "$(AZ_RESOURCE_GROUP)" -n "$(AZ_DEPLOYMENT_NAME)" \
		--template-file infra.json --parameters \
			cidr="$$(cat tmp/myip)" \
			storageAccountName="$(AZ_STORAGE_ACCOUNT)"
	touch $@

tmp/myip: | tmp
	dig @resolver1.opendns.com ANY myip.opendns.com +short -4 > $@
 
tmp/site_published: tmp/build | tmp
	generate_manifest > tmp/new_manifest
	comm -13 $@ tmp/new_manifest | awk '{ print $$1 }' > tmp/files_to_upload
	comm -23 $@ tmp/new_manifest | awk '{ print $$1 }' > tmp/old_files_changed
	comm -23 tmp/{old_files_changed,files_to_upload} > tmp/files_to_delete
	echo "Uploading $$(wc -l tmp/files_to_upload | cut -d' ' -f1) files..."
	xargs -a tmp/files_to_upload -P1 -I{} \
		$(AZ) storage blob upload -c '$$web' --account-name "$(AZ_STORAGE_ACCOUNT)" \
			-f "public/{}" -n "{}" --content-cache-control '$(CACHE_HEADERS)' \
			--auth-mode login --no-progress
	echo "Deleting $$(wc -l tmp/files_to_delete | cut -d' ' -f1) files..."
	xargs -a tmp/files_to_delete -P1 -I{} \
		$(AZ) storage blob delete -c '$$web' --account-name "$(AZ_STORAGE_ACCOUNT)" -n "{}" \
			--auth-mode login
	cp tmp/new_manifest $@
	echo "Done"

tmp/build: $(shell find content -type f -name '*.md') | tmp
	hugo
	touch $@
