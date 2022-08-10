% Compute oxygen sensor measurements (MOLAR_DOXY) to dissolved oxygen
% measurements (DOXY). 
% 
% where:
%        dphase: input phase data (diff between blue and red)
%        pres: pressure measurement values from CTD 
%        temp: temperature measurement values from CTD
%        psal: salinity measurement values from CTD
%
%
% See https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% equation 7.2.11 case 201_201_301 
%
% title - compute_doxy_201_201_301 vr - 1.0 author - bodc/qtl date - 20220808

function doxy=compute_doxy_201_201_301(dphase,pres,temp,psal)

% compute potential temperature and potential density
tpot=tetai(pres,temp,psal,0);
[null,sigma0]=swstat90(psal,tpot,0);
rho=(sigma0+1000)/1000;

%compute the molar_doxy
molar_doxy=calcmolar_doxy_aanderaa3830(idphase,pres,temp)

% compute doxy [umol/kg]
oxy=molar_doxy.*salcorrcalc(psal,temp).*prescorrcalc(pres,temp);
doxy=oxy./rho';

