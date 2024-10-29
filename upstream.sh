UPSTREAM_DIR=../supabase-upstream

# Update upstream
pushd $UPSTREAM_DIR;
git checkout master;
git fetch;
git pull;

# Merge upstream onto local develop, resolve common conflicts.
popd;
git checkout upstream;
cp -R $UPSTREAM_DIR/docker/* ./docker;
git checkout master;
GIT_EDITOR=true git merge master;
