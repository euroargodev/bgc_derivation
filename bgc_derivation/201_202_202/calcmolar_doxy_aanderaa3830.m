%see https://archimer.ifremer.fr/doc/00287/39795/94062.pdf
% equation 7.2.12 case 201_202_202
%
% title - calcmolar_doxy_aanderaa3830 vr - 1.0  author - bodc/vidkri date - 20220810

% OUTPUT PARAMETERS :
%   molarDoxy : MOLAR_DOXY values (in umol/L)
%

function [molarDoxy] = calcmolar_doxy_aanderaa3830( ...
   dPhaseDoxy, pres, temp, stcoeff)

tabCoef = genmatrix(stcoeff)
phasePcorr = dPhaseDoxy + stcoeff.Pcoef1 .* pres/1000;

DPhase = stcoeff.PhaseCoef0 + stcoeff.PhaseCoef1*phasePcorr + stcoeff.PhaseCoef2*phasePcorr.^2 + stcoeff.PhaseCoef3*phasePcorr.^3

for idCoef = 1:5
   tmpCoef = tabCoef(idCoef, 1) + tabCoef(idCoef, 2)*temp + tabCoef(idCoef, 3)*temp.^2 + tabCoef(idCoef, 4)*temp.^3;
   eval(['C' num2str(idCoef-1) 'Coef=tmpCoef;']);
end

molarDoxy = C0Coef + C1Coef.*DPhase  + C2Coef.*DPhase.^2 + C3Coef.*DPhase.^3 + C4Coef.*DPhase.^4;

return
