
set output "badshare.eps"
set terminal epscairo

set key top center Left reverse
set xlabel "Year"
set ylabel "Cumulative Fuel Given to\nUnder-fueled Reactors (batch·month)\n"
set title "Imperfect Fuel Sharing"

plot \
  "badshare.dat" u ($1/12):($2) w l lc 1 lw 4 smooth cum title "Case MI: monthly", \
  "badshare.dat" u ($1/12):($3) w l lc 2 lw 4 smooth cum title "Case QI: quarterly", \

