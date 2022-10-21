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
all_delimiters = {';',','};
delimiters = {};
for ii = 1:length(all_delimiters)
    ndelimit = length(strfind(coefstring,all_delimiters{ii}));
    if (ndelimit > 0)
        delimiters{end+1} = all_delimiters{ii};
    end
end

if (isempty(delimiters))
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
    coefcell = delimit(coefstring,delimiters);

    % Handle known names with following parantheses
    names = {...
        'UV_INTENSITY_REF_NITRATE(Ntrans)', ...
        'E_SWA_NITRATE(Ntrans)', ...
        'OPTICAL_WAVELENGTH_UV(Ntrans)', ...
        'E_NITRATE(Ntrans)'...
    };
    for ii=1:length(names)
        name = names{ii};
        parenthesis = strfind(name, '(');
        replacement = name(1:parenthesis-1);
        
        instance = contains(coefcell, name);
        if (any(instance))
            coefcell{instance} = [replacement, ...
                coefcell{instance}(length(name)+1:end)];
        end

    end
    
    % Account for special cases
    % BETASW700 (Contribution of Pure Sea Water)
    BETASW700Search = 'BETASW700(contributionofpureseawater)';
    BETASW700 = contains(coefcell,BETASW700Search);
    if (any(BETASW700))
        coefcell{BETASW700} = ['BETASW700=',...
            coefcell{BETASW700}(52:end)];
    end
    % Recover anything caught up in the BETASW cell
    leftover = coefcell{BETASW700}(strfind(coefcell{BETASW700}, 'angularDeg') + 10:end);
    coefcell{BETASW700} = replace(coefcell{BETASW700}, leftover, '');
    coefcell{end+1} = leftover;
    
    adjusted_coefs = {};
    bracket = false;
    previous = '';
    for ii=1:length(coefcell)
        coef = coefcell{ii};
        if bracket && contains(coef, '[')
            error('Coefficient opens a square bracket without closing the previous one!');
        elseif bracket && contains(coef, ']')
            adjusted_coefs{end+1} = [previous, ',', coef];
            bracket = false;
            previous = '';
        elseif contains(coef, '[')
            bracket = true;
            previous = coef;
        elseif bracket
            previous = [previous, ',', coef];
        else
            adjusted_coefs{end+1} = coef;
        end
    end

    % Generate struct
    eqmask = contains(adjusted_coefs, '=');
    coefeq = adjusted_coefs(eqmask);

    for ii=1:length(coefeq) % Inefficient :(
        [key, val] = strtok(coefeq{ii},'=');
        val = val(2:end);
        if strcmp(val(1), '[') && strcmp(val(end), ']')  % Array of values
            coefs.(key) = {};
            values = split(val(2:end-1), ',');
            for jj=1:length(values)
                if strisnumeric(values{jj})
                    values{jj} = str2double(values{jj});
                end
                coefs.(key){end+1} = values{jj};
            end
            continue
        end
            
        if strisnumeric(val)
            val = str2double(val);
        end
        coefs.(key) = val;
    end
end

end