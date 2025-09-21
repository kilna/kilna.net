# Simple Hugo Makefile for contact-kilna
SHELL := /usr/bin/env bash
SERVER_PORT := 4291
#PARAMS := --disableFastRender --logLevel debug --printPathWarnings --printUnusedTemplates
PARAMS := --disableFastRender --port $(SERVER_PORT)

# Set HUGO_BASEURL for Cloudflare Pages deployment
ifeq ($(CF_PAGES),true)
ifeq ($(CF_PAGES_BRANCH),main)
export HUGO_BASEURL=https://kilna.net
else
export HUGO_BASEURL=https://$(CF_PAGES_BRANCH).kilna.net
endif
else
export HUGO_BASEURL=http://localhost:$(SERVER_PORT)
-include .env
endif

.PHONY: build tool-plugins server launch clean deploy cloudflare cloudflare-api help icons

build: tool-plugins
	hugo

tool-plugins:
	./scripts/tool-plugins.sh

server: kill-server
	hugo server $(PARAMS)

launch: kill-server
	hugo server $(PARAMS) | ./scripts/open-hugo-url.sh

kill-server:
	lsof -ti:$(SERVER_PORT) | xargs kill -9 2>/dev/null || true

clean:
	rm -rf public

deploy: build
	@echo "Site built successfully. Ready for deployment to Cloudflare Pages."
	git add -A
	git commit -m "Deploy: $(shell date +%Y-%m-%d\ %H:%M:%S)"
	git push

cloudflare:
	./scripts/cloudflare.sh

cloudflare-api:
	./scripts/cloudflare.sh api

help:
	@echo "Available targets:"
	@echo "  build      - Build the site"
	@echo "  server     - Start development server"
	@echo "  launch     - Start server and auto-detect URL to open"
	@echo "  prebuild   - Setup dependencies for Cloudflare Pages"
	@echo "  clean      - Remove generated files"
	@echo "  deploy     - Build site for deployment"
	@echo "  cloudflare - Open Cloudflare Pages deployment dashboard"
	@echo "  cloudflare-api - Find and open specific deployment via API (requires CLOUDFLARE_API_TOKEN)"
	@echo "  help       - Show this help message"
	@echo "  icons      - Download/refresh SVG icons from icons.yaml"

icons:
	./scripts/icons.sh
