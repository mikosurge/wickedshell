# 32 Fixing grep
#!/bin/bash

# cgrep--grep with context display and highlighted pattern matches
. ../01_the_missing_code_library/initializeANSI.sh

# initializeANSI
context=0
# esc="^["
esc="$(printf '\033')"  # If this doesn't work, enter an ESC directly.
boldon="${esc}[41m"
boldoff="${esc}[0m"
sedscript="/tmp/cgrep.sed.$$"
tempout="/tmp/cgrep.$$"

showMatches()
{
  matches=0

  echo "s/$pattern/${boldon}$pattern${boldoff}/g" > $sedscript
  for lineno in $(grep -n "$pattern" $1 | cut -d: -f1) ; do
    if [ $context -gt 0 ] ; then
      prev="$(($lineno - $context))"

      if [ $prev -lt 1 ] ; then
        # This results in "invalid usage of line address 0."
        prev="1"
      fi

      next="$(($lineno + $context))"

      if [ $matches -gt 0 ] ; then
        echo "${prev}i\\" >> $sedscript
        echo "----" >> $sedscript
      fi

      echo "${prev},${next}p" >> $sedscript
    else
      echo "${lineno}p" >> $sedscript
    fi
    matches="$(($matches + 1))"
  done

  if [ $matches -gt 0 ] ; then
    echo $sedscript
    cat $sedscript
    sed -n -f $sedscript $1 | uniq | more
  fi
}

trap "$(which rm) -f $tempout $sedscript" EXIT

if [ -z "$1" ] ; then
  echo "Usage: $0 [-c X] pattern [filename]" >&2
  exit 0
fi

if [ "$1" = "-c" ] ; then
  context="$2"
  shift; shift
elif [ "$(echo $1 | cut -c1-2)" = "-c" ] ; then
  context="$(echo %1 | cut -c3-)"
  shift
fi

pattern="$1"; shift

if [ $# -gt 0 ] ; then
  for filename ; do
    echo "----- $filename -----"
    showMatches $filename
  done
else
  cat - > $tempout  # Save stream to a temp file.
  showMatches $tempout
fi

exit 0
