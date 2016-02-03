#!/bin/bash

oldref=$1
olddir=/tmp/latexdiff1

newref=HEAD
newdir=/tmp/latexdiff2

if [[ $# -ge 2 ]]; then
    newref=$2
fi

echo "Running 'latexdiff $oldref $newref'..."


rm -rf $olddir $newdir
mkdir -p $olddir
mkdir -p $newdir
bash -c "cd $olddir &>/dev/null && git clone $PWD &>/dev/null && cd fleetpaper &>/dev/null && git checkout $oldref &>/dev/null"
bash -c "cd $newdir &>/dev/null && git clone $PWD &>/dev/null && cd fleetpaper &>/dev/null && git checkout $newref &>/dev/null"
latexdiff --flatten $olddir/fleetpaper/paper.tex $newdir/fleetpaper/paper.tex > diff.tex
pdflatex diff.tex &> /dev/null
bibtex diff.aux &>/dev/null
pdflatex diff.tex &> /dev/null
bibtex diff.aux &>/dev/null
pdflatex diff.tex &> /dev/null

rm -rf $olddir $newdir diff.tex diff.aux diff.blg diff.glo diff.ist diff.log diff.bbl diff.acn diff.out diff.xwm

