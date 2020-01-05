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


## External target definitions

serve: deps
> bundle exec jekyll server --config _config/base.yml,_config/dev.yml
.PHONY: serve

deps: .tmp/dependencies_installed
.PHONY: deps

clean:
> rm -rf _site
.PHONY: clean


## Internal target definitions

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

.tmp/dependencies_installed: .tmp/bundler_installed Gemfile
> bundle install
> touch $@
