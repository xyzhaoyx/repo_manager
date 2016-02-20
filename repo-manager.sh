#!/bin/bash

# Initialize variables/config
CONFIG_FILE=~/.repo-manager.conf
touch $CONFIG_FILE
declare -A config
FILE_NAME=${0//\.\//}
APP_NAME=${FILE_NAME%%[^a-zA-Z\-]*}

# If no bash, install one immediately (if that's even possible)
if [ ! $BASH_VERSION ]
then
  echo "You do not have bash installed. To use $APP_NAME, you must have bash 4 installed"
  read -p "Would you like me to install bash 4.3.30 for you? If you answer no, too bad, you can't use this script [Yy/Nn]"
  if [[ $REPLY =~ ^[Yy] ]]
  then
    BASH_DOWNLOAD_FILE="bash-4.3.30"
    curl -L "http://gnu.mirror.vexxhost.com/bash/$BASH_DOWNLOAD_FILE.tar.gz" | tar xz
    pushd "./$BASH_DOWNLOAD_FILE"
    sh ./configure --prefix=/usr/local --silent && make install
    popd
    BASH_LOCATION=/usr/local/bin/bash
    if [ ! $(cat /etc/shells | grep "$BASH_LOCATION") ]
    then
      echo "It appears that you $BASH_LOCATION is not in the list of permitted shells"
      echo "Please enter your password so we can add $BASH_LOCATION"
      sudo echo "$BASH_LOCATION" >> /etc/shells
      echo "Added $BASH_LOCATION to list of permitted shells"
    fi
    chsh -s "$BASH_LOCATION"
    $BASH_LOCATION
    exit 0
  fi
fi

# Stuff to add:
# mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez

start() {
  echo "Would you like to combine all scripts into one or have them separated by name?"
  options=(combined "separate (recommended)" cancel)
  PS3="#? "
  select choice in "${options[@]}"
  do
    case "$choice" in
      combined)
        startAllLogs
        break
        ;;

      "separate (recommended)")
        startSeparateLogs
        break
        ;;

      cancel)
        break
        ;;

      *)
        printUsage "select"
        ;;
    esac
  done
  # OR
}

logs() {
  tail -f "$HOME/Developer/repo-manager/all.log" "$HOME/Developer/repo-manager/error.log" # "$HOME/Developer/repo-manager/chevron-zeus.log" "$HOME/Developer/repo-manager/chevron-zeus-error.log" "$HOME/Developer/repo-manager/chevron-server.log" "$HOME/Developer/repo-manager/chevron-server-error.log" "$HOME/Developer/repo-manager/vaderboats.log" "$HOME/Developer/repo-manager/vaderboats-error.log" "$HOME/Developer/repo-manager/factors-zeus.log" "$HOME/Developer/repo-manager/factors-zeus-error.log" "$HOME/Developer/repo-manager/factors-server.log" "$HOME/Developer/repo-manager/factors-server-error.log" "$HOME/Developer/repo-manager/factors-ernicorn.log" "$HOME/Developer/repo-manager/factors-ernicorn-error.log" "$HOME/Developer/repo-manager/holonet.log" "$HOME/Developer/repo-manager/holonet-error.log"
}

prepare() {
  procdog start chevron-prepare --dir="$HOME/Developer/chevron" --command="bundle install && rake db:migrate" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  procdog start vaderboats-prepare --dir="$HOME/Developer/Vaderboats" --command="nvm install && npm install" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  procdog start factors-prepare --dir="$HOME/Developer/factors" --command="bundle install" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  procdog start holonet --dir="$HOME/Developer/holonet" --command="mix deps.get && mix deps.compile && mix ecto.create && mix ecto.migrate" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
}

stop() {
  procdog stop chevron-zeus
  procdog stop chevron-server
  procdog stop vaderboats
  procdog stop factors-zeus
  procdog stop factors-server
  procdog stop factors-ernicorn
  procdog stop holonet
  echo "Stopped all apps"
}

force() {
  for pid in $(pgrep rubies)
  do kill -9 "$pid"
  done
  for pid in $(pgrep gulp)
  do kill -9 "$pid"
  done
  for pid in $(pgrep beam)
  do kill -9 "$pid"
  done
  echo "Forced quit all ruby, gulp, elixir"
}

checkout() {
  normalCheckout
  OR
  isolateCheckout
}

