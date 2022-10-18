classdef DOXY_201_202_202 < DOXY_X_X_202
    % Derivation class for case 201_202_202.
    
    
    % title - s DOXY_201_202_202 vr - 1.0 author - bodc/vidkri date - 20221013
    
    methods
        function output = compute_parameter(self)
            % Primary method for dissolved oxygen derivation.
            %
            % derivation.compute_parameter()
            %
            
            % Fetch all required parameters from source data

            bphasedoxy = self.variables('BPHASE_DOXY');
            rphasedoxy = self.variables('RPHASE_DOXY');
            pres = self.variables('PRES');
            temp = self.variables('TEMP');
            psal = self.variables('PSAL');

            % Any adjustments or transformations applied to source data
            % to meet expectations of the underlying eqaution should happen
            % here.

		            
            % Compute desired output value(s)
            doxy = self.equation(bphasedoxy, rphasedoxy, pres, temp, psal,self.coeffs );
            if isempty(self.coeffs) 
                error('Error: calibration coefficients not set');
            else
            % Any subsequent adjustments or transformations for consistency
            % should happen here.
            
            % Return the desired output
                output = doxy;
            end
        end
    end
end
