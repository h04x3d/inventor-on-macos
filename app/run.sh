#!/bin/bash
# Entry point used by the "Autodesk Inventor 2027" app (installed by scripts/50-make-app.sh).
#   run.sh launch [files...]       start Inventor (or open files in the running one)
#   run.sh url <adskidmgr://...>   sign-in callback from the browser
PORT="@INVMAC_HOME@/inventor-mac-port"
source "$PORT/mac-env.sh"
mkdir -p "$PORT/logs"
case "$1" in
  launch) shift; exec bash "$PORT/scripts/launch-inventor.sh" "$@" >>"$PORT/logs/app-launch.log" 2>&1 ;;
  url)    shift; exec bash "$PORT/scripts/adskidmgr-callback.sh" "$1" >>"$PORT/logs/app-url.log" 2>&1 ;;
  *)      echo "usage: $0 launch [files...] | url <adskidmgr://...>" >&2; exit 2 ;;
esac
