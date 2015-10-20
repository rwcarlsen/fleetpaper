
set output "puinv-MF.eps"
set terminal epscairo

set xrange [93:155]
set yrange [10:1000]
set logscale y
set key top center Left reverse

set title "Pu Inventory and Flow: Case MF Zoom"
set ylabel "Separated Pu (tonnes)"
set xlabel "Year"

plot \
  "puinv.dat" u ($1/12):($3/1000) w l lc 7 lw 4 title "Inventory", \
  "puflow.dat" u ($1/12):($3/1000) w p lc 8 pt 5 ps .30 title "Monthly outflow", \
  "puflowin.dat" u ($1/12):($3/1000) w l lc rgb "blue" lw 3 title "Monthly inflow", \

