# StealthAuction Makefile
# Convenient shortcuts for Foundry commands and project workflows

.PHONY: help install build test coverage format format-check clean lint deploy-anvil deploy-demo start-anvil stop-anvil logs

# Default target
help: ## Show this help message
	@echo "StealthAuction - Confidential Dutch Auctions on Uniswap v4"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Installation and Setup
install: ## Install all dependencies (pnpm + forge)
	@echo "📦 Installing Node.js dependencies..."
	pnpm install
	@echo "🔧 Installing Forge dependencies..."
	forge install
	@echo "✅ All dependencies installed!"

# Build Commands
build: ## Build all contracts
	@echo "🏗️  Building contracts..."
	forge build

build-clean: ## Clean and rebuild all contracts
	@echo "🧹 Cleaning build artifacts..."
	forge clean
	@echo "🏗️  Rebuilding contracts..."
	forge build

# Testing Commands
test: ## Run all tests with summary
	@echo "🧪 Running tests..."
	forge test --summary

test-verbose: ## Run tests with verbose output
	@echo "🧪 Running tests (verbose)..."
	forge test -vvv

test-gas: ## Run tests with gas reporting
	@echo "⛽ Running tests with gas reporting..."
	forge test --gas-report

test-specific: ## Run specific test file (usage: make test-specific FILE=StealthAuction)
	@echo "🧪 Running tests for $(FILE)..."
	forge test --match-contract $(FILE)Test -vv

# Coverage Analysis
coverage: ## Generate coverage report (resolves stack too deep)
	@echo "📊 Generating coverage report..."
	forge coverage --ir-minimum

coverage-html: ## Generate HTML coverage report
	@echo "📊 Generating HTML coverage report..."
	forge coverage --ir-minimum --report lcov && genhtml lcov.info -o coverage/

# Code Quality
format: ## Format all Solidity files
	@echo "✨ Formatting code..."
	forge fmt

format-check: ## Check if code is properly formatted
	@echo "🔍 Checking code formatting..."
	forge fmt --check

lint: ## Run linter on contracts
	@echo "🔍 Linting contracts..."
	forge build 2>&1 | grep -E "(Warning|Error)" || echo "✅ No linting issues found"

# Deployment Commands
start-anvil: ## Start local Anvil node
	@echo "🔥 Starting Anvil..."
	anvil --host 0.0.0.0 --port 8545 &
	@echo "⏳ Waiting for Anvil to start..."
	@sleep 3
	@echo "✅ Anvil started on http://localhost:8545"

stop-anvil: ## Stop local Anvil node
	@echo "⏹️  Stopping Anvil..."
	@pkill -f anvil || echo "Anvil was not running"

deploy-anvil: ## Deploy complete system to local Anvil
	@echo "🚀 Deploying to Anvil..."
	forge script script/Anvil.s.sol --fork-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

deploy-tokens: ## Deploy tokens only
	@echo "🪙 Deploying tokens..."
	forge script script/DeployTokens.s.sol --fork-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

deploy-hook: ## Deploy StealthAuction hook only
	@echo "🎣 Deploying StealthAuction hook..."
	forge script script/StealthAuction.s.sol --fork-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

deploy-demo: ## Run auction demo
	@echo "🎪 Running auction demo..."
	forge script script/AuctionDemo.s.sol --fork-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Development Workflow
dev: start-anvil deploy-anvil ## Start development environment (Anvil + deploy)
	@echo "🎉 Development environment ready!"
	@echo "🌐 Anvil: http://localhost:8545"
	@echo "📚 Run 'make logs' to see contract addresses"

full-deploy: start-anvil deploy-anvil deploy-demo ## Complete deployment with demo
	@echo "🎯 Full deployment complete!"

# Utility Commands
clean: ## Clean all build artifacts and cache
	@echo "🧹 Cleaning build artifacts..."
	forge clean
	@echo "🗑️  Removing coverage files..."
	rm -rf coverage/ lcov.info
	@echo "✅ Cleanup complete!"

logs: ## Show recent Anvil logs and deployed addresses
	@echo "📋 Recent deployment addresses:"
	@ls -la broadcast/*/31337/run-latest.json 2>/dev/null | head -5 || echo "No recent deployments found"

status: ## Show project status
	@echo "📊 StealthAuction Project Status"
	@echo "================================"
	@echo "📁 Contracts: $(shell find src -name "*.sol" | wc -l | tr -d ' ')"
	@echo "🧪 Tests: $(shell find test -name "*.t.sol" | wc -l | tr -d ' ')"
	@echo "📜 Scripts: $(shell find script -name "*.s.sol" | wc -l | tr -d ' ')"
	@echo ""
	@forge --version
	@pnpm --version

# CI/CD Commands  
ci-check: format-check build test coverage ## Run all CI checks locally
	@echo "✅ All CI checks passed!"

watch-test: ## Watch for changes and run tests
	@echo "👀 Watching for changes..."
	forge test --watch

# Advanced Commands
gas-snapshot: ## Create gas usage snapshot
	@echo "📸 Creating gas snapshot..."
	forge snapshot

trace-test: ## Run tests with execution traces
	@echo "🔍 Running tests with traces..."
	forge test --trace-min -vvv

debug-test: ## Run specific test with full debugging (usage: make debug-test TEST=testCreateAuction)
	@echo "🐛 Debugging test: $(TEST)"
	forge test --match-test $(TEST) -vvvv --trace-min

# Documentation
docs: ## Generate contract documentation
	@echo "📚 Generating documentation..."
	forge doc

# Network specific deployments (add your RPC URLs to foundry.toml)
deploy-sepolia: ## Deploy to Sepolia testnet
	@echo "🌐 Deploying to Sepolia..."
	forge script script/Anvil.s.sol --rpc-url sepolia --broadcast --verify

deploy-mainnet: ## Deploy to Ethereum mainnet (USE WITH EXTREME CAUTION)
	@echo "⚠️  MAINNET DEPLOYMENT - Are you sure? (Ctrl+C to cancel)"
	@sleep 5
	forge script script/Anvil.s.sol --rpc-url mainnet --broadcast --verify

# Default target points to help
.DEFAULT_GOAL := help
