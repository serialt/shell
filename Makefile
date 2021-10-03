#!/bin/bash
# ******************************************************
# Author       	:	serialt 
# Email        	:	serialt@qq.com
# Filename     	:   makefile
# Version      	:	v1.0
# Created Time 	:	2021-06-25 10:47
# Last modified	:	2021-06-25 10:47
# By Modified  	: 
# Description  	:       build go package
#  
# ******************************************************


# Go Parameters
include .env

PROJECT_NAME= go-pkg
APP_NAME=go-pkg

GOBASE=$(shell pwd)
GOBIN=$(GOBASE)/bin
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
PLATFORMS := linux darwin

GOFILES=$(wildcard *.go)

BRANCH := $(shell git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)
BUILD := $(shell git rev-parse --short HEAD)
BUILD_DIR:=$(GOBASE)/build
VERSION = $(BRANCH)-$(BUILD)

BuildTime:= $(shell date -u '+%Y-%m-%d %I:%M:%S%p')
GitHash:= $(shell git rev-parse HEAD)
GoVersion:= $(shell go version)

PKGFLAGS :="-X main.BuildStamp=$(BuildTime) -X main.GitHash=$(GitHash) -X main.GoVersion=$(GoVerion)"

BIN_NAME=$(PROJECT_NAME)-$(VERSION)

# go-pkg.v0.1.1-linux-amd64
# go-pkg







.PHONY: release
release: build-linux build-darwin build-win
	@echo "编译完成"
	ls $(BUILD_DIR)/$(PROJECT_NAME)*


all: test build

test: 
		$(GOTEST) -v ./...
install: 
		$(GOMOD) tidy
clean:
        $(GOCLEAN)
        rm -f $(BIN_DIR)/$(BINARY_NAME)
        rm -f $(BIN_DIR)/$(BINARY_UNIX)
serve:
		$(GOCMD) run .

.PHONY: build-linux
build-linux: install
		CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -ldflags $(PKGFLAGS)  -o  $(BUILD_DIR)/$(APP_NAME).$(VERSION)-linux-amd64 -v 
		CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $(GOBUILD) -ldflags $(PKGFLAGS)  -o  $(BUILD_DIR)/$(APP_NAME)-linux-arm64 -v 

.PHONY: build-mac
build-mac: install
		CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 $(GOBUILD) -ldflags $(PKGFLAGS)  -o  $(BUILD_DIR)/$(APP_NAME)-darwin-amd64 -v 
		CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 $(GOBUILD) -ldflags $(PKGFLAGS)  -o  $(BUILD_DIR)/$(APP_NAME)-darwin-arm64 -v 

.PHONY: build-win
build-win: install
		CGO_ENABLED=0 GOOS=windows GOARCH=amd64 $(GOBUILD) -ldflags $(PKGFLAGS)  -o  $(BUILD_DIR)/$(APP_NAME)-windows-amd64.exe -v 
		
















