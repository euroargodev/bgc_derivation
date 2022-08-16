function processo2(floatnos,varargin)
%
%     processo2(floatnos[,sensorid])
%  where
%     floatnos      is the float number (integer) or an array of same
%     sensorid      is identifier in the calibration system for the sensor
%                       (e.g. '103' or '201').
%
%   A float is processed for oxygen saturation. This first involves
%   segregating the data into profiles, determining the equation to be applied
%   for the individual profile, reading the data from the .nc files and 
%   outputting the desired O2 output (DOXY).
%
%   NB Code under development. Calculated v. stored differ for 201_201_301. 
%      Also no wiring yet for certificate values

%  title - s processo2  vr - 1.0  author - bodc/sgl  date - 20211112

   sensorid  =  '';
   addarg  =  false;
   while(numel(varargin))
     varg  =  varargin{1};
     varargin(1)  =  [];
     vargtype  =  class(varg);
     switch(vargtype)
       case 'char'
         sensorid  =  varg;
         addarg  =  true;
       otherwise
         error('Unrecognised type %s',vargtype)
     end
   end
%
%  If more than one sensor ID invoke recursively
% 
   if(addarg && numel(floatnos)>1)
     processo2(floatnos,sensorid)
     return
   end
   if(~addarg)
%
%  Need to add in the sensor ID
%    
     for  ii  =  1:numel(floatnos) 
       [~,sensorids] = geto2sensor(floatnos(ii));
       if(numel(sensorids)>0)
         for jj  =  1:numel(sensorids)
          processo2(floatnos(ii),sensorids{jj})
         end
       end
     end
    return
   end
 %
 %  So we know the sensorid a this point
 %
    floatno  =  floatnos(1);
    floatpath  =  getfloatpath(floatno);
    profpath  =  fullfile(floatpath,'profiles');
%
%  Note profile cell array contains just the numeric elements
%  of <float>_<profile> 
%
    profiles  =  getprofiles(floatno);
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
    metafilepath  =  fullfile(floatpath,sprintf('%d_meta.nc',floatno));
    stcoeff = getPredeploymentCoefficients(metafilepath);
    for  ii  =  1:numel(profiles)
      if(isempty(equid{ii}))
        error('No equation defined for this profile %s',profiles{ii})
      end
%
%  Note the transpose in the following to get to conventional columns
%
      ncdox  =  netcdf(pathdox{ii});
      ncctd  =  netcdf(pathctd{ii});

      switch(equid{ii})
        case '103_208_307'
%Seabird   
          phase_delay_doxy  =  ncdox{'PHASE_DELAY_DOXY'}(:)';
          S  =  ncctd{'PSAL'}(:)';
          P  =  ncctd{'PRES'}(:)';
          Tdox  =  ncdox{'TEMP_DOXY'}(:)';
          maskdoxy  =  phase_delay_doxy  ==  99999;  %  More properly this should be the fill value
          maskctd  =  S == 99999;              %  as defined in the .nc file
          maskdoxy  =  maskdoxy | Tdox == 99999;
          mask  =  ~(maskdoxy | maskctd);

          doxycalc  =  phase_delay_doxy;             % Get right dimensions
          stc  =  stcoeff.optode1;
          doxycalc(mask)  =  O2phoO2s(stc,phase_delay_doxy(mask),P(mask),Tdox(mask),S(mask)); 
          doxy  =  ncdox{'DOXY'}(:)';
        case '103_209_301'
        case '201_201_301' 
          ncdox  =  netcdf(pathdox{ii});
          ncctd  =  netcdf(pathctd{ii});
          T  =  ncctd{'TEMP_ADJUSTED'}(:)';
          P  =  ncctd{'PRES_ADJUSTED'}(:)';
          S  =  ncctd{'PSAL_ADJUSTED'}(:)';

          %  NB THIS CODE is under development - stored and calculated values
                              %  do not yet agree
          molar_doxy  =  ncdox{'MOLAR_DOXY'}(:)';
          maskdoxy  =  molar_doxy  ==  99999;  %  More properly this should be the fill value
          maskctd  =  S == 99999;              %  as defined in the .nc file

          mask  =  ~(maskdoxy | maskctd);

          doxycalc  =  molar_doxy;             % Get right dimensions
          doxycalc(mask)  =  O2ctoO2s(molar_doxy(mask),T(mask),S(mask),P(mask)); %,p_atm(mask));
          doxy  =  ncdox{'DOXY'}(:)';
        
        case '201_202_202'
          T  =  ncctd{'TEMP'}(:);
          S  =  ncctd{'PSAL'}(:);
          P  =  ncctd{'PRES'}(:);
          bphasedoxy=ncdox{'BPHASE_DOXY'}(:);
          rphasedoxy=ncdox{'RPHASE_DOXY'}(:);
          doxy  =  ncdox{'DOXY'}(:);
          
          %retrieving the calibration coeffs.
          stc  =  stcoeff(1).optode2; % could be many optodes.sgl working on geto2sensor to solve the issue.         
          maskctdS = S == 99999; % as defined in the .nc file
          mask = ~(maskctdS)';
          
          %computing doxy 
          doxy_calc = [];
          doxy_calc = phase2doxy(bphasedoxy,rphasedoxy,P,T,S(mask),stc).doxy;
          
          %difference between the computed and doxy in netcdf
          if ~isempty(doxy)
            diff = (abs(doxy-doxy_calc));
            [doxy doxy_calc diff]';
            min_diff = min((diff));
            max_diff = max((diff));

            disp(['float ' num2str(floatno) ' profile ' num2str(ii) ...
                 ' min diff ' num2str(min_diff,12) ' max diff ' num2str(max_diff,12)]) 
          end

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
