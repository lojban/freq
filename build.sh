#!/bin/bash

mydir=$(dirname $0)
builddir=$mydir/build

if [ "$1" != "-h" -a "$1" != "--help" -a "$1" != "shell" ]
then
  $mydir/update_datafiles.sh $builddir
  if [ "$?" -ne 0 ]
  then
    echo "jbovlaste file update failed; bailing"
    exit 1
  fi

  echo "Unpacking corpus."
  rm $builddir/corpus.txt
  bunzip2 -k $builddir/corpus.txt.bz2

  echo "Building basic frequencies; this'll take a bit."
  tr -cd "[a-zA-Z' \t\n0-9]" <$builddir/corpus.txt | sed -r 's/\s+/\n/g' | sort | uniq -c | sort -rn >$builddir/freq.raw

  echo "Done building basic frequencies; starting actual wordlist generation."
fi

$mydir/generate_wordlist.rb "$@"
