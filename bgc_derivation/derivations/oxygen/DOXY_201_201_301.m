classdef DOXY_201_201_301 < DOXY_X_X_301
    % Derivation class for case 201_201_301.
    % This class is an EXAMPLE and is not for actual usage.
    %
    
    % title - s DOXY_201_201_301 vr - 1.0 author - bodc/matcaz date - 20220811
    
    methods
        function output = compute_parameter(self)
            % Primary method for example dissolved oxygen derivation.
            %
            % derivation.compute_parameter()
            %
            
            % Fetch all required parameters from source data
            molar_doxy = self.variables('MOLAR_DOXY');
            pres = self.variables('PRES');
            temp = self.variables('TEMP');
            psal = self.variables('PSAL');
            
            % Any adjustments or transformations applied to source data
            % to meet expectations of the underlying eqaution should happen
            % here.
            if isempty(self.coeffs) 
                error('Error: calibration coefficients not set');
            else
                % Compute desired output value(s)
                doxy = self.equation(molar_doxy,pres,temp,psal, self.coeffs);
            end
            % Any subsequent adjustments or transformations for consistency
            % should happen here.
            
            % Return the desired output
            output = doxy;
        end
    end
end
