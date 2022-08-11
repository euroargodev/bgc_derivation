function doxy=doxy_301(molar_doxy,pres,temp,psal)
% Example code - not known to be correct.
% Salinity and Bittig pressure compensation + unit conversion

% compute potential temperature and potential density
tpot=tetai(pres,temp,psal,0);
[~,sigma0]=swstat90(psal,tpot,0);
rho=(sigma0+1000)/1000;

% compute doxy [umol/kg]
oxy=molar_doxy.*salcorrcalc(psal,temp).*prescorrcalc(pres,temp);
doxy=oxy./rho';
end



function prescorr=prescorrcalc(pres,temp,pCoef2,pCoef3)

% defaults for pressure coefficients
if nargin<4, pCoef3=0.0328; end
if nargin<3, pCoef2=0.00025; end

% Pressure compensation correction
prescorr=1+((((pCoef2*temp)+pCoef3).*pres)/1000);
end

function salcorr=salcorrcalc(psal,temp,sref,spreset)

% defaults for sfref and spreset
if nargin<5, spreset=0; end
if nargin<4, sref=0; end

% Co-efficients
B0=-6.24523e-3;
B1=-7.37614e-3;
B2=-1.03410e-2;
B3=-8.17083e-3; 
C0=-4.88682e-7;
D0=24.4543;
D1=-67.4509; 
D2=-4.8489;
D3=-5.44e-4;

% Salinity compensation correction
ts = log((298.15-temp)./(273.15+temp));
salcorr=A(temp,psal,spreset).*exp(((psal-sref).*(B0+(B1.*ts)+(B2.*ts.^2)+(B3.*ts.^3)))+(C0.*(psal.^2 -sref.^2)));

  % Inner function to calculate coefficent A
  function a=A(temp,psal,spreset)
    a=(1013.25-ph2ocalc(temp,spreset))./(1013.25-ph2ocalc(temp,psal)); 
  end

  % Inner function to calculate pH2O
  function ph2o=ph2ocalc(temp,salin)
    ph2o=1013.25*exp(D0+D1*(100./(temp+273.15))+D2*log((temp+273.15)./100)+D3*salin);
  end
end
