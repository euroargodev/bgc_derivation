function oxycalib(floatno,printnames)
%
%    oxycalib(floatno,printnames)
%  where
%    floatno      identifies a cached float
%    printnames   boolean to print out the names of (selected) variables
%                 (variables selected at cache time)

% title - s oxycalib  vr - 1.0  author - bodc/sgl  date - 20211110

    basecachepath  =  getenv('ARGOCACHEPATH');
    syscom =  sprintf('find %s -type d -name %d',basecachepath,floatno);
    [~,pathdir]  =  system(syscom);
    if(numel(pathdir)>1), pathdir(end)  =  ''; end
    
    if(isempty(pathdir))
      fprintf('Float not recognised in cache\n');
      return
    end
    matfilest  =  dir(fullfile(pathdir,'profiles'));
    cellname  =  struct2cell(matfilest)';
    maskcell  =  regexp(cellname(:,1),'^.$|^..$|.nc$','match');
    mask  =  ~cellfun(@isempty,maskcell);
    matfilest(mask)  =  [];
    matfiles  =  cell(numel(matfilest),1);
%    
    for  ii  = 1:numel(matfilest)
      matfiles{ii}  =  fullfile(matfilest(ii).folder,matfilest(ii).name); 
    end
%
%  Now sort by profile
%
    profileno  =  regexprep(matfiles,'^(.*/)([A-Z]){1,2}([^/]*)$','$1$3_$2');
    [~,indxa]  =  sort(profileno);
%
%  The following code dependent on having associated pairs of files 
%  in sorted order
%
    for  ii  =  1:numel(matfiles)
      ff  =  matfiles{indxa(ii)};
      if(mod(ii,2))
        clear doxystruct ctdstruct 
        fprintf('\n\n')
      end
      fprintf('Profile %s\n',ff)
      load(ff)
      if(mod(ii,2)), continue; end
      doxynames  =  sort(fieldnames(doxystruct));
      ctdnames  =  sort(fieldnames(ctdstruct));

      if(printnames)
        fprintf('\ndoxy names\n')   
        for  jj  =  1:numel(doxynames)
          fprintf('%2d) %s\n',jj,doxynames{jj})
        end
        fprintf('\nctd names\n')
        for  jj  =  1:numel(ctdnames)
          fprintf('%2d) %s\n',jj,ctdnames{jj})
        end
      end
%
% Check pressures are the same across structures
%
     if(numel(ctdstruct.PRES)~=numel(doxystruct.PRES))
        error('Pressure arrays not of equal size across structures\n')
     else
       mask  =  ctdstruct.PRES~=doxystruct.PRES;
       if(any(mask))
         fprintf('Pressures differ\n')
       end
     end
%
%  Check if EQUATIONS and CALIBRATIONS are or are not null (blank)
%

       if(all(doxystruct.SCIENTIFIC_CALIB_EQUATION==' '))
         fprintf('SCIENTIFIC_CALIB_EQUATION not given for DOXY\n')
       else
         error('This profile has SCIENTIFIC_CALIB_EQUATION non null')  
       end

       if(all(ctdstruct.SCIENTIFIC_CALIB_EQUATION==' '))
         fprintf('SCIENTIFIC_CALIB_EQUATION not given for CTD\n')
       end
    end
%
%  Get hold of metadata to identify sensor
%
   oxysensor  =  geto2sensor(floatno);
   if(isempty(oxysensor))
     error('No recognised oxygen sensor - one might need to be added to list')
   end
%
%  Work through profiles
%
   profiles  =  getprofiles(floatno);
   for  ii  =  1,numel(pprofiles)
     calibid  =  maptocalib(oxysensor,floatno,profile);
   end
end
function profiles  =  getprofiles(floatno)
% 
%     profiles  =  getprofiles(floatno)
%  where
%     
Identifies NC files which have DOXY variables
   basecachepath  =  getenv('ARGOCACHEPATH');
   findcom  =  sprintf('find %s -type d -name %d',basecachepath,floatno);
   

    
   
  
   
