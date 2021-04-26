function nitrate = nitcalc(...
    pres, temp, psal,...  % Profile variables
    nitrate_uv, nitrate_uv_dark, nitrate_temp,...  % B-profile variables
    e_nitrate, e_swa_nitrate, optical_wavelength_uv, nitrate_uv_ref, optical_wavelength_offset, fit, temp_cal_nitrate...  % Coefficients
)
%
%    nitrate = nitcalc(pres, temp, psal, nitrate_uv, nitrate_uv_dark,
%    nitrate_temp, e_nitrate, e_swa_nitrate, optical_wavelength_uv,
%    nitrate_uv_ref, optical_wavelength_offset, fit, temp_cal_nitrate)
%  where
%    pres                  is a vector of pressure values
%    temp                  is a vector of temperature values
%    psal                  is a vector of salinity values
%    nitrate_uv            is a vector of UV intensity nitrate values
%    nitrate_uv_dark       is a vector of UV intensity nitrate dark values
%    nitrate_temp          is a vector of temperature values from the nitrate
%                          sensor
%    e_nitrate             is a vector of E_NITRATE coefficient values
%    e_swa_nitrate         is a vector of E_SWA_NITRATE coefficient values
%    optical_wavelength_uv is a vector of OPTICAL_WAVELENGTH_UV coefficient
%                          values
%    fit                   is a vector of pixel numbers/wavelengths to
%                          restrict calculations to
%    temp_cal_nitrate      is the TEMP_CAL_NITRATE coefficient value

% title - s nitcalc vr - 1.0 author - bodc/matcaz date - 2021-04-26
%
% mods -
%
addpath("submodules/gibbs_seawater/Toolbox");
a = 1.1500276;
b = 0.0284;
c = -0.3101349;
d = 0.001222;

fit_e_nitrate = e_nitrate(fit);
fit_wavelength = optical_wavelength_uv(fit);


% Eq. 1 - Calculate seawater spectrum
absorbance_sw = -log10((nitrate_uv - nitrate_uv_dark) ./ nitrate_uv_ref);

% Eq. 2 & 3 - Calculate bromide and sea salt spectrum
f_sw = (a + b .* nitrate_temp)...
    .* exp((c + d .* nitrate_temp) .* (optical_wavelength_uv - optical_wavelength_offset));

f_cal = (a + b .* temp_cal_nitrate)...
    .* exp((c + d .* temp_cal_nitrate) .* (optical_wavelength_uv - optical_wavelength_offset));

e_swa_insitu = e_swa_nitrate .* f_sw ./ f_cal;

% Eq. 4 - Calculate absorbance of nitrate
absorbance_cor_nitrate = absorbance_sw - e_swa_insitu .* psal;

% Eq. 5 - Calculate molar nitrate
fit_abs_cor = absorbance_cor_nitrate(:, fit);
m = [fit_e_nitrate; ones(size(fit_e_nitrate)); fit_wavelength];
m_inv = pinv(m);

dimensions = size(nitrate_uv_dark');
molar_nitrate = nan(dimensions);
intercept = nan(dimensions);
slope = nan(dimensions);

for ii=1:length(nitrate_uv_dark)
    molar_nitrate(ii) = m_inv(:, 1)' * fit_abs_cor(ii, :)';
    intercept(ii) = m_inv(:, 2)' * fit_abs_cor(ii, :)';
    slope(ii) = m_inv(:, 3)' * fit_abs_cor(ii, :)';
end

% Eq. 6 - Convert molar nitrate to nitrate with Argo units
rho = gsw_rho(psal, temp, pres);
nitrate = molar_nitrate' ./ (rho / 1000);
end