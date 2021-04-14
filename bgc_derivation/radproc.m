function radvars = radproc(profvarnams,profvarids,profids,coefs)
%
%    radvars = radproc(profvarnams, profvarids, profids, metaid, metavarnams, 
%                       metavarids, coefs)
%  where
%    profvarnams    is a cell array containing cell arrays of profile
%                   NetCDF variable names
%    profvarids     is a cell array containing vectors of profile NetCDF
%                   variable IDs
%    profids        is a vector of profile NetCDF file IDs (ncids)
%    metaid         is a NetCDF file id (ncid) for the relevant meta file
%    metavarnams    is a cell array containing meta NetCDF variable names
%    metavarids     is a vector of meta NetCDF variable IDs
%    coefs          is a key-value pair structure containing metadata from a 
%                   PREDEPLOYMENT_CALIB_COEFFICIENT string
%    radvars        is a key-value pair structure of processed results
%

% title - s radproc vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%

    radvars = struct('prof',struct(),'coef',struct(),'out',struct());
    
    coefkeys = fields(coefs);

    profradkeys = {'RAW_DOWNWELLING_IRRADIANCE','RAW_UPWELLING_RADIANCE','RAW_DOWNWELLING_PAR'};
    coefradkeys = {'A0_','A1_','lm_'};

    for ii=1:length(profradkeys)
        for jj=1:length(profvarnams)
            % Get keys for profile values
            radmask = ~cellfun('isempty',strfind(profvarnams{jj},profradkeys{ii}));
            newradkeys = profvarnams{jj}(radmask);
            radvarids = profvarids{jj}(radmask);
            % Exclude QC variables
            radmask = cellfun('isempty',strfind(newradkeys,'_QC'));
            newradkeys = newradkeys(radmask);
            radvarids = radvarids(radmask);
            for ll=1:length(newradkeys)
                % Add key-value pairs to profile struct
                radvars.prof.(newradkeys{ll}) = netcdf.getVar(profids(jj),radvarids(ll));

                % Replace fill values with NaNs
                radvars.prof.(newradkeys{ll})(radvars.prof.(newradkeys{ll}) == 99999) = nan;
            end
        end
    end

    for ii=1:length(coefradkeys)
        % Get keys for coefficient values
        newradkeys = coefkeys(~cellfun('isempty',strfind(coefkeys,coefradkeys{ii})));
        % Add key-value pairs to coefficient struct
        for jj=1:length(newradkeys)
            radvars.coef.(newradkeys{jj}) = coefs.(newradkeys{jj});
        end
    end


    % Calculate all irradiance values
    radprofkeys = fields(radvars.prof);
    for ii=1:length(radprofkeys)
        % Prepare wavelength-specific variables
        wl = radprofkeys{ii}(end-2:end);
        ispar = strcmp(wl,'PAR');
        if (~ispar), c = 1; else c = 0.01; end
        raw = radvars.prof.(radprofkeys{ii});
        a1 = radvars.coef.(['A1_',wl]);
        a0 = radvars.coef.(['A0_',wl]);
        lm = radvars.coef.(['lm_',wl]);

        % Calculate values
        rad = radcalc(c, a1, a0, raw, lm);
        
        % Generate key
        if (~isempty(strfind(radprofkeys{ii},'UPWELLING')))
            radoutkey = ['UP_RADIANCE',wl];f
        else
            if(ispar)
                radoutkey = 'DOWNWELLING_PAR';
            else
                radoutkey = ['DOWN_IRRADIANCE',wl];
            end
        end

        % Add key-value pair to output struct
        radvars.out.(radoutkey) = rad;
    end
end