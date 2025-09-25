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
* --- Load Model Parameters ---------------------------------------------------
* =============================================================================

// Include desired model definition files here
$include '%input_dir%/investInit.gms'

* =============================================================================
* --- Optional Data Manipulation ----------------------------------------------
* =============================================================================

// Define representative period node state bounds.
// First, storages with no inter-sample dynamics:
loop(ms_initial('invest', s),
    gnss_bound(gn_state('batterystor', node), s, s) = yes;
    gnss_bound(gn_state('heatsto', node), s, s) = yes;
    gnss_bound(gn_state('largeheatsto', node), s, s) = yes;
    gnss_bound(gn_state('ror', node), s, s) = yes;
);

// Declare temporary set displacement operator for inter-sample dynamics
PARAMETER ds(s) "Sample-displacement operator for cyclic inter-sample gnss bounds";
ds(s) = 1;
ds(s)${ord(s) = card(s)} = 1 - card(s);

// Next, storages with inter-sample dynamics:
loop(ms_initial('invest', s),
    gnss_bound(gn_state('psClosed', node), s, s+ds(s)) = yes;
    gnss_bound(gn_state('psOpen', node), s, s+ds(s)) = yes;
    gnss_bound(gn_state('reservoir', node), s, s+ds(s)) = yes;
    gnss_bound(gn_state('seasonheatsto', node), s, s+ds(s)) = yes;
);

// Bind investments for energy storage charging and discharging units.
alias(unit_invest, unit_invest_);
uu_bindInvestments(unit_invest, unit_invest_)${
    sum(gnu_output(grid, node, unit_invest), p_gnu_io(grid, node, unit_invest, 'output', 'upperLimitCapacityRatio')) // Charging units determining storage capacity investments.
    and sum(gnu_output(grid, node, unit_invest), gnu_input(grid, node, unit_invest_)) // Discharging units taking input from said energy storage.
} = yes;