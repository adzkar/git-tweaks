# Git Multiple Push

A flexible Git tool for pushing multiple branches to a remote repository with various push strategies and options. This tool simplifies the process of pushing several branches at once while providing safety features and detailed feedback.

## The Story: When You Need Multiple Push

You've just finished a complex feature development workflow:

1. You used `git chain-sync` to synchronize branches locally
2. Everything builds successfully and you're ready to deploy
3. But now you need to push 5 branches to the remote repository

The manual process is repetitive:

```bash
git push origin main
git push origin develop
git push origin feature-a
git push origin feature-b
git push origin feature-c
```

What if:

- One push fails due to network issues?
- Some branches need force-push while others don't?
- You need to set upstream tracking for new branches?
- You want to see which pushes succeeded and failed?

**Multiple Push handles all these scenarios** with a single command and comprehensive feedback.

## Installation

1. Ensure the script is executable:

```bash
chmod +x ~/.git-tweaks/multiple-push/multiple-push.sh
```

2. Add the git alias to your `~/.gitconfig`:

```ini
[alias]
	multiple-push = !bash ~/.git-tweaks/multiple-push/multiple-push.sh
```

## Usage

### Basic Usage

```bash
git multiple-push <remote> branch1 branch2 branch3 ...
```

### Interactive Flow Example

```
git multiple-push origin main develop feature-a feature-b
git multiple-push
----------------------------------------------------------------

remote:  origin
branches:
  · main
  · develop
  · feature-a
  · feature-b

push mode:
  1. normal push
  2. force push  (--force-with-lease, safe force)
  3. force push  (--force, destructive)
  choice [1-3]: 1
  -> using: normal push

set upstream (-u)?
  1. yes - set upstream tracking for each branch
  2. no  - push only, no tracking change
  choice [1-2]: 1
  -> will set upstream for each branch

----------------------------------------------------------------
ready to push 4 branch(es) to origin.
continue? [y/N]: y

  pushing main...                     [2.1s] 12.3 MB/s 100%
  pushing develop...                  [1.8s] 8.7 MB/s  100%
  pushing feature-a...                [0.9s] 4.2 MB/s  100%
  pushing feature-b...                [1.1s] 5.1 MB/s  100%

----------------------------------------------------------------
  pushed (4):
  · main -> origin/main
  · develop -> origin/develop
  · feature-a -> origin/feature-a
  · feature-b -> origin/feature-b
```

## Features

### Push Modes

