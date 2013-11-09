#!/bin/bash
until /Applications/Telepath.app/Contents/MacOS/Telepath; do
    echo "Telepath crashed with exit code $?.  Respawning.." >&2
    sleep 1
done
