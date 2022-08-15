% Compute oxygen sensor measurements (BPHASE_DOXY, RPHASE_DOXY) to dissolved oxygen
% measurements (DOXY).
%
% where:
%        rphase, bphase: input phase data
%        pres: pressure measurement values from CTD 
%        temp: temperature measurement values from CTD
%        psal: salinity measurement values from CTD
%
% This covers OPTODES AANDERAA_OPTODE_3830
%
% See https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% equation 7.2.12 case 201_202_202
%
% usage:
%        obj=p2doxy(bphase,rphase,pres,temp,psal,coeffs);
%
%        The derived DOXY can be accessed from the class objects doxy field i.e.
%
%        obj.doxy 
%
%
% title - pdoxy2doxy vr - 1.0 author - bodc/vidkri date - 20220815

classdef phase2doxy
  properties
    % equation calibration coefficients
    Sref = 0,Spreset,
    Pcoef1, Pcoef2,Pcoef3,
    B0,B1,B2,B3,
    C0,
    D0,D1,D2,D3,
    PhaseCoef0, PhaseCoef1, PhaseCoef2, PhaseCoef3,
    tabCoef,
    doxy % DOXY derivation 
  end
  methods
    function this=phase2doxy(bphase,rphase,pres,temp,psal,coeffs)
      if ~exist('coeffs') 
        error('Error: calibration coefficients not set');
      else
       % set coefficients
       %get only the tab coeff (without C01- c43)
        this.tabCoef = gentabmatrix(this,coeffs);
        for  ii  =  0:4
          for jj  =  0:3
            fieldname_toremove  =  sprintf('c%d%d',ii,jj);
            coeffs  =  rmfield(coeffs,fieldname_toremove);
          end
        end 
        % set coefficients
        coeffNames=fieldnames(coeffs);
        for i=1:numel(coeffNames)
          eval(['this.' coeffNames{i} '=' num2str(coeffs.(coeffNames{i}),12) ';']);
        end
        % calculate DOXY
        this.doxy=doxycalc(this,bphase,rphase,pres,temp,psal);
      end
    end

    % calculate DOXY from  Phase
    function doxy=doxycalc(this,bphase,rphase,pres,temp,psal)
      %compute the rphase
      if isempty(rphase), rphase =0; end

      %calculate the phase diff
      dphase = bphase - rphase;

      % compute potential temperature and potential density
      tpot=tetai(pres,temp,psal,0);
      [null,sigma0]=swstat90(psal,tpot,0);
      rho=(sigma0+1000)/1000;

      % compute doxy [umol/kg]
      oxy=molardoxycalc(this,dphase,pres,temp).*salcorrcalc(this,psal,temp).*prescorrcalc(this,pres,temp);
      doxy=oxy./rho';
    end
    
    % calculate molardoxy 
    function molar_doxy=molardoxycalc(this,dPhaseDoxy, pres,temp)
     
     phasePcorr = dPhaseDoxy + this.Pcoef1 .* pres/1000;
     DPhase = this.PhaseCoef0 + this.PhaseCoef1*phasePcorr + this.PhaseCoef2*phasePcorr.^2 + this.PhaseCoef3*phasePcorr.^3;
     for idCoef = 1:5
         tmpCoef=this.tabCoef(idCoef, 1) + this.tabCoef(idCoef, 2)*temp + this.tabCoef(idCoef, 3)*temp.^2 + this.tabCoef(idCoef, 4)*temp.^3;
         eval(['C' num2str(idCoef-1) 'Coef=tmpCoef;']);
     end
     molar_doxy=C0Coef + C1Coef.*DPhase  + C2Coef.*DPhase.^2 + C3Coef.*DPhase.^3 + C4Coef.*DPhase.^4;
    end

    % calculate Pressure correction
    function prescorr=prescorrcalc(this,pres,temp)
      prescorr=1+((((this.Pcoef2*temp)+this.Pcoef3).*pres)/1000);
    end

    % calculate Salinity correction
    function salcorr=salcorrcalc(this,psal,temp)
      % Salinity compensation correction
      ts = log((298.15-temp)./(273.15+temp));
      salcorr=A(this,temp,psal,this.Spreset).*exp(((psal).*(this.B0+(this.B1.*ts)+...
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
    %generate a matrix of certain coeff
    function matrix  =  gentabmatrix(this,stcoeff)
     fields  =  fieldnames(stcoeff);
     mask =  ~cellfun(@isempty,regexp(fields,'^c[0-4][0-3]$'));
     if(sum(mask)~=20)
         error('Doesn''t appear to have the right number of fields');
     end
     %
     %  Pre-allocate
     %
     matrix  =  zeros(5,4);
     for  ii  =  0:4
      for jj  =  0:3
       fieldname  =  sprintf('c%d%d',ii,jj);
       matrix(ii+1,jj+1)  =  stcoeff.(fieldname);
      end
     end 
    end
 end
end
