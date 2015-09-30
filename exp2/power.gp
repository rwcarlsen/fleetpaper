
set output "power.eps"
set terminal epscairo

set key top center Left reverse
set xlabel "Year"
set ylabel "Power (GWe)"
set title "Generated Power"

plot \
  "power.dat" u ($1/12):($2/1000) w p ps .5 lc 1 pt 1 title "Case MI: monthly, individual", \
  "power.dat" u ($1/12):($3/1000) w l lw 4 lc 7 title "Case MF: monthly, fleet", \
  "power.dat" u ($1/12):($4/1000) w p ps .4 lc 2 pt 6 title "Case QI: quarterly, individual", \
  "power.dat" u ($1/12):($3/1000) w l lw 4 lc 7 notitle, \
  "power.dat" u ($1/12):($5/1000) w l lw 4 lc 4 title "Case QF: quarterly, fleet", \

