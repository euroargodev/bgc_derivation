function nitrate = nitproc(profvarnams, profvarids, profids, coefs)

    addpath("seawater_ver3_2");  % TODO This should be a submodule

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
    for ii=1:length(profvarids)
        varids = profvarids{ii};
        varnams = profvarnams{ii};
        for jj=1:length(varnams)
            switch varnams{jj}
                case 'NITRATE'
                    nitrate_id = varids(jj);
                    nc_nitrate = netcdf.getVar(profids(ii), nitrate_id);
                    [~, nitrate_fill] = netcdf.inqVarFill(profids(ii), nitrate_id);
                case 'UV_INTENSITY_NITRATE'
                    nitrate_uv_id = varids(jj);
                    nitrate_uv = netcdf.getVar(profids(ii), nitrate_uv_id);
                    [~, nitrate_uv_fill] = netcdf.inqVarFill(profids(ii), nitrate_uv_id);
                case 'UV_INTENSITY_DARK_NITRATE'
                    nitrate_uv_dark_id = varids(jj);
                    nitrate_uv_dark = netcdf.getVar(profids(ii), nitrate_uv_dark_id);
                    [~, nitrate_uv_dark_fill] = netcdf.inqVarFill(profids(ii), nitrate_uv_dark_id);
                case 'TEMP_NITRATE'
                    nitrate_temp_id = varids(jj);
                    nitrate_temp = netcdf.getVar(profids(ii), nitrate_temp_id);
                    [~, nitrate_temp_fill] = netcdf.inqVarFill(profids(ii), nitrate_temp_id);
                case 'PSAL'
                    psal_id = varids(jj);
                    psal = netcdf.getVar(profids(ii), psal_id);
                    % (Unused) [~, psal_fill] = netcdf.inqVarFill(core_profids(ii), psal_id);
                case 'PRES'
                    pres_id = varids(jj);
                    pres = netcdf.getVar(profids(ii), pres_id);
                    % (Unused) [~, pres_fill] = netcdf.inqVarFill(core_profids(ii), pres_id);
                case 'TEMP'
                    temp_id = varids(jj);
                    temp = netcdf.getVar(profids(ii), temp_id);
                    % (Unused) [~, temp_fill] = netcdf.inqVarFill(core_profids(ii), temp_id);
            end
        end
    end

    
    if nitrate_id == -1 || nitrate_uv_id == -1 || nitrate_uv_dark_id == -1 || nitrate_temp_id == -1 || pres_id == -1 || temp_id == -1
        error('Nitrate variables are missing from provided NetCDF file!');
    end

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
    pres = pres(pixel_range ~= nitrate_uv_fill);
    temp = temp(pixel_range ~= nitrate_uv_fill);
    
    % Discard fill value cycles from simple variables
    nitrate_temp = nitrate_temp(nc_nitrate ~= nitrate_fill);
    if any(nitrate_temp == nitrate_temp_fill)
        error('Unexpected fill values in filtered Nitrate temperatures!');
    end
    nc_nitrate = nc_nitrate(nc_nitrate ~= nitrate_fill);
    nitrate_uv_dark = nitrate_uv_dark(nitrate_uv_dark ~= nitrate_uv_dark_fill);
    
    % Check our nitrate variables are the right size
    if size(nc_nitrate) ~= size(uv_pixels{1})
        error('Nitrate UV has size mismatch with Nitrate!');
    end
    if size(nc_nitrate) ~= size(nitrate_uv_dark)
        error('Nitrate UV Dark has size mismatch with Nitrate!');
    end
    % Size of temperature is checked earlier as we have essentially forced the same size here
    
    % Get required coefficient values
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
    
    % Calculate nitrate
    nitrate = nitcalc(pres, temp, psal, uv_pixels, nitrate_uv_dark, nitrate_temp, e_nitrate, e_swa_nitrate, optical_wavelength_uv, nitrate_uv_ref, optical_wavelength_offset, fit, temp_cal_nitrate, a, b, c, d);
end