clean() {
  removeIsolateArtifacts
  echo "Cleaned all isolate artifacts"
}

setup() {
  # RVM
  taggedPrint "INSTALL" "Checking if bundle is installed..."
  if type -p rvm > /dev/null
  then
    taggedPrint "INSTALL" "Installing rvm..."
    curl -L https://get.rvm.io | bash -s stable --auto-dotfiles --autolibs=enable --rails
    taggedPrint "INSTALL" "Finished installing rvm"
  else
    taggedPrint "INSTALL" "rvm already installed"
  fi
  taggedPrint "INSTALL" "Finished installing rvm"
  # Bundle/Gems
  taggedPrint "INSTALL" "Checking if bundle is installed..."
  if type -p bundle > /dev/null
  then
    taggedPrint "INSTALL" "Installing bundler..."
    gem install bundle
    taggedPrint "INSTALL" "Finished installing bundler"
  else
    taggedPrint "INSTALL" "Bundler already installed"
  fi
  taggedPrint "INSTALL" "Checking if zeus is installed"
  if type -p zeus > /dev/null
  then
    taggedPrint "INSTALL" "Installing zeus..."
    gem install zeus
    taggedPrint "INSTALL" "Finished installing zeus"
  else
    taggedPrint "INSTALL" "zeus already installed"
  fi
  # Brew (itself)
  taggedPrint "INSTALL" "Checking if zeus is installed"
  if type -p brew > /dev/null
  then
    taggedPrint "INSTALL" "Installing brew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    taggedPrint "INSTALL" "Finished installing brew"
  else
    taggedPrint "INSTALL" "brew already installed"
  fi
  # Get user to give oauth access to brew to avoid rate limiting from github
  read -p "Brew uses github API to find and install your favourite tools.
  To remove rate limiting, please go to https://github.com/settings/tokens/new?scopes=&description=Homebrew,
 click 'Generate Token' (don't change scopes), and then copy the token (clipboard icon) and paste it here: "
  echo "export HOMEBREW_GITHUB_API_TOKEN=$REPLY" >> ~/.bashrc
  echo "The token is added to homebrew! (via ~/.bashrc)"
  # Brew taps
  taggedPrint "INSTALL" "Adding brew taps..."
  # cask comes automatically now and versions is used to install previous versions of software
  for tap in "homebrew/versions"
  do
    taggedPrint "INSTALL" "Adding $tap tap"
    brew tap $tap
    taggedPrint "INSTALL" "Finished adding $tap tap"
  done
  taggedPrint "INSTALL"  "Finished adding brew taps"
  # Brews
  taggedPrint "INSTALL" "Installing brew packages..."
  for pkg in "bash" "hr" "elixir" "git" "postgresql" "elasticsearch" "python" "procdog"
  do
    if [ ! $(brew list $pkg) ]
    then
      taggedPrint "INSTALL" "Installing $pkg"
      brew install $pkg
      taggedPrint "INSTALL" "Finished installing $pkg"
    else
      taggedPrint "INSTALL" "$pkg already installed"
    fi
  done
  taggedPrint "INSTALL"  "Finished installing brew packages"
  # NVM/NPM
  taggedPrint "INSTALL"  "Checking if nvm is installed..."
  if type -p nvm > /dev/null
  then
    taggedPrint "INSTALL"  "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash
    taggedPrint "INSTALL"  "Finished installing nvm"
  else
    taggedPrint "INSTALL"  "nvm already installed"
  fi
  taggedPrint "INSTALL"  "Checking if npm is installed..."
  if type -p npm > /dev/null
  then
    taggedPrint "INSTALL"  "Installing npm..."
    curl -L https://www.npmjs.com/install.sh | sh
    taggedPrint "INSTALL"  "Finished installing npm"
  else
    taggedPrint "INSTALL"  "npm already installed"
  fi
}

quit() {
  echo "NOTE: quitting this app won't stop the running programs. Select stop to actually stop them"
  echo "Bye!"
  exit 0
}

# Helpers

startAllLogs() {
  procdog start chevron-zeus --dir="$HOME/Developer/chevron" --command="zeus start" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  procdog start chevron-server --dir="$HOME/Developer/chevron" --command="rails server" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  procdog start vaderboats --dir="$HOME/Developer/Vaderboats" --command="gulp" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  procdog start factors-zeus --dir="$HOME/Developer/factors" --command="zeus start" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  procdog start factors-server --dir="$HOME/Developer/factors" --command="rails server" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  procdog start factors-ernicorn --dir="$HOME/Developer/factors" --command="ernicorn" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  procdog start holonet --dir="$HOME/Developer/holonet" --command="mix phoenix.server" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  echo \
"The logs are as follows:
app:
  success | error"
  hr "-"
  echo \
"all:
  all.log | error.log"
}

startSeparateLogs() {
  procdog start chevron-zeus --dir="$HOME/Developer/chevron" --command="zeus start" --stdout="$HOME/Developer/repo-manager/chevron-zeus.log" --stderr="$HOME/Developer/repo-manager/chevron-zeus-error.log" --append
  procdog start chevron-server --dir="$HOME/Developer/chevron" --command="rails server" --stdout="$HOME/Developer/repo-manager/chevron-server.log" --stderr="$HOME/Developer/repo-manager/chevron-server-error.log" --append
  procdog start vaderboats --dir="$HOME/Developer/Vaderboats" --command="gulp" --stdout="$HOME/Developer/repo-manager/vaderboats.log" --stderr="$HOME/Developer/repo-manager/vaderboats-error.log" --append
  procdog start factors-zeus --dir="$HOME/Developer/factors" --command="zeus start" --stdout="$HOME/Developer/repo-manager/factors-zeus.log" --stderr="$HOME/Developer/repo-manager/factors-zeus-error.log" --append
  procdog start factors-server --dir="$HOME/Developer/factors" --command="rails server" --stdout="$HOME/Developer/repo-manager/factors-server.log" --stderr="$HOME/Developer/repo-manager/factors-server-error.log" --append
  procdog start factors-ernicorn --dir="$HOME/Developer/factors" --command="ernicorn" --stdout="$HOME/Developer/repo-manager/factors-ernicorn.log" --stderr="$HOME/Developer/repo-manager/factors-ernicorn-error.log" --append
  procdog start holonet --dir="$HOME/Developer/holonet" --command="mix phoenix.server" --stdout="$HOME/Developer/repo-manager/holonet.log" --stderr="$HOME/Developer/repo-manager/holonet-error.log" --append
  echo \
"The logs are as follows:
app:
  process | success | error"
  hr "-"
  echo \
"chevron:
  zeus start | chevron-zeus.log | chevron-zeus-error.log
  rails server | chevron-server.log | chevron-server-error.log
vaderboats:
  gulp | vaderboats-zeus.log | vaderboats-zeus-error.log
factors:
  zeus start | factors-zeus.log | factors-zeus-error.log
  rails server | factors-server.log | factors-server-error.log
  ernicorn | factors-ernicorn.log | factors-ernicorn-error.log
holonet:
  mix phoenix.server | holonet-zeus.log | holonet-zeus-error.log"
}

isolate() {
  isolateDatabase "$HOME/Developer/chevron"
  setupDatabase "$HOME/Developer/chevron"
}

isolateCheckout() {
  explainDatabaseConfig "$HOME/Developer/chevron"
}

isolateDatabase() {
  pushd "$1"
  psql -c "CREATE DATABASE isolate_"databaseBranchName
  popd
}

setupDatabase() {
  pushd "$1"
  procdog start chevron-setup --dir="$HOME/Developer/chevron" --command="bundle install && rake db:create db:migrate" --stdout="$HOME/Developer/repo-manager/all.log" --stderr="$HOME/Developer/repo-manager/error.log" --append
  popd
}

databaseBranchName() {
  branchName=$(git symbolic-ref -q HEAD | cut -b 12-)
  branchName=${branchName//-/_}
  branchName=${branchName//\//_}
  echo $branchName
}

explainDatabaseConfig() {
  echo "For $1"
  echo "In order to take advantage of isolation, you have to update your database.yml config.
  I can replace your file for you or you can do it yourself.
  Don't worry about replace affecting normal use; it defaults the database name to one that you can provide."
  presentDatabaseConfigChoices $1
}

presentDatabaseConfigChoices() {
  echo "Which would you like me to do?"
  options=(replace DIY)
  PS3="#? "
  select choice in "${options[@]}"
  do
    case "$choice" in
      replace)
        chooseReplaceDatabaseConfig $1
        break
        ;;
      DIY)
        chooseDIYDatabaseConfig $1
        break
        ;;
      *)
        printUsage "select"
        ;;
    esac
  done
}

