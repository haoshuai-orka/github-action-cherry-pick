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

PR_BRANCH="auto-$INPUT_PR_BRANCH-$GITHUB_SHA"
MESSAGE=$(git log -1 $GITHUB_SHA | grep "AUTO" | wc -l)

if [[ $MESSAGE -gt 0 ]]; then
  echo "Autocommit, NO ACTION"
  exit 0
fi

PR_TITLE=$(git log -1 --format="%s" $GITHUB_SHA)

echo "111"
git_setup
echo "222"
git_cmd git remote update
echo "333"
git_cmd git fetch --all
echo "444"
git_cmd git checkout -b "${PR_BRANCH}" origin/"${INPUT_PR_BRANCH}"
echo "555"
git config --global --add safe.directory '*'
echo "666"
git_cmd git merge "${GITHUB_SHA}"
echo "777"
git_cmd git push -u origin "${PR_BRANCH}"
echo "888"
git_cmd hub pull-request -b "${INPUT_PR_BRANCH}" -h "${PR_BRANCH}" -l "${INPUT_PR_LABELS}" -a "${GITHUB_ACTOR}" -m "\"AUTO: ${PR_TITLE}\""
echo "999"
