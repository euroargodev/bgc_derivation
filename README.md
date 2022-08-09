# Argo Biogeochemical Derivations
This is the development branch for an infrastructure agnostic set of common BGC parameter derivation equation functions.

Once validated, they will be published to the https://github.com/argodac GitHub repo, alongside other infrastructure agnostic DAC repos.

This project will initially collate and develop the code for a complete set of derivation equations for:
 - dissolved oxygen
 - pH
 - irradiance
 - chlorophyll fluorescence
 - particle backscatter
 - coloured dissolved organic matter (CDOM)

This project will initially write a Matlab version, and aims to develop a Python version as well.

The aim is to provide a toolbox of functions that anyone can make use of, and where no assumptions are made about wider codebase that is in-use.

The definitions of the BGC parameter derivations are based on those specified in the "Processing BGC-Argo XXX at the DAC level" documents available from:
http://www.argodatamgt.org/Documentation


# How to use it
Broadly speaking, the code for different equations can be used in much the same way. Each (implemented) equation has a corresponding "calc" and "proc" .m file that can be used.

## Submodules
Note that this repo makes use of a [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to include the Gibbs-SeaWater Toolkit. In order to have access to this submodule, use the relevant argument while cloning:
```shell
git clone --recurse-submodules https://github.com/euroargodev/bgc_derivation.git
```
Or use the git submodule commands to pull the submodule after cloning:
```shell
git submodule init
git submodule update
```

## Calc files
Calc code represents the equation and calculation work itself, taking a number of arguments that are up to the user to provide from whatever form they have available. Provided you have the relevant parameters available, you can use a calc function directly to generate some output.
### pH - phcalc.m
The phcalc function ([detailed here](https://archimer.ifremer.fr/doc/00460/57195/)) is provided by MBARI. It is invoked as:
```matlab
[phfree, phtot] = phcalc(Vrs, Press, Temp, Salt, k0, k2, Pcoefs)
```
Where:
- Vrs is the voltage between reference electrode and ISFET source
- Press is pressure values in decibars
- Temp is temperature in degrees C
- Salt is salinity (usually CTD salinity on the PSS)
- k0 is the sensor reference potential (intercept at Temp = 0C)
- k2 is the linear temperature coefficient (slope)
- Pcoefs are sensor dependent pressure coefficients

### Radiometry - radcalc.m
The radcalc function is invoked as:
```matlab
rad = radcal(c, a1, a0, raw, lm)
```
Where:
- c is the conversion unit, usually 1 (or 0.01 for PAR)
- a1 is the calibration coefficient A1 at given wavelength/PAR
- a0 is the calibration coefficient at A0 at given wavelength/PAR
- raw is the downwelling of irradiance at given wavelength OR raw upwelling radiance at given wavelength OR raw photo-synthetically active radation (PAR)
- lm is the calibration coefficient lm at given wavelength/PAR
### Chlorophyll-a - chlacalc.m
The chlacalc function is invoked as:
```matlab
chla = chlacalc(raw, dark, scale)
```
Where:
- raw is the raw counts, i.e. from FLUORESCENCE_CHLA
- dark is the manufacturer dark count or the pre-deployment operator dark count
- scale is the scale factor from the instrument manufacturer characterisation

### Backscatter - bbscalc.m
The bbscalc function is invoked as:
```matlab
bbp = bbscalc(chi, beta, dark, scale, betasw)
```
Where:
- chi is the conversion factor coefficient
- beta is the raw count from backscattering metre
- dark is the raw count from backscattering metre dark count
- scale is the scale factor coefficient
- betasw is the seawater contribution to backscattering coefficient

### Oxygen - Not implemented
Oxygen processing is currently not implemented.

### Nitrate - nitcalc.m
The nitcalc function is invoked as:
```matlab
nitrate = nitcalc(...
    pres, temp, psal,...  % Profile variables
    nitrate_uv, nitrate_uv_dark, nitrate_temp,...  % B-profile variables
    e_nitrate, e_swa_nitrate, optical_wavelength_uv, nitrate_uv_ref, optical_wavelength_offset, fit, temp_cal_nitrate,...  % Coefficients
    eq7
)
```
Where:
- pres is pressure values in decibars
- temp is temperature in degrees C
- psal is salinity
- nitrate_uv is UV intensity nitrate values
- nitrate_uv_dark is UV intensity nitrate dark values
- nitrate_temp is temperature values in degrees C as recorded by the nitrate sensor
- e_nitrate is the E_NTIRATE coefficient values
- optical_wavelength_uv is the OPTICAL_WAVELENGTH_UV coefficient values
- fit is the range of pixel numbers/wavelengths to restrict calculations to
- temp_cal_nitrate is the TEMP_CAL_NITRATE coefficient value
- eq7 is an optional boolean to enable compensation for the pressure effect - note that this is enabled by default when using nitproc or bgcproc!

Note that this function makes use of the gibbs_seawater toolbox, so an addpath must be set before this function can be used outside of bgcproc.

### CDOM - cdomcalc.m
The cdomcalc function is invoked as:
```matlab
cdom = cdomcalc(raw, dark, scale)
```
Where:
- raw is the raw counts output when measuring a sample of interest
- dark is the dark counts coefficient
- scale is the scale factor/multiplier coefficient value 

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

#### Seawater Toolkit Submodule
Note that this function includes an addpath to the Gibbs-SeaWater toolbox submodule, so that [submodule should be cloned](https://git-scm.com/book/en/v2/Git-Tools-Submodules#_cloning_submodules) before this function is used.

Currently, the toolbox is only required for nitrate calculation, but will be required for oxygen in future.
