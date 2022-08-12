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
%         prescorrcalc vr - 1.0 author - bodc/vidkriv date - 20220810 Changed the coeff for this case id 

function prescorr=prescorrcalc(pres,temp,stcoeff)

% Pressure compensation correction
prescorr=1+((((stcoeff.Pcoef2*temp)+stcoeff.Pcoef3).*pres)/1000);
return
