addpath /users/bodcsoft/matlab/netcdfnew/mp/
addpath /users/bodcsoft/matlab/netcdfnew/ncutility/mp/
addpath /users/argo/sware/decArgo_20220111_046j/decArgo_soft/soft/sub_foreign/

ncdox  =  netcdf('/users/qtl/argo/test_data/dac/coriolis/3900515/profiles/BD3900515_010.nc');
ncctd  =  netcdf('/users/qtl/argo/test_data/dac/coriolis/3900515/profiles/D3900515_010.nc');

%T=ncctd{'TEMP_ADJUSTED'}(:);
%P=ncctd{'PRES_ADJUSTED'}(:);
%S=ncctd{'PSAL_ADJUSTED'}(:);

T=ncctd{'TEMP'}(:);
S=ncctd{'PSAL'}(:);
P=ncctd{'PRES'}(:);

LAT=ncctd{'LATITUDE'}(:);
LON=ncctd{'LONGITUDE'}(:);

molar_doxy=ncdox{'MOLAR_DOXY'}(:);
maskdoxy=molar_doxy==99999;  %  More properly this should be the fill value
maskctd=S==99999; % as defined in the .nc file
mask=~(maskdoxy | maskctd)';

doxycalc_old=compute_doxy_201_201_301(molar_doxy(mask),P(mask),T(mask),S(mask));
doxycalc=compute_doxy_201_201_301_new_rho(molar_doxy(mask),P(mask),T(mask),S(mask),LAT,LON);

doxy =ncdox{'DOXY'}(:);

diffold=(doxy-doxycalc_old)';
diff=(doxy-doxycalc)';

[doxy; doxycalc; diff'; diffold']'

%min(diff)
%max(diff)
