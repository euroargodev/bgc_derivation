% Calculate Salinity correction 
% 
% where:
%        temp: temperature measurement values 
%        psal: salinity measurement values
%        sref: reference salinity given in the optode settings
%        spreset: salinity used for the salinity correction
%
%
% See https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% equation 7.2.11 case 201_201_301 
%
% title - salcorrcalc vr - 1.0  author - bodc/qtl date - 20220808

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
