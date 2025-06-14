it: download

.PHONY: dockerhub
dockerhub:
	@bash dockerhub/README.sh

download:
	docker buildx bake download --no-cache
	docker buildx bake verify --no-cache

build:
	@docker buildx bake build --print
