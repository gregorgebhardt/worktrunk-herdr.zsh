# worktrunk-herdr.zsh

Zsh commands for opening [Worktrunk](https://worktrunk.dev) worktrees as
[Herdr](https://herdr.dev) spaces.

Requires `zsh`, `git`, `wt`, `herdr`, `jq`, and `gh` for `wti`.

## Install

With Antidote:

```zsh
gregorgebhardt/worktrunk-herdr.zsh
```

Or source `worktrunk-herdr.plugin.zsh` directly.

## Commands

```zsh
wtc feat/new-branch       # Create a branch and worktree
wtco existing-branch     # Open an existing branch
wtco pr:123              # Open a pull request
wti 123                  # Create a worktree for an issue
wti project#123          # Issue in another repo in the same org
wti org/project#123      # Issue in another org on the same host
wtrm                     # Remove worktree and branch, then close the space
```

Run these commands inside Herdr. `wtrm` protects dirty worktrees but deletes
the local branch even when it has not been merged.
