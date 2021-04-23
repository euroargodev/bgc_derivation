function cdom = cdomproc(profvarnams, profvarids, profids, coefs)
    if length(profids) ~= 1
        error('Only one profile is supported for CDOM processing!')
    end
    varids = profvarids{1};
    varnams = profvarnams{1};
    ncid = profids(1);
    
    % Get data from profile NetCDF
    fluorescence_cdom_id = varids(strcmp(varnams, 'FLUORESCENCE_CHLA'));
    fluorescence_cdom = netcdf.getVar(ncid, fluorescence_cdom_id);
    [~, fluorescence_cdom_fill] = netcdf.inqVarFill(ncid, fluorescence_cdom_id);
    % Discard fill values
    fluorescence_cdom = fluorescence_cdom(fluorescence_cdom ~= fluorescence_cdom_fill);
    
    % Get coefficient values
    dark_cdom = coefs.DARK_CDOM;
    scale_cdom = coefs.SCALE_CDOM;
    
    cdom = cdomcalc(fluorescence_cdom, dark_cdom , scale_cdom);
end
