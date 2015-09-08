
set output "power-rel.eps"
set terminal epscairo

set yrange [.8:1.2]
set key top left at first 30,1.19 Left reverse
set xlabel "Year"
set ylabel "Supply-Demand Power Ratio"
set title "Normalized Power (all cases)"

# the floor div and mult 21 are to account for deployments only occuring every
# 21 months. This is appropriate since the reactor capacity is only
# managed/checkpointed on a build period interval.
plot \
  "power.dat" u ($1/12):($2/1000/(100*exp(.01*(floor($1/21)*21)/12))) w p ps 1.0 lc 1 pt 1 title "Case 1: monthly, individual", \
  "power.dat" u ($1/12):($3/1000/(100*exp(.01*(floor($1/21)*21)/12))) w p ps .5 lc 7 pt 2 title "Case 2: monthly, fleet", \
  "power.dat" u ($1/12):($4/1000/(100*exp(.01*(floor($1/21)*21)/12))) w p ps .4 lc 2 pt 6 title "Case 3: quarterly, individual", \
  "power.dat" u ($1/12):($3/1000/(100*exp(.01*(floor($1/21)*21)/12))) w p ps .5 lc 7 pt 2 notitle, \
  "power.dat" u ($1/12):($5/1000/(100*exp(.01*(floor($1/21)*21)/12))) w p ps .1 lc 4 pt 4 title "Case 4: quarterly, fleet", \

