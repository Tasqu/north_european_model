equation q_bindInvestments(unit, unit) "Force equal `v_invest`s for two units";
q_bindInvestments(uu_bindInvestments(unit, unit_))..
    + v_invest_LP(unit) $ unit_investLP(unit)
    + v_invest_MIP(unit) $ unit_investMIP(unit)

    =E=

    + v_invest_LP(unit_) $ unit_investLP(unit_)
    + v_invest_MIP(unit_) $ unit_investMIP(unit_)
;