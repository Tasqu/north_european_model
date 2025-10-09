$ontext
This file is part of Backbone.

Backbone is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Backbone is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Backbone.  If not, see <http://www.gnu.org/licenses/>.
$offtext

* =============================================================================
* --- Model Definition - Invest -----------------------------------------------
* =============================================================================

* TLDR: Solve a full year as a single model (albeit samples later define the representative periods).

if (mType('invest'),
    m('invest') = yes; // Definition, that the model exists by its name

* --- Define Key Execution Parameters in Time Indeces -------------------------

    // Define simulation start and end time indeces
    mSettings('invest', 't_start') = 1;  // First time step to be solved, 1 corresponds to t000001 (t000000 will then be used for initial status of dynamic variables)
    mSettings('invest', 't_end') = 8760; // Last time step to be included in the solve (may solve and output more time steps in case t_jump does not match)

    // Define simulation horizon and moving horizon optimization "speed"
    mSettings('invest', 't_horizon') = mSettings('invest', 't_end');   // How many active time steps the solve contains (aggregation of time steps does not impact this, unless the aggregation does not match)
    mSettings('invest', 't_jump') = mSettings('invest', 't_end');      // How many time steps the model rolls forward between each solve

    // Define length of data for proper circulation
    mSettings('invest', 'dataLength') =  mSettings('invest', 't_end');

* =============================================================================
* --- Model Time Structure ----------------------------------------------------
* =============================================================================

* --- Define Samples ----------------------------------------------------------

    $$include '%input_dir%\samples_%climateYear%.inc'
    // Currently, the NE-model has an infeasibility if a sample starts at 1.
    // Temporary fix to delay by 1 hour.
    msStart(ms_initial)${msStart(ms_initial) = 1} = 2;

* --- Define Time Step Intervals ----------------------------------------------

    // Define the duration of a single time-step in hours
    mSettings('invest', 'stepLengthInHours') = 1;

    // Define the time step intervals in time-steps
    mInterval('invest', 'stepsPerInterval', 'c000') = 1;
    mInterval('invest', 'lastStepInIntervalBlock', 'c000') = mSettings('invest', 't_end');

* --- z-structure for superpositioned nodes ----------------------------------

    // number of candidate periods in model
    // please provide this data
    mSettings('invest', 'candidate_periods') = 0;

    // add the candidate periods to model
    // no need to touch this part
    mz('invest', z) = no;
    loop(z$(ord(z) <= mSettings('invest', 'candidate_periods') ),
       mz('invest', z) = yes;
    );

    // Mapping between typical periods (=samples) and the candidate periods (z).
    // Assumption is that candidate periods start from z000 and form a continuous
    // sequence.
    // please provide this data
    zs(z,s) = no;

* =============================================================================
* --- Model Forecast Structure ------------------------------------------------
* =============================================================================

* TLDR: No forecasts for an investment run.

    // Define the number of forecasts used by the model
    mSettings('invest', 'forecasts') = 0;

    // Define forecast properties and features
    mSettings('invest', 't_forecastStart') = 0;                // At which time step the first forecast is available ( 1 = t000001 )
    mSettings('invest', 't_forecastLengthUnchanging') = 0;     // Length of forecasts in time steps - this does not decrease when the solve moves forward
    mSettings('invest', 't_forecastLengthDecreasesFrom') = 0;  // Length of forecasts in time steps - this decreases when the solve moves forward until the new forecast data is read and then extends back to full length
    mSettings('invest', 't_forecastJump') = 0;                 // Number of time steps between each update of the forecasts

    // Define Realized and Central forecasts
    mf_realization('invest', 'f00') = yes;
    mf_central('invest', 'f00') = yes;

    // Define forecast probabilities (weights)
    p_mfProbability(mf_realization('invest', f)) = 1;

    // Define active model features
    active('invest', 'storageValue') = yes; // TODO: Is this necessary?

* =============================================================================
* --- Model Features ----------------------------------------------------------
* =============================================================================

* TLDR: No reserves, no changing unit approximations, no initialization, no incremental heat rates.

* --- Define Reserve Properties -----------------------------------------------

    // Lenght of reserve horizon
*    mSettingsReservesInUse('invest', 'primary', 'up') = no;
*    mSettingsReservesInUse('invest', 'primary', 'down') = no;
*    mSettingsReservesInUse('invest', 'secondary', 'up') = no;
*    mSettingsReservesInUse('invest', 'secondary', 'down') = no;
*    mSettingsReservesInUse('invest', 'tertiary', 'up') = no;
*    mSettingsReservesInUse('invest', 'tertiary', 'down') = no;

* --- Define Unit Approximations ----------------------------------------------

    // Define the last time step for each unit aggregation and efficiency level (3a_periodicInit.gms ensures that there is a effLevel until t_horizon)
    mSettingsEff('invest', 'level1') = inf;

    // Define the horizon when start-up and shutdown trajectories are considered
    mSettings('invest', 't_trajectoryHorizon') = 0;

* --- Define output settings for results --------------------------------------

    // Define the length of the initialization period. Results outputting starts after the period. Uses ord(t) > t_start + t_initializationPeriod in the code.
    mSettings('invest', 't_initializationPeriod') = 0;  // r_state_gnft and r_online_uft are stored also for the last step in the initialization period, i.e. ord(t) = t_start + t_initializationPeriod

* --- Define the use of additional constraints for units with incremental heat rates

    // How to use q_conversionIncHR_help1 and q_conversionIncHR_help2
    mSettings('invest', 'incHRAdditionalConstraints') = 0;
    // 0 = use the constraints but only for units with non-convex fuel use
    // 1 = use the constraints for all units represented using incremental heat rates


* =============================================================================
* --- Solver Features ---------------------------------------------------------
* =============================================================================

* TLDR: No advanced basis, dummies included, automatic rounding enabled.

* --- Control the solver ------------------------------------------------------

    // Control the use of advanced basis
    mSettings('invest', 'loadPoint') = 0;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve
    mSettings('invest', 'savePoint') = 0;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve


* --- solver speed improvements ------------------------------------------------------
    //available from v3.9 onwards

    // Option to reduce the amount of dummy variables. 0 = off = default. 1 = automatic for unrequired dummies. 
    // Values 2... remove also possibly needed dummies from N first hours (time steps) of the solve.
    // Using value that ar larger than t_horizon drops all dummy variables from the solve. 
    // Impacts vq_gen, vq_reserveDemand, vq_resMissing, vq_unitConstraint, and vq_userconstraint   
    // NOTE: Should be used only with well behaving models
    // NOTE: this changes the shape of the problem and there are typically differences in the decimals of the solutions
    // NOTE: It is the best to keep 0 here when editing and updating the model and drop the dummies only when running a stable model.
    mSettings('invest', 'reducedDummies') = 0;  
                       
    // Scaling the model with a factor of 10^N. 0 = off = default. Accepted values 1-6.                                         
    // This option might improve the model behaviour in case the model has "infeasibilities after unscaling" issue.
    // It also might improve the solve time of well behaving model, but this is model specific and the option might also slow the model.
    mSettings('invest', 'scalingMethod') = 0; 

    // Automatic rounding of cost parameters, ts_influx, ts_node, ts_cf, ts_gnn, and ts_reserveDemand. 0 = off = default. 1 = on. 
    mSettings('invest', 'automaticRoundings') = 1; 


); // END if(mType)


