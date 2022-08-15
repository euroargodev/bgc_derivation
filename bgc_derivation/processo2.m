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

%  title - s processo2  vr - 1.0  authot - bodc/sgl  date - 20211112

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
       
       if(numel(sensorids)>=1)
         for jj  =  1:numel(sensorids)
           processo2(floatnos(ii), sensorids{jj});
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
        case {'201_201_301','202_201_301'}

          % if empty coefficients then either we can
          %
          % 1) set them to those in the Argo manual
          % 2) get them from the database (to do)
          % 3) continue loop' for now 
          %
          if isempty(stcoeff)
            %{ % Argo manual defaults
            coeffs.Sref=0; coeffs.Spreset=0;
            coeffs.Pcoef2=0.00025; coeffs.Pcoef3=0.0328;
            coeffs.B0=-6.24523e-3; coeffs.B1=-7.37614e-3; coeffs.B2=-1.03410e-2; coeffs.B3=-8.17083e-3;
            coeffs.C0=-4.88682e-7;
            coeffs.D0=24.4543; coeffs.D1=-67.4509; coeffs.D2=-4.8489; coeffs.D3=-0.000544;
            %}
            disp('could not find predeployment calibration coefficients')
            continue;
          else
            coeffNames=fieldnames(stcoeff.optode1); % could be many optodes
            for i=1:numel(coeffNames)
              eval(['coeffs.' coeffNames{i} '=' num2str(stcoeff.optode1.(coeffNames{i})) ';']);
            end
          end

          T  =  ncctd{'TEMP'}(1,:);
          P  =  ncctd{'PRES'}(1,:);
          S  =  ncctd{'PSAL'}(1,:);
          molar_doxy = ncdox{'MOLAR_DOXY'}(1,:);
          doxy = ncdox{'DOXY'}(1,:);

          fillval_doxy = ncreadatt(pathdox{ii},'MOLAR_DOXY','_FillValue');
          fillval_ctd = ncreadatt(pathctd{ii},'PSAL','_FillValue');

          maskdoxy = molar_doxy == fillval_doxy;
          maskctd = S == fillval_ctd;
          mask =~ (maskdoxy | maskctd)';

          % doxy computation
          obj = mdoxy2doxy(molar_doxy(mask),P(mask),T(mask),S(mask),coeffs);

          % difference between doxy and calculated doxy
          if ~isempty(doxy)
            diff = (abs(doxy-obj.doxy))';
            accuracy = (doxy ./ obj.doxy) * 100;
            [doxy' obj.doxy' diff];
            min_diff = min((diff));
            max_diff = max((diff));

            disp(['float ' num2str(floatnos) ' profile ' num2str(ii) ...
                 ', min-diff ' num2str(min_diff,8) ', max-diff ' num2str(max_diff,8) ...
                 ', min-accuracy ' num2str(min(accuracy),8) '% , max accuracy ' num2str(max(accuracy),8) '%']) 
          end

        case '201_202_204'
        case '201_203_204'
        case '202_204_304'
        case '202_204_305'
        case '202_205_304'
        otherwise
          error('Unknown equation designator: %s',equid{ii});
      end
      close(ncctd);
      close(ncdox);
    end
