function bbp = bbscalc(chi, beta, dark, scale, betasw)
%
%    bbp = bbscalc(chi, beta, dark, scale, betasw)
%  where
%    chi            is the conversion factor (from
%                   PREDEPLOYMENT_CALIB_COEFFICIENT)
%    beta           is the raw count from backscattering meter
%    dark           is the raw count from backscattering meter dark count
%                   test (from PREDEPLOYMENT_CALIB_COEFFICIENT)
%    scale          is the scale factor (from
%                   PREDEPLOYMENT_CALIB_COEFFICIENT)
%    betasw         is the seawater contribution to backscattering (from
%                   PREDEPLOYMENT_CALIB_COEFFICIENT)
%    bbp            is the backscattering at given wavelength
%

% title - s bbscalc vr - 1.0 author - bodc/matcaz, bodc/matdon date - 25012019
%
% mods - 
%

bbp = 2 * pi * chi * ( ( beta - dark ) * scale - betasw );
end
