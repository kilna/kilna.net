# Simple Hugo Makefile for contact-kilna
SHELL := /usr/bin/env bash
SERVER_PORT := 4291

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

.PHONY: build server clean deploy help icons launch launch-auto prebuild

build:
	hugo

server: kill-server
	 hugo server --disableFastRender 

kill-server:
	lsof -ti:$(SERVER_PORT) | xargs kill -9 2>/dev/null || true

open-wait:
	@echo "Waiting for Hugo server to start..."
	@hugo server --disableFastRender --logLevel=error 2>&1 | \
	while IFS= read -r line; do \
		echo "$$line"; \
		if echo "$$line" | grep -q "Local:"; then \
			URL=$$(echo "$$line" | sed -n 's/.*Local: *\(http[^ ]*\).*/\1/p'); \
			echo "Opening $$URL"; \
			open "$$URL"; \
		fi; \
	done

open:
	open http://localhost:$(SERVER_PORT)

clean:
	rm -rf public

deploy: build
	@echo "Site built successfully. Ready for deployment to Cloudflare Pages."

help:
	@echo "Available targets:"
	@echo "  build      - Build the site"
	@echo "  server     - Start development server"
	@echo "  launch     - Start server and auto-detect URL to open"
	@echo "  prebuild   - Setup dependencies for Cloudflare Pages"
	@echo "  clean      - Remove generated files"
	@echo "  deploy     - Build site for deployment"
	@echo "  help       - Show this help message"
	@echo "  icons      - Download/refresh SVG icons from icons.yaml"

icons:
	./scripts/icons.sh -f

