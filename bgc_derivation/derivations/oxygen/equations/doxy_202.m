% Salinity and Bittig pressure compensation + unit conversion
% Compute oxygen sensor measurements (BPHASE_DOXY, RPHASE_DOXY) to dissolved oxygen
% measurements (DOXY).
%
% where:
%        rphase, bphase: input phase data
%        pres: pressure measurement values from CTD 
%        temp: temperature measurement values from CTD
%        psal: salinity measurement values from CTD
%        coeffs: Coeff from the predeployment
%
% This covers OPTODES AANDERAA_OPTODE_3830
%
% See https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% equation 7.2.12 case 201_202_202
%
function doxy=doxy_202(bphase, rphase,pres,temp,psal, coeffs)
    if ~exist('coeffs') 
        error('Error: calibration coefficients not set');
      else
       % set coefficients
       %get only the tab coeff (without C01- c43)
        this.tabCoef = gentabmatrix(coeffs);
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
        this.doxy=doxycalc(bphase,rphase,pres,temp,psal);
      end
    end


%generate a matrix of certain coeff
function matrix  =  gentabmatrix(coeffs)
    fields  =  fieldnames(coeffs);
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
            matrix(ii+1,jj+1)  =  coeffs.(fieldname);
        end
    end 
end

% calculate the A component of the Salinity correction equation
function a=A(temp,psal,Spreset)
    a=(1013.25-ph2ocalc(temp,Spreset))./(1013.25-ph2ocalc(temp,psal));
end

% calculate pH2O
function ph2o=ph2ocalc(temp,salin)
    ph2o=1013.25*exp(D0+D1*(100./(temp+273.15))+ ...
                    D2*log((temp+273.15)./100)+D3*salin);
end

% Salinity compensation correction
function salcorr=salcorrcalc(psal,temp)
    ts = log((298.15-temp)./(273.15+temp));
    salcorr=A(temp,psal,Spreset).*exp(((psal).*(B0+(B1.*ts)+...
            (B2.*ts.^2)+(B3.*ts.^3)))+(C0.*(psal.^2-Sref.^2)));
end

% calculate Pressure correction
function prescorr=prescorrcalc(pres,temp)
    prescorr=1+((((Pcoef2*temp)+Pcoef3).*pres)/1000);
end

 % calculate molardoxy 
function molar_doxy=molardoxycalc(dPhaseDoxy, pres,temp)
     
    phasePcorr = dPhaseDoxy + Pcoef1 .* pres/1000;
    DPhase = PhaseCoef0 + PhaseCoef1*phasePcorr + PhaseCoef2*phasePcorr.^2 + PhaseCoef3*phasePcorr.^3;
    for idCoef = 1:5
        tmpCoef=tabCoef(idCoef, 1) + tabCoef(idCoef, 2)*temp + tabCoef(idCoef, 3)*temp.^2 + tabCoef(idCoef, 4)*temp.^3;
        eval(['C' num2str(idCoef-1) 'Coef=tmpCoef;']);
    end
    molar_doxy=C0Coef + C1Coef.*DPhase  + C2Coef.*DPhase.^2 + C3Coef.*DPhase.^3 + C4Coef.*DPhase.^4;
end

% calculate DOXY from  Phase
function doxy=doxycalc(bphase,rphase,pres,temp,psal)
    %compute the rphase
    if isempty(rphase), rphase =0; end

    %calculate the phase diff
    dphase = bphase - rphase;

    % compute potential temperature and potential density
    tpot=tetai(pres,temp,psal,0);
    [null,sigma0]=swstat90(psal,tpot,0);
    rho=(sigma0+1000)/1000;

    % compute doxy [umol/kg]
    oxy=molardoxycalc(dphase,pres,temp).*salcorrcalc(psal,temp).*prescorrcalc(pres,temp);
    doxy=oxy./rho';
end




