function driverout = driverproc(filnam)
%
%    driverout = driverproc(filnam)
%  where
%    filnam     is the path to a driver file of NetCDFs or driver files
%

% title - s driverproc vr - 1.0 author - bodc/matcaz date - 24012019
%
% mods - 
%

% Read and split file into cell array
text = transpose(regexp(fileread(filnam),'\r?\n','split'));

% Check driver type header and proceed accordingly
if(strcmp(text{1},'%!DRIVER_TYPE=NETCDF'))
    driverout = {drivenetcdf(text)};
elseif(strcmp(text{1},'%!DRIVER_TYPE=DRIVERS'))
    driverout = drivedriver(text);
else
    error('Unrecognized driver type!');
end
save('output.mat','driverout');
end

function driverout = drivenetcdf(text)
    text(1) = [];
    outstruct = struct('noname',cell(0));
    
    
    for ii=1:length(text)
        filnam = [];
        % Process arguments
        if(isempty(text{ii}) || strcmp(text{ii}(1),'#')), continue; end
        line = text{ii}(2:end);
        jump = strfind(line,'}');
        
        % Process profile arguments
        profiles = line(1:jump-1);
        line = line(jump+1:end);
        profcell = delimit(profiles,' ');
        
        % Process remaining arguments
        args = transpose(delimit(line, ' '));
        % Remove empty arguments
        args = args(~strcmp(args,' '));
        args = args(~cellfun('isempty',args));
        % Account for file output
        fidx = strcmp(args,'-f');
        if (any(fidx))
            if (strcmp(args{find(fidx)+1},'noname.mat'))
                error('"noname.mat" is a reserved output filename!');
            end
            filnam = args{find(fidx)+1};
            if(strfind(filnam,'.mat'))
                filnam = filnam(1:end-4);
            end
            args(find(fidx):find(fidx)+1) = [];
        end
        
        % Combine args and invoke bgcproc
        args = [{profcell}, args]; % Ignore size/iteration warning
        out = bgcproc(args{:});
        
        if (~isempty(filnam))
            keys = fields(outstruct);
            if (~any(strcmp(keys,filnam)))
                outstruct(1).(filnam) = cell(0);
            end
            outstruct(1).(filnam){end+1} = out;
        else
            outstruct.noname{end+1} = out;
        end
    end
driverout = outstruct;
end

function driverout = drivedriver(text)
    text(1) = [];
    driverout = cell(length(text),1);
    for ii=1:length(text)
        if(isempty(text{ii}) || strcmp(text{ii}(1),'#')), continue; end
        filnam = text{ii};
        drvtxt = transpose(regexp(fileread(filnam),'\r?\n','split'));
        driverout{ii} = drivenetcdf(drvtxt);
    end
    % Drop empty cells
    driverout = driverout(~cellfun('isempty',driverout));
end