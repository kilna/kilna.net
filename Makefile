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

.PHONY: build server clean deploy help icons launch launch-auto

build:
	yq --help
	hugo

server:
	hugo server --disableFastRender

launch:
	@echo "Starting Hugo server and auto-detecting URL..."
	@hugo server --disableFastRender --logLevel=error 2>&1 | \
		while IFS= read -r line; do \
			echo "$$line"; \
			if echo "$$line" | grep -q "Local:"; then \
				URL=$$(echo "$$line" | sed -n 's/.*Local: *\(http[^ ]*\).*/\1/p'); \
				echo "Opening $$URL"; \
				open "$$URL"; \
			fi; \
		done

clean:
	rm -rf public

deploy: build
	@echo "Site built successfully. Ready for deployment to Cloudflare Pages."

help:
	@echo "Available targets:"
	@echo "  build      - Build the site"
	@echo "  server     - Start development server"
	@echo "  launch     - Start server on port 1313 and open browser"
	@echo "  launch-auto- Start server and auto-detect URL to open"
	@echo "  clean      - Remove generated files"
	@echo "  deploy     - Build site for deployment"
	@echo "  help       - Show this help message"
	@echo "  icons      - Download/refresh SVG icons from icons.yaml"

icons:
	./scripts/icons.sh -f
