#!/bin/bash
# based on thoughtbot's laptop script
# shamelessly adapted to my needs

install_log="$HOME/$0_$(date +"%Y_%m_%d").out"
bottles="$HOME/postmac/install_me"

casks=()
brews=()

timestamp() {
  date +'%H:%M:%S'
}

spit() {
  local format
  local ts
  ts=$(timestamp)
  format="%s %-25s %s\n"
  printf "$format" "$ts" "$1" "[ $2 ]" |tee -a "$install_log"
}

isBrew() {
  local item
  item=$(brew info "$1" 2>/dev/null | head -1 | cut -f1 -d ":")
 ! [ -z "$item" ]
}


isCask() {
  local item
  item=$(brew cask info "$1" 2>/dev/null | head -1 | cut -f1 -d ":")

 ! [ -z "$item" ]
}

bottles_installable() {
  for i in "${brews[@]}"; do
    if brew list -1 | grep -Fqx "$(brew_name "$i")"; then
      :
    else
      spit "Installing" "$i"
      brew install "$i"
    fi
  done

  for e in "${casks[@]}"; do
    if brew cask list -1 | grep -Fqx "$(brew_name "$e")"; then
      :
    else
      spit "Installing" "$e"
      brew cask install "$e"
    fi
  done
}

brew_name() {
  brew info "$1" 2>/dev/null | head -1 | cut -f1 -d ":"
}

brews_upgradeable() {
  for i in "${brews[@]}";do
    if ! brew outdated --quiet "$i" > /dev/null; then
      spit "Upgrading" "$i"
      brew upgrade "$i"
    else
      spit "Up to date" "$i"
    fi
  done

}


bottle_sort() {
  if isBrew "$1";then
    brews=("${brews[@]}" "$1")
  else
    if isCask "$1";then
      casks=("${casks[@]}" "$1")
    else
      spit "Package not found" "$1"
      return 1
    fi
  fi
}


brew_file() {
  local filename="$1"
  local name

  while read -r line
  do
    name="$line"
    bottle_sort "$name"
  done < "$filename"

}

printf "%s %s\n\n" "$0" "running from $(pwd) on $(uname -n)" |tee -a "$install_log"
brew_file "$bottles"
bottles_installable
brews_upgradeable

# rvm and latest ruby
if ! command -v rvm >/dev/null;then
  spit "Installing [ rvm ]"
  curl -sSL https://get.rvm.io | bash
  spit "Installing [ ruby latest ]"
  zsh -c 'rvm install ruby'
else
  spit "RVM installed " "$(which rvm)"
  ruby_installed=$(ruby -v | cut -f2 -d " " | awk -F 'p' '{print $1}')
  ruby_latest="$(curl -sSL http://ruby.thoughtbot.com/latest)"
  spit "Ruby installed" "$ruby_installed"
  spit "Ruby latest " "$ruby_latest"
fi


# zsh and theme
case "$SHELL" in
  */zsh)
    spit "Shell" "$(which zsh)"
    spit "Unchanged" "zsh theme"
    spit "Unchanged" "terminal theme"
    ;;
  *)
  if [ ! -d "$HOME/.oh-my-zsh/" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    # downloading and executing random code from the internet. Yay!
  fi
    chsh -s "$(which zsh)"
    mv "./assets/_clean.zsh-theme" "$HOME/.oh-my-zsh/themes"
    open "./assets/Flat.terminal"
    sleep 1
    defaults write /Users/"$USER"/Library/Preferences/com.apple.Terminal.plist "Default Window Settings" "Flat"
    defaults write /Users/"$USER"/Library/Preferences/com.apple.Terminal.plist "Startup Window Settings" "Flat"
    perl -pi.bkp -e 's/ZSH_THEME="robbyrussell"/ZSH_THEME="_clean"/' "$HOME/.zshrc"
    spit "Shell to" "$(which zsh)"
    ;;
esac
