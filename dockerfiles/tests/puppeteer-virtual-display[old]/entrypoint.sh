#!/bin/sh
rm /tmp/.X99-lock || true

Xvfb :99 -ac -screen 0 600x800x16 -listen tcp &
x11vnc -shared -forever -noxdamage -display :99 -nopw -loop -xkb &

node index.js

kill -9 "$(pgrep -f "Xvfb" | awk '{print $2}')"
kill -9 "$(pgrep -f "x11vnc" | awk '{print $2}')"