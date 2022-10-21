function profiles  =  getprofiles(floatno)
%
%      profiles  =  getprofiles(floatno)
%   where
%      profiles   is a cell array of middle portion of file names
%                   (omits alphabetic prefix and suffix)
%      floatno    is the float number(integer)
%  

% title - s getprofiles  vr - 1.0  author - bodc/sgl  date - 20211112

      floatpath  =  getfloatpath(floatno);
      dirp  =  fullfile(floatpath,'profiles');
      dirst  =  dir(dirp);
      dircell  =  struct2cell(dirst);
      dircell  =  dircell';
      dircell  =  dircell(:,1);
      profiles  =  regexprep(dircell,'[^0-9_]','');
      maskempty  =  cellfun(@isempty,profiles);
      profiles(maskempty)  =  [];
      profiles  =  unique(profiles);
      
