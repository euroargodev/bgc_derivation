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
%         salcorrcalc vr - 1.0  bodc/vidkri date - 20220810- Changed the equation for the case id 201_202_202



function salcorr=salcorrcalc(psal,temp,stcoeff,sref)
% defaults for sfref and sref
if nargin<4, sref=0; end

% Salinity compensation correction
ts = log((298.15-temp)./(273.15+temp));
salcorr=A(temp,psal,stcoeff.Spreset).*exp(((psal).*(stcoeff.B0+(stcoeff.B1.*ts)+(stcoeff.B2.*ts.^2)+(stcoeff.B3.*ts.^3)))+(stcoeff.C0.*(psal.^2 )));

  % Inner function to calculate coefficent A
  function a=A(temp,psal,spreset)
    a=(1013.25-ph2ocalc(temp,spreset))./(1013.25-ph2ocalc(temp,psal)); 
  end

  % Inner function to calculate pH2O
  function ph2o=ph2ocalc(temp,salin)
    ph2o=1013.25*exp(stcoeff.D0+stcoeff.D1*(100./(temp+273.15))+stcoeff.D2*log((temp+273.15)./100)+stcoeff.D3*salin);
  end
end
