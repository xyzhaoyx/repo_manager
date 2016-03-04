Repo Manager
------------

## Description

Manages all repos, prepares environment, runs it in the background, and shows status/logs

## Use

```sh
bash ./repo-manager.sh
```

Use cases:

1. Checkout branches on all repos w/ exact name (and create one if none exists)
     
    ```bash
    ./repo-manager.sh checkout [branch-name] 2
    ```

## Contributing

Create a PR with a description of what it does and how it accomplishes it. Follow the style in the existing code or fallback to Google's shell style: https://google.github.io/styleguide/shell.xml

You can contribute in whatever language you feel most comfortable in, be it bash or ruby or python or any other scripting language (no compiled languages). Our primary target are Macs as this is for development purposes only. That frees us up in scope. It also means that we can assume that a target machine with El Capitan comes preloaded with bash 3 and ruby 1.9. See this list for languages its versions on Mountain Lion (10.8): http://superuser.com/questions/580687/what-scripting-programming-languages-are-default-on-mac-osx. El Capitan is 10.11 so it has at least those versions. Remember, repo-manager can always install new languages so these restrictions are only pre-setup phase.
