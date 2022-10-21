function chlavars = chlaproc(profvarnams,profvarids,profids,coefs)
%
%    chlavars = chlaproc(profvarnams, profvarids, profids, metaid, metavarnams, 
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
%    chlavars       is a key-value pair structure of processed results
%

% title - s chlaproc vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%

    chlavars = struct(...
        'prof',struct(),...
        'coef',struct(),...
        'out',struct());

    for ii=1:length(profvarnams)
        varid = profvarids{ii}(strcmp(profvarnams{ii},'FLUORESCENCE_CHLA'));
        if(isempty(varid)), continue; end
        FLUORESCENCE_CHLA = netcdf.getVar(profids(ii),varid);
        % Replace fill values with NaNs
        FLUORESCENCE_CHLA(FLUORESCENCE_CHLA == 99999) = nan;
        chlavars.prof.raw = FLUORESCENCE_CHLA;
        break;
    end

    known_darks = {'DARK_CHLA','DARK_CHLA_O','Dark_Counts'};
    known_scales = {'SCALE_CHLA','Scale'};

    chlacoefs = coefs;
    coefkeys = fields(chlacoefs);
    if (any(strcmp(coefkeys, 'CHLA')))
        chlacoefs = chlacoefs.CHLA;
        coefkeys = fields(chlacoefs);
    end

    for ii=1:length(known_darks)
        cmp = strcmp(coefkeys,known_darks{ii});
        if (any(cmp))
            chlavars.coef.dark = chlacoefs.(coefkeys{cmp});
            break;
        end
    end

    for ii=1:length(known_scales)
        cmp = strcmp(coefkeys,known_scales{ii});
        if (any(cmp))
            chlavars.coef.scale = chlacoefs.(coefkeys{cmp});
            break;
        end
    end
    raw = chlavars.prof.raw;
    dark = chlavars.coef.dark;
    scale = chlavars.coef.scale;
    
    % Calculate chla values
    chlavars.out.chla = chlacalc(raw, dark, scale);
end