function createo2cache(floatnos)
% 
%    createo2cache(floatnos)
% where
%    floatnos is an array of float numbers
%
%  Copies 3 profiles from mirror site to caching directory (near
%  beginning, near middle, near end). It also creates .mat file
%  for structures abstracted from NetCDF. The idea is to reduce  
%  the number of variables to those that are pertinent.
%
%  You do need to be on livljobs7/argo. You need to specify
%  ARGOCACHEPATH. If not specified advice will be given when it fails.
%
%  To start from scratch use (at Linux prompt):
%  > rm $ARGOCACHEPATH/dac
%  
%  Use >> help o2readme
%  for more background information
 
% title - s createo2cache  vr - 1.0 author - bodc/sgl  date - 20211104

%
%   First set the cache. Note that the 'vkamino' in the following causes  
%   problems with the program if omitted 
%
    origpath  =  '/vkamino/scratch/argo/gdac_mirror';
    basecachepath  =  getenv('ARGOCACHEPATH');
    if(isempty(basecachepath))
      fprintf('Need to specify ARGOCACHEPATH environment variable\n');
      fprintf('Use >> setenv ARGOCACHEPATH mydir      in Matlab session\n');
      fprintf(' or > export ARGOCACHEPATH=mydir       in Bash\n');
      return
    end
%
%  Employ recursion when more than one
%
    if(numel(floatnos)>1)
      for ii = 1:numel(floatnos)
        createo2cache(floatnos(ii));
      end
      return
    end
%
%  Search cache first for float profiles
%
    floatno  =  floatnos(1);
    syscom =  sprintf('find %s -type d -name %d',basecachepath,floatno);
    [~,pathdir]  =  system(syscom);
    if(numel(pathdir)>1), pathdir(end)  =  ''; end
    
    if(~isempty(pathdir))
      fprintf('Files already cached\n') ;
      return
     
%       filest  =  dir(fullfile(pathdir,'profiles'));
%       cellname  =  struct2cell(filest)';
%       maskcell  =  regexp(cellname(:,1),'^.$|^..$|.mat$','match');
%       mask  =  ~cellfun(@isempty,maskcell);
%       filest(mask)  =  [];
%       testfiles  =  cell(numel(filest),1);
%       for  ii  = 1:numel(filest)
%         testfiles(ii)  =  cellstr(fullfile(filest(ii).folder,filest(ii).name));
%       end
    else
      [~,hostname]  =  system('hostname -s');
      hostname(hostname==10) = ''; %Remove CR
      if(~strcmp(hostname,'livljobs7'))
        fprintf('Have to be on livljobs7 for this to run\n')
        return
      end
  
%
%  Otherwise go to mirror site, find files and cache them
%
      syscom =  sprintf('find %s -type d -name %d',origpath,floatno);
      [~,pathdir]  =  system(syscom);
      pathdir(end)  =  '';  %Remove CR.
      fprintf('Path is %s\n',pathdir);

      pathdirp = fullfile(pathdir,'profiles');
      stdir  =  dir(pathdirp);
      cellname  =  struct2cell(stdir)';
      mask =  strncmp(cellname(:,1),'BR',2);
      stdir(~mask)  =  [];
      if(numel(stdir)<20)
        fprintf('No data or insufficient data for float %d\n',floatno)
        return
      end
      
      takef  =  [10,fix(numel(stdir)/2),numel(stdir)-9];
      testfiles  =  cell(3,1);
      for  ii = 1:numel(takef)
        nn  =  takef(ii);  
        testfiles(ii)  =  cellstr(fullfile(stdir(nn).folder,stdir(nn).name));
      end
 %
 %  Create cache directories 
 %
      cachepathdirp  =  strrep(pathdirp,origpath,basecachepath);
      syscom  =  sprintf('mkdir -p %s',cachepathdirp);
      [st,~]  =  system(syscom);
      addfiles  =  cell(size(testfiles));
%
%  Copy over the meta file 
%
      metafile  = fullfile(pathdir,sprintf('%d_meta.nc',floatno));
      copyfile(metafile,strrep(pathdir,origpath,basecachepath));
%
%  Copy DOXY profiles over but include "CTD" as well.
%
      for ii  =  1:numel(testfiles)
        copyfile(testfiles{ii},cachepathdirp)
        rfile  =  regexprep(testfiles{ii},'BR([0-9])*','R$1');
        if(exist(rfile,'file'))
          copyfile(rfile,cachepathdirp);
          addfiles{ii}  =  rfile;
          continue;
        end
        dfile  =  regexprep(testfiles{ii},'BR([0-9])*','D$1');
        if(exist(dfile,'file'))
          copyfile(dfile,cachepathdirp);
          addfiles{ii}  =  dfile;
          continue;
        end 

      end
      testfiles =  [testfiles;addfiles];
  %
  %   Change original path to cache path
  %
      testfiles  =  regexprep(testfiles,origpath,basecachepath);

    end
    
  %
  %   Reorder testfiles so files belonging to the same profile appear together
  %
    profileno  =  regexprep(testfiles,'^(.*/)([A-Z]){1,2}([^/]*)$','$1$3_$2');
    [~,indxa]  =  sort(profileno);
    mm  =  0;
    nn  =  0;
    clear doxystruct ctdstruct
 %
 %  Generate structures
 %
    profileid  =  cell(fix(numel(indxa)/2),1);
    for kk  =  1:numel(indxa)
      ii  =  indxa(kk);  
      ncobj  =  netcdf(testfiles{ii});
      type  =  regexprep(testfiles{ii},'^(.*/)([A-Z]){1,2}([^/]*)$','$2');
      switch(type)
        case 'BR'
          mm  =  mm + 1;
          profileid{mm} = ...
           regexprep(testfiles{ii},'^(.*/)([A-Z]){1,2}([^/]*).nc$','$3');
        case 'D'
          nn  =  nn + 1;
        otherwise
          error('Unrecognised type %s',type)
      end
      fprintf('\n%2d) %s\n',kk,testfiles{ii});
      vars  =  var(ncobj);
      clear doxystruct ctdstruct
      testmat  =  strrep(testfiles{ii},'.nc','.mat');
      for jj  =  1:numel(vars)
        varnam  =  name(vars{jj});
        if(~isempty(regexp(varnam,'_QC','match'))), continue; end
        if(~isempty(regexp(varnam,'DOXY|PRES|SAL|TEMP|SCIENTIFIC','match')))  
%           fprintf('    %2d)variable %s\n',jj,name(vars{jj}));
          switch(type) 
            case 'BR'
              doxystruct.(varnam)  =  ncobj{varnam}(:);
            case 'D'
              ctdstruct.(varnam)  =  ncobj{varnam}(:); 
            otherwise
              error('Unexpected type %s',type);     
          end
        end
      end
      close(ncobj)
      if(exist('doxystruct','var')), save(testmat,'doxystruct'); end
      if(exist('ctdstruct','var')), save(testmat,'ctdstruct'); end
      end
      if(mm~=nn)
        error('Structure array mismatch %d:%d',mm,nn)
      end

