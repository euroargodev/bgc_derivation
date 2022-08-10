function processo2(floatnos)
%
%     processo2(floatno)
%  where
%     floatnos      is the float number (integer) or an array of same
%
%   A float is processed for oxygen saturation. This first involves
%   segregating the data into profiles, determining the equation to be applied
%   for the individual profile, reading the data from the .nc files and 
%   outputting the desired O2 output (DOXY).
%
%   NB Code under development. Calculated v. stored differ for 201_201_301. 
%      Also no wiring yet for certificate values

%  title - s processo2  vr - 1.0  authot - bodc/sgl  date - 20211112


%
%  If more than one invoke recursively
% 
    if(numel(floatnos)>1)
      for  ii  =  1:numel(floatnos) 
         processo2(floatnos(ii));
      end
      return
    end
    floatno  =  floatnos(1);
%
    floatpath  =  getfloatpath(floatno);
    profpath  =  fullfile(floatpath,'profiles');
%
%  Note profile cell array contains just the numeric elements
%  of <float>_<profile> 
%
    profiles  =  getprofiles(floatno);
    [~,sensorid]  =  geto2sensor(floatno);
    certspec  =  true;                 %irrelevant if no choice to be made
    pathdox  =  cell(size(profiles));
    pathctd  =  pathdox;
    equid  =  pathdox;
%  
%  Note the following is agnostic on file name prefixes. The file has to
%  contain references to "DOXY" variables before an equationid will be
%  issued
%
    for ii = 1:numel(profiles)
      ppath  =  fullfile(profpath,['*',profiles{ii},'.nc']);
      ppathst  =  dir(ppath);
      for jj  =  1:numel(ppathst)
        pprofpath  =  fullfile(profpath,ppathst(jj).name);  
        equationid  =  getequationid(sensorid,pprofpath,certspec);
        if(isempty(equationid))
          pathctd{ii}  =  pprofpath;
          continue;
        else
          equid{ii}  =  equationid;
          pathdox{ii}  =  pprofpath;
          fprintf('%s uses %s\n',profiles{ii},equationid);
        end
      end
    end
%
%  Now evaluate
%
    for  ii  =  1:numel(profiles)
      if(isempty(equid{ii}))
        error('No equation defined for this profile %s',profiles{ii})
      end
%
%  Note the transpose in the following to get to conventional columns
%
      ncdox  =  netcdf(pathdox{ii});
      ncctd  =  netcdf(pathctd{ii});
      T  =  ncctd{'TEMP_ADJUSTED'}(:)';
      P  =  ncctd{'PRES_ADJUSTED'}(:)';
      S  =  ncctd{'PSAL_ADJUSTED'}(:)';
      
      switch(equid{ii})
        case '103_208_307'
        case '103_209_301'
        case '201_201_301'    %  NB THIS CODE is under development - stored and calculated values
                              %  do not yet agree
          molar_doxy  =  ncdox{'MOLAR_DOXY'}(:)';
          maskdoxy  =  molar_doxy  ==  99999;  %  More properly this should be the fill value
          maskctd  =  S == 99999;              %  as defined in the .nc file

          mask  =  ~(maskdoxy | maskctd);

          doxycalc  =  molar_doxy;             % Get right dimensions
          doxycalc(mask)  =  O2ctoO2s(molar_doxy(mask),T(mask),S(mask),P(mask)); %,p_atm(mask));
          doxy  =  ncdox{'DOXY'}(:)';

        case '201_202_204'
        case '201_203_204'
        case '202_201_301'
        case '202_204_304'
        case '202_204_305'
        case '202_205_304'
        otherwise
          error('Unknown equation designator: %s',equid{ii});
      end
      close(ncctd);
      close(ncdox);
    end
