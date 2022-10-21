function rad = radcalc(c, a1, a0, raw, lm)
%
%    rad = radcalc(c, a1, a0, raw, lm)
%  where
%    c              is the conversion unit, usually 1 (or 0.01 for PAR)
%    a1             is calibration coefficient A1 at given wavelength/PAR
%                   (from PREDEPLOYMENT_CALIB_COEFFICIENT)
%    a0             is calibration coefficient A0 at given wavelength/PAR
%                   (from PREDEPLOYMENT_CALIB_COEFFICIENT)
%    raw            is the raw downwelling irradiance at given wavelength
%                   OR raw upwelling radiance at given wavelength
%                   OR raw Photo-synthetically Active Radiation (PAR)
%    lm             is calibration coefficient lm at given wavelength/PAR
%                   (from PREDEPLOYMENT_CALIB_COEFFICIENT)
%

% title - s radcalc vr - 1.0 author - bodc/matcaz, bodc/matdon date - 25012019
%
% mods - 
%

rad = c * a1 * (raw - a0) * lm;

end