DOCKER ?= docker
IMAGE_NAME ?= mcp-toolkit
CONTAINER_NAME ?= mcp-toolkit

.PHONY: build run stop clean

build:
	$(DOCKER) build -t $(IMAGE_NAME) .

run: build
	$(DOCKER) run --rm --name $(CONTAINER_NAME) -it $(IMAGE_NAME)

stop:
	-$(DOCKER) stop $(CONTAINER_NAME)

clean:
	-$(DOCKER) rm -f $(CONTAINER_NAME)
	-$(DOCKER) rmi -f $(IMAGE_NAME)
