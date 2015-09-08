
set output "sync-cycle.eps"
set terminal epscairo

set xlabel "Year"
set ylabel "Total Generated Power (MWe)"
set key off
set xrange [0:185]

set title "Poorly Staggered Reactor Refueling"

plot "sync-cycle-power.dat" u ($1/12):2 w p

