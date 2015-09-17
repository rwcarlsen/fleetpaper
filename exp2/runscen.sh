#!/bin/bash

# runscen takes 2 arguments - the first is the build schedule file name,
# the second is the case to run (i.e. 1, 2, 3, or 4)
function runscen {
    db=$(cat $1 | cycobj -sched -scen scen-case${2}.json | grep -o ' \+[^ ]*\.sqlite')
    mv $db case${3}.sqlite
    rm -f *-*-*-*
}

runscen buildsched-monthly.dat 1
runscen buildsched-monthly.dat 2
runscen buildsched-quarterly.dat 3
runscen buildsched-quarterly.dat 4

