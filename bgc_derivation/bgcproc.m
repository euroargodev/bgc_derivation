function bgcout = bgcproc(varargin)
%
%    output = bgcproc([profin, metain], [,-f, filout],
%       [-ph, -rad, -chla, -bbs])
%  where
%    profin     is a cell array of paths to profile NetCDF files
%    metain     is a path to a meta NetCDF file
%    -f         is an argument for if you want to output to a .mat file
%    filout     is the path to the .mat file you want to create
%    -ph        is flag to enable pH processing
%    -rad       is a flag to enable radiometry processing
%    -chla      is a flag to enable chlorophyll-a processing
%    -bbs       is a flag to enable backscatter processing
%    -oxy       is a flag to enable oxygen processing (NOT
%               IMPLEMENTED)
%    -nit       is a flag to enable nitrate processing
%    -cdom      is a flag to enable CDOM processing
%

% title - s argoproc vr - 1.0 author - bodc/matcaz date - 24012019
%
% mods - 
%

bgcout = struct();

% Process arguments
outpth = [];

if (nargin >= 2 && iscell(varargin{1}) && ischar(varargin{2}))
    profs = varargin{1};
    metapath = varargin{2};
    varargin(1:2) = [];
elseif (nargin > 0)
    [gfil,gpth] = uigetfile('.nc','Select Profile NetCDF file(s)',...
        'MultiSelect','on');
    if (~strcmp(gpth(end),filesep))
        gpth(end+1) = filesep;
    end
    if (iscell(gfil))
        profs = cell(size(gfil));
        for ii=1:length(gfil)
            profs{ii} = [gpth,gfil{ii}];
        end
    else
        profs = {[gpth,gfil]};
    end
    
    [gfil,gpth] = uigetfile('.nc','Select Meta NetCDF file');
    if (~strcmp(gpth(end),filesep))
        gpth(end+1) = filesep;
    end
    metapath = [gpth,gfil];
end



procph = false;
procrad = false;
procchla = false;
procbbs = false;
procoxy = false;
procnit = false;
proccdom = true;

procany = false;
for ii=1:length(varargin)
    if (~strcmp(varargin{ii}(1),'-'))
        continue;
    elseif (strcmp(varargin{ii},'-f'))
        outpth = varargin{ii+1};
        continue;
    else
        procany = true;
    end
    
    switch varargin{ii}
        case '-ph'
            procph = true;
        case '-rad'
            procrad = true;
        case '-chla'
            procchla = true;
        case '-bbs'
            procbbs = true;
        case '-oxy'
            procoxy = true;
        case '-nit'
            procnit = true;
        case '-cdom'
            proccdom = true;
        otherwise
            error('Unrecognized flag!');
    end
end

if(~procany)
    error('No data selected to process!');
end


% Open NetCDF files as necessary
profids = nan(length(profs),1);
for ii=1:length(profs)
    profids(ii) = netcdf.open(profs{ii},'nowrite');
end

metaid = netcdf.open(metapath,'nowrite');

% List variables
profvarids = cell(length(profids),1);
profvarnams = profvarids;

for ii=1:length(profids)
    profvarids{ii} = inqVarIDs(profids(ii));
    profvarnams{ii} = inqVarNams(profids(ii),profvarids{ii});
end

metavarids = inqVarIDs(metaid);
metavarnams = inqVarNams(metaid, metavarids);

coefid = find(strcmp(metavarnams, 'PREDEPLOYMENT_CALIB_COEFFICIENT'));
if (isempty(coefid))
    error('Meta NetCDF does not contain a predeployment calibration coefficients variable!');
end

coefstring = netcdf.getVar(metaid,metavarids(coefid)); % Get string from NetCDF

% Parse coefficient string
coefs = getCoefs(coefstring);

% Process pH as necessary
if (procph)
    bgcout.ph = phproc(profvarnams,profvarids,profids,coefs);
end

% Process Radiometry as necessary
if (procrad)
    bgcout.rad = radproc(profvarnams,profvarids,profids,coefs);
end

% Process Chlorophyll-a as necessary
if (procchla)
    bgcout.chla = chlaproc(profvarnams,profvarids,profids,coefs);
end

% Process backscattering as necessary
if (procbbs)
    bgcout.bbs = bbsproc(profvarnams,profvarids,profids,...
        metaid,metavarnams,metavarids,coefs);
end

% Process oxgen as necessary
if (procoxy)
    bgcout.oxy = oxyproc();
end

% Process nitrate as necessary
if (procnit)
    bgcout.nit = nitproc(profvarnams, profvarids, profids, coefs);
end

% Process CDOm as necessary
if (proccdom)
    bgcout.cdom = cdomproc(profvarnams, profvarids, profids, coefs);
end

if(~isempty(outpth))
    save(outpth,'bgcout');
end

% Close opened NetCDF file handles
for ii=1:length(profs)
    netcdf.close(profids(ii));
end
netcdf.close(metaid);

end

