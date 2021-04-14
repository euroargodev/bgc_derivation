function bbsvars = bbsproc(profvarnams,profvarids,profids,metaid,metavarnams,metavarids,coefs)
%
%    bbsvars = bbsproc(profvarnams, profvarids, profids, metaid, metavarnams, 
%                       metavarids, coefs)
%  where
%    profvarnams    is a cell array containing cell arrays of profile
%                   NetCDF variable names
%    profvarids     is a cell array containing vectors of profile NetCDF
%                   variable IDs
%    profids        is a vector of profile NetCDF file IDs (ncids)
%    metaid         is a NetCDF file id (ncid) for the relevant meta file
%    metavarnams    is a cell array containing meta NetCDF variable names
%    metavarids     is a vector of meta NetCDF variable IDs
%    coefs          is a key-value pair structure containing metadata from a 
%                   PREDEPLOYMENT_CALIB_COEFFICIENT string
%    bbsvars        is a key-value pair structure of processed results
%

% title - s bbsproc vr - 1.0 author - bodc/matcaz date - 22012019
%
% mods - 
%

    % Get sensor metadata
    sensors = cellstr(transpose(...
        netcdf.getVar(metaid,metavarids(strcmp(metavarnams,'SENSOR')))));
    sensors = sensors(~cellfun('isempty',strfind(sensors,'BACKSCATTERING')));

    delta = 0.039;

    % Get backscattering wavelengths
    lambda = cell(size(sensors));
    for ii=1:length(sensors)
        wl = sensors{ii}(end-2:end);
        if(strisnumeric(wl)), lambda{ii} = wl; end
    end

    % Drop empty cells
    lambda(cellfun('isempty',lambda)) = [];

    % Generate struct
    bbsvars = struct(...
        'prof',struct(),...
        'coef',struct('delta',delta),...
        'out', struct());

    % Get values from profile NetCDF(s)
    for ii=1:length(profids)
        cmp = strcmp(profvarnams{ii},'TEMP');
        if (any(cmp))
            bbsvars.prof.temp = netcdf.getVar(profids(ii),profvarids{ii}(cmp));
            bbsvars.prof.temp = dropfills(bbsvars.prof.temp, 99999);
        end
        cmp = strcmp(profvarnams{ii},'PSAL');
        if (any(cmp))
            bbsvars.prof.psal = netcdf.getVar(profids(ii),profvarids{ii}(cmp));
            bbsvars.prof.psal = dropfills(bbsvars.prof.psal, 99999);
        end

        for jj=1:length(lambda)
            bnam = ['BETA_BACKSCATTERING',lambda{jj}];
            cmp = strcmp(profvarnams{ii},bnam);
            if (any(cmp))
                bbsv = netcdf.getVar(profids(ii),profvarids{ii}(cmp));
                bbsvars.prof.(bnam) = dropfills(bbsv, 99999);
            end
        end
    end

    profkeys = fields(bbsvars.prof);
    for ii=1:length(profkeys)
        % Replace fill values with NaNs
        bbsvars.prof.(profkeys{ii})(bbsvars.prof.(profkeys{ii}) == 99999) = nan;
    end



    nans = nan(size(bbsvars.prof.temp));

    for ii=1:length(lambda)
        bbp = ['BBP',lambda{ii}];
        bbsvars.coef.(bbp) = struct('betasw',nans,'beta90sw',nans,'bsw',nans);
        bbsvars.out.(bbp) = struct('bbp',nans);
        lam = str2double(lambda{ii});

        for jj=1:length(bbsvars.prof.temp) % Very inefficient :(
            % Calculate scattering coefficients
            [...
                bbsvars.coef.(bbp).betasw(jj),...
                bbsvars.coef.(bbp).beta90sw(jj),...
                bbsvars.coef.(bbp).bsw(jj)...
                ] =...
            betasw_ZHH2009(lam,bbsvars.prof.temp(jj),bbsvars.prof.psal(jj),delta);
        end
    end

    bbskeys = fields(bbsvars.out);

    for ii =1:length(bbskeys)
        % Get chi
        known_chi = {'FLBBChi','FLBBKhi','khi','chi'};

        if (any(strcmp(fields(coefs),bbskeys{ii})))
           ckeys = fields(coefs.(bbskeys{ii}));
           ipair = true;
        else
            ckeys = fields(coefs);
            ipair = false;
        end
        
        for jj = 1:length(known_chi)
            cidx = strfind(ckeys,known_chi{jj});
            cidx = ~cellfun('isempty',cidx);
            if(any(cidx) && ipair)
                chi = coefs.(bbskeys{ii}).(ckeys{cidx});
                break;
            elseif(any(cidx) && ~ipair)
                chi = coefs.(ckeys{cidx});
            end
        end

        % Get scale
        known_scale = {['SCALE_BACKSCATTERING',bbskeys{ii}(end-2:end)],'Scale'};
        for jj = 1:length(known_scale)
            cidx = strfind(ckeys,known_scale{jj});
            cidx = ~cellfun('isempty',cidx);
            if(any(cidx) && ipair)
                scale = coefs.(bbskeys{ii}).(ckeys{cidx});
                break;
            elseif(any(cidx) && ~ipair)
                scale = coefs.(ckeys{cidx});
                break;
            end
        end
        
        % Get dark
        known_darks = {['DARK_BACKSCATTERING',bbskeys{ii}(end-2:end)],'DARK_CHLA','DARK_CHLA_O','Dark_Counts'};
        for jj=1:length(known_darks)
            cmp = strcmp(ckeys,known_darks{jj});
            if (any(cmp) && ipair)
                dark = coefs.(bbskeys{ii}).(ckeys{cmp});
                break;
            elseif(any(cmp) && ~ipair)
                dark = coefs.(ckeys{cmp});
                break;
            end
        end

        % Get beta
        beta = bbsvars.prof.(['BETA_BACKSCATTERING',bbskeys{ii}(end-2:end)]);

        % Get betasw
        betasw = bbsvars.coef.(bbskeys{ii}).betasw;
        
        % Calculate backscattering at wavelength
        bbsvars.out.(bbskeys{ii}) = bbscalc(chi, beta, dark, scale, betasw);
        
    end
end