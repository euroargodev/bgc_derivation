function cellout = delimit(str,delimiter)
%
%    cellout = delimit(str,delimiter)
%  where
%    str            is the input character array to be split
%    cellout        is a cell array of delimited results
%

% title - s delimit vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%

    steps = strfind(str,delimiter); % Indexes of delimiters in string
    cellout = cell(length(steps)-1,1); % Output cell array
    last = 1;
    for ii=1:length(steps)
        cellout{ii} = str(last+1:steps(ii)-1);
        last = steps(ii);
    end
    cellout{1} = [str(1),cellout{1}];
    fin = str(steps(end)+1:end);
    if (~isempty(fin))
        cellout{end+1} = fin;
    end
end