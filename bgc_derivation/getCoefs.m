function coefs = getCoefs(fullstring)
%
%    coefs = getCoefs(fullstring)
%  where
%    fullstring     is a full, unmodified coefficient string
%    coefs          is a structure of parsed key-value pairs from
%                   fullstring
%

% title - s getCoefs vr - 1.0 author - bodc/matcaz date - 25012019
%
% mods - 
%

% Parse coefficient string
coefs = struct();

coefstring = transpose(fullstring(~isspace(fullstring))); % Remove all whitespace

% Remove nones
nones = {'n/a','none'};
for ii = 1:length(nones)
    none = strfind(coefstring,nones{ii});
    sub = 0;
    len = length(nones{ii});
    if (~isempty(none))
        for jj=1:length(none)
            coefstring(none(jj)-sub:none(jj)-sub-1+len) = [];
            sub = sub + len;
        end
        %break; % Mixed nones do occur
    end
end

% Attempt to identify delimiter
delimiters = {';',','};
delimiter = ' ';
peak = 0;
for ii = 1:length(delimiters)
    ndelimit = length(strfind(coefstring,delimiters{ii}));
    if (ndelimit > peak)
        delimiter = delimiters{ii};
        peak = ndelimit;
    end
end

if (peak < 1)
    disp('Could not identify delimiter in coefficient string, attempting to parse with whitespace...');
    coefstring = transpose(fullstring); % Revert to whitespace-filled string
    sz = size(coefstring);
    coefstr = cell(sz(1), 1);
    
    for ii=1:length(coefstr)
        coeftemp = coefstring(ii,:);
        % Discard any strings that are blank or hold only none values
        for jj=1:length(nones)
            coeftemp = strrep(coeftemp,nones{jj},'');
        end
        if (any(~isspace(coeftemp)))
            coefstr{ii} = coefstring(ii,:);
        end
    end
    
    % Drop empty cells
    coefstr = coefstr(~cellfun('isempty',coefstr));

    coeftemp = cell(size(coefstr));
    for ii=1:length(coefstr)
        cidx = strfind(coefstr{ii},'coeffs:');
        if (~isempty(cidx))
            % Extra processing for strings with 'coeffs:' because we
            % recognize the pattern
            coefcat = delimit(coefstr{ii}(1:cidx-1),' ');
            
            if(strcmp(coefcat{end},'BBP') && strisnumeric(coefcat{end-1}))
                % Special case (AUS Backscattering)
                coefcat = [coefcat{end},coefcat{end-1}];
            else
                coefcat = coefcat{end};
            end

            % Parse remaining text
            coefs.(coefcat) = parseWhitespace(coefstr{ii}(cidx+7:end));
            continue;
        else
            coeftemp{ii} = coefstr{ii};
        end
    end
    coeftemp = coeftemp(~cellfun('isempty',coeftemp));
    if (~isempty(coeftemp))
        coeftemp = parseWhitespace([coeftemp{:}]);
        tempkeys = fields(coeftemp);
        for ii=1:length(tempkeys)
            coefs.(tempkeys{ii}) = coeftemp.(tempkeys{ii});
        end
    end
else
    % Apply delimiter
    coefcell = delimit(coefstring,delimiter);

    % Account for special cases
    BETASW700Search = 'BETASW700(contributionofpureseawater)';
    BETASW700 = ~cellfun('isempty',strfind(coefcell,BETASW700Search));
    if (any(BETASW700))
        coefcell{BETASW700} = ['BETASW700=',...
            coefcell{BETASW700}(52:end)];
    end

    % Generate struct
    eqmask = ~cellfun('isempty',strfind(coefcell,'='));
    coefeq = coefcell(eqmask);

    for ii=1:length(coefeq) % Inefficient :(
        [key, val] = strtok(coefeq{ii},'=');
        val = val(2:end);
        if strisnumeric(val)
            val = str2double(val);
        end
        coefs.(key) = val;
    end
end

end