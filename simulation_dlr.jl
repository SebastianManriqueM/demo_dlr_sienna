
c_sys5 = PSB.build_system(PSITestSystems, "c_sys5")
c_sys14 = PSB.build_system(PSITestSystems, "c_sys14")
c_sys14_dc = PSB.build_system(PSITestSystems, "c_sys14_dc")
systems = [c_sys5, c_sys14, c_sys14_dc]
objfuncs = [GAEVF, GQEVF, GQEVF]
constraint_keys = [
    PSI.ConstraintKey(RateLimitConstraint, PSY.Line, "lb"),
    PSI.ConstraintKey(RateLimitConstraint, PSY.Line, "ub"),
    PSI.ConstraintKey(CopperPlateBalanceConstraint, PSY.System),
    PSI.ConstraintKey(NetworkFlowConstraint, PSY.Line),
]
PTDF_ref = IdDict{System, VirtualPTDF}(
    c_sys5 => VirtualPTDF(c_sys5),
    c_sys14 => VirtualPTDF(c_sys14),
    c_sys14_dc => VirtualPTDF(c_sys14_dc),
)
branches_dlr = IdDict{System, Vector{String}}(
    c_sys5 => ["1", "2", "6"],
    c_sys14 => ["Line1", "Line2", "Line9", "Line10", "Line12", "Trans2"],
    c_sys14_dc => ["Line1", "Line9", "Line10", "Line12", "Trans2"],
)
dlr_factors = vcat([fill(x, 6) for x in [1.15, 1.05, 1.1, 1]]...)
test_results = IdDict{System, Vector{Int}}(
    c_sys5 => [264, 0, 264, 264, 168],
    c_sys14 => [600, 0, 600, 600, 504],
    c_sys14_dc => [600, 0, 648, 552, 456],
)
test_obj_values = IdDict{System, Float64}(
    c_sys5 => 324244.401,
    c_sys14 => 142000.0,
    c_sys14_dc => 142000.0,
)
for (ix, sys) in enumerate(systems)
    template = get_thermal_dispatch_template_network(
        NetworkModel(
            PTDFPowerModel;
            PTDF_matrix = PTDF_ref[sys],
        ),
    )

    set_device_model!(template, line_device_model)
    set_device_model!(template, TapTransf_device_model)
    ps_model = DecisionModel(template, sys; optimizer = HiGHS_optimizer)

    

    @test build!(ps_model; output_dir = mktempdir(; cleanup = true)) ==
            PSI.ModelBuildStatus.BUILT
    psi_constraint_test(ps_model, constraint_keys)

    moi_tests(
        ps_model,
        test_results[sys][1],
        test_results[sys][2],
        test_results[sys][3],
        test_results[sys][4],
        test_results[sys][5],
        false,
    )
    psi_checkobjfun_test(ps_model, objfuncs[ix])
    psi_checksolve_test(
        ps_model,
        [MOI.OPTIMAL, MOI.ALMOST_OPTIMAL],
        test_obj_values[sys],
        10000,
    )
end


using Pkg
Pkg.activate("demo_dlr_sienna")
using Logging
using InfrastructureSystems
using PowerSystems
using PowerSystemCaseBuilder
using PowerSimulations
using HydroPowerSimulations
using PowerFlows
using PowerNetworkMatrices
using HiGHS
using DataFrames
using DataStructures
using Dates
using TimeSeries
using HiGHS

function add_dlr_to_system_branches!(
    sys::System, 
    branches_dlr::Vector{String},
    n_steps::Int, 
    dlr_factors::Vector{Float64};
    initial_date::String = "2020-01-01",
    )
    # Add dynamic line ratings to the system
    for branch_name in branches_dlr
        branch = get_component(ACTransmission, sys, branch_name)

        dlr_data = SortedDict{Dates.DateTime, TimeSeries.TimeArray}()
        data_ts = collect(
            DateTime("$initial_date 0:00:00", "y-m-d H:M:S"):Hour(1):(
                DateTime("$initial_date 23:00:00", "y-m-d H:M:S") + Day(n_steps-1)
            )
        )
        @show branch_name
        @show length(dlr_factors)
        @show length(data_ts)
        dlr_data =
                TimeArray(
                    data_ts,
                    get_rating(branch) * get_base_power(sys) * dlr_factors,
                )


        PowerSystems.add_time_series!(
            sys,
            branch,
            PowerSystems.SingleTimeSeries(
                "dynamic_line_ratings",
                dlr_data;
                scaling_factor_multiplier = get_rating,
            ),
        )
        # for t in 1:look_ahead
        #     @show t
        #     ini_time = data_ts[1] + Day(t - 1)
        #     dlr_data[ini_time] =
        #         TimeArray(
        #             data_ts + Day(t - 1),
        #             get_rating(branch) * get_base_power(sys) * dlr_factors,
        #         )
        # end

        # PowerSystems.add_time_series!(
        #     sys,
        #     branch,
        #     PowerSystems.Deterministic(
        #         "dynamic_line_ratings",
        #         dlr_data;
        #         scaling_factor_multiplier = get_rating,
        #     ),
        # )
    end
end


mip_gap = 0.01
optimizer = optimizer_with_attributes(
                HiGHS.Optimizer,
                #"parallel" => "on",
                "mip_rel_gap" => mip_gap)

sys_name = "modified_RTS_GMLC_DA_sys" #modified_RTS_GMLC_DA_sys, c_sys14
kind_system = PSISystems #PSISystems, PSITestSystems


sys = build_system(kind_system, sys_name)

steps_ts_horizon= 366 #days to run
initial_date = "2020-01-01" #initial date of the simulation
dlr_factors_daily = vcat([fill(x, 6) for x in [1.15, 1.05, 1.1, 1]]...)
dlr_factor_ts_horizon = repeat(dlr_factors_daily, steps_ts_horizon)

branches_dlr_v = ["A2", "A5", "A24", "B8", "B10","B18", "CA-1", "C22", "C34",
                    "A7", "A17", "B14", "B15", "C7", "C17"] # Example branch names, replace with actual branch names that you want to include DLR
add_dlr_to_system_branches!(
    sys,
    branches_dlr_v,
    steps_ts_horizon,
    dlr_factor_ts_horizon,
)

transform_single_time_series!(sys, Hour(48), Day(1))

template_uc =
    ProblemTemplate(
        NetworkModel(PTDFPowerModel;
        reduce_radial_branches = false,
        use_slacks = false,
        ),
    )

set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
set_device_model!(template_uc, RenewableNonDispatch, FixedOutput)
set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
set_device_model!(template_uc, HydroDispatch, HydroDispatchRunOfRiver)


line_device_model = DeviceModel(
    Line,
    StaticBranch;
    time_series_names = Dict(
        DynamicBranchRatingTimeSeriesParameter => "dynamic_line_ratings",
    ))
TapTransf_device_model = DeviceModel(
    TapTransformer,
    StaticBranch;
    time_series_names = Dict(
        DynamicBranchRatingTimeSeriesParameter => "dynamic_line_ratings",
    ))

set_device_model!(template_uc, DeviceModel(TwoTerminalGenericHVDCLine,
                                    HVDCTwoTerminalLossless))

set_service_model!(
    template_uc,
    ServiceModel(VariableReserve{ReserveUp}, RangeReserve, use_slacks = false) 
)
set_service_model!(
    template_uc,
    ServiceModel(VariableReserve{ReserveDown}, RangeReserve, use_slacks = false)
)





model = DecisionModel(
    template_uc,
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

models = SimulationModels(
    decision_models = [model],
)

DA_sequence = SimulationSequence(
    models = models,
    ini_cond_chronology = InterProblemChronology(),
)


current_date = string( today() )
steps_sim = 7
sim = Simulation(
    name = current_date * "_RTS_DA" * "_" * string(steps_sim) * "steps",
    steps = steps_sim,
    models = models,
    initial_time = DateTime(string(initial_date,"T00:00:00")),
    sequence = DA_sequence,
    simulation_folder = tempdir())

build!(sim; console_level = Logging.Info)

execute!(sim)

results = SimulationResults(sim)
uc      = get_decision_problem_results(results, "UC")