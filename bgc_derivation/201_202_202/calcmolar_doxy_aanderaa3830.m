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

PCoef0=2.55824e00;
PCoef1=1.11436e00
PCoef2=0.00000e00;
PCoef3=0.00000e00;


%Coeff to calculate molar doxy obtained from 9.2.1.1 of DAC Cookbook (https://archimer.ifremer.fr/doc/00287/39795/94062.pdf)

tabCoef=[5.32650e+03 -1.92117e02 4.14357e00 -3.78695e-02;
-2.92068e02 9.71993e00 -2.14295e-01 2.00778e-03;
6.4759e00 -1.98080e-01 4.49940e-03 -4.30530e-05;
-6.69288e-02 1.88066e-03 -4.42348e-05 4.28382e-07 ;
2.6504e-04 -6.83185e-06 1.67071e-07 -1.61989e-09]

phasePcorr = dPhaseDoxy + pCoef1 .* pres/1000;

DPhase = PCoef0 + PCoef1*phasePcorr + PCoef2*phasePcorr.^2 + PCoef3*phasePcorr.^3

for idCoef = 1:5
   tmpCoef = tabCoef(idCoef, 1) + tabCoef(idCoef, 2)*temp + tabCoef(idCoef, 3)*temp.^2 + tabCoef(idCoef, 4)*temp.^3;
   eval(['C' num2str(idCoef-1) 'Coef=tmpCoef;']);
end

molarDoxy = C0Coef + C1Coef.*DPhase  + C2Coef.*DPhase.^2 + C3Coef.*DPhase.^3 + C4Coef.*DPhase.^4;

return
