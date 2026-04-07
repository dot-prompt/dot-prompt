# Elixir Hex Package Skill

## Purpose
Provides specialized knowledge and workflows for working with Elixir Hex packages, including package management, dependency resolution, and package development best practices.

## When to Use
Use this skill when:
- Installing or updating Elixir dependencies
- Publishing packages to Hex.pm
- Managing package versions and releases
- Troubleshooting dependency conflicts
- Working with mix.exs configuration
- Understanding package metadata and documentation

## Key Capabilities
- Hex package installation and management
- Dependency resolution and conflict handling
- Package publishing workflows
- Version management and semantic versioning
- Repository configuration and authentication
- Performance optimization for package management

## Available Tools
- mix hex.install - Install packages from Hex.pm
- mix hex.outdated - Check for outdated dependencies
- mix hex.publish - Publish packages to Hex.pm
- mix deps.get - Fetch dependencies
- mix deps.update - Update dependencies
- mix deps.clean - Clean dependencies

## Examples

### Installing a package
```elixir
mix hex.install ecto
```

### Publishing a package
```elixir
mix hex.publish
```

### Checking for outdated packages
```elixir
mix hex.outdated
```

## Best Practices
- Always run `mix deps.get` after adding new dependencies
- Use semantic versioning for package releases
- Test packages thoroughly before publishing
- Keep dependencies up to date with `mix hex.outdated`
- Use `mix deps.clean --unused` to remove unused dependencies
- Configure proper authentication for private repositories

## Common Issues
- Dependency conflicts: Use `mix deps.tree` to visualize conflicts
- Network issues: Check Hex.pm status and proxy settings
- Authentication problems: Verify API keys and repository access
- Version resolution: Use `mix hex.package` to inspect package versions

## Related Skills
- Mix workflow management
- Elixir development best practices
- Testing and quality assurance
- Documentation generation

## Learning Resources
- [Hex.pm documentation](https://hex.pm/docs)
- [Mix documentation](https://hexdocs.pm/mix/Mix.html)
- [Elixir package development guide](https://hexdocs.pm/elixir/package-development.html)