function updateCoefs(meta,newcoefs)
%
%    updateCoefs(fullstring)
%  where
%    meta           is the path to a meta NetCDF file
%    newcoefs       is a struct of new keys and values to add to the
%                   meta NetCDF file's coefficient string
%

% title - s updateCoefs vr - 1.0 author - bodc/matcaz date - 25012019
%
% mods - 
%

% Open and read from NetCDF
ncid = netcdf.open(meta,'write');
metavarids = inqVarIDs(ncid);
metavarnams = inqVarNams(ncid,metavarids);

% Get string from NetCDF
coefid = find(strcmp(metavarnams, 'PREDEPLOYMENT_CALIB_COEFFICIENT'));
coefstring = netcdf.getVar(ncid,metavarids(coefid));

% Generate coefficient struct
coefs = getCoefs(coefstring);

% Create new, empty coefficient string
strsiz = size(coefstring);
strlen = strsiz(1) * strsiz(2);
coefstring = char(ones(1,strlen) * 32);

% Merge old and new coefficient structures
keys = fields(newcoefs);
for ii=1:length(keys)
    coefs.(keys{ii}) = newcoefs.(keys{ii});
end
keys = fields(coefs);

% Insert key-value pairs into new coefficient string
scan = 1;
for ii=1:length(keys)
    value = coefs.(keys{ii});
    if (isscalar(value) || ischar(value))
        if (isnumeric(value))
            value = num2str(value);
        end
        pair = [keys{ii},'=',value,'; '];
        if (scan + length(pair) + 1 > length(coefstring))
            error('Coefficient string length limit exceeded!');
        end
        coefstring(scan+1:scan+length(pair)) = pair;
        scan = scan + length(pair);
    else
        error('Sorry, only scalar values and character arrays are supported at this time!');
    end
end

% Write updated coefficient string
netcdf.putVar(ncid,coefid,transpose(coefstring));

netcdf.close(ncid);

end