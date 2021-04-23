function nitrate = nitcalc(pres, temp, psal, uv_pixels, nitrate_uv_dark, nitrate_temp, e_nitrate, e_swa_nitrate, optical_wavelength_uv, nitrate_uv_ref, optical_wavelength_offset, fit, temp_cal_nitrate, a, b, c, d)
    addpath("submodules/gibbs_seawater/Toolbox");

    fit_e_nitrate = e_nitrate(fit);
    fit_wavelength = optical_wavelength_uv(fit);
    

    % Eq. 1 - Calculate seawater spectrum
    absorbance_sw = -log10(([uv_pixels{:}] - nitrate_uv_dark) ./ nitrate_uv_ref);
    
    % Eq. 2 & 3 - Calculate bromide and sea salt spectrum
    f_sw = (a + b .* nitrate_temp) .* exp((c + d .* nitrate_temp) .* (optical_wavelength_uv - optical_wavelength_offset));
    f_cal = (a + b .* temp_cal_nitrate) .* exp((c + d .* temp_cal_nitrate) .* (optical_wavelength_uv - optical_wavelength_offset));
    e_swa_insitu = e_swa_nitrate .* f_sw ./ f_cal;
    
    % Eq. 4 - Calculate absorbance of nitrate
    absorbance_cor_nitrate = absorbance_sw - e_swa_insitu .* psal;
    
    % Eq. 5 - Calculate NITRATE and convert to Argo units
    fit_abs_cor = absorbance_cor_nitrate(:, fit);
    m = [fit_e_nitrate; ones(size(fit_e_nitrate)); fit_wavelength];
    m_inv = pinv(m);
    
    molar_nitrate = [];
    intercept = [];
    slope = [];
    for ii=1:length(nitrate_uv_dark)
        molar_nitrate(ii, :) = m_inv(:, 1)' * fit_abs_cor(ii, :)';
        intercept(ii, :) = m_inv(:, 2)' * fit_abs_cor(ii, :)';
        slope(ii, :) = m_inv(:, 3)' * fit_abs_cor(ii, :)';
    end
    
    % Eq. 6 - Convert molar nitrate to nitrate
    rho = gsw_rho(psal, temp, pres);
    nitrate = molar_nitrate ./ (rho / 1000);
end