chooseReplaceDatabaseConfig() {
  printPreviousDatabaseConfig $1
  overwriteDatabaseConfig $1
}

chooseDIYDatabaseConfig() {
  read -p "Edit config/database.yml. Would you like me to open it? [Yy/Nn] "
  if [[ $REPLY =~ ^[Yy] ]]
  then
    pushd $1
    open ./config/database.yml
    popd
  fi
  echo "Under 'development:', replace 'database: [DATABASE_NAME]' with the following:
  database: <%= ENV['ISOLATE_DEVELOPMENT_DATABASE'] || [DATABASE_NAME] %>
  Replace [DATABASE_NAME] with the original database name"
  echo "Next, under 'test:', replace 'database: [DATABASE_NAME]' with the following:
  database: <%= ENV['ISOLATE_TEST_DATABASE'] || [DATABASE_NAME] %>
  Replace [DATABASE_NAME] with the original test database name"
}

printPreviousDatabaseConfig() {
  pushd $1
  echo "This is your database.yml config for reference before we replace"
  cat ./config/database.yml
  popd
}

overwriteDatabaseConfig() {
  echo "Replacing config/database.yml..."
  pushd $1
  echo \
"development:
  host: localhost
  adapter: postgresql
  encoding: utf-8
  database: <%= ENV['ISOLATE_DEVELOPMENT_DATABASE'] || 'lendesk_development' %>

test:
  host: localhost
  adapter: postgresql
  encoding: utf-8
  database: <%= ENV['ISOLATE_TEST_DATABASE'] || 'lendesk_test' %>"\
  > ./config/database.yml
  popd
  echo "Successfully replaced!"
  echo "Remember to change 'lendesk_development' and 'lendesk_test' to what was there before"
}

