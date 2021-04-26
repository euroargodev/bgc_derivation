function nitrate = nitproc(profvarnams, profvarids, profids, coefs)

    

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
                    [~, psal_fill] = netcdf.inqVarFill(profids(ii), psal_id);
                case 'PRES'
                    pres_id = varids(jj);
                    pres = netcdf.getVar(profids(ii), pres_id);
                    [~, pres_fill] = netcdf.inqVarFill(profids(ii), pres_id);
                case 'TEMP'
                    temp_id = varids(jj);
                    temp = netcdf.getVar(profids(ii), temp_id);
                    [~, temp_fill] = netcdf.inqVarFill(profids(ii), temp_id);
            end
        end
    end

    
    if nitrate_id == -1 || nitrate_uv_id == -1 || nitrate_uv_dark_id == -1 || nitrate_temp_id == -1 || pres_id == -1 || temp_id == -1
        error('Nitrate variables are missing from provided NetCDF file!');
    end

    % Identify the relevant profile to get data from
    profile = any(nc_nitrate ~= nitrate_fill);
    if ~profile
        error('No nitrate data was found!');
    end
    psal = psal(:, profile);
    pres = pres(:, profile);
    temp = temp(:, profile);
    nitrate_temp = nitrate_temp(:, profile);
    nc_nitrate = nc_nitrate(:, profile);
    nitrate_uv = nitrate_uv(:, :, profile)';
    nitrate_uv_dark = nitrate_uv_dark(:, profile);

    % Mask out fill values
    psal(psal == psal_fill) = nan;
    pres(pres == pres_fill) = nan;
    temp(temp == temp_fill) = nan;
    nitrate_temp(nitrate_temp == nitrate_temp_fill) = nan;
    nc_nitrate(nc_nitrate == nitrate_fill) = nan;
    nitrate_uv(nitrate_uv == nitrate_uv_fill) = nan;
    nitrate_uv_dark(nitrate_uv_dark == nitrate_uv_dark_fill) = nan;
    
    % Check our nitrate variables are the right size
    if length(nc_nitrate) ~= length(nitrate_uv)
        error('Nitrate UV has size mismatch with Nitrate!');
    end
    if size(nc_nitrate) ~= size(nitrate_uv_dark)
        error('Nitrate UV Dark has size mismatch with Nitrate!');
    end
    % Size of temperature is checked earlier as we have essentially forced the same size here
    
    % Get required coefficient values
    temp_cal_nitrate = coefs.TEMP_CAL_NITRATE;
    optical_wavelength_uv = [coefs.OPTICAL_WAVELENGTH_UV{:}];
    optical_wavelength_offset = coefs.OPTICAL_WAVELENGTH_OFFSET;
    nitrate_uv_ref = [coefs.UV_INTENSITY_REF_NITRATE{:}];
    e_nitrate = [coefs.E_NITRATE{:}];
    e_swa_nitrate = [coefs.E_SWA_NITRATE{:}];
    fit = 1:coefs.PIXEL_FIT_END - coefs.PIXEL_FIT_START + 1;
    
    % Calculate nitrate
    nitrate = nitcalc(pres, temp, psal, nitrate_uv, nitrate_uv_dark, nitrate_temp, e_nitrate, e_swa_nitrate, optical_wavelength_uv, nitrate_uv_ref, optical_wavelength_offset, fit, temp_cal_nitrate);
end