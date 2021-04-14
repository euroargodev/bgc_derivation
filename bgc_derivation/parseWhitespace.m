function outstruct = parseWhitespace(str)
%
%    outstruct = parseWhitespace(str)
%  where
%    str            is a character array of PREDEPLOYMENT_CALIB_COEFFICIENT
%    outstruct      is a key-value pair structure containing parsed
%                   metadata
%

% title - s parseWhitespace vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%

    % Split into chunks of text separated by whitespace
    chunks = delimit(str, ' ');
    chunks = chunks(~cellfun('isempty',chunks));

    % Generate key-pair values based on the position of '=' characters
    for jj=1:length(chunks)
        chunk = chunks{jj};
        if (strcmp(chunk,'=') && jj+1 <= length(chunks) && jj-1 > 0)
            % Sanitise key and convert value if necessary
            outkey = sanitiseField(chunks{jj-1});
            if (isvalidkey(chunks{jj-2}))
                outkey = [chunks{jj-2},'_',outkey];
            end
            outval = chunks{jj+1};
            if strisnumeric(outval)
                outval = str2num(outval);
            end
            outstruct.(outkey) = outval;
        else
            continue;
        end
    end
end