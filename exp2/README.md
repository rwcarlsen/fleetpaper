
Provenance, Data Generation, and Analysis
==========================================

There are 4 simulation cases run and analyzed in this paper. They are:

* Case 1: individually modeled reactors with monthly time steps
* Case 2: fleet modeled reactors with monthly time steps
* Case 3: individually modeled reactors with quarterly time steps
* Case 4: fleet modeled reactors with quarterly time steps

Reproducibility
----------------

Versions:

* Cloudlus (github.com/rwcarlsen/cloudlus): ``50477f3``

* CyAn (github.com/rwcarlsen/cyan): ``5c6700b``

* Cyclus::

    Cyclus Core 1.3.0 (1.3.1-65-gacf86cc)

    Dependencies:
       Boost    1_58
       Coin-Cbc 2.9.5
       Coin-Clp 1.16.6
       Hdf5     1.8.14-
       Sqlite3  3.8.11.1
       xml2     2.9.2
       xml++    2.38.1

* rwc archetypes: these are the custom storage and fleet-reactor archetypes
  used in this analysis.  The version used are inside the ``agents`` folder in
  this directory.  To install them, first install Cyclus, then run ``make -j
  install``.

* Cycamore: ``1.3.1-44-g888a8a2``.  Some queries use a special database table
  that was created by applying this patch to the cycamore reactor before
  installing::

    diff --git a/src/reactor.cc b/src/reactor.cc
    index 9870557..2e30dc6 100644
    --- a/src/reactor.cc
    +++ b/src/reactor.cc
    @@ -22,7 +22,8 @@ Reactor::Reactor(cyclus::Context* ctx)
           cycle_step(0),
           power_cap(0),
           power_name("power"),
    -      discharged(false) {
    +      discharged(false),
    +      cycle_count(0) {
       cyclus::Warn<cyclus::EXPERIMENTAL_WARNING>(
           "the Reactor archetype "
           "is experimental");
    @@ -103,6 +104,7 @@ bool Reactor::CheckDecommissionCondition() {
     }
     
     void Reactor::Tick() {
    +  old_core_count = core.count();
       // The following code must go in the Tick so they fire on the time step
       // following the cycle_step update - allowing for the all reactor events to
       // occur and be recorded on the "beginning" of a time step.  Another reason
    @@ -346,14 +348,35 @@ void Reactor::Tock() {
     
       if (cycle_step == 0 && core.count() == n_assem_core) {
         Record("CYCLE_START", "");
    +    cycle_count++;
       }
     
    +  double genpower = 0;
       if (cycle_step >= 0 && cycle_step < cycle_time &&
           core.count() == n_assem_core) {
    -    cyclus::toolkit::RecordTimeSeries<cyclus::toolkit::POWER>(this, power_cap);
    -  } else {
    -    cyclus::toolkit::RecordTimeSeries<cyclus::toolkit::POWER>(this, 0);
    -  }
    +    genpower = power_cap;
    +  }
    +  cyclus::toolkit::RecordTimeSeries<cyclus::toolkit::POWER>(this, genpower);
    +
    +  bool offline =
    +      ((cycle_step >= 0 && cycle_step < cycle_time) ||  // new reactors without full cores
    +       cycle_step >= cycle_time + refuel_time) &&  // old reactors that can't get refuel batches
    +      core.count() < n_assem_core;
    +
    +  context()->NewDatum("ReactorFuelInfo")
    +    ->AddVal("Time", context()->time())
    +    ->AddVal("Cycle", cycle_count)
    +    ->AddVal("Offline", offline)
    +    ->AddVal("CycleStep", cycle_step)
    +    ->AddVal("CycleTime", cycle_time)
    +    ->AddVal("RefuelTime", refuel_time)
    +    ->AddVal("AgentId", id())
    +    ->AddVal("AssemPerCore", n_assem_core)
    +    ->AddVal("AssemPerBatch", n_assem_batch)
    +    ->AddVal("NCore", core.count())
    +    ->AddVal("NCoreAdd", core.count() - old_core_count)
    +    ->AddVal("NFresh", fresh.count())
    +    ->Record();
     
       // "if" prevents starting cycle after initial deployment until core is full
       // even though cycle_step is its initial zero.
    diff --git a/src/reactor.h b/src/reactor.h
    index 67c04de..466c525 100644
    --- a/src/reactor.h
    +++ b/src/reactor.h
    @@ -384,6 +384,14 @@ class Reactor : public cyclus::Facility,
     
       // populated lazily and no need to persist.
       std::set<std::string> uniq_outcommods_;
    +
    +  // intra-timestep value doesn't need persistence
    +  double old_core_count;
    +
    +  #pragma cyclus var {"default": 0, "doc": "This should NEVER be set manually", \
    +                      "internal": True \
    +  }
    +  int cycle_count;
     };
     
     } // namespace cycamore


