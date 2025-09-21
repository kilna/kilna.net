# Simple Hugo Makefile for contact-kilna
SHELL := /usr/bin/env bash
#PARAMS := --disableFastRender --logLevel debug --printPathWarnings --printUnusedTemplates
PARAMS := --disableFastRender --port $$SERVER_PORT

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

.PHONY: build tool-plugins server launch clean deploy dash help icons

build: tool-plugins
	hugo

tool-plugins:
	./scripts/tool-plugins.sh

server: kill-server
	hugo server $(PARAMS) | ./scripts/open-server.sh

kill-server:
	lsof -ti:$$SERVER_PORT | xargs kill -9 2>/dev/null || true

clean:
	rm -rf public

deploy: build
	git add -A
	git commit -m "Deploy: $(shell date +%Y-%m-%d\ %H:%M:%S)" --allow-empty
	git push | ./scripts/open-deploy.sh

preview: build
	wrangler pages deploy ./public --project-name=$$CLOUDFLARE_PAGES_PROJECT \
		| ./scripts/open-preview.sh

dash:
	./scripts/open-dash.sh

help:
	@echo "Available targets:"
	@echo "  build   - Build the site"
	@echo "  server  - Start development server"
	@echo "  launch  - Start server and auto-detect URL to open"
	@echo "  deploy  - Build and deploy via git push"
	@echo "  preview - Deploy to Cloudflare Pages preview and open in browser"
	@echo "  clean   - Remove generated files"
	@echo "  help    - Show this help message"
	@echo "  icons   - Download/refresh SVG icons from icons.yaml"

icons:
	./scripts/icons.sh
