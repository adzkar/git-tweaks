# Git Chain Sync

A powerful Git tool for synchronizing multiple branches in sequence with build validation. This tool is designed to manage branch hierarchies where changes need to flow from one branch to another in a controlled manner.

## The Story: When You Need Chain Sync

You're working on a project with a clear branch hierarchy:

- `main` (production)
- `develop` (integration)
- `feature-a` (in development)
- `feature-b` (depends on feature-a)

When `main` gets updated (security patch, dependency update, etc.), you need to propagate those changes through all branches. The manual process is tedious and error-prone:

```bash
git checkout develop
git merge main
npm run build
git push origin develop
git checkout feature-a
git merge develop
npm run build
git push origin feature-a
# ... and so on
```

One failed build breaks the entire chain, and you might lose track of which branches have been updated. **Chain Sync automates this entire workflow** with validation and safety checks.

## Installation

1. Ensure the script is executable:

```bash
chmod +x ~/.git-tweaks/chain-sync/chain-sync.sh
```

2. Add the git alias to your `~/.gitconfig`:

```ini
[alias]
	chain-sync = !bash ~/.git-tweaks/chain-sync/chain-sync.sh
```

## Usage

### Basic Usage

```bash
git chain-sync branch-a branch-b branch-c branch-d
```

### Interactive Flow Example

```
$ git chain-sync branch-a branch-b branch-c branch-d

git chain-sync
----------------------------------------------------------------

branch chain:
  branch-a -> branch-b -> branch-c -> branch-d

build check:
  1. npm run build
  2. npm run lint && npm run build
  3. npm run test
  4. custom (enter your own)
  5. skip build check
  choice [1-5]: 2
  -> will run: npm run lint && npm run build

merge strategy:
  1. git merge   (merge commit, safer for shared branches)
  2. git rebase  (linear history, requires force-push)
  choice [1-2]: 1
  -> using: git merge

----------------------------------------------------------------
ready to sync 4 branches. this will push to remote.
continue? [y/N]: y
```

## Features

### Build Validation

Choose from predefined build commands or enter your own:

- `npm run build` - Basic build check
- `npm run lint && npm run build` - Lint + build
- `npm run test` - Run tests
- Custom command - Enter any shell command
- Skip build check - For when you're confident

### Merge Strategies

- **Git Merge**: Creates merge commits, safer for shared branches
- **Git Rebase**: Linear history, requires force-push (uses `--force-with-lease`)

### Push Options

- **Auto-push**: Automatically push each branch after successful sync
- **Local only**: Sync locally without pushing (use `git multiple-push` later)

### Safety Features

- Stops on first build failure with detailed error output
- Confirms before starting the sync process
- Shows progress through the branch chain
- Returns to original branch when complete

## Advanced Examples

### Feature Branch Workflow

```bash
# Sync from main through feature branches
git chain-sync main develop feature-auth feature-ui feature-api
```

### Release Preparation

```bash
# Prepare release branches from develop
git chain-sync develop release-1.0 release-1.1 release-2.0
```

### Hot Fix Propagation

```bash
# Propagate hot fixes through environment branches
git chain-sync hotfix/critical-bug staging production
```

## Error Handling

### Build Failures

If a build fails on any branch:

- The sync process stops immediately
- Shows the last 20 lines of build output
- Displays the failing branch name
- Exits with error code 1

### Merge Conflicts

- The script will stop on merge conflicts
- Resolve conflicts manually
- Run `git chain-sync` again with the same branches

### Network Issues

- If push fails due to network, branches remain synced locally
- Use `git multiple-push` to retry pushing later

## Best Practices

### When to Use Chain Sync

- **Regular maintenance**: Propagating dependency updates across branches
- **Release preparation**: Syncing release branches from develop
- **Hot fix deployment**: Moving critical fixes through environments
- **Feature integration**: Merging completed features up the hierarchy

### When NOT to Use Chain Sync

- **Independent features**: When branches don't have a clear hierarchy
- **Experimental branches**: When you want to keep branches isolated
- **Complex merges**: When manual conflict resolution is expected

### Recommended Workflow

1. Always start with the most stable branch (usually `main` or `develop`)
2. Use build validation to catch issues early
3. Choose merge strategy based on branch sharing:
   - Use `git merge` for shared/team branches
   - Use `git rebase` for personal feature branches
4. Enable auto-push for immediate deployment or skip for staging

## Troubleshooting

### Common Issues

**"Build failed on branch"**

- Check the build output shown in the error
- Fix the issue on the failing branch
- Run chain-sync again

**"Permission denied" error**

- Ensure script is executable: `chmod +x ~/.git-tweaks/chain-sync/chain-sync.sh`
- Check git alias in `~/.gitconfig`

**"Branch not found" error**

- Verify all branches exist locally and remotely
- Run `git fetch --all` to update remote references

### Getting Help

```bash
# Check if the script is working
git chain-sync --help  # Shows usage if no arguments provided
```

## Technical Details

### How It Works

1. **Validation**: Checks arguments and current Git state
2. **Configuration**: Interactive prompts for build, merge, and push options
3. **Root Branch**: Updates the first branch from remote
4. **Chain Processing**: Sequentially merges each branch into the next
5. **Build Validation**: Runs build checks after each merge (if enabled)
6. **Push**: Pushes successful branches (if auto-push enabled)
7. **Cleanup**: Returns to original branch

### Exit Codes

- `0`: Success
- `1`: Error (invalid arguments, build failure, merge conflict, etc.)

### Dependencies

- Git 2.0+
- Bash shell
- Standard Unix utilities (no external dependencies)

## Related Tools

- **[multiple-push](../multiple-push/)**: Push multiple branches after chain-sync
- **git rebase**: Alternative merge strategy for linear history
- **git merge**: Default merge strategy for shared branches
