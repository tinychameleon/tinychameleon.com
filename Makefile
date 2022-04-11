# GNU Make Configuration
SHELL := /bin/sh
.SHELLFLAGS = -e -c
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

ifndef CLOUDFLARE_API_TOKEN
  CLOUDFLARE_API_TOKEN = $(error The CLOUDFLARE_API_TOKEN variable must be defined)
endif

ifndef CLOUDFLARE_ZONE_ID
  CLOUDFLARE_ZONE_ID = $(error The CLOUDFLARE_ZONE_ID variable must be defined)
endif


# Executable Variables
BREW_BIN ?= $(shell brew --prefix)/bin
AZ ?= $(BREW_BIN)/az
DIRENV ?= $(BREW_BIN)/direnv


# Recipe Variables
HUGO_VERSION ?= 0.91.2
HUGO_IMAGE ?= tc_hugo
CACHE_CONTROL := public, max-age=432000

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
	$(AZ) deployment group create -g "$(AZ_RESOURCE_GROUP)" -n "$(AZ_DEPLOYMENT_NAME)" \
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
	echo "Uploading $$(wc -l tmp/files_to_upload | cut -d' ' -f1) files:"
	sed -e 's/^/\t/' tmp/files_to_upload
	rm -r tmp/uploads
	mkdir tmp/uploads
	xargs -a tmp/files_to_upload -P1 -I{} cp --parents "public/{}" tmp/uploads
	$(AZ) storage blob upload-batch --account-name "$(AZ_STORAGE_ACCOUNT)" \
		--auth-mode login -d '$$web' -s tmp/uploads/public \
		--content-cache-control "$(CACHE_CONTROL)" \
		--overwrite
	echo "Deleting $$(wc -l tmp/files_to_delete | cut -d' ' -f1) files:"
	sed -e 's/^/\t/' tmp/files_to_delete
	xargs -a tmp/files_to_delete -P1 -I{} \
		$(AZ) storage blob delete -c '$$web' --account-name "$(AZ_STORAGE_ACCOUNT)" -n "{}" \
			--auth-mode login
	cp tmp/new_manifest $@
	echo
	echo 'Purging URLs from CloudFlare:'
	urls_to_purge
	do_cloudflare_purge
	echo
	echo "Done"

tmp/build: $(shell find content -type f -name '*.md') | tmp
	hugo
	touch $@
