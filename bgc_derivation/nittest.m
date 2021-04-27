% A simple sandbox script for testing out the functionality of nitrate
% functions.

ncs = {'input/nittest/ifremer/BR6902904_015.nc', 'input/nittest/ifremer/R6902904_015.nc'};
metas = 'input/nittest/ifremer/6902904_meta.nc';


bgcout = bgcproc(ncs, metas, '-nit');
