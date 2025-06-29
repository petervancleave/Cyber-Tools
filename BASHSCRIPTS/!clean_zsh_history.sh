#!/bin/bash

cd ~

# backup
mv .zsh_history .zsh_history_corrupt

# extract readable strings to rebuild history
strings .zsh_history_corrupt > .zsh_history

fc -R .zsh_history

rm .zsh_history_corrupt

echo "Zsh history cleaned and reloaded."
