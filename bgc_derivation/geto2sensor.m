function [oxysensor,sensorid] = geto2sensor(floatno)
%  Identifies a match from SENSOR_MODEL
%     [oxysensor,sensorid] = geto2sensor(floatno)
%   where
%     oxysensor      is name of sensor (as seen in metadata file)
%     sensorid       is the identifier for the sensor in the calibration
%                        system

% title - s geto2sensor  vr - 1.0  author - bodc/sgl  date - 20211112

  oxysensorlist  =  ...
      {'AANDERAA_OPTODE_4330','202';
       'AANDERAA_OPTODE_3830','201';
       'SBE63_OPTODE','103'};
%
%  Look in metadata file
%
    basecachepath  =  getenv('ARGOCACHEPATH');
    if(isempty(basecachepath))
      error('Need to specify cache path')
    end
    findcom  =  sprintf('find %s -name %d_meta.nc',basecachepath,floatno);
    [~,metafile]  =  system(findcom);
    if(isempty(metafile))
      error('Unable to find metafile')
    end
    metafile(end)  =  '';
    ncobj  =   netcdf(metafile);
    sensor_model  =  ncobj{'SENSOR_MODEL'}(:);
    sensor_model  =  cellstr(sensor_model);
    oxysensor  =  '';
    for ii  =  1:numel(sensor_model)
      mask =  strcmp(sensor_model{ii},oxysensorlist(:,1));
      if(any(mask))
        if(isempty(oxysensor))
          oxysensor = sensor_model{ii}; 
          sensorid  =  oxysensorlist{mask,2};
        else
          error('More than one match for oxygen sensor')
        end
      end
    end
    close(ncobj)