removeIsolateArtifacts() {
  isolateDatabases=$(psql -l -t | grep isolate | cut -d "|" -f 1)
  for db in $isolateDatabases
  do psql -c "DROP DATABASE "$db
  done
}

# Utility

waitFor() {
  while [[ $(procdog status $1) != "exited"* && $(procdog status $1) != "stopped" ]]
  do sleep 0.5
  done
}

taggedPrint() {
  tag=$(echo $1 | tr '[:lower:]' '[:upper:]')
  echo "[$tag] ${*:2}"
}

printUsage() {
  if [[ $1 == "input" ]]
  then
    echo "Usage: $0 $(IFS='|'; echo "${options[*]}")"
    exit 1
  else
    array=()
    for i in "${!options[@]}"
    do
      number=$((i + 1))
      array+=($number)
    done
    echo "Choices are: $(IFS='|'; echo "${options[*]}")"
    echo "Enter $(IFS='|'; echo "${array[*]}")"
  fi
}

# Read
readConfig() {
  IFS="="
  while read -r key value
    do
      if [ $value ]
      then config[$key]=${value//\"/}
      fi
  done < $CONFIG_FILE
}

# Write
writeConfig() {
  declare -A config=( [username]=matrinox [host]=localhost [dev-folder]=~/Developer/ )
  echo > $CONFIG_FILE
  for key in "${!config[@]}"
  do
    value=${config[$key]}
    echo "$key=$value" >> $CONFIG_FILE
  done
}

# Main menu (choicess)

execChoice() {
  case "$1" in
    start)
      start
      break
      ;;

    logs)
      logs
      break
      ;;

    prepare)
      prepare
      break
      ;;

    stop)
      stop
      break
      ;;

    force)
      force
      break
      ;;

    checkout)
      checkout
      break
      ;;

    clean)
      clean
      break
      ;;

    setup)
      setup
      break
      ;;

    quit)
      quit
      ;;

    *)
      printUsage "$2"
      ;;
  esac
}

printChoices() {
  echo "You have several choices: start/stop all apps, prepare/clean the apps, check status/logs or force quit all apps, checkout features/branches, setup dependencies to run this program, or quit this program (this program will not quit until you select this option or force quit)"
  PS3="#? "
  select opt in "${options[@]}"
  do execChoice "$opt" "select"
  done
}

# Starting point of app, after defining everything above because bash can't read things properly

readConfig

if [ $1 ]
then
  options=(start stop prepare clean status logs force checkout setup quit)
  execChoice "$1" "input"
  exit 0
else
  while true
  do
    options=(start stop prepare clean status logs force checkout setup quit)
    printChoices
  done
fi
