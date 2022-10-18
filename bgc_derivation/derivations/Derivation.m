classdef (Abstract) Derivation
    % Abstract class providing common functionality for derived parameters.
    
    % title - s Derivation vr - 1.0 author - bodc/matcaz date - 20221108
    
    properties
        variables;  % Variables extracted from source data
		coeffs;  % predeployment coeffs 
        default_glob;  % Default glob pattern used for selecting data files
    end
    properties (Abstract, Constant = true)
        equation;  % Underlying equation function
    end
    methods
        function self = Derivation(variables, coeffs)
            % Constructor for Derivation objects. Accepts a pre-configured
            % Map of variables or can use add_ methods to ingest data.
            %
            % derivation = Derivation([variables, coeffs ])
            % where
            %  variables is a pre-populated name-value Map of variables.
            %
            
            self.default_glob = '**/*.nc';
            
            switch nargin
                case 2
                    self.variables = variables;
                    self.coeffs = coeffs;
                case 1
                    self.variables = variables;
                otherwise
                    self.variables = containers.Map;
    		end

        end

        function add_data(self, name, data)
            % Add a single data variable by name.
            %
            % derivation.add_data(name, data)
            % where
            %  name is the name of the supplied variable.
            %  data is the underlying array for the supplied variable.
            %
            
            self.variables(name) = data;
        end

		function add_data_coeff(self, name, data)
            % Add a single coeff by name.
            %
            % derivation.add_add_data_coeff(name, data)
            % where
            %  name is the name of the supplied variable.
            %  data is the underlying array for the supplied variable.
            %
            
            [self.coeffs(:).name] = data;
        end
        
        function add_netcdf(self, nc)
            % Add all variables from an opened NetCDF dataset.
            %
            % derivation.add_netcdf(nc)
            % where
            %  nc is the file handle or "ncid" of the NetCDF dataset.
            %
            
            [~, ncvars, ~, ~] = netcdf.inq(nc);
            varids = transpose(0:ncvars-1);
            
            for ii = 1:length(varids)
                name = netcdf.inqVar(nc, varids(ii));
                data = netcdf.getVar(nc, varids(ii));
                self.add_data(name, data);
            end
        end
        
        function add_file(self, path)
            % Add all variables from a NetCDF file on disk.
            %
            % derivation.add_file(path)
            % where
            %  path is the path to a NetCDF file on disk.
            %

            if ~exist(path, 'file')
                error(['File "', path, '" not found!']);
            end
            nc = netcdf.open(path, 'NOWRITE');
            self.add_netcdf(nc);
            netcdf.close(nc);
        end
        
        function add_directory(self, path, glob)
            % Add all variables from a directory of NetCDF variables.
            %
            % derivation.add_directory(path, [glob])
            % where
            %  path is the path to a directory on disk.
            %  glob is the pattern to select files with. Uses default_glob
            %       if not supplied.
            %
            if nargin < 3
                glob = self.default_glob;
            end
            
            if ~exist(path, 'dir')
                error(['Directory "', path, '" not found!']);
            end
            
            paths = dir(fullfile(path, glob));
            for ii = 1:length(paths)
                path = paths(ii);
                if ~path.isdir
                    file = fullfile(path.folder, path.name);
                    self.add_file(file);
                end
            end
        end
    end
    methods (Abstract)
        output = compute_parameter(~);
    end
end