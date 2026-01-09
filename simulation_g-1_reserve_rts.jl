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
using Dates
using TimeSeries
using HiGHS

mip_gap = 0.01
optimizer = optimizer_with_attributes(
                HiGHS.Optimizer,
                #"parallel" => "on",
                "mip_rel_gap" => mip_gap)

sys_name = "modified_RTS_GMLC_DA_sys" #modified_RTS_GMLC_DA_sys, c_sys14
kind_system = PSISystems #PSISystems, PSITestSystems


sys = build_system(kind_system, sys_name)