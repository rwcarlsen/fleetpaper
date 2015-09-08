#!/bin/bash

function querycmd {
    cyan -db $1 -custom query.json badshare
}

function expand {
    awk 'NR==1{print $0;next;} {print $1*3-2" "$2; print $1*3-1" "$2; print $1*3-0" "$2;}'
}

querycmd case1.sqlite  > tmp1.dat
querycmd case3.sqlite | expand > tmp3.dat

paste tmp1.dat tmp3.dat | awk 'NR==1 {print "Time\t\tCase1\t\tCase3"; next;} {print $1"\t\t"$2"\t\t"$4}' > badshare.dat

rm tmp1.dat tmp3.dat

