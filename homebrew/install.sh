#!/bin/sh
#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

# Check for Homebrew
if test ! $(which brew)
then
  echo "  x You should probably install Homebrew first:"
  echo "    https://github.com/mxcl/homebrew/wiki/installation"
  exit
fi

define(){ IFS='\n' read -r -d '' ${1} || true; }
define RECIPES_TO_INSTALL <<-'EOF'
	cowsay
	git
	mtr
	tree
	task
	thefuck
	figlet
	fortune
	lolcat
	readline
	task
	watch
EOF
RECIPES_TO_INSTALL=$(echo $RECIPES_TO_INSTALL | tr '\n' ' ')

# Enable rbenv caching of downloads
mkdir -p ~/.rbenv/cache

# Install homebrew packages
brew install $RECIPES_TO_INSTALL

exit $?