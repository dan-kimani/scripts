#!/bin/bash

update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/hyper 0
update-alternatives --set x-terminal-emulator /usr/local/bin/hyper
