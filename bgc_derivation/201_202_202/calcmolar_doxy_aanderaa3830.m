%see https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% equation 7.2.12 case 201_202_202
%
% title - calcmolar_doxy_aanderaa3830 vr - 1.0  author - bodc/vidkri date - 20220810

% OUTPUT PARAMETERS :
%   molarDoxy : MOLAR_DOXY values (in umol/L)
%

function [molarDoxy] = calcmolar_doxy_aanderaa3830( ...
   dPhaseDoxy, pres, temp)

% Aanderaa standard calibration method

pCoef1=0.1;

%Phase coeff obtained from 9.2.1.1 of DAC Cookbook (https://archimer.ifremer.fr/doc/00287/39795/94062.pdf)
PCoef0=1.36355e00;
PCoef1=1.12308e00;
PCoef2=0.00000e00;
PCoef3=0.00000e00;

%Coeff to calculate molar doxy obtained from 9.2.1.1 of DAC Cookbook (https://archimer.ifremer.fr/doc/00287/39795/94062.pdf)

tabCoef=[5.21413e+03 -1.67321e+02 3.14576e+00 -2.57702e-02; 
-2.84238e+02 7.89369e+00 -1.39348e-01 -1.09312e-03;
 6.23425e+00 -1.46694e-01 2.40267e-03 -1.75678e-05;
-6.34528e-02 1.24323e-03 -1.86980e-05 1.21236e-07 ;
2.46614e-04 -3.92225e-06 5.3218e-08 -2.70264e-10]

phasePcorr = dPhaseDoxy + pCoef1 .* pres/1000;

DPhase = PCoef0 + PCoef1*phasePcorr + PCoef2*phasePcorr.^2 + PCoef3*phasePcorr.^3

for idCoef = 1:5
   tmpCoef = tabCoef(idCoef, 1) + tabCoef(idCoef, 2)*temp + tabCoef(idCoef, 3)*temp.^2 + tabCoef(idCoef, 4)*temp.^3;
   eval(['C' num2str(idCoef-1) 'Coef=tmpCoef;']);
end

molarDoxy = C0Coef + C1Coef.*DPhase  + C2Coef.*DPhase.^2 + C3Coef.*DPhase.^3 + C4Coef.*DPhase.^4;

return
