function matrix  =  genmatrix(stcoeff)
%    matrix  =  genmatrix(stcoeff)
%  where 
%    matrix  is 5x4 matrix 
%    stcoeff is a structure containing 20 fields in the range c00-c43
%
%  The fields are abstracted and placed in the matrix.

fields  =  fieldnames(stcoeff);
mask =  ~cellfun(@isempty,regexp(fields,'^c[0-4][0-3]$'));
if(sum(mask)~=20)
  error('Doesn''t appear to have the right number of fields');
end
%
%  Pre-allocate
%
matrix  =  zeros(5,4);
for  ii  =  0:4
  for jj  =  0:3
    fieldname  =  sprintf('c%d%d',ii,jj);
    matrix(ii+1,jj+1)  =  stcoeff.(fieldname);
  end
end