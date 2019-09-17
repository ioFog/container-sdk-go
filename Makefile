SHELL = /bin/bash
OS = $(shell uname -s | tr '[:upper:]' '[:lower:]')

# Build variables
VERSION ?= $(shell git tag | tail -1 | sed "s|v||g")-dev
COMMIT ?= $(shell git rev-parse HEAD 2>/dev/null)
BUILD_DATE ?= $(shell date +%FT%T%z)
PREFIX = github.com/eclipse-iofog/iofogctl/pkg/util
LDFLAGS += -X $(PREFIX).versionNumber=$(VERSION) -X $(PREFIX).commit=$(COMMIT) -X $(PREFIX).date=$(BUILD_DATE) -X $(PREFIX).platform=$(GOOS)/$(GOARCH)
REPORTS_DIR ?= reports
TEST_RESULTS ?= TEST-iofogctl.txt
TEST_REPORT ?= TEST-iofogctl.xml

# Go variables
export CGO_ENABLED ?= 0
export GOOS ?= $(OS)
export GOARCH ?= amd64
GOLANG_VERSION = 1.12
GOFILES_NOVENDOR = $(shell find . -type f -name '*.go' -not -path "./vendor/*" -not -path "./client/*")

.PHONY: all
all: dep test## Get deps and run tests

.PHONY: clean
clean: ## Clean the working area and the project
	rm -rf vendor/
	rm -rf $(REPORTS_DIR)

.PHONY: dep
dep: ## Install dependencies
	@dep ensure -v -vendor-only

.PHONY: fmt
fmt: ## Format the source
	@gofmt -s -w $(GOFILES_NOVENDOR)

.PHONY: test
test: ## Run unit tests
	mkdir -p $(REPORTS_DIR)
	rm -f $(REPORTS_DIR)/*
	set -o pipefail; go list ./... | xargs -n1 go test -ldflags "$(LDFLAGS)" -v -parallel 1 2>&1 | tee $(REPORTS_DIR)/$(TEST_RESULTS)
	cat $(REPORTS_DIR)/$(TEST_RESULTS) | go-junit-report -set-exit-code > $(REPORTS_DIR)/$(TEST_REPORT)

.PHONY: list
list: ## List all make targets
	@$(MAKE) -pRrn : -f $(MAKEFILE_LIST) 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | sort

.PHONY: help
.DEFAULT_GOAL := help
help: ## Get help output
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# Variable outputting/exporting rules
var-%: ; @echo $($*)
varexport-%: ; @echo $*=$($*)