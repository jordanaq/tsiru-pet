# tsiru-pet — the Zola source for tsiru.pet.
# Consumed by the cloud-server flake as a pinned input.

.PHONY: check build serve og

check: ## Realize the site derivation — the canonical gate (see flake.nix)
	nix flake check

build: ## Build the site into ./public
	nix shell nixpkgs#zola -c zola build

serve: build ## Build, then serve ./public on http://127.0.0.1:8791
	python3 -m http.server 8791 --directory public --bind 127.0.0.1

og: ## Re-render static/og.png from og/card.html
	./scripts/make-og-card.sh