Data Generation and Analysis
----------------------------

Generating all the data is as simple as (once Cyclus, patched Cycamore, the
custom fleet reactor and storage agents, CyAn, and Cloudlus are installed)::

    # run simulations
    ./runscen.sh

    # query time series from databases
    ./gendata.sh

    # generate plots
    gnuplot power.gp
    gnuplot power-rel.gp
    gnuplot badshare.gp
    gnuplot unfueled.gp
    gnuplot puinv.gp
    gnuplot puinv-compare.gp


Files
------

A description of all the important files in this directory follows.  For each
of the four cases, there are:

* ``case[num].xml``: This is a cyclus input file with a templated place-holder
  for the actual deployments that are filled in.  This contains all simulation
  details (except reactor deployment schedule) including compositions,
  facility throughputs, etc.

* ``scen-case[num].json``: This is a scenario file that describes the power
  growth, deployment frequency, and other relevant parameters for cloudlus to
  be able to generate deployment schedules and do things like calculate
  objective function values (although this particular functionality is not
  used in for this paper).

* ``case[num].sqlite``: the output database generated by cyclus for each case.
  All data analysis operates on data in these files.

Other important files are:

* ``runscen.sh``: Assuming cyclus, cloudlus (esp the ``cycobj`` command),
  cyan, custom archetypes, patched cycamore are installed, this script will
  use the case scenario and input files to generate the output database for
  all four cases.

* ``gendata.sh`` operates on the sqlite databases for all cases generating the
  following data files containing time series data:

    - ``puflow.dat``: Pu flow out of fab

    - ``puflowin.dat``: Pu flow into fab

    - ``puinv.dat``: Pu inv of fab

    - ``power.dat``: total generated power

    - ``unfueled.dat``: total offline power capacity due to fuel shortage

    - ``badshare.dat``: total unnecessary offline power due to inefficient
      fuel sharing

  for the actual deployments that are filled in .

* ``power-constr.sh``: This is used to generate the min and max power bounds
  in the case scenario files to follow an exponential 1% growth curve.

* ``query.json``: This is a file containing custom queries to be used with
  CyAn.  "unfueled-fleet" reports the amount of fleet-reactor capacity that is
  offline due to fuel shortage that would otherwise be operating.  "unfueled"
  reports the same thing but for scenarios with individually modeled reactors.
  "badshare" reports the number of reactors that could have been operating but
  aren't because available fuel was not distributed efficiently (i.e. reactors
  needing more than one batch received a single batch where some reactors that
  only needed 1 batch didn't get any).

* ``buildsched-[monthly/quarterly].dat``: the build schedules used for all four
  cases.  These were generated by running::
    
    seq 230 | awk '{print 1}' | cycobj -transform -scen scen-case[1/2/3/4].json > buildsched-[monthly/quarterly].dat

  Although there are two separate files, the build schedules they contain are
  the same, they just have different time related values due to the different
  time step granularity in the monthly v quarterly scenarios.

* ``flow.dot``: contains a graphviz dot script that describes/generates a
  node-arc graph depicting material flows between different facility types in
  the scenarios.

* ``sync-cycle.xml``, ``sync-cycle-power.dat``, ``sync-cycle.gp``: these are
  input file, data, and plot generation for an example simulation just to show
  poor reactor cycle staggering.  They are not part of the main data and
  analysis.

* several gnuplot scripts that generate plots via ``gnuplot [scriptname]``

    - ``power.gp``: Power generated v time for all reactors all cases.

    - ``power-rel.gp``: Power generated v time normalized to the expected
      exponential 1% power demand for all cases.

    - ``unfueled.gp``: offline capacity due to fuel shortage

    - ``badshare.gp``: wasted batch-months due to inefficient fuel sharing

    - ``puinv.gp``: Pu inventory and flow v time for all cases showing the drawdown
        effect.

    - ``puinv-compare.gp``: Pu inventory v time for all cases ploted on top of
        each other.

    - ``sync-cycle.gp``: Not part of the main analysis - just generates a
      sample scenario power curve with poorly staggered reactor cycles.

