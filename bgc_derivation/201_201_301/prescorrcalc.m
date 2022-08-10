% Calculate Pressure correction 
% 
% where:
%        pres: pressure measurement values from CTD 
%        temp: temperature measurement values from CTD
%        pCoef2: pressure compensation coefficient 
%        pCoef3: pressure compensation coefficient 
%
%
% See https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% equation 7.2.11 case 201_201_301 
%
% title - prescorrcalc vr - 1.0 author - bodc/qtl date - 20220808

function prescorr=prescorrcalc(pres,temp,pCoef2,pCoef3)

% defaults for pressure coefficients
if nargin<4, pCoef3=0.0328; end
if nargin<3, pCoef2=0.00025; end

% Pressure compensation correction
prescorr=1+((((pCoef2*temp)+pCoef3).*pres)/1000);
