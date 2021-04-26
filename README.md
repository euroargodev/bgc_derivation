# Argo Biogeochemical Derivations
This is the development branch for an infrastructure agnostic set of common BGC parameter derivation equation functions.

Once validated, they will be published to the https://github.com/argodac GitHub repo, alongside other infrastructure agnostic DAC repos.

This project will initially collate and develop the code for a complete set of derivation equations for:
 - dissolved oxygen
 - pH
 - irradiance
 - chlorophyll fluorescense
 - particle backscatter
 - coloured dissolved organic matter (CDOM)

This project will initially write a Matlab version, and aims to develop a Python version as well.

The aim is to provide a toolbox of functions that anyone can make use of, and where no assumptions are made about wider codebase that is in-use.

The definitions of the BGC parameter derivations are based on those specified in the "Processing BGC-Argo XXX at the DAC level" documents available from:
http://www.argodatamgt.org/Documentation


# How to use it
Broadly speaking, the code for different equations can be used in much the same way. Each (implemented) equation has a corresponding "calc" and "proc" .m file that can be used.
## Calc files
Calc code represents the equation and calculation work itself, taking a number of arguments that are up to the user to provide from whatever form they have available. Provided you have the relevant parameters available, you can use a calc function directly to generate some output.
### pH - phproc


### Radiometry - radproc.m

### Chlorophyll-a - chlaproc.m

### Backscatter - bbsproc.m

### Oxygen - Not implemented
Oxygen processing is currently not implemented.

### Nitrate - nitproc.m

### CDOM - cdomproc.m


## Proc files
Proc code deals with interrogating Argo NetCDF profiles to source the required parameters for the relevant calc function. Note that the proc functions are not guaranteed to work with specific float models, though they can hopefully still serve as helpful examples.

The proc functions are invoked as:
```matlab
output = somethingproc(profvarnams, profvarids, profids, coefs)
```
Where:
- profvarnams is a cell array containing cell arrays of profile NetCDF variable names. Each top-level cell array represents variables from a single NetCDF file.
- profvarids is a cell array containing vectors of profile NetCDF variable IDs. Each vector represents variables from a single NetCDF file.
- profids is a vector of profile or B-profile NetCDF file IDs (files should be of a single profile, i.e. with no duplicate variables) to read data from.
- coefs is a key-value pair structure containing metadata from a PREDEPLOYMENT_CALIB_COEFFICIENT string, from a meta NetCDF file.
- output is the derived output, depending on which derivation is being used

Note that the items of profvarnams, profvarids and profids will be matched against eachother, so the indexes of cell arrays and vectors must match the variable ID/name and NetCDF ID.

### bgcproc
There is also a generic "bgcproc" function that takes in profile and meta NetCDF files as well as flags to determine which derivations are to be employed.
```matlab
output = bgcproc(profin, metain, ['-f'], [filout], ['-ph'], ['-rad'], ['-chla'], ['-bbs'], ['-nit'], ['-cdom']) 
```
Where:
- profin is a cell array of paths to profile or B-profile NetCDF files (as previously, these should be of a single profile only).
- metain is a path to a single meta NetCDF file, corresponding to the profile NetCDFs provided.
- -f is an optional flag to save the derived output to a .mat file.
- filout is the path to the output file, if -f is used.
- -ph is an optional flag to enable pH processing.
- -rad is an optional flag to enable radiometry processing.
- -chla is an optional flag to enable chlorophyll-a processing.
- -bbs is an optional flag to enable backscatter processing.
- -nit is an optional flag to enable nitrate processing.
- -cdom is an optional flag to enable CDOM processing.
