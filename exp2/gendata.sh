#!/bin/bash

function badshare {
    cyan -db $1 -custom query.json badshare
}

function puflow {
    cyan -db $1 flow -nucs pu239,pu240,pu241,pu242 -from fastfab -to fast_reactor
}

function puflowin {
    cyan -db $1 flow -nucs pu239,pu240,pu241,pu242 -to fastfab
}

function puinv {
    cyan -db $1 inv -nucs pu239,pu240,pu241,pu242 fastfab
}

function power {
    cyan -db $1 power
}

function indivunfueled {
    cyan -db $1 -custom query.json unfueled
}

function fleetunfueled {
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

function finalize {
    paste tmp1.dat tmp2.dat tmp3.dat tmp4.dat | awk 'NR==1{print "Time\t\tCase1\t\tCase2\t\tCase3\t\tCase4";next;} {print $1"\t\t"$2"\t\t"$4"\t\t"$6"\t\t"$8}' > $1
    rm tmp1.dat tmp2.dat tmp3.dat tmp4.dat
}

puflow case1.sqlite > tmp1.dat
puflow case2.sqlite > tmp2.dat
puflow case3.sqlite | expand > tmp3.dat
puflow case4.sqlite | expand > tmp4.dat
finalize puflow.dat

puflowin case1.sqlite > tmp1.dat
puflowin case2.sqlite > tmp2.dat
puflowin case3.sqlite | expand > tmp3.dat
puflowin case4.sqlite | expand > tmp4.dat
finalize puflowin.dat

puinv case1.sqlite > tmp1.dat
puinv case2.sqlite > tmp2.dat
puinv case3.sqlite | expand > tmp3.dat
puinv case4.sqlite | expand > tmp4.dat
finalize puinv.dat

power case1.sqlite > tmp1.dat
power case2.sqlite > tmp2.dat
power case3.sqlite | expand > tmp3.dat
power case4.sqlite | expand > tmp4.dat
finalize power.dat

indivunfueled case1.sqlite | topower > tmp1.dat
fleetunfueled case2.sqlite > tmp2.dat
indivunfueled case3.sqlite | expand | topower > tmp3.dat
fleetunfueled case4.sqlite | expand > tmp4.dat
finalize unfueled.dat

badshare case1.sqlite  > tmp1.dat
badshare case3.sqlite | expand > tmp3.dat
paste tmp1.dat tmp3.dat | awk 'NR==1 {print "Time\t\tCase1\t\tCase3"; next;} {print $1"\t\t"$2"\t\t"$4}' > badshare.dat
rm tmp1.dat tmp3.dat

