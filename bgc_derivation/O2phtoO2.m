function DOXY  =  O2phtoO2(stc,PHASE_DELAY_DOXY,PRES, TEMP_DOXY, PSAL)
%
%     DOXY  =  O2phtoO2(stc,PHASE_DELAY_DOXY,PRES, TEMP_DOXY, PSAL)
%  where
%     stc   is the structure containing the desired coefficients.
%           This is normally abstracted by getPredeploymentCoefficients
%           from the float's NC metadata file
%    PHASE_DELAY_DOXY   BGC variable
%    PRES               CTD variable
%    TEMP_DOXY          BGC variable
%    PSAL               CTD variable
%
%  Note that if stc doesn't have coefficients D0-D3 (used for pH) the 
%  defaults are added to the structure. Of course this doesn't affect
%  the argument provided

%
%  Defaults forpH20 - replacement not done partially
%
  if(~isfield(stc,'D0'))
    stc.D0 = 24.4543; 
    stc.D1  =  -67.4509;
    stc.D2  =  -4.8489;
    stc.D3  =  -5.44e-4;
  end

V=(PHASE_DELAY_DOXY+stc.Pcoef1*PRES./1000)/39.457071; 
Ksv=stc.C0+stc.C1.*TEMP_DOXY+stc.C2*TEMP_DOXY.^2;

MLPL_DOXY=((stc.A0+stc.A1.*TEMP_DOXY+stc.A2*V.*V)./(stc.B0+stc.B1*V)-1)./Ksv; 
Pcorr=1+((stc.Pcoef2*TEMP+stc.Pcoef3).*PRES)/1000; 
TS=log((298.15-TEMP)./(273.15+TEMP));

pH2O=1013.25*exp(stc.D0+stc.D1*(100./(TEMP+273.15))+...
     stc.D2*log((TEMP+273.15)/100)+stc.D3*S); 
A=(1013.25-pH2O)./(1013.25-pH2O);
Scorr=A*exp(PSAL*(stc.SolB0+stc.SolB1*TS+stc.SolB2*TS^2+...
    stc.SolB3*TS.^3)+stc.SolC0*PSAL.^2); 
O2=MLPL_DOXY*Scorr*Pcorr; 
%
%  calculate density
%
tpot=tetai(PRES,TEMP_DOXY,PSAL,0);
[~,sigma0]=swstat90(PSAL,tpot,0);
rho=(sigma0+1000)/1000; 

DOXY=44.6596*O2/rho;