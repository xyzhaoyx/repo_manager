#!/bin/bash

# Options
options=(start stop prepare clean status logs force checkout setup quit)

# Stuff to add:
# mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez

start() {
  echo "Would you like to combine all scripts into one or have them separated by name?"
  options=(combined separate)
  PS3="#? "
  select choice in "${options[@]}"
  do
    case "$choice" in
      combined)
        startAllLogs
        ;;

      separate)
        startSeparateLogs
        ;;

      *)
        printUsage "select" "${options[@]}"
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
    do
      kill -9 "$pid"
  done
  for pid in $(pgrep gulp)
    do
      kill -9 "$pid"
  done
  for pid in $(pgrep beam)
    do
      kill -9 "$pid"
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
  if type -p rvm > /dev/null
    then curl -L https://get.rvm.io | bash -s stable --auto-dotfiles --autolibs=enable --rails
  fi
  # Bundle/Gems
  echo "Checking if bundle is installed..."
  if type -p bundle > /dev/null
    then
      echo "Installing bundler..."
      gem install bundle
      echo "Finished installing bundler"
    else
      echo "Bundler already installed"
  fi
  if type -p zeus > /dev/null
    then gem install zeus
  fi
  # Brew (itself)
  if type -p brew > /dev/null
    then /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  # Get user to give oauth access to brew to avoid rate limiting from github
  read -p "Brew uses github API to find and install your favourite tools.
  To remove rate limiting, please go to https://github.com/settings/tokens/new?scopes=&description=Homebrew,
 click 'Generate Token' (don't change scopes), and then copy the token (clipboard icon) and paste it here: "
  echo "export HOMEBREW_GITHUB_API_TOKEN=$REPLY" >> ~/.bashrc
  echo "The token is added to homebrew! (via ~/.bashrc)"
  # Brew taps
  echo "Adding brew taps..."
  # cask comes automatically now and versions is used to install previous versions of software
  for tap in "homebrew/versions"
    do brew tap $tap
  done
  echo "Finished adding brew taps"
  # Brews
  echo "Installing brew packages..."
  for pkg in "hr" "elixir" "git" "postgresql" "elasticsearch" "python" "procdog"
    do
      if [ ! $(brew list $pkg) ]
        then brew install $pkg
      fi
  done
  echo "Finished installing brew packages"
  # NVM/NPM
  echo "Checking if nvm is installed..."
  if type -p nvm > /dev/null
    then
      echo "Installing nvm..."
      curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash
      echo "Finished installing nvm"
    else
      echo "nvm already installed"
  fi
  echo "Checking if npm is installed..."
  if type -p npm > /dev/null
    then
      echo "Installing npm..."
      curl -L https://www.npmjs.com/install.sh | sh
      echo "Finished installing npm"
    else
      echo "npm already installed"
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
        printUsage "select" "${options[@]}"
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
  echo "[$1] ${*:2}"
}

printUsage() {
  IFS=' ' read -r -a opts <<< "${*:2}"
  if [[ $1 == "input" ]]
    then
      echo "Usage: $0 $(IFS='|'; echo "${opts[*]}")"
      exit 1
    else
      array=()
      for i in "${!opts[@]}"
        do
          number=$((i + 1))
          array+=($number)
      done
      echo "Choices are: $(IFS='|'; echo "${opts[*]}")"
      echo "Enter $(IFS='|'; echo "${array[*]}")"
  fi
}

# Main menu (choicess)

execChoice() {
  case "$1" in
    start)
      start
      ;;

    logs)
      logs
      ;;

    prepare)
      prepare
      ;;

    stop)
      stop
      ;;

    force)
      force
      ;;

    checkout)
      checkout
      ;;

    clean)
      clean
      ;;

    setup)
      setup
      ;;

    quit)
      quit
      ;;

    *)
      printUsage "$2" "${options[@]}"
      ;;
  esac
}

if [ $1 ]
  then
    execChoice "$1" "input"
    exit 0
  else
    echo "You have several choices: start/stop all apps, prepare/clean the apps, check status/logs or force quit all apps, checkout features/branches, setup dependencies to run this program, or quit this program (this program will not quit until you select this option or force quit)"
    PS3="#? "
    select opt in "${options[@]}"
    do
      execChoice "$opt" "select"
    done
fi