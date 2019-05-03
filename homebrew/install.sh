#!/bin/sh
#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.
# To uninstall all homebrew packages brew uninstall --force $(brew list)

# Check for Homebrew
echo "  Check for Homebrew"
if test ! $(which brew)
then
  echo "  x You should probably install Homebrew first:"
  echo "    https://github.com/mxcl/homebrew/wiki/installation"
  exit
fi

define(){ IFS='\n' read -r -d '' ${1} || true; }
echo "  Gathering recipes..."
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
	watch
EOF
RECIPES_TO_INSTALL=$(echo $RECIPES_TO_INSTALL | tr '\n' ' ')

# Enable rbenv caching of downloads
mkdir -p ~/.rbenv/cache

# Install homebrew packages
brew install $RECIPES_TO_INSTALL

exit $?