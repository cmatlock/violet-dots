#!/bin/bash

DOTFILES_ROOT="`pwd`"

set -e

echo ''

info () {
  printf "  [ \033[00;34m..\033[0m ] $1"
}

user () {
  printf "\r  [ \033[0;33m?\033[0m ] $1 "
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

link_files () {
  ln -s $1 $2 && success "linked $1 to $2" || fail "linking $1 to $2"
}

setup_gitconfig () {
  if ! [ -f git/gitconfig.symlink ]
  then
    info 'setup gitconfig'

    user ' - What is your github author name?'
    read -e git_authorname
    user ' - What is your github author email?'
    read -e git_authoremail

    sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" git/gitconfig.symlink.example > git/gitconfig.symlink

    $? && success 'gitconfig' || fail 'gitconfig'
  fi
}

install_dotfiles () {
  info 'installing dotfiles\n'

  overwrite_all=false
  backup_all=false
  skip_all=false

  for source in `find $DOTFILES_ROOT -maxdepth 2 -name \*.symlink`
  do
    dest="$HOME/.`basename \"${source%.*}\"`"

    if [ -f $dest ] || [ -d $dest ] || [ -L $dest ]
    then

      overwrite=false
      backup=false
      skip=false

      if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
      then
        user "File already exists: `basename $source`, what do you want to do? [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;;
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            ;;
        esac
      fi

      if [ "$overwrite" == "true" ] || [ "$overwrite_all" == "true" ]
      then
        rm -rf $dest && success "removed $dest" || fail "removing $dest"
      fi

      if [ "$backup" == "true" ] || [ "$backup_all" == "true" ]
      then
        mv $dest $dest\.backup && success "moved $dest to $dest.backup" || fail "moving $dest to $dest.backup"
      fi

      if [ "$skip" == "false" ] && [ "$skip_all" == "false" ]
      then
        link_files $source $dest
      else
        success "skipped $source"
      fi

    else
      link_files $source $dest
    fi

  done
}

function install_homebrew () {
  info "installing xcode\n"

  XCODE="/usr/bin/xcode-select"
  if [ -e "$XCODE" ]; then
    success "xcode-select already installed"
  else
    xcode-select --install
  fi

  info "bootstrapping homebrew\n"

  BREW="/usr/local/bin/brew"
  if [ -e "$BREW" ]; then
    success "skipped homebrew install; already present"
  elif [ `command -v ruby` ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
      || fail "brew install failed"
    $BREW doctor || fail "The Doctor needs a bit of help..."
  else
    fail "can't find ruby"
  fi

  info "installing homebrew packages\n"
  $BREW update > /dev/null
  homebrew/install.sh >> $HOME/tmp/brew_package_install.log 2>&1 \
    || fail "installing brew packages"
  
  success "installed brew packages"

  MTR_PATH=$(which mtr)
  sudo chown root:wheel $MTR_PATH
  sudo chmod u+s $MTR_PATH
  success "mtr handled"
}

info 'creating directories\n'
for dirname in repositories bin tmp .config ; do
	if [[ ! -e ~/$dirname ]] ; then
		mkdir ~/$dirname && success "created ~/$dirname" || fail "could not create ~/$dirname"
	fi
done

install_dotfiles

if [ "$(uname -s)" == "Darwin" ]; then
  info 'configuring OS X; authentication may be required\n'
  # Ask for the administrator password upfront
  sudo -v
  # Keep-alive: update existing `sudo` time stamp until finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  # This may not work well as the set-defaults.sh script is doing the same thing

  $DOTFILES_ROOT/osx/set-defaults.sh

  install_homebrew

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \
      || fail "oh-my-zsh install failed"
  link_files "$DOTFILES_ROOT/zsh/themes/bullet-train.zsh-theme" "$HOME/.oh-my-zsh/themes/bullet-train.zsh-theme"
  # pip3 install powerline-status
  # brew tap homebrew/cask-fonts
  # brew cask install font-monofur-nerd-font-mono font-firacode-nerd-font


  success "Completed with OS X configuration"
fi
