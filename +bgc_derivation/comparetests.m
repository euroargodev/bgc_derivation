function comparetests()
%
%    comparetests()
%  

% title - s comparetests vr - 1.0 author - bodc/matcaz date - 24012019
%
% mods - 
%

files = dir('output/');
subdirs = files([files.isdir]);
subdirs = subdirs(3:end);

versions = struct();

for ii=1:length(subdirs)
    load(['output/',subdirs(ii).name,'/output_',subdirs(ii).name,'.mat']);
    versions(1).(['m',subdirs(ii).name]) = driverout;
    clear driverout;
end

keys = fields(versions);
base = DataHash(versions.(keys{1}));

fid = fopen('output/checksums.txt','w');
for ii=1:length(keys)
    checksum = DataHash(versions.(keys{ii}));
    if(strcmp(checksum,base))
        fprintf(fid,[keys{ii},': ', checksum,'\n']);
    else
        fprintf(fid,[keys{ii},': ', checksum,' (DIFF!)\n']);
    end
end

fclose(fid);
end