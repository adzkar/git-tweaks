# Git Scripts Collection

A collection of custom Git tools to streamline branch management and synchronization workflows. These scripts are designed to solve common Git workflow pain points, particularly when managing multiple branches in complex development scenarios.

## Tools Overview

| Tool                              | Description                                                     | Use Case                                                                      |
| --------------------------------- | --------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [chain-sync](./chain-sync/)       | Synchronize multiple branches in sequence with build validation | When you need to propagate changes across a branch hierarchy                  |
| [multiple-push](./multiple-push/) | Push multiple branches to remote with flexible options          | When you need to push several branches at once with different push strategies |

## Installation

1. Clone or download this repository to `~/.git-tweaks/`
2. Add the following aliases to your `~/.gitconfig`:

```ini
[alias]
	chain-sync = !bash ~/.git-tweaks/chain-sync/chain-sync.sh
	multiple-push = !bash ~/.git-tweaks/multiple-push/multiple-push.sh
```

3. Make the scripts executable:

```bash
chmod +x ~/.git-tweaks/chain-sync/chain-sync.sh
chmod +x ~/.git-tweaks/multiple-push/multiple-push.sh
```

## Quick Start

### Chain Sync Example

```bash
# Sync a branch hierarchy: main -> develop -> feature-a -> feature-b
git chain-sync main develop feature-a feature-b
```

### Multiple Push Example

```bash
# Push multiple branches to origin
git multiple-push origin main develop feature-a feature-b
```

## Features

- **Interactive prompts** for build checks and merge strategies
- **Build validation** with customizable commands
- **Flexible merge strategies** (merge vs rebase)
- **Safe force-push options** with `--force-with-lease`
- **Colorful output** for better readability
- **Error handling** with detailed feedback

## Requirements

- Git 2.0 or higher
- Bash shell
- Standard Unix utilities (no external dependencies)

## Contributing

Feel free to submit issues or pull requests to improve these scripts. When contributing:

1. Follow the existing code style and conventions
2. Test your changes thoroughly
3. Update documentation as needed

## License

This project is open source and available under the MIT License.
