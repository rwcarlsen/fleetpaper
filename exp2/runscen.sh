#!/bin/bash

# runscen takes 3 arguments - the first is the build schedule file name,
# the second is the case to run (i.e. 1, 2, 3, or 4), and the third is the
# file name for the generated output database.
function runscen {
    db=$(cat $1 | cycobj -sched -scen scen-case${2}.json | grep -o ' \+[^ ]*\.sqlite')
    mv $db $3
    rm -f *-*-*-*
}

runscen buildsched-monthly-noshortage.dat 1 noshortage-case1.sqlite
runscen buildsched-monthly-noshortage.dat 2 noshortage-case2.sqlite
runscen buildsched-quarterly-noshortage.dat 3 noshortage-case3.sqlite
runscen buildsched-quarterly-noshortage.dat 4 noshortage-case4.sqlite
