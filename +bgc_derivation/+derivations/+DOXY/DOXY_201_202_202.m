classdef DOXY_201_202_202 < bgc_derivation.derivations.DOXY.DOXY_X_X_202
    % Derivation class for case 201_202_202.
    
    
    % title - s DOXY_201_202_202 vr - 1.1 author - bodc/vidkri date - 20221013
    %
    % mods - 1.1 - Minor tweaks to names and shapes for integration with
    %              BODC processing pipeline.               (matcaz20221021)
    %
    
    methods
        function output = compute_parameter(self)
            % Primary method for dissolved oxygen derivation.
            %
            % derivation.compute_parameter()
            %
            
            import bgc_derivation.utils.force_row
            
            % Fetch all required parameters from source data/metdata
            pres = self.variables.p;
            temp = self.variables.t;
            psal = self.variables.s;
            bphase = self.variables.TPhase;

            % Any adjustments or transformations applied to source data
            % to meet expectations of the underlying eqaution should happen
            % here.
            pres = force_row(pres);
            temp = force_row(temp);
            psal = force_row(psal);
            bphase = force_row(bphase);
            rphase = zeros(size(bphase));
            
            % Final checks
            if isempty(self.coeffs) 
                error('Error: calibration coefficients not set');
            end
		            
            % Compute desired output value(s)
            doxy = self.equation(bphase, rphase, pres, temp, psal, self.coeffs);
            
            % Any subsequent adjustments or transformations for consistency
            % should happen here.
            if any(size(pres) ~= size(self.variables.p))
                % Restore orientation
                doxy = doxy';
            end
            
            % Return the desired output
            output = doxy;
        end
    end
end
