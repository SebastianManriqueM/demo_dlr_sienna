# demo_dlr_sienna
This is a demo to demonstrate new sienna capabilities with Dynamic Line Ratings (DLR)

## Required Packages

To run the scripts in this repository, install the following Julia packages and branches:

- `DataFrames` v1.7.0
- `HiGHS` v1.18.1
- `HydroPowerSimulations` v0.11.1  
    [`psy5` branch](https://github.com/NREL-Sienna/HydroPowerSimulations.jl.git#psy5)
- `InfrastructureSystems` v2.6.0  
    [`main` branch](https://github.com/NREL-Sienna/InfrastructureSystems.jl.git#main)
- `PowerFlows` v0.9.0  
    [`psy5` branch](https://github.com/NREL-Sienna/PowerFlows.jl.git#psy5)
- `PowerNetworkMatrices` v0.13.0  
    [`mb/ybus-reductions` branch](https://github.com/NREL-Sienna/PowerNetworkMatrices.jl.git#mb/ybus-reductions)
- `PowerSimulations` v0.30.1  
    [`jd/transmissions_sc_ptdf` branch](https://github.com/NREL-Sienna/PowerSimulations.jl.git#jd/transmissions_sc_ptdf)
- `PowerSystemCaseBuilder` v1.3.11  
    (local path: `C:\Users\YOUR_LOCAL_PATH\PowerSystemCaseBuilder.jl`)
- `PowerSystems` v4.6.2  
    [`psy5` branch](https://github.com/NREL-Sienna/PowerSystems.jl.git#psy5)
- `TimeSeries` v0.24.2
- `Dates` v1.11.0
- `Logging` v1.11.0

Make sure to use the specified branches for packages installed from GitHub.

Please clone `PowerSystemCaseBuilder` and `PowerSystemsTestData` repos. Then open `PowerSystemCaseBuilder` and switch to the branch "psy5", in that Branch modify the file "definitions.jl" and change the directory path to PowerSystemsTestData.jl:
```julia
const DATA_DIR =
    joinpath("C:/Users/YOUR_PATH/", "PowerSystemsTestData")
```