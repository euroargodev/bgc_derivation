function nitvars = nitproc(profvarnams, profvarids, profids, coefs)

    nc = profids(1);
    core_nc = profids(2);
    varids = profvarids{1};
    varnams = profvarnams{1};
    core_ids = profvarids{2};
    core_nams = profvarnams{2};
    
    nitrate_id = -1;
    nitrate_uv_id = -1;
    nitrate_uv_dark_id = -1;
    nitrate_temp_id = -1;
    
    
    % Get requisite NetCDF variable IDs
    for ii=1:length(varnams)
        switch varnams{ii}
            case 'NITRATE'
                nitrate_id = varids(ii);
            case 'UV_INTENSITY_NITRATE'
                nitrate_uv_id = varids(ii);
            case 'UV_INTENSITY_DARK_NITRATE'
                nitrate_uv_dark_id = varids(ii);
            case 'TEMP_NITRATE'
                nitrate_temp_id = varids(ii);
            case 'PSAL_STD'
        end
    end
    
    for ii=1:length(core_nams)
        switch core_nams{ii}
            case 'PSAL'
                psal_id = core_ids(ii);
                break
        end
    end
    
    if nitrate_id == -1 || nitrate_uv_id == -1 || nitrate_uv_dark_id == -1 || nitrate_temp_id == -1
        error('Nitrate variables are missing from provided NetCDF file!');
    end
    % Get NetCDF variable content
    nc_nitrate = netcdf.getVar(nc, nitrate_id);
    nitrate_uv = netcdf.getVar(nc, nitrate_uv_id);
    nitrate_uv_dark = netcdf.getVar(nc, nitrate_uv_dark_id);
    nitrate_temp = netcdf.getVar(nc, nitrate_temp_id);
    psal = netcdf.getVar(core_nc, psal_id);
    
    if size(nc_nitrate) ~= size(nitrate_temp)
        error('Nitrate Temperature has a size mismatch with Nitrate!');
    end

    % Get NetCDF variable fill values
    [~, nitrate_fill] = netcdf.inqVarFill(nc, nitrate_id);
    [~, nitrate_uv_fill] = netcdf.inqVarFill(nc, nitrate_uv_id);
    [~, nitrate_uv_dark_fill] = netcdf.inqVarFill(nc, nitrate_uv_dark_id);
    [~, nitrate_temp_fill] = netcdf.inqVarFill(nc, nitrate_temp_id);
    
    
    
    % Treat each pixel as a unique array
    [uv_x, ~, ~] = size(nitrate_uv);
    uv_pixels = {};
    for pixel=1:uv_x
        pixel_range = nitrate_uv(pixel, :, :);
        % Discard fill value cycles
        uv_pixels{pixel} = pixel_range(pixel_range ~= nitrate_uv_fill);
    end
    % Drop all but the relevant salinity values
    psal = psal(pixel_range ~= nitrate_uv_fill);
    
    
    % Discard fill value cycles from simple variables
    nitrate_temp = nitrate_temp(nc_nitrate ~= nitrate_fill);
    if any(nitrate_temp == nitrate_temp_fill)
        error('Unexpected fill values in filtered Nitrate temperatures!');
    end
    nc_nitrate = nc_nitrate(nc_nitrate ~= nitrate_fill);
    nitrate_uv_dark = nitrate_uv_dark(nitrate_uv_dark ~= nitrate_uv_dark_fill);
    
    
    
    if size(nc_nitrate) ~= size(uv_pixels{1})
        error('Nitrate UV has size mismatch with Nitrate!');
    end
    if size(nc_nitrate) ~= size(nitrate_uv_dark)
        error('Nitrate UV Dark has size mismatch with Nitrate!');
    end
    % Size of temperature is checked earlier as we have essentially forced
    % the same size here
    
    % Get required coefficients
    a = coefs.A;
    b = coefs.B;
    c = coefs.C;
    d = coefs.D;
    temp_cal_nitrate = coefs.TEMP_CAL_NITRATE;
    optical_wavelength_uv = [coefs.OPTICAL_WAVELENGTH_UV{:}];
    optical_wavelength_offset = coefs.OPTICAL_WAVELENGTH_OFFSET;
    nitrate_uv_ref = [coefs.UV_INTENSITY_REF_NITRATE{:}];
    e_nitrate = [coefs.E_NITRATE{:}];
    e_swa_nitrate = [coefs.E_SWA_NITRATE{:}];
    
    fit = 1:coefs.PIXEL_FIT_END - coefs.PIXEL_FIT_START + 1;
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
    
    inv_abs_cor = {};
    molar_nitrate = [];
    intercept = [];
    slope = [];
    for ii=1:length(nc_nitrate)
        molar_nitrate(ii, :) = m_inv(:, 1)' .* fit_abs_cor(ii, :);
        intercept(ii, :) = m_inv(:, 2)' .* fit_abs_cor(ii, :);
        slope(ii, :) = m_inv(:, 3)' .* fit_abs_cor(ii, :);
    end
    
    
    
    % Eq. 6 - Convert molar nitrate to nitrate
    % TODO

    
    nitvars = {absorbance_sw; e_swa_insitu; absorbance_cor_nitrate; nitrate};
end