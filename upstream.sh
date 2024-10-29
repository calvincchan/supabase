UPSTREAM=upstream-master
CURRENT=master

# Update upstream
git checkout $UPSTREAM;
git fetch;
git pull;

# Merge upstream onto local develop, resolve common conflicts.
git checkout $CURRENT;
GIT_EDITOR=true git merge $UPSTREAM;
