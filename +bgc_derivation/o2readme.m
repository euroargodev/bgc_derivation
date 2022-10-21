function o2readme
%
%   Here is some background information on the testing and development
%   of the dissolved oxygen computation
%
%   Caching
%   We have a mirror GDAC site housed at /scratch/argo/gdac_mirror/ with
%   data for individual floats under for example 
%   /scratch/argo/gdac_mirror/dac/coriolis.
%   Test data sets are taken from this site.
%
%   A Linux find command applied to the mirror site will locate 
%   any desired profile but it will take some time because of
%   the many files present and the inability to limit the search to the
%   top levels of the directory structure. Although there are ways to
%   optimise the process it was thought better to keep the programming
%   simple by operating from a local subsetted copy of the GDAC data.
%
%   The CREATEO2CACHE copies over a small selection of profiles into a 
%   designated cache directory identified through the environment variable
%        ARGOCACHEPATH
%   The copying process preserves the directory structure. A selection is
%   made to limit profiles to three (10'th, middle, 10'th from the end)
%   This constitutes a de facto test dataset. E.g. one such file might be:
%     /users/argo/sgl/data/dac/coriolis/3900532/profiles/D3900532_008.nc
%
%   One aspect of maintaining the directory structure is that one can
%   actually set ARGOCACHEPATH to the mirror site itself and the calibration
%   software will continue to work.
%   
%   File types
%   Profiles are kept under the "profiles" directory of the relevant
%   float's directory. There are different profile file types - as 
%   identified by prefixes - depending on the nature of the processing
%   undertaken. For the floats of interest we expect two files (one
%   with "DOXY" variables present and one without); the determination is 
%   through internal inspection rather than by assessment of prefix.
%
%   MAT files
%   MAT files with the .mat extension are created by creato2cache.m 
%   to house abbreviated structures of content and are named for the 
%   related file. This is a convenience as ncdump -h <file>.nc can produce
%   a lot of output. To tweak the content visit createo2cache.m
%
%   The metadata file
%   In addition to the above we need to copy over the metadata file 
%   (sibling to profiles directory). E.g. 3900532_meta.nc
%
%   Recursion
%   Like CREATEO2CACHE PROCESSO2 can operate with an array of floats 
%   which are processed recursively.
%
%   SCIENTIFIC_CALIB_EQUATION
%   One of the variables in the .nc file defines the equation to be used
%   for either "CTD" or "DOXY". Experience shows that this is often blank 
%   for DOXY. processo2.m checks that this is in fact the case and halts if
%   not.