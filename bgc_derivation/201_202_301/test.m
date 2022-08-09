addpath /users/bodcsoft/matlab/netcdfnew/mp/
addpath /users/bodcsoft/matlab/netcdfnew/ncutility/mp/

ncdox  =  netcdf('/users/qtl/argo/test_data/dac/coriolis/3900515/profiles/BD3900515_010.nc');
ncctd  =  netcdf('/users/qtl/argo/test_data/dac/coriolis/3900515/profiles/D3900515_010.nc');

T=ncctd{'TEMP_ADJUSTED'}(:);
P=ncctd{'PRES_ADJUSTED'}(:);
S=ncctd{'PSAL_ADJUSTED'}(:);

molar_doxy=ncdox{'MOLAR_DOXY'}(:);
maskdoxy=molar_doxy==99999;  %  More properly this should be the fill value
maskctd=S==99999; % as defined in the .nc file
mask=~(maskdoxy & maskctd)';

doxycalc=compute_doxy_201_201_301(molar_doxy(mask),P(mask),T(mask),S(mask));
doxy =ncdox{'DOXY'}(:);

diff=(doxy-doxycalc)'


