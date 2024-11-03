APP_NAME ?= tutorials

.PHONY: docs-build-image
docs-build-image:
	docker build -f _build/Dockerfile --progress plain -t app/mkdocs-$(APP_NAME) .

.PHONY: docs-build
docs-build:
	@docker run --rm -p 3487:3487 -v "$(PWD):/usr/src/source" --name $(APP_NAME)-serve app/mkdocs-$(APP_NAME) build

.PHONY: docs-serve
docs-serve:
	docker run --rm -p 3487:3487 -v "$(PWD):/usr/src/source" --name $(APP_NAME)-serve app/mkdocs-$(APP_NAME) serve

.PHONY: docs-enter
docs-enter:
	docker exec -it $(APP_NAME)-serve bash
