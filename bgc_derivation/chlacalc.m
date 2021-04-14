function chla = chlacalc(raw, dark, scale)
%
%    chla = chlacalc(raw, dark, scale)
%  where
%    raw            
%    dark           is the manufacturer dark count or the pre-deployment 
%                   operator dark count (from 
%                   PREDEPLOYMENT_CALIB_COEFFICIENT)
%    scale          is the scale factor from instrument manufacturer 
%                   characterisation (from PREDEPLOYMENT_CALIB_COEFFICIENT)
%

% title - s chlacalc vr - 1.0 author - bodc/matcaz, bodc/matdon date - 25012019
%
% mods - 
%

chla = ( raw - dark ) * scale;

end