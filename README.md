# demo_dlr_sienna
This is a demo to demonstrate new sienna capabilities with:
- Dynamic Line Ratings (DLR).
- Security-Constrained Unit commitment (SCUC) (N-1, G-1, and G-1 with reserves deliverability constraints)

## Required Packages

To run the scripts in this repository, install the following Julia packages and branches:

- DataFrames v1.7.0
- HiGHS v1.18.2
- HydroPowerSimulations v0.11.1 `https://github.com/NREL-Sienna/HydroPowerSimulations.jl.git#psy5`
- InfrastructureSystems v2.6.0 `https://github.com/NREL-Sienna/InfrastructureSystems.jl.git#main`
- PowerFlows v0.9.0 `https://github.com/NREL-Sienna/PowerFlows.jl.git#psy5`
- PowerNetworkMatrices v0.13.0 `https://github.com/NREL-Sienna/PowerNetworkMatrices.jl.git#mb/other-fixes-for-psi`
- PowerSimulations v0.30.1 `https://github.com/NREL-Sienna/PowerSimulations.jl.git#sm/scuc_implementations`
- PowerSystemCaseBuilder v1.3.11 `C:\Users\smachado\repositories\PowerSystemCaseBuilder.jl`
- PowerSystems v4.6.2 `https://github.com/NREL-Sienna/PowerSystems.jl.git#psy5`
- Revise v3.8.0
- TimeSeries v0.24.2
- Dates v1.11.0
- Logging v1.11.0

Make sure to use the specified branches for packages installed from GitHub. The folder "demo_dlr_sienna" contains the .toml files so just activating the enviroment and doing "Pkg.instantiate()" you should get the correct branches.

## REPOS YOU'LL NEED TO CLONE
Please clone `PowerSystemCaseBuilder` and `PowerSystemsTestData` repos. 

Then open `PowerSystemCaseBuilder` and switch to the branch "psy5", in that Branch modify the file "definitions.jl" and change the directory path to PowerSystemsTestData.jl:
```julia
const DATA_DIR =
    joinpath("C:/Users/YOUR_PATH/", "PowerSystemsTestData")
```