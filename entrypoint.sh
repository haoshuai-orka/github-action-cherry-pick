#!/bin/sh -l

git_setup() {
  cat <<- EOF > $HOME/.netrc
		machine github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN
		machine api.github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN
EOF
  chmod 600 $HOME/.netrc
  git config --global user.email "$GITBOT_EMAIL"
  git config --global user.name "$GITHUB_ACTOR"
  git config --global --add safe.directory /github/workspace
}

git_cmd() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo $@
  else
    eval $@
  fi
}

PR_BRANCH="auto-$GITHUB_SHA"
MESSAGE=$(git log -1 $GITHUB_SHA | grep "AUTO" | wc -l)

if [[ $MESSAGE -gt 0 ]]; then
  echo "Autocommit, NO ACTION"
  exit 0
fi

PR_TITLE=$GITHUB_SHA
CLONE_DIR=$(mktemp -d)

#fetch src repo
git_setup
git_cmd git remote update
git_cmd git fetch --all

#merge src repo pr to dst repo
git_cmd git clone "https://x-access-token:$GITHUB_TOKEN@github.com/$DST_REPO_OWNER/$DST_REPO_NAME.git" "$CLONE_DIR"
cd "$CLONE_DIR"
git_cmd git remote add "$SRC_REPO_REMOTE_NAME" "https://x-access-token:$GITHUB_TOKEN@github.com/$SRC_REPO_OWNER/$SRC_REPO_NAME.git"
git_cmd git remote update
git_cmd git checkout -b "$PR_BRANCH"
git_cmd git merge --allow-unrelated-histories "$SRC_REPO_REMOTE_NAME/$SRC_REPO_PR_BRANCH"
git_cmd git push -u origin "$PR_BRANCH"

#create pr on dst repo
git remote rm "$SRC_REPO_REMOTE_NAME"
git_cmd hub pull-request -b "$DST_REPO_PR_BRANCH" -h "$PR_BRANCH" -l "${INPUT_PR_LABELS}" -a "${GITHUB_ACTOR}" -m "\"$DST_PR_TITLE_PREFIX: ${PR_TITLE}\""
