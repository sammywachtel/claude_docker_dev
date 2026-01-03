# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- **Diátaxis Documentation Framework** - Reorganized documentation into tutorials, how-to guides, reference, and explanation sections
  - Created `/docs/` directory with Diátaxis structure
  - Added [Getting Started Tutorial](docs/tutorials/getting-started.md) - Complete walkthrough for first-time users
  - Added [Command Reference](docs/reference/commands.md) - Comprehensive command documentation
  - Added [GitHub CLI How-To Guide](docs/how-to/setup-github-cli.md) - Step-by-step GitHub CLI setup
  - Added [Design Philosophy](docs/explanation/design-philosophy.md) - Architectural decisions and trade-offs
  - Added [Documentation Index](docs/README.md) - Navigation hub for all documentation

### Fixed
- **Documentation Drift Issues**:
  - Documented Playwright cache ownership fix (commit e4769be) in Troubleshooting section
  - Documented health check NVM sourcing behavior (commits 5b13cb7, d31a96f) in Troubleshooting section
  - Documented cache directory system with comprehensive ownership and volume management details
  - Reconciled conflicting GitHub token guidance (shell profile vs .env file) - now recommends shell profile approach consistently

### Changed
- **GitHub Token Setup** - Updated documentation to recommend shell profile approach over per-project `.env` files:
  - Better security (secrets out of repos)
  - Works across all docker_dev projects automatically
  - No need to update `.env` when tokens change
  - Alternative `.env` approach still documented for edge cases
- **README.md** - Added documentation navigation section pointing to new Diátaxis structure
- **Troubleshooting Section** - Expanded with three new comprehensive sections:
  - Playwright Browser Installation Issues
  - Health Check Failures (with NVM sourcing explanation)
  - Cache Directory Ownership Issues (with volume management details)

## Recent Code Changes (Previously Undocumented)

### [2024-12-31] - Cache and Health Check Fixes
- `e4769be` - fix: fix cache directory ownership before Playwright install
- `d31a96f` - fix: use build-time nvm path in health check
- `5b13cb7` - fix: update docker-compose health check to source nvm

### [2024-12-30] - Token Management
- `c00eb27` - docs: recommend GH_TOKEN in shell profile instead of .env

### [2024-12-29] - Health Check Improvements
- `5a0ec57` - fix: health check now sources nvm to find node

---

## Documentation Coverage Status

✅ **Up to date**: Documentation now matches codebase state as of 2025-01-03
✅ **Organized**: Follows Diátaxis framework for better discoverability
✅ **Comprehensive**: Recent code changes fully documented
✅ **Consistent**: GitHub token guidance aligned across all files

## Next Steps

Potential future documentation improvements:
- [ ] Create more how-to guides (SSH keys setup, adding packages, etc.)
- [ ] Add reference docs for configuration options, environment variables, ports
- [ ] Create explanation docs for security model, volume mounting, cache management
- [ ] Extract SSH_CONFIG_GUIDE.md content into Diátaxis structure
