it: dockerhub
.PHONY: dockerhub
dockerhub:
	@bash dockerhub/README.sh
build:
	@docker buildx bake dev --load
