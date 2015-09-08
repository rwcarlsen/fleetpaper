#!/bin/bash

function querycmd {
    cyan -db $1 flow -nucs pu239,pu240,pu241,pu242 -from fastfab -to fast_reactor
}

function expand {
    awk 'NR==1{print $0;next;} {print $1*3-2" "$2; print $1*3-1" "$2; print $1*3-0" "$2;}'
}

querycmd case1.sqlite > tmp1.dat
querycmd case2.sqlite > tmp2.dat
querycmd case3.sqlite | expand > tmp3.dat
querycmd case4.sqlite | expand > tmp4.dat

paste tmp1.dat tmp2.dat tmp3.dat tmp4.dat | awk 'NR==1{print "Time\t\tCase1\t\tCase2\t\tCase3\t\tCase4";next;} {print $1"\t\t"$2"\t\t"$4"\t\t"$6"\t\t"$8}' > puflow.dat

rm tmp1.dat tmp2.dat tmp3.dat tmp4.dat

