function equationid  =  getequationid(sensorid,sensord,profpath,certspec)
%
%    equationid  =  getequationid(sensorid,sensor,profpath,certspec)
%  where 
%    equationid       is either returned empty or with the desired
%                     equation id (concatenation of sensor, parameter and 
%                     calibration IDs)
%    sensorid         sensor ID; available from geto2sensor.m
%    sensord          Sensor ordinal. Where sensor comes in the file's list
%                      of oxygen sensors
%    profpath         path of profile file
%    certspec         set true if certificate info needed. Only used where 
%                     discrimination required
%
%  If a variable with string 'DOXY' in its name is detected but not
%  known to the table 

% title - s getequationid  vr - 1.0  author - bodc/sgl  date - 20211111

   paramids  =  ...
      {'MOLAR_DOXY','201';
       'TPHASE_DOXY','204';
       'CPHASE_DOXY','205';  % Expecting C2PHASE_DOXY too
       'PHASE_DELAY_DOXY','208';
       'MLPL_DOXY','209';
       'BPHASE_DOXY','202';
       'DPHASE_DOXY','203'
       };
   equationids =  ...
      {'202_201','301','';
       '202_204','304','';
       '202_204','305','spec';
       '103_208','307','';
       '103_209','301','spec';
       '201_201','301','spec';
       '201_202','204','spec';
       '201_203','204','spec'};
       
  
   ncobj  =  netcdf(profpath);
   if(isempty(ncobj))
     error('Unable to open file %s',profpath);
   end
   vars  =  var(ncobj);
   equationid  =  '';
   mapped  =  false;
   doxypres  =  false;
   if(sensord>1)
     spo2  =  sprintf('%d',sensord);
   else
     spo2  =  '';
   end
   for  ii  =  1:numel(vars)
     varnam  =  name(vars{ii});
     for  jj  =  1:size(paramids,1)
       expr  =  ['^',paramids{jj,1},spo2,'$'];
       if(isempty(regexp(varnam,expr,'match'))), continue; end
       paramid  =  paramids{jj,2};
       doxypres  =  true;
       mapped  =  true;
       break;
     end
%      doxypres  =  true;
%      
%      sz1  =  size(paramids,1);
%      mask  =  ~isempty(regexp(varnam,cellfun(@cat,repmat({2},sz1,1),...
%        paramids(:,1),repmat({'[2-3]?'},sz1,1),'UniformOutput',false) ));
%      if(~any(mask)), continue; end  
%      if(sum(mask)>1)
%        error('Unexpected matching')
%      end
%      mapped  =  true;
%      paramid  =  paramids{mask,2};
%      break;
   end
   close(ncobj);
%
%  OK not have any DOXY (e.g. "CTD" file)
%
   if(~doxypres)
     return
   end
%
%  but if present it should be mapped
%
   if(~mapped)
      error('DOXY variable(s) present for %s but not mapped',profpath);
   end
   sensidparamid  =  [sensorid,'_',paramid];
   mask  =  strcmp(sensidparamid,equationids(:,1));
   switch(sum(mask))
     case 0
       error('Equation ID not found')      ;
     case 1
       equationid  =  [equationids{mask,1},'_',equationids{mask,2}];
     case 2
       specneeded  =  strcmp('spec',equationids(:,3)); 
       if(certspec)
         mask  =  mask & specneeded;
       else
         mask  =  mask & ~specneeded; 
       end
       equationid  =  [equationids{mask,1},'_',equationids{mask,2}];
       otherwise  
       error('Too many matches')   
   end
     
   
   
      
      