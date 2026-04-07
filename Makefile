.PHONY: test test-elixir test-go test-python test-ts test-integration build clean help status stop-server server

help:
	@echo "dot-prompt Local CI/CD"
	@echo "Usage:"
	@echo "  make test             - Run unit tests across all components"
	@echo "  make test-integration - Run integration tests against a live server"
	@echo "  make test-elixir      - Run Elixir compiler and server tests"
	@echo "  make test-go          - Run Go client and compiler tests"
	@echo "  make test-python      - Run Python client tests"
	@echo "  make test-ts          - Run TypeScript client tests"
	@echo "  make build            - Build all components locally"
	@echo "  make server           - Start Elixir server in background"
	@echo "  make stop-server      - Stop background Elixir server"
	@echo "  make status           - Check if server is running"
	@echo "  make publish-ts       - Publish TypeScript package to npm"
	@echo "  make publish-python   - Publish Python package to PyPI"
	@echo "  make publish-elixir   - Publish Elixir packages to Hex"
	@echo "  make publish-docker   - Build and push Docker images"
	@echo "  make publish-all      - Publish all packages and images"

test: test-elixir test-go test-python test-ts

test-integration: server
	@echo "Waiting for server to be ready (10s)..."
	@sleep 10
	@echo "Running TypeScript integration tests..."
	cd clients/typescript && DOT_PROMPT_URL=http://localhost:4000 npm run test:integration
	@echo "Running Python integration tests..."
	cd clients/python && . .venv/bin/activate && DOT_PROMPT_URL=http://localhost:4000 pytest tests/test_integration.py
	$(MAKE) stop-server

test-elixir:
	@echo "Running Elixir tests..."
	cd compilers/elixir && mix test
	cd server && mix test

test-go:
	@echo "Running Go tests..."
	cd compilers/go && go test ./...
	cd clients/go && go test ./...

test-python:
	@echo "Running Python tests..."
	cd clients/python && . .venv/bin/activate && pytest

test-ts:
	@echo "Running TypeScript tests..."
	cd clients/typescript && npm test

server: stop-server
	@echo "Starting server in background..."
	@cd server && nohup mix phx.server > server.log 2>&1 &
	@echo "Server starting, logs at server/server.log"

stop-server:
	@echo "Stopping server..."
	@lsof -t -i :4000 | xargs kill -9 2>/dev/null || true

status:
	@lsof -i :4000 || echo "Server is not running on port 4000"

publish-ts:
	@echo "Publishing TypeScript package..."
	cd tools/scripts && ./publish-ts.sh

publish-python:
	@echo "Publishing Python package..."
	cd tools/scripts && ./publish-python.sh

publish-elixir:
	@echo "Publishing Elixir packages..."
	cd compilers/elixir && mix hex.publish
	cd server && mix hex.publish

publish-docker:
	@echo "Building and pushing Docker images..."
	cd tools/scripts && ./build-and-push.sh

publish-all: publish-ts publish-python publish-elixir publish-docker

build:
	@echo "Building components..."
	cd clients/typescript && npm run build
	cd clients/python && . .venv/bin/activate && python3 -m build
	docker build -t dot-prompt:latest .
