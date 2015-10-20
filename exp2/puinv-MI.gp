
set output "puinv-MI.eps"
set terminal epscairo

set xrange [93:155]
set yrange [3:1000]
set logscale y
set key top center Left reverse

set title "Pu Inventory and Flow: Case MI Zoom"
set ylabel "Separated Pu (tonnes)"
set xlabel "Year"
set key top center

plot \
  "puinv.dat" u ($1/12):($2/1000) w p lc 1 pt 1 title "Inventory", \
  "puflow.dat" u ($1/12):($2/1000) w p lc 8 pt 5 ps .15 title "Monthly outflow", \

