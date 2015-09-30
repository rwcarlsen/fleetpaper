
set output "unfueled.eps"
set terminal epscairo

set key top left Left reverse
set xlabel "Year"
set ylabel "Cumulative Offline Power\n(GWe*month)"
set title "Fuel Shortages"

plot \
  "unfueled.dat" u ($1/12):($2/1000) w l lc 1 lw 4 smooth cum title "Case MI: monthly, individual", \
  "unfueled.dat" u ($1/12):($3/1000) w l lc 7 lw 4 smooth cum title "Case MF: monthly, fleet", \
  "unfueled.dat" u ($1/12):($4/1000) w l lc 2 lw 4 smooth cum title "Case QI: quarterly, individual", \
  "unfueled.dat" u ($1/12):($5/1000) w l lc 4 lw 4 smooth cum title "Case QF: quarterly, fleet", \
  "unfueled.dat" u ($1/12):($2/1000) w l lc 1 lw 4 smooth cum notitle, \

