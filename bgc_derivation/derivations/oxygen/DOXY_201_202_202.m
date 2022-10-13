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
            Sref = 0,
			Spreset =self.variables('Spreset'),
            Pcoef1= self.variables('Pcoef1'), 
			Pcoef2= self.variables('Pcoef2'),
			Pcoef3 = self.variables('Pcoef3'),
            B0 = self.variables('B0'),
			B1 = self.variables('B1'),
			B2 = self.variables('B2'),
			B3 = self.variables('B3'),
            C0 =self.variables('C0'),
            D0 = self.variables('D0'),
			D1 = self.variables('D1'),
			D2 = self.variables('D2'),
			D3 = self.variables('D3'),
            PhaseCoef0 = self.variables('PhaseCoef0'), 
			PhaseCoef1 = self.variables('PhaseCoef1'), 
			PhaseCoef2 = self.variables('PhaseCoef2'), 
			PhaseCoef3 = self.variables('PhaseCoef3'),
            tabCoef = self.variables('tabCoef'),
            pres = self.variables('PRES');
            temp = self.variables('TEMP');
            psal = self.variables('PSAL');
            
            % Any adjustments or transformations applied to source data
            % to meet expectations of the underlying eqaution should happen
            % here.
			%generate a matrix of certain coeff
			function matrix  =  gentabmatrix(self)
				fields  =  fieldnames(self.variables);
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
						matrix(ii+1,jj+1)  =  self.variables(fieldname);
					end
				end 
			end
            
            % Compute desired output value(s)
            doxy = self.equation(bphase, rphase,pres,temp,psal, coeffs);
            
            % Any subsequent adjustments or transformations for consistency
            % should happen here.
            
            % Return the desired output
            output = doxy;
        end
    end
end
