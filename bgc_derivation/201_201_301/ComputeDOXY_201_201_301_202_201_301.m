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
% This covers OPTODES AANDERAA_OPTODE_4330 and AANDERAA_OPTODE_4330 
%
% See https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% equation 7.2.11 case 201_201_301
% equation 7.2.22 case 202_201_301
%
% usage:
%        obj=ComputeDOXY_201_201_301_202_201_201(molar_doxy(mask),P(mask),T(mask),S(mask),stcoeff);
%
%        The derived DOXY output can be accessed from the class objects doxy field i.e.
%
%        obj.doxy 
%
%
% title - ComputeDOXY_201_201_301_202_201_301 vr - 1.0 author - bodc/qtl date - 20220808

classdef ComputeDOXY_201_201_301_202_201_301
  properties
    % equation calibration coefficients
    Sref,Spreset,
    Pcoef2,Pcoef3,
    B0,B1,B2,B3,
    C0,
    D0,D1,D2,D3,
    doxy % DOXY derivation 
  end
  methods
    function this=ComputeDOXY_201_201_301_202_201_301(molar_doxy,pres,temp,psal,coeffs)
      if ~exist('coeffs') 
        error('Error: calibration coefficients not set');
      else
        % set coefficients
        coeffNames=fieldnames(coeffs);
        for i=1:numel(coeffNames)
          eval(['this.' coeffNames{i} '=' num2str(coeffs.(coeffNames{i}),12) ';']);
        end
        % calculate DOXY
        this.doxy=doxycalc(this,molar_doxy,pres,temp,psal);
      end
    end

    % calculate DOXY from MOLAR_DOXY
    function doxy=doxycalc(this,molar_doxy,pres,temp,psal)
      % compute potential temperature and potential density
      tpot=tetai(pres,temp,psal,0);
      [null,sigma0]=swstat90(psal,tpot,0);
      rho=(sigma0+1000)/1000;

      % compute doxy [umol/kg]
      oxy=molar_doxy.*salcorrcalc(this,psal,temp).*prescorrcalc(this,pres,temp);
      doxy=oxy./rho';
    end

    % calculate Pressure correction
    function prescorr=prescorrcalc(this,pres,temp)
      prescorr=1+((((this.Pcoef2*temp)+this.Pcoef3).*pres)/1000);
    end

    % calculate Salinity correction
    function salcorr=salcorrcalc(this,psal,temp)
      % Salinity compensation correction
      ts = log((298.15-temp)./(273.15+temp));
      salcorr=A(this,temp,psal,this.Spreset).*exp(((psal-this.Sref).*(this.B0+(this.B1.*ts)+...
               (this.B2.*ts.^2)+(this.B3.*ts.^3)))+(this.C0.*(psal.^2-this.Sref.^2)));
    end

    % calculate the A component of the Salinity correction equation
    function a=A(this,temp,psal,Spreset)
      a=(1013.25-ph2ocalc(this,temp,Spreset))./(1013.25-ph2ocalc(this,temp,psal));
    end

    % calculate pH2O
    function ph2o=ph2ocalc(this,temp,salin)
      ph2o=1013.25*exp(this.D0+this.D1*(100./(temp+273.15))+ ...
                       this.D2*log((temp+273.15)./100)+this.D3*salin);
    end
  end
end
