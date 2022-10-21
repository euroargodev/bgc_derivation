function bool = strisnumeric(str)
%
%    bool = strisnumeric(str)
%  where
%    str            is a character or character array
%    bool           is a logical representing the numeric status of str
%

% title - s strisnumeric vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%
    if (length(str) > 1)
        bool = all(ismember(str,'1234567890.+-dDeEiI'));
    else
        bool = all(ismember(str,'1234567890'));
    end
end