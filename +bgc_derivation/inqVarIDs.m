function varids = inqVarIDs(ncid)
%
%    varnams = inqVarIDs(ncid)
%  where
%    ncid           is a NetCDF file ID
%    varids         is a vector of NetCDF variable IDs
%

% title - s inqVarIDs vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%
    % Replacement function
    [~,nvars,~,~] = netcdf.inq(ncid);
    varids = transpose(0:nvars-1);
end