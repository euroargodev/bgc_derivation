function floatpath  =  getfloatpath(floatno)
%
%     floatpath  =  getfloatpath(floatno)
%  where
%     floatpath     is path to top level directory of the float's data


%  title - s getfloatpath  vr - 1.0  author - bodc/sgl  date - 20211111


     cachepath  =  getenv('ARGOCACHEPATH');
     if(isempty(cachepath))
       error('Need ARGOCACHEPATH specified')
     end
     syscom =  sprintf('find %s -type d -name %d',cachepath,floatno);
     [~,floatpath]  =  system(syscom);
     if(~isempty(floatpath))
       floatpath(end)  =  '';  %Remove CR.
     end

    
              