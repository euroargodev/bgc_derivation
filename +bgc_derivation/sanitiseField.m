function sanitised = sanitiseField(str)
%
%    sanitised = sanitiseField(str)
%  where
%    str            is a character vector for a structure field
%                   name
%    sanitised      is a character vector for sanitised, valid field name
%

% title - s sanitiseField vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%
    mask = ismember(str,'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890');
    sanitised = str(mask);
end