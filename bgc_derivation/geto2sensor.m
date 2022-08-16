function [oxysensors,sensorids] = geto2sensor(varargin)
%  Identifies a match from SENSOR_MODEL
%     oxysensor = geto2sensor(floatno|metadatafile)
%   where
%     oxysensors      is cell array of sensors (as seen in metadata file)
%     sensorids       is cell array of identifiers for the sensors in 
%                        the calibration system
%     floatno         is the float number (integer)
%     metadatafile    is the metadatafile
%     

% title - s geto2sensor  vr - 1.0  author - bodc/sgl  date - 20211112

  floatno  =  [];
  metafile  =  '';
  while(numel(varargin))
    varg  =  varargin{1};
    varargin(1)  =  [];
    vargtype  =  class(varg);
    switch(vargtype)
      case 'double'
        floatno  =  varg;
      case 'char'
        metafile  =  varg;
      otherwise
        error('unrecognised type %s',vargtype);
    end
  end
  
    
  oxysensorlist  =  ...
      {'AANDERAA_OPTODE_4330','202';
       'AANDERAA_OPTODE_3830','201';
       'SBE63_OPTODE','103'};
     
%
%  Look in metadata file if float number given
%
    if(~isempty(floatno))
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
    end
    ncobj  =   netcdf(metafile);
    sensor_model  =  ncobj{'SENSOR_MODEL'}(:);
    sensor_model  =  cellstr(sensor_model);
    oxysensors  =  {};
    sensorids  =  {};
    jj  =  0;
    for ii  =  1:size(oxysensorlist,1)
      if(any(strcmp(oxysensorlist(ii,1),sensor_model)))
        jj  =  jj + 1;
        oxysensors{jj} =  oxysensorlist{ii,1};
        sensorids{jj}  =  oxysensorlist{ii,2};
      end
    end
    close(ncobj)