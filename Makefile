BAZEL_FILES = $(shell find . -type f \( -iname '*.bazel' -or -iname '*.bzl' \))
PROTO_FOLDERS := $(filter-out ./external%, $(shell find ./proto -name '*.proto' -print0 | xargs -0 -n1 dirname | sort --unique))

.PHONY: all
all: proto-fmt build

.PHONY: deps
deps:
	go mod tidy
	go mod vendor

.PHONY: local-deps
local-deps:
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.46.2; \
	go install github.com/bazelbuild/buildtools/buildifier@5.1.0;

.PHONY: lint
lint:
	golangci-lint run ./cmd/... ./pkg/...

.PHONY: build
build:
	go build ./cmd/... ./pkg/...

.PHONY: test
test:
	go test ./cmd/... ./pkg/...

.PHONY: run-server
run-server:
	go run ./cmd/server

.PHONY: run-client
run-client:
	go run ./cmd/client

# Proto

.PHONY: proto
proto: remove-go
	for f in ${PROTO_FOLDERS}; do \
		protoc \
			--proto_path=./proto \
			--go_out=plugins=grpc:./proto \
			--go_opt=paths=source_relative \
			$$f/*.proto; \
	done

.PHONY: proto-fmt
proto-fmt:
	find . -name "*.proto" | xargs clang-format -i

.PHONY: proto-fmt-check
proto-fmt-check:
	test -z "$$(find . -name "*.proto" | xargs clang-format -i -output-replacements-xml | grep "<replacement ")"

.PHONY: remove-go
remove-go:
	find ./proto -name "*.pb.go" -type f -delete

# Docker

.PHONY: build-docker-images
build-docker-images:
	bazelisk build //cmd/server:image

.PHONY: push-docker-images
push-docker-images:
	cat ~/ghcr.txt | docker login ghcr.io -u $(GITHUB_TOKEN_USER) --password-stdin
	bazelisk run //cmd/server:image_push_github

# Others

.PHONY: clean
clean:
	rm -rf bazel-*
	rm -rf vendor
	bazelisk clean --expunge