#!/bin/zsh

unalias wtc wtco wti wtrm 2>/dev/null

_wth_open() {
  local repo=$1 label=$2
  shift 2
  wt switch --no-cd --execute herdr "$@" -- \
    worktree open --cwd "$repo" --path '{{ worktree_path }}' \
    --label "$label" --focus
}

wtc() {
  emulate -L zsh
  (( $# == 1 )) || { print -u2 'usage: wtc <branch>'; return 2; }
  [[ ${HERDR_ENV:-} == 1 ]] || { print -u2 'wtc must run inside Herdr'; return 1; }

  local repo
  repo=$(git rev-parse --show-toplevel) || return
  _wth_open "$repo" '{{ branch }}' --create "$1"
}

wtco() {
  emulate -L zsh
  (( $# == 1 )) || { print -u2 'usage: wtco <branch|pr:number|pr-url>'; return 2; }
  [[ ${HERDR_ENV:-} == 1 ]] || { print -u2 'wtco must run inside Herdr'; return 1; }

  local repo
  repo=$(git rev-parse --show-toplevel) || return
  _wth_open "$repo" '{{ branch }}' "$1"
}

wti() {
  emulate -L zsh
  (( $# == 1 )) || {
    print -u2 'usage: wti <number|repo#number|owner/repo#number|issue-url>'
    return 2
  }
  [[ ${HERDR_ENV:-} == 1 ]] || { print -u2 'wti must run inside Herdr'; return 1; }

  local issue=$1 issue_repo current_repo current_url host owner
  local -a issue_repo_args
  if [[ $issue == *'#'* ]]; then
    issue_repo=${issue%#*}
    issue=${issue##*#}
    [[ -n $issue_repo && $issue == <-> ]] || {
      print -u2 'wti: invalid issue reference'
      return 2
    }

    IFS=$'\t' read -r current_repo current_url < <(
      gh repo view --json nameWithOwner,url --jq '[.nameWithOwner, .url] | @tsv'
    ) || return
    host=${${current_url#*://}%%/*}
    owner=${current_repo%%/*}
    [[ $issue_repo == */* ]] || issue_repo="$owner/$issue_repo"
    issue_repo_args=(--repo "$host/$issue_repo")
  fi

  local number title issue_type slug prefix branch repo
  IFS=$'\t' read -r number title issue_type < <(
    gh issue view "$issue" "${issue_repo_args[@]}" \
      --json number,title,issueType \
      --jq '[.number, .title, (.issueType.name // "issue")] | @tsv'
  ) || return
  repo=$(git rev-parse --show-toplevel) || return

  slug=$(print -r -- "$title" | LC_ALL=C tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-')
  slug=${${${slug#-}%-}[1,48]}
  slug=${slug%-}
  prefix=$(print -r -- "$issue_type" | LC_ALL=C tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-')
  prefix=${${prefix#-}%-}
  branch="$prefix/$number${slug:+-$slug}"

  local -a create
  git show-ref --verify --quiet "refs/heads/$branch" ||
    git show-ref --verify --quiet "refs/remotes/origin/$branch" ||
    create=(--create)
  _wth_open "$repo" "#$number $title" "${create[@]}" "$branch"
}

wtrm() {
  emulate -L zsh
  (( $# == 0 )) || { print -u2 'usage: wtrm'; return 2; }
  [[ ${HERDR_ENV:-} == 1 && -n ${HERDR_WORKSPACE_ID:-} ]] || {
    print -u2 'wtrm must run inside Herdr'
    return 1
  }

  local workspace=$HERDR_WORKSPACE_ID main_workspace
  main_workspace=$(herdr workspace list | jq -r --arg id "$workspace" '
    .result.workspaces as $workspaces
    | ($workspaces[] | select(.workspace_id == $id).worktree.repo_key) as $repo
    | $workspaces[]
    | select(.worktree.repo_key == $repo and (.worktree.is_linked_worktree | not))
    | .workspace_id
  ') || return
  [[ -n $main_workspace ]] || {
    print -u2 'wtrm: main Herdr space not found'
    return 1
  }

  wt remove --force-delete --foreground || return
  herdr workspace focus "$main_workspace" || return
  herdr workspace close "$workspace"
}

alias wtc='noglob wtc'
alias wtco='noglob wtco'
alias wti='noglob wti'
