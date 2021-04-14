function remain = dropfills(data, fillvalue)
%
%    remain = dropfills(data, fillvalue)
%  where
%    data           is a 2xN or Nx2 numeric array
%    fillvalue      is a scalar (or NaN) fill value to be targeted
%    remain         is the remaining vector
%

% title - s dropfills vr - 1.0 author - bodc/matcaz date - 24012019
%
% mods - 
%

if (~isnan(fillvalue))
    fillstat = sum(data == fillvalue);
else
    fillstat = sum(isnan(fillvalue));
end
mask = fillstat == max(fillstat);
fillstat(mask) = 1;
fillstat(~mask) = 0;
fillstat = logical(fillstat);

remain = data(1:end,~fillstat);
end