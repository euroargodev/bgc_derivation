function stcoeff  =  getPredeplomentCoefficients(metadatafile)
%
%    stcoeff  =  getPredeplomentCoefficients(metadatafile)
%  where 
%    stcoeff        is a structure of coefficients required for oxygen
%                   calibration. 
%    metadatafile   is the path to the appropriate NC metadata file
%
%  The information is stored in the PREDEPLOYMENT_CALIB_COEFFICIENT 
%  variable. stcoeff should always have an .optode1 field
%  but may be returned as the empty structure if no information found.
%  stcoeff.optode2  would relate to a second optode if found
% 
metanc  =  netcdf(metadatafile);
stcoeff  =  struct([]);
vals  =  metanc{'PREDEPLOYMENT_CALIB_COEFFICIENT'}(:);
names  =  metanc{'PREDEPLOYMENT_CALIB_COMMENT'}(:);
mask  =  ~cellfun(@isempty,regexp(cellstr(names),'Argo (oxygen|OXYGEN) data'));


if(sum(mask)==0), return; end
clear stcoeff
theStruct  =  struct([]);
vals  =  vals(mask,:);
close(metanc);  

for  nn  =  1:sum(mask)
  ssstring  =  vals(nn,:);
  ststring  =  regexprep(ssstring,'([,;]|^| +)([A-Za-z])','$1stcoeff.$2');
  ststring  =  regexprep(ststring,',',';'); %Quietens the evaluation
  ststring  =  ...
    regexprep(ststring,'([^;])$','$1;'); % Put in semicolon if missing at end
  eval(ststring);
  theStruct(1).(sprintf('optode%d',nn)) =  stcoeff;
end
stcoeff  =  theStruct;
end