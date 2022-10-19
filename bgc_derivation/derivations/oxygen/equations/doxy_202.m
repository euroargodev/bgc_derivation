% Salinity and Bittig pressure compensation + unit conversion
% Compute oxygen sensor measurements (BPHASE_DOXY, RPHASE_DOXY) to dissolved oxygen
% measurements (DOXY).
%
% where:
%        rphase, bphase: input phase data
%        coeffs: Coeff from the predeployment
%        pres: pressure measurement values from CTD 
%        temp: temperature measurement values from CTD
%        psal: salinity measurement values from CTD
%
% This covers OPTODES AANDERAA_OPTODE_3830
%
% See https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% See the following for the constants that are used fo various corrections
% DOI: https://dx.doi.org/10.13155/39795  version 2.3.3
%
% equation 7.2.12 case 201_202_202
%
function doxy=doxy_202(bphase, rphase, pres, temp, psal,coeffs)
    %setting the Spreset = 0
    [coeffs.Spreset]= 0;
    %get only the tab coeff (without C01- c43)
    matrix = gentabmatrix(coeffs);
    [coeffs(:).tabCoef]= matrix;
    for  ii  =  0:4
      for jj  =  0:3
        fieldname_toremove  =  sprintf('OptodeCalibrationC%dCoef%d',ii,jj);
        coeffs  =  rmfield(coeffs,fieldname_toremove);
      end
    end 
    % set coefficients
    coeffNames=fieldnames(coeffs);
    for i=1:numel(coeffNames) -1
      eval(['coeffs.' coeffNames{i} '=' num2str(coeffs.(coeffNames{i}),12) ';']);
    end
   
    % calculate DOXY
    doxy=doxycalc(bphase,rphase, pres, temp, psal, coeffs);
end


%generate a matrix of certain coeff
function matrix  =  gentabmatrix(coeffs)
    fields  =  fieldnames(coeffs);
    mask =  ~cellfun(@isempty,regexp(fields,'^OptodeCalibrationC[0-4]Coef[0-3]$'));
    if(sum(mask)~=20)
        error('Doesn''t appear to have the right number of fields');
    end
    %
    %  Pre-allocate
    %
    matrix  =  zeros(5,4);
    for  ii  =  0:4
        for jj  =  0:3
            fieldname  =  sprintf('OptodeCalibrationC%dCoef%d',ii,jj);
            matrix(ii+1,jj+1)  = coeffs.(fieldname);
        end
    end 
end

% calculate the A component of the Salinity correction equation
function a=A(temp,psal,Spreset)
    a=(1013.25-ph2ocalc(temp,Spreset))./(1013.25-ph2ocalc(temp, psal));
end

% calculate pH2O
function ph2o=ph2ocalc(temp,salin)
    %SCOR WG (SCOR Working Group 142 on "Quality Control Procedures for Oxygen and Other Biogeochemical Sensors on Floats and Gliders" [RD13]
    D0 = 24.4543
    D1 = -67.4509
    D2 = -4.8489
    D3 = -5.44E-4
    ph2o=1013.25*exp(D0+D1*(100./(temp+273.15))+ ...
                    D2*log((temp+273.15)./100)+D3*salin);
end

% Salinity compensation correction
function salcorr=salcorrcalc(psal,temp, coeffs)
    % set the fixed coefficients
    % 4.2.4.2 SCOR WG 142 recommendation for Salinity Compensation coefficients
    B0 = -6.24523E-3; % fixed constant
    B1 = -7.37614E-3; % fixed constant
    B2 = -1.03410E-3; % fixed constant
    B3 = -8.17083E-3; % fixed constant
    C0 = -4.88682E-7; % fixed constant

    ts = log((298.15-temp)./(273.15+temp));
    salcorr=A(temp,psal,coeffs.Spreset).*exp(((psal).*(B0+(B1.*ts)+...
            (B2.*ts.^2)+(B3.*ts.^3)))+(C0.*(psal.^2-coeffs.OptodeCalibrationSalinity.^2)));
end

% calculate Pressure correction
function prescorr=prescorrcalc(pres,temp)
    %constants for pressure correction
    Pcoef2 = 0.00022 ; % fixed constant 
    Pcoef3 = 0.0419 ;% fixed constant
    prescorr=1+((((Pcoef2*temp)+Pcoef3).*pres)/1000);
end

 % calculate molardoxy 
function molar_doxy=molardoxycalc(dPhaseDoxy, pres, temp, coeffs)
    % BPhase / TCPhase has been corrected for the pressure effect
    Pcoef1 = 0.1; % fixed constant


    phasePcorr = dPhaseDoxy + Pcoef1.* pres/1000;
    DPhase = coeffs.OptodeCalibrationPhaseCoef0+ coeffs.OptodeCalibrationPhaseCoef1*phasePcorr + coeffs.OptodeCalibrationPhaseCoef2*phasePcorr.^2 + coeffs.OptodeCalibrationPhaseCoef3*phasePcorr.^3;
    for idCoef = 1:5
        tmpCoef=coeffs.tabCoef(idCoef, 1) + coeffs.tabCoef(idCoef, 2)*temp + coeffs.tabCoef(idCoef, 3)*temp.^2 + coeffs.tabCoef(idCoef, 4)*temp.^3;
        eval(['C' num2str(idCoef-1) 'Coef=tmpCoef;']);
    end
    molar_doxy=C0Coef + C1Coef.*DPhase  + C2Coef.*DPhase.^2 + C3Coef.*DPhase.^3 + C4Coef.*DPhase.^4;
end

% calculate DOXY from  Phase
function doxy=doxycalc(bphase,rphase,pres,temp,psal, coeffs)
    %compute the rphase
    if isempty(rphase), rphase =0; end

    %calculate the phase diff
    dphase = bphase - rphase;

    % compute potential temperature and potential density
    tpot=tetai(pres,temp,psal,0);
    [null,sigma0]=swstat90(psal,tpot,0);
    rho=(sigma0+1000)/1000;

    % compute doxy [umol/kg]
    oxy=molardoxycalc(dphase,pres,temp, coeffs).*salcorrcalc(psal,temp, coeffs).*prescorrcalc(pres,temp);
    doxy=oxy./rho';
end




