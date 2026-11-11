# The targets the pipeline runs. They need the Crossplane CLI, Docker and yq.
PACKAGE := _output/${{ values.name }}.xpkg

.PHONY: all test build clean

all: test build

test: ## Render the composition for every test input, validate and check the result
	bash tests/render.sh

build: ## Build the configuration package
	mkdir -p _output
	crossplane xpkg build --package-root=package --examples-root=examples --package-file=$(PACKAGE)

clean:
	rm -rf _output
