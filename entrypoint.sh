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

git_setup
echo "aaa"
git_cmd git remote update
echo "bbb"
git_cmd git fetch --all

echo "111"
echo "$GITHUB_TOKEN"
echo "222"

git_cmd git clone "https://x-access-token:$GITHUB_TOKEN@github.com/haoshuai-orka/temp_algo.git" "$CLONE_DIR"
echo "333"

cd "$CLONE_DIR"

git_cmd git remote add src_repo "https://x-access-token:$GITHUB_TOKEN@github.com/haoshuai-orka/temp_fw.git"
git_cmd git remote update
git_cmd git checkout -b "$PR_BRANCH"

git_cmd git merge --allow-unrelated-histories src_repo/main
echo "666"
git_cmd git push -u origin "$PR_BRANCH"
git remote rm src_repo
git_cmd hub pull-request -b "main" -h "$PR_BRANCH" -l "${INPUT_PR_LABELS}" -a "${GITHUB_ACTOR}" -m "\"AUTO FW UPDATES: ${PR_TITLE}\""