- **Normal Push**: Standard `git push` (safe for non-diverged branches)
- **Force with Lease**: `git push --force-with-lease` (safe force, won't overwrite remote changes)
- **Force Push**: `git push --force` (destructive, overwrites remote changes)

### Upstream Options

- **Set Upstream**: Adds `-u` flag to establish tracking branches
- **No Upstream**: Push only, leaves tracking unchanged

### Comprehensive Feedback

- Real-time progress for each branch
- Success/failure summary
- Detailed error messages for failed pushes
- Helpful tips for common issues

## Advanced Examples

### After Chain Sync

```bash
# After running git chain-sync locally, push all branches
git multiple-push origin main develop feature-a feature-b
```

### New Branch Setup

```bash
# Push new branches and set upstream tracking
git multiple-push origin feature-x feature-y feature-z
# Choose option 1 for upstream tracking
```

### Force Push Scenario

```bash
# After rebasing branches, need to force-push
git multiple-push origin feature-a feature-b
# Choose option 2 for force-with-lease (safer)
```

### Multiple Remotes

```bash
# Push to different remotes
git multiple-push origin main develop
git multiple-push upstream main develop
git multiple-push fork feature-a feature-b
```

## Push Strategies

### When to Use Each Mode

**Normal Push (Option 1)**

- Branches haven't diverged from remote
- Standard workflow after regular commits
- Safest option for shared branches

**Force with Lease (Option 2)**

- After rebase operations
- After amending commits
- When you're sure remote hasn't changed
- **Recommended for most force-push scenarios**

**Force Push (Option 3)**

- When you need to overwrite remote changes
- Emergency situations
- **Use with caution - can lose remote work**

### Upstream Tracking

**Set Upstream (Option 1)**

- New branches that need tracking
- After branch creation/migration
- Enables `git pull` without specifying remote

**No Upstream (Option 2)**

- Existing branches with tracking
- Temporary pushes
- When you don't want to change tracking

## Error Handling

### Common Scenarios

**Network Timeout**

```
  pushing feature-a...                     [30s] Timeout
  pushing feature-b...                     [2.1s] 8.7 MB/s  100%

----------------------------------------------------------------
  pushed (1):
  · feature-b -> origin/feature-b

  failed (1):
  · feature-a

tip: if branches have diverged, re-run and choose force-with-lease.
```

**Branch Divergence**

```
  pushing feature-a...                     [0.5s] ! rejected
To github.com:user/repo.git
 ! [rejected] feature-a (non-fast-forward)
error: failed to push some refs to 'github.com:user/repo.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: and have been overwritten.
```

**Authentication Issues**

- Script will show authentication error messages
- Fix credentials and re-run
- Previously successful pushes won't be re-attempted

### Recovery Strategies

**Partial Failure Recovery**

```bash
# Re-run only failed branches
git multiple-push origin feature-a
# Choose force-with-lease if needed
```

**Network Issues**

```bash
# Wait for network recovery, then re-run
git multiple-push origin main develop feature-a feature-b
# Script will skip already-pushed branches
```

## Best Practices

### Workflow Integration

1. **Chain Sync First**: Use `git chain-sync` to prepare branches locally
2. **Validate**: Ensure all builds pass locally
3. **Multiple Push**: Use `git multiple-push` to push all branches
4. **Verify**: Check remote repository to confirm pushes

### Safety Guidelines

- Always use `force-with-lease` instead of `force` when possible
- Check branch status before force-pushing shared branches
- Use upstream tracking for new branches, skip for existing ones
- Review the push summary before confirming

### Team Collaboration

- Communicate before force-pushing shared branches
- Use descriptive commit messages to avoid confusion
- Consider using merge commits instead of rebasing for team branches

## Troubleshooting

### Common Issues

**"Permission denied" error**

- Ensure script is executable: `chmod +x ~/.git-tweaks/multiple-push/multiple-push.sh`
- Check git alias in `~/.gitconfig`

**"Authentication failed"**

- Check your Git credentials
- Verify SSH key or personal access token
- Test with `git fetch` first

**"Branch not found"**

- Verify branches exist locally: `git branch`
- Update remote references: `git fetch --all`
- Check branch names for typos

**"Push rejected"**

- Branch has diverged from remote
- Use force-with-lease if appropriate
- Pull latest changes first if needed

### Getting Help

```bash
# Check if the script is working
git multiple-push --help  # Shows usage if no arguments provided
```

## Technical Details

### How It Works

1. **Validation**: Checks arguments and remote accessibility
2. **Configuration**: Interactive prompts for push mode and upstream options
3. **Confirmation**: Shows summary and asks for confirmation
4. **Push Loop**: Processes each branch with selected options
5. **Summary**: Reports successes and failures with detailed feedback

### Exit Codes

- `0`: All pushes succeeded
- `1\*\*: One or more pushes failed

### Dependencies

- Git 2.0+
- Bash shell
- Standard Unix utilities (no external dependencies)

### Security Considerations

- Force push options require explicit confirmation
- Script shows exactly what commands will be executed
- Error messages are sanitized but informative

## Related Tools

- **[chain-sync](../chain-sync/)**: Prepare branches locally before pushing
- **git push**: Standard single-branch push
- **git push --force-with-lease**: Safe force-push for individual branches
- **git remote**: Manage remote repositories

## Examples Repository

For more examples and advanced usage patterns, consider these scenarios:

### Feature Branch Workflow

```bash
# Create and sync feature branches
git chain-sync main develop feature-auth feature-ui
# Push all branches with upstream tracking
git multiple-push origin main develop feature-auth feature-ui
```

### Release Management

```bash
# Sync release branches
git chain-sync develop release-1.0 release-1.1
# Push with normal mode (no force needed)
git multiple-push origin develop release-1.0 release-1.1
```

### Emergency Hot Fix

```bash
# After emergency fix on main
git chain-sync main hotfix/critical-bug
# Force push hotfix branch
git multiple-push origin main hotfix/critical-bug
# Choose force-with-lease for safety
```
