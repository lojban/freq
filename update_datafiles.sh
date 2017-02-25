#!/bin/bash

set -e

if [ ! "$1" ]
then
  echo "Give build dir as sole argument."
  exit 1
fi

builddir=$1

downloader() {
  builddir=$1
  url=$2
  file=$3

  wget --no-verbose $url -O "$builddir/$file.new"

  sizenew="$(stat -c %s $builddir/$file.new || echo 0)"
  if [ ! -f "$builddir/$file.new" -o ! "$sizenew" -o "$sizenew" -lt 100 ]
  then
    echo "Couldn't fetch $file; bailing."
    exit 1
  fi

  size="$(stat -c %s $builddir/$file || echo 0)"
  if [ ! -f "$builddir/$file" -o ! "$size" -o "$size" -lt 100 ]
  then
    echo -e "\n\nold $file is bad; replacing\n\n"
    mv "$builddir/$file.new" "$builddir/$file"
  else
    if diff -q "$builddir/$file.new" "$builddir/$file" >/dev/null 2>&1
    then
      echo -e "\n\n$file has not changed.\n\n"
      # rm "$builddir/$file.new"
    else
      echo -e "\n\nNew $file found; putting in place.\n\n"
      cp "$builddir/$file.new" "$builddir/$file"
    fi
  fi
}

echo -e "\nDownloading corpus data.\n\n"
downloader "$builddir" 'http://www.lojban.org/corpus/corpus.txt.bz2' 'corpus.txt.bz2'
echo -e "Downloading jbovlaste data.\n\n"
downloader "$builddir" 'http://jbovlaste.lojban.org/export/xml-export.html?lang=en&bot_key=z2BsnKYJhAB0VNsl' 'jbovlaste.xml'
