# mise quick reference

This package provides the global mise configuration at
`~/.config/mise/config.toml`.

```bash
# Install every tool declared in the active configuration
mise install

# Show active and installed tool versions
mise current
mise ls

# Check for and install compatible updates
mise outdated
mise upgrade

# Add or change a global tool version
mise use --global node@lts

# Run a command with a one-off tool version
mise exec node@22 -- node --version

# Locate an active executable or installation
mise which node
mise where node

# Diagnose mise and remove unused tool versions
mise doctor
mise prune
```

`mise upgrade --bump` updates tools beyond their current requested ranges and
rewrites the configuration. Review that diff before committing it.
