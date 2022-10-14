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
% equation 7.2.12 case 201_202_202
%
function doxy=doxy_202(bphase, rphase, pres, temp, psal, coeffs)
    if ~exist('coeffs') 
        error('Error: calibration coefficients not set');
      else
       % set coefficients
       %get only the tab coeff (without C01- c43)
        add_data_coeff('tabCoef',gentabmatrix(coeffs));
        for  ii  =  0:4
          for jj  =  0:3
            fieldname_toremove  =  sprintf('c%d%d',ii,jj);
            remove(coeffs,fieldname_toremove);
          end
        end 
        % set coefficients
        coeffNames=fieldnames(coeffs);
        for i=1:numel(coeffNames)
          eval(['this.' coeffNames{i} '=' num2str(coeffs.(coeffNames{i}),12) ';']);
        end

        % calculate DOXY
        doxy=doxycalc(bphase,rphase,pres,  pres, temp, psal, coeffs);
      end
    end


%generate a matrix of certain coeff
function matrix  =  gentabmatrix(coeffs)
    fields  =  keys(coeffs);
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
            matrix(ii+1,jj+1)  =  coeffs(fieldname);
        end
    end 
end

% calculate the A component of the Salinity correction equation
function a=A(temp,psal,Spreset,coeffs)
    a=(1013.25-ph2ocalc(coeffs,temp,Spreset))./(1013.25-ph2ocalc(coeffs, temp, psal));
end

% calculate pH2O
function ph2o=ph2ocalc(coeffs,temp,salin)
    ph2o=1013.25*exp(coeffs('D0')+coeff('D1')*(100./(temp+273.15))+ ...
                    coeffs('D2')*log((temp+273.15)./100)+coeffs('D3')*salin);
end

% Salinity compensation correction
function salcorr=salcorrcalc(psal,temp, coeffs)
    ts = log((298.15-temp)./(273.15+temp));
    salcorr=A(temp,psal,coeffs('Spreset'),coeffs).*exp(((psal).*(coeffs('B0')+(coeffs('B1').*ts)+...
            (coeffs('B2').*ts.^2)+(coeffs('B3').*ts.^3)))+(coeffs('C0').*(psal.^2-coeffs('Sref').^2)));
end

% calculate Pressure correction
function prescorr=prescorrcalc(pres,temp, coeffs)
    prescorr=1+((((coeffs('Pcoef2')*temp)+coeffs('Pcoef3')).*pres)/1000);
end

 % calculate molardoxy 
function molar_doxy=molardoxycalc(dPhaseDoxy, pres, temp, coeffs)
     
    phasePcorr = dPhaseDoxy + coeffs('Pcoef1') .* pres/1000;
    DPhase = coeffs('PhaseCoef0') + coeffs('PhaseCoef1')*phasePcorr + coeffs('PhaseCoef2')*phasePcorr.^2 + coeffs('PhaseCoef3')*phasePcorr.^3;
    for idCoef = 1:5
        tmpCoef=coeffs('tabCoef')(idCoef, 1) + coeffs('tabCoef')(idCoef, 2)*temp + coeffs('tabCoef')(idCoef, 3)*temp.^2 + coeffs('tabCoef')(idCoef, 4)*temp.^3;
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
    oxy=molardoxycalc(dphase,pres,temp, coeffs).*salcorrcalc(psal,temp).*prescorrcalc(pres,temp, coeffs);
    doxy=oxy./rho';
end




