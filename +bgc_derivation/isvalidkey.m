function bool = isvalidkey(str)
%
%    bool = isvalidkey(str)
%  where
%    str            is a character or character array
%    bool           is a logical representing the validity of str as a
%                   structure field name
%

% title - s isvalidkey vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%
    bool = ~strisnumeric(str(1)) && all(ismember(str,...
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_'));
end