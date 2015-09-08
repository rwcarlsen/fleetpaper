
set output "badshare.eps"
set terminal epscairo

set key top center Left reverse
set xlabel "Year"
set ylabel "Cumulative Fuel Given to\nOffline Reactors (batch*mo)\n"
set title "Imperfect Fuel Sharing (individual reactor)"

plot \
  "badshare.dat" u ($1/12):($2) w l lc 1 lw 4 smooth cum title "Case 1: monthly", \
  "badshare.dat" u ($1/12):($3) w l lc 2 lw 4 smooth cum title "Case 3: quarterly", \

