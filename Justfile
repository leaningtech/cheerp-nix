fetch-cheerp:
	npins --lock-file=npins/sources.json update cheerp-compiler cheerp-utils cheerp-musl cheerp-libs

fetch-nixpkgs:
	npins --lock-file=npins/sources.json update nixpkgs
	nix flake lock --update-input nixpkgs

update-cheerp: fetch-cheerp
	git add npins/sources.json
	git commit -m "updated cheerp repos"

update-nixpkgs: fetch-nixpkgs
	git add npins/sources.json flake.lock
	git commit -m "updated deps"

update: fetch-cheerp fetch-nixpkgs
	git add npins/sources.json flake.lock
	git commit -m "updated repos and nixpkgs"

build-all:
	rm -rf roots
	mkdir roots
	nom build -f . packages.test.cheerp packages.test.unit-tests packages.dev.cheerp packages.cheerp packages.cheerp-clangd --out-link roots/result
