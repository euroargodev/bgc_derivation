% Compute oxygen sensor measurements (MOLAR_DOXY) to dissolved oxygen
% measurements (DOXY).
%
% where:
%        molar_doxy: sensor output dissolved oxygen concentration [umol/L]
%        pres: pressure measurement values from CTD
%        temp: temperature measurement values from CTD
%        psal: salinity measurement values from CTD
%        coeffs: structure holding the required calibration coefficents.
%
% This covers OPTODES AANDERAA_OPTODE_3830 and AANDERAA_OPTODE_4330 
%
% See https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% equation 7.2.11 case 201_201_301
% equation 7.2.22 case 202_201_301
%
%
%        obj.doxy [umol/kg] 
%
function doxy=doxy_301(molar_doxy,pres,temp,psal,coeffs)
  if ~exist('coeffs') 
    error('Error: calibration coefficients not set');
  else
    % set coefficients
    coeffNames=fieldnames(coeffs);
    for i=1:numel(coeffNames)
      eval(['coeffs.' coeffNames{i} '=' num2str(coeffs.(coeffNames{i}),12) ';']);
    end
    % calculate DOXY
    %set preset = 0 if does not exist
    if ~isfield(coeffs,'Spreset')
        [coeffs(:).Spreset]= 0;
    end
    %check if all coeff required for doxty calc exist
    required_coeffs = {'Sref';'Pcoef2';'Pcoef3';'B0';'B1'; 'B2';'B3';'C0';'D0';'D1';'D3'};
    missing_fields = coeff_check(coeffs, required_coeffs);
    if ~isempty(missing_fields)
        disp('The missing coeffs are:');
        disp(missing_fields);
        error(' Cannot compute Doxy as there are some coeff missing');
    end
    doxy=doxycalc(molar_doxy,pres, temp, psal, coeffs);
  end
end

% calculate DOXY from MOLAR_DOXY
    function doxy=doxycalc(molar_doxy,pres,temp,psal,coeffs)
      % compute potential temperature and potential density
      tpot=tetai(pres,temp,psal,0);
      [null,sigma0]=swstat90(psal,tpot,0);
      rho=(sigma0+1000)/1000;

      % compute doxy [umol/kg]
      oxy=molar_doxy.*salcorrcalc(psal,temp, coeffs).*prescorrcalc(pres,temp, coeffs);
      doxy=oxy./rho';
    end

function prescorr=prescorrcalc(pres,temp, coeffs)
% Pressure compensation correction
    prescorr=1+((((coeffs.Pcoef2*temp)+coeffs.Pcoef3).*pres)/1000);
end
function salcorr=salcorrcalc(psal,temp,coeffs)
% Salinity compensation correction
 ts = log((298.15-temp)./(273.15+temp));
 salcorr=A(temp,psal,coeffs.Spreset, coeffs).*exp(((psal-coeffs.Sref).*(coeffs.B0+(coeffs.B1.*ts)+(coeffs.B2.*ts.^2)+(coeffs.B3.*ts.^3)))+(coeffs.C0.*(psal.^2 -coeffs.Sref.^2)));
end
% Inner function to calculate coefficent A
function a=A(temp,psal,spreset, coeffs)
  a=(1013.25-ph2ocalc(temp,spreset, coeffs))./(1013.25-ph2ocalc(temp,psal, coeffs)); 
end

% Inner function to calculate pH2O
function ph2o=ph2ocalc(temp,salin, coeffs)
  ph2o=1013.25*exp(coeffs.D0+coeffs.D1*(100./(temp+273.15))+coeffs.D2*log((temp+273.15)./100)+coeffs.D3*salin);
end

function missing_fields =coeff_check(coeffs, required_coeffs)
    missing_fields =[]
    for i=1:numel(required_coeffs)
        if ~(isfield(coeffs,string(required_coeffs(i))))
            missing_fields = [missing_fields;string(required_coeffs(i))]
        end
    end

end