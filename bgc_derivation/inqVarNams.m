function varnams = inqVarNams(ncid, varids)
%
%    varnams = inqVarNams(ncid, varids)
%  where
%    ncid           is a NetCDF file ID
%    varids         is a vector of NetCDF variable IDs
%    varnams        is a cell array of NetCDF variable names
%

% title - s inqVarNams vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%

    varnams = cell(length(varids),1);
    for ii = 1:length(varids)
        varnams{ii} = netcdf.inqVar(ncid,varids(ii));
    end
end