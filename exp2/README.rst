
Experiment 2
==============

Same optimization and simulation scenario as experiment 1.  But introduce a
fleet-based reactor.  The fleet reactor deploys and retires capacity in units
of single reactors (e.g. 1 GWe for LWRs). Primary differences from the
individual reactor model are:

* Material is discharged continuously (every time step) pro-rated by its batch
  size and cycle length.

* If the fleet is short on fuel, power generated is reduced by the same
  fraction of missing fuel; capacity is not shut off in full-reactor quanta
  Fleet "reactors" don't compete for fuel - it is shared perfectly.  Power
  production by a group of individual reactors for a fixed amount of fuel
  shortage may vary depending on how the existing fuel is distributed.  Being
  short 3 batches might mean that one reactor has no batches and isn't
  operating or that 3 reactors are missing a single batch.

* When capacity is retired a full reactor core of material is discharged and
  transmuted even if there was some fraction of unfueled capacity.

The most significant differences between the two modeling paradims involve
fuel inventory handling and operation under supply constraints.  The objective
function chosen tends to drive toward deployment schedules that push the limit
on available fuel inventory for fast reactors.  The objective function is at
its lowest when on-hand fast reactor fresh fuel inventory for the simulation
stays as close to zero as possible. Much of the optimization process will be
searching around boundaries between transitions with fueled vs unfueled
reactors.  

Reproducibility
----------------

Versions:

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

* Cycamore: ``1.3.1-44-g888a8a2`` + patch shown below

* rwc archetypes (from this repository's agents directory): ``21d8da0``

* Cloudlus (github.com/rwcarlsen/cloudlus): ``50477f3``

Some queries use a special database table that was created by applying this
patch to the cycamore reactor::

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


Scenario Descriptions
----------------------

There will be four cases:

1. monthly time steps, individual reactors
2. monthly time steps, fleet reactors
3. quarterly time steps, individual reactors
4. quarterly time steps, fleet reactors

Each of the cases has a template input file ``case[num].xml`` and a
optimization scenario file for generating deployments ``scen-case[num].json``.
``power-constr.sh`` was used to generate the MaxPower and MinPower parameters
for the scenario files.  A 21-month build period is used - this provides
better natural staggering of reactor cycles than a 24 month build period.  In
order to avoid having all the initially deployed light water reactors
refueling at the same time, a separate reactor prototype was used identical to
the LWR configuration except the refueling outage time was set to zero and the
cycle time was increased to keep the integrated cycle time equivalent; the
power capacity was also reduced to 900 - preserving the invariants described
below.

The reference deployment schedule doesn't build any more LWRs as soon as SFRs
become available and builds along the top of the +/- 10% curve across the
entire 200 years.  The schedule was created by running::

    seq 230 | awk '{print 1}' | cycobj -scen scen-case1.json -transform

for each of the cases.  ``cycobj`` is a command provided as part of the
``cloudlus`` suite.

The base input file was computed starting from the experiment 1
recycle-tmpl.xml input file.  Invariants of reactor parameters that are
preserved between all four cases are:

* Fuel discharge rate from a single reactor core (kg/month). Computed:

     - fleet: batch_size / (cycle_time * timestep_duration)

     - individual: (assem_size * n_assem_batch) / ((cycle_time + refuel_time) * timestep_duration)
 
* Fuel Burnup (MWmo/kgHM). Computed:

     - fleet: cycle_time * timestep_duration * power_cap / batch_size

     - individual: cycle_time * timestep_duration * power_cap / (assem_size * n_assem_batch)
 
* Power capacity including capacity factor (MW). Computed:

     - fleet:  power_cap

     - individual: power_cap * cycle_time / (cycle_time + refuel_time)
 
* Core size (kgHM). Computed:

     - fleet:  core_size

     - individual: n_assem_core * assem_size


Experiment 1 represents case 2 (with minor adjustements) and is the reference
for the computed invariants.  The only invariant not preserved between the
experiment 1 scenario and case 2 is the fast reactor core size - which is
slightly larger in case 2.  The invariants are:

* thermal:

    - discharge rate: 29565/18 = 1642.5
    - burnup: 18*900/29565 = 0.547945
    - effective power: 900
    - core size: 88695

* fast:

    - discharge rate: 7490/14 = 535
    - burnup: 14*360/7490 = 0.6728972
    - effective power: 360
    - core size: 40125

Reactor parameters that preserve these invariants for all four cases are:

* Case 1: individual, monthly

    * thermal:

        <cycle_time>15</cycle_time>
        <refuel_time>3</refuel_time>
        <assem_size>29565</assem_size>
        <n_assem_core>3</n_assem_core>
        <n_assem_batch>1</n_assem_batch>
        <power_cap>1080</power_cap>

    * fast:

        <cycle_time>12</cycle_time>
        <refuel_time>3</refuel_time>
        <assem_size>8025</assem_size>
        <n_assem_core>5</n_assem_core>
        <n_assem_batch>1</n_assem_batch>
        <power_cap>450</power_cap>

* Case 2: fleet, monthly

    * thermal:

        <cycle_time>18</cycle_time>
        <batch_size>29565</batch_size>
        <core_size>88695</core_size>
        <power_cap>900</power_cap>

    * fast:

        <cycle_time>15</cycle_time>
        <batch_size>8025</batch_size>
        <core_size>40125</core_size>
        <power_cap>360</power_cap>

* Case 3: individual, quarterly

    * thermal:

        <cycle_time>5</cycle_time>
        <refuel_time>1</refuel_time>
        <assem_size>29565</assem_size>
        <n_assem_core>3</n_assem_core>
        <n_assem_batch>1</n_assem_batch>
        <power_cap>1080</power_cap>

    * fast:

        <cycle_time>4</cycle_time>
        <refuel_time>1</refuel_time>
        <assem_size>8025</assem_size>
        <n_assem_core>5</n_assem_core>
        <n_assem_batch>1</n_assem_batch>
        <power_cap>450</power_cap>

* Case 4: fleet, quarterly

    * thermal:

        <cycle_time>6</cycle_time>
        <batch_size>29565</batch_size>
        <core_size>88695</core_size>
        <power_cap>900</power_cap>

    * fast:

        <cycle_time>5</cycle_time>
        <batch_size>8025</batch_size>
        <core_size>40125</core_size>
        <power_cap>360</power_cap>

Analysis
-----------

Each simulation was generated/run by entering::

    seq 230 | awk '{print 1}' | cycobj -scen scen-case1.json

on the command line.

Simulation Detail Comparison
+++++++++++++++++++++++++++++

Look at:

* power v time for all cases. show/discuss cycle staggering effect.

* idling reactors v time for all cases. also plot assemblies distributed to
  reactors unable to operate times time v time. show/discuss fuel sharing
  effect.

* Pu inventory in fuel fab (separated and in storage) v time for all cases
  with impulse flows out of the fab (i.e. into fast reactors) overlaid.
  show/discuss inventory drawdown effect.

* Pu flow out of reactors v time for all cases.

* (maybe) Pu flow out of separations v time for all cases (if interesting)

Try to explain what causes the differences between the cases in each of the
above figures/plots.  Discuss about the discrete shutdown effect in the
context of the results/plots.

Inefficient fuel sharing quantified by counting the number of assemblies given
to reactors that ended up not being able to operate at the end of their normal
refueling outage period and multiplying this number by the number of extra
time steps the reactor was offline before finally receiving enough fuel to
operate.  This is what was used ``query.json`` was used with the ``cyan
-custom query.json -db ...  [unfueled/poorshare]`` to generate a time series
for unfueled reactors (by count) and a time series for the number of
assemblies given to reactors times the number of time steps those reactors
were not able to operate (post refueling outage time) before receiving enough
fresh fuel to come back online.

The ``power.sh`` script was used to generate ``power.dat`` which holds the
power time series for each of the four cases.  ``unfueled.sh`` generates
``unfueled.dat`` from the four case simulations (assuming they are named
``case[num].sqlite``); this holds offline MWe*months due to fuel shortage
(excluding normal refueling).  ``badshare.sh`` generates ``badshare.dat`` from
the sim dbs also; this holds an approximation of offline MWe*months due to
imperfect fuel sharing by multiplying the number of assemblies given to
reactors that ended up not being able to operate times the number of time
steps before they were finally able to operate times the power capacity of a
single reactor - this assumes that every single individual assembly could have
allowed an offline reactor to operate if given to the right reactor.
``puinv.sh``, ``puflow.sh``, and ``puflowin`` generate time series for
separated Pu in storage (``puinv.dat``), flow out of storage (``puflow.dat``),
and flow into storage (``puflowin.dat``) respectively for all cases. Gnuplot
scripts are used by the dissertation makefile to generate final figures.

Optimization Comparison
++++++++++++++++++++++++

* How different are the optimum fleet and individual deployment schedules
  (e.g. manhattan distance, L2 norm) from each other? - all cases

* How different are the optimum fleet and individual objective function values
  from each other? - all cases

