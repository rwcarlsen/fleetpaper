#!/bin/bash

function indivquerycmd {
    cyan -db $1 -custom query.json unfueled
}

function fleetquerycmd {
    cyan -db $1 -custom query.json unfueled-fleet
}

function expand {
    awk 'NR==1{print $0;next;} {print $1*3-2" "$2; print $1*3-1" "$2; print $1*3-0" "$2;}'
}

# the individual reactor unfueled query returns a count of offline reactors -
# convert this to MWe power
function topower {
    awk 'NR==1{print $0;next;} {print $1" "$2*450;}'
}

indivquerycmd case1.sqlite | topower > tmp1.dat
fleetquerycmd case2.sqlite > tmp2.dat
indivquerycmd case3.sqlite | expand | topower > tmp3.dat
fleetquerycmd case4.sqlite | expand > tmp4.dat

paste tmp1.dat tmp2.dat tmp3.dat tmp4.dat | awk 'NR==1{print "Time\t\tCase1\t\tCase2\t\tCase3\t\tCase4";next;} {print $1"\t\t"$2"\t\t"$4"\t\t"$6"\t\t"$8}' > unfueled.dat

rm tmp1.dat tmp2.dat tmp3.dat tmp4.dat

