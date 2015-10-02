
set output "sync-cycle.eps"
set terminal epscairo

set xlabel "Year"
set ylabel "Total Generated Power (MWe)"
set xrange [0:185]

set title "Poorly Staggered Reactor Refueling"

plot "sync-cycle-power.dat" u ($1/12):2 w p title "Generated power", \
     16.0/18.0*100000*exp(0.01*x) w l lw 4 title "Installed net capacity"

