
set output "puinv-compare.eps"
set terminal epscairo

set yrange [3:2750]
set logscale y
set key top center reverse Left

set title "Pu Inventory and Flow: comparison"
set xlabel "Year"
set ylabel "Separated Pu (tonnes)"
plot \
  "puinv.dat" u ($1/12):($2/1000) w p lc 1 ps 0.6 pt 1 title "Case 1: monthly, individual", \
  "puinv.dat" u ($1/12):($3/1000) w p lc 7 ps 0.5 pt 2 title "Case 2: monthly, fleet", \
  "puinv.dat" u ($1/12):($4/1000) w p lc 2 ps 0.4 pt 6 title "Case 3: quarterly, individual", \
  "puinv.dat" u ($1/12):($5/1000) w p lc 4 ps 0.13 pt 4 title "Case 4: quarterly, fleet", \

