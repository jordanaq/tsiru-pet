# tsiru-pet — the Zola source for tsiru.pet.
# Consumed by the cloud-server flake as a pinned input.

.PHONY: check conventions layout build serve og lint-css

check: ## Canonical gate — realize the derivation, then guard the conventions
	nix flake check
	$(MAKE) conventions
	$(MAKE) layout

conventions: ## Hero/CSS conventions guard (no drift, no page-level styling)
	./scripts/check-conventions.sh

layout: build ## Assert the shared header geometry matches on every page
	./scripts/check-layout.py

build: ## Build the site into ./public
	nix shell nixpkgs#zola -c zola build

serve: build ## Build, then serve ./public on http://127.0.0.1:8791
	python3 -m http.server 8791 --directory public --bind 127.0.0.1

og: ## Re-render static/og.png from og/card.html
	./scripts/make-og-card.sh

lint-css: ## Stylelint the stylesheet
	nix shell nixpkgs#stylelint -c stylelint "static/**/*.css"
