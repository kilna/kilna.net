# Simple Hugo Makefile for contact-kilna
SHELL := /usr/bin/env bash

# Set HUGO_BASEURL for Cloudflare Pages deployment
ifeq ($(CF_PAGES),true)
ifeq ($(CF_PAGES_BRANCH),main)
export HUGO_BASEURL=https://kilna.net
else
export HUGO_BASEURL=https://$(CF_PAGES_BRANCH).kilna.net
endif
else
-include .env
endif

.PHONY: build server clean deploy help icons install-yq

build:
	hugo

server:
	hugo server --disableFastRender

clean:
	rm -rf public

deploy: build
	@echo "Site built successfully. Ready for deployment to Cloudflare Pages."

help:
	@echo "Available targets:"
	@echo "  build  - Build the site"
	@echo "  server - Start development server"
	@echo "  clean  - Remove generated files"
	@echo "  deploy - Build site for deployment"
	@echo "  help   - Show this help message"
	@echo "  icons  - Download/refresh SVG icons from icons.yaml"

install-yq:
	@if ! command -v yq >/dev/null 2>&1; then \
		echo "Installing yq..."; \
		curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_darwin_amd64 -o /tmp/yq; \
		chmod +x /tmp/yq; \
		mkdir -p $$HOME/.local/bin; \
		mv /tmp/yq $$HOME/.local/bin/yq; \
		echo "yq installed to $$HOME/.local/bin/yq"; \
	fi

icons: install-yq
	PATH="$$HOME/.local/bin:$$PATH" ./scripts/icons.sh -f
