#!/bin/bash

dir=submit-zip
prefix="NT15-138R1"
manuscript=${prefix}_LaTeX_FinalText.tex

rm -rf $dir
mkdir -p $dir

cp submission-makefile $dir/Makefile
cp paper.tex $dir/$manuscript

cp ans.bst $dir/${prefix}_bibstyle.bst
sed -i 's/{ans}/{'"$prefix"'_bibstyle}/g' $dir/$manuscript

cp refs.bib $dir/${prefix}_references.bib
sed -i 's/{refs}/{'"$prefix"'_references}/g' $dir/$manuscript

cp printmanuscript.cls $dir/${prefix}_LaTeX_class.cls
sed -i 's/{style}/{'"$prefix"'_LaTeX_class}/g' $dir/$manuscript

sed -i 's/{neup_logo_large.jpg}/{'"$prefix"'_neup_logo_large.jpg}/g' $dir/$manuscript
cp neup_logo_large.jpg $dir/${prefix}_neup_logo_large.jpg

srcs=("flow.eps" "sync-cycle.eps" "fuel-sharing.pdf" "power.eps" "power-rel.eps" "unfueled.eps" "badshare.eps" "puinv.eps" "puinv-MI.eps" "puinv-MF.eps" "puinv-compare.eps" "puinv-compare-zoom.eps")

declare -i i=1
for src in "${srcs[@]}"; do
    dstname=$(echo "$src" | sed 's/.*\.\(.*\)/'"$prefix"'_Fig'"$i"'.\1/')
    cp exp2/$src $dir/$dstname
    sed -i 's/exp2\/'"$src"'/'"$dstname"'/g' $dir/$manuscript
    i=$i+1
done

tar -czf fleetpaper-final.tar.gz submit-zip/*

