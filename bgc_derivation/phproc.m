function phvars = phproc(profvarnams,profvarids,profids,coefs)
%
%    phvars = phproc(profvarnams, profvarids, profids, metaid, metavarnams, 
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
%    phvars         is a key-value pair structure of processed results
%

% title - s phproc vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%

    phvars = struct(...
        'prof',struct('VRS_PH',nan,'PRES',nan,'TEMP_PH',nan,'PSAL',nan),...
        'coef',struct('k0',nan,'k2',nan,'f1',nan,'f2',nan,'f3',nan,'f4',nan,'f5',nan),...
        'out',struct('phfree',nan,'phtot',nan));

    profphkeys = fields(phvars.prof);
    coefphkeys = fields(phvars.coef);

    for ii=1:length(profvarnams)
        for jj=1:length(profphkeys)
            if (isnan(phvars.prof.(profphkeys{jj})))
                keymask = strcmp(profvarnams{ii},profphkeys{jj});
                if any(keymask)
                    varid = profvarids{ii}(keymask);
                    ncvar = netcdf.getVar(profids(ii),varid);
                    % Replace fill values with NaNs.
                    ncvar(ncvar == 99999) = nan;
                    phvars.prof.(profphkeys{jj}) = dropfills(ncvar,99999);
                end
            end
        end
    end


    for ii=1:length(coefphkeys)
        if (isfield(coefs,coefphkeys{ii}))
            phvars.coef.(coefphkeys{ii}) = coefs.(coefphkeys{ii});
        else
            procph = false;
            break;
        end
    end

    [phvars.out.phfree,phvars.out.phtot] = phcalc(...
        phvars.prof.VRS_PH,phvars.prof.PRES,phvars.prof.TEMP_PH,phvars.prof.PSAL,...
        phvars.coef.k0,phvars.coef.k2,[phvars.coef.f1;phvars.coef.f2;...
        phvars.coef.f3;phvars.coef.f4;phvars.coef.f5]);


end