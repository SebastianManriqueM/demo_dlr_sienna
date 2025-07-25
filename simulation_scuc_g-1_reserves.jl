using Pkg
#Pkg.activate("demo_dlr_sienna")
Pkg.activate("demo_dlr_sienna")
Pkg.instantiate()
#using Revise
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using InfrastructureSystems
const IS = InfrastructureSystems

using PowerSystemCaseBuilder
using PowerNetworkMatrices
using Dates
using TimeSeries
using Logging
using HiGHS

mip_gap = 0.01
optimizer = optimizer_with_attributes(
    HiGHS.Optimizer,
    "parallel" => "on",
    "mip_rel_gap" => mip_gap)


sys = build_system(PSITestSystems, "c_sys5_uc", add_reserves = true)

components_outages_names = ["Alta"] #Add Here the names of the generators to be considered for outages in the G-1 formulation
for component_name in components_outages_names
    # --- Create Outage Data ---
    transition_data = GeometricDistributionForcedOutage(;
        mean_time_to_recovery = 10,  # Units of hours - This value does not have any influence for G-1 formulation
        outage_transition_probability = 0.9999,  # Probability for outage per hour - This value does not have any influence for G-1 formulation
    )
    component = get_component(ThermalStandard, sys, component_name) #Brighton (Infeasible), Solitude (infinite Iteration),  Park City, Alta, Sundance
    add_supplemental_attribute!(sys, component, transition_data)
end


template = ProblemTemplate(
    NetworkModel(
        PTDFPowerModel; #SecurityConstrainedPTDFPowerModel;  #PTDFPowerModel;
        use_slacks = false,
        PTDF_matrix = PTDF(sys),
    ),
)

set_device_model!(template, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template, PowerLoad, StaticPowerLoad)
set_device_model!(template, DeviceModel(Line, StaticBranch;
    use_slacks = false)) #

set_service_model!(template,
    ServiceModel(
        VariableReserve{ReserveUp},
        RangeReserveWithDeliverabilityConstraints,
        "Reserve1",
    ))

set_service_model!(template,
    ServiceModel(
        VariableReserve{ReserveDown},
        RangeReserveWithDeliverabilityConstraints,
        "Reserve2",
    ))

model = DecisionModel(
    template,
    sys;
    name = "UC",
    optimizer = optimizer,
    system_to_file = false,
    initialize_model = true,
    check_numerical_bounds = false,
    optimizer_solve_log_print = true,
    direct_mode_optimizer = false,
    rebuild_model = false,
    store_variable_names = true,
    calculate_conflict = false,
)

models = SimulationModels(;
    decision_models = [model],
)

DA_sequence = SimulationSequence(;
    models = models,
    ini_cond_chronology = InterProblemChronology(),
)

initial_date = "2024-01-01"
steps_sim = 2
current_date = string(today())
sim = Simulation(;
    name = current_date * "_5bus" * "_" * "_" * string(steps_sim) * "steps",
    steps = steps_sim,
    models = models,
    initial_time = DateTime(string(initial_date, "T00:00:00")),
    sequence = DA_sequence,
    simulation_folder = tempdir(),#".",   tempdir()
)


build!(sim; console_level = Logging.Debug)
 
execute!(sim)

results = SimulationResults(sim)
uc = get_decision_problem_results(results, "UC")

therm_df = read_realized_variable(uc, "ActivePowerVariable__ThermalStandard")
Pline_df = read_realized_variable(uc, "FlowActivePowerVariable__Line")


vars = model.internal.container.variables
keys_var = collect(keys(vars))
constr = model.internal.container.constraints
keys_constr = collect(keys(constr))
expr = model.internal.container.expressions
keys_expr = collect(keys(expr))