classdef Faces
    properties %(input)
       Temp_face {mustBeNumeric} % Temperature at the face [K]
       Temp_surr {mustBeNumeric} % Temperature of the surrounding [K]
       Length {mustBeNumeric} % Length of the plate's side [m]
       Width {mustBeNumeric} % Width of the plate's side [m]
       Material % Material ['ss' 'in' 'hexane' 'n-dodecane' 'air']
       Orientation % Orientation of the Plate ['v' for Vertical else horizontal]
       Fluid % Surrounding Fluid Property
    end
    properties %(constants)
       Gravity = 9.81; % Earths Gravity [m/s^2]
       Sigma = 5.67e-8; % Stefan Boltzmann Constant[W/m^2*K^4]
    end
    properties %(dependent)
       Area % Area of the face
       Rayleigh % Rayleigh Number
       Beta % Coefficient of thermal expansion [K^-1]
       Nusselt % Nusselt Number
       ConvectionCoef % Convective coefficient [W/m^2*K]
       Qrad % Radiative Losses [W]
       Qconv % Convective Losses [W]
       FaceLoss % Total Losses associated to the face
    end
    methods
        function fac = Faces(m,f,Tsurr,Tface,l,w,o)
           if nargin > 0
           fac.Temp_surr = Tsurr;
           fac.Temp_face = Tface;
           m = lower(m);
           fac.Material = Materials(m,fac.Temp_face,fac.Temp_surr);
           fac.Fluid = Materials(f,fac.Temp_face,fac.Temp_surr);
           fac.Length = l;
           fac.Width = w;
           if strcmpi(o,'v')
               fac.Orientation = 'Vertical';
           else
               fac.Orientation = 'Horizontal';
           end
           end
        end
        
        function aval = get_Area(fac)
            aval = fac.Length * fac.Width;
        end
        
        function bval = get_Beta(fac)
            bval = 1/fac.Material.Tfilm; % p.598 (Bergman et al.)
        end
        
        % To obtain the rayleigh number the equation outlined in p.605
        % (Bergman et al.) was used.
        function rval = get_Rayleigh(fac)
            if strcmp(fac.Orientation,'Vertical')
                rval = fac.Gravity*fac.Beta*(fac.Temp_face-fac.Temp_surr)*fac.Length^3*fac.Fluid.Prandtl/fac.Fluid.viscosity^2;
            else
                Lc = fac.Area/(2*(fac.Length+fac.Width));
                rval = fac.Gravity*fac.Beta*(fac.Temp_face-fac.Temp_surr)*Lc^3*fac.Fluid.Prandtl/fac.Fluid.viscosity^2;
            end
        end
        
        function nval = get_Nusselt(fac)
            if strcmp(fac.Orientation,'Vertical')
                if fac.Rayleigh < 10^9
                    nval = .68+.67*fac.Rayleigh^.25/(1+(.492/fac.Fluid.Prandtl)^(9/16))^(4/9); % p.605 (Bergman et al.)
                else
                    nval = (.825+.387*fac.Rayleigh^(1/6)/(1+(.492/fac.Fluid.Prandtl)^(9/16))^(8/27))^2; % p.605 (Bergman et al.)
                end
            else
                if fac.Rayleigh > 10^4 && fac.Rayleigh < 10^9
                    nval = .59*fac.Rayleigh^(.25); % p.610 (Bergman et al.)
                elseif fac.Rayleigh > 10^9 && fac.Rayleigh < 10^13
                    nval = .1*fac.Rayleigh^(.33); % p.610 (Bergman et al.)
                else
                    nval = 0; % Negligible losses
                end
            end
        end
        
        function htc = get_ConvectionCoef(fac)
             htc = fac.Fluid.k_conductivity * fac.Nusselt/fac.Length; % p.602 (Bergman et al.)
        end
        
        function qrval = get_Qrad(fac)
            qrval = fac.Sigma*fac.Material.emissivity*fac.Area*(fac.Temp_face^4 - fac.Temp_surr^4); % p.10 (Bergman et al.)
        end
        function qcval = get_Qconv(fac)
            qcval = fac.ConvectionCoef*fac.Area*(fac.Temp_face-fac.Temp_surr); % p.8 (Bergman et al.)
        end
        
        function fl = get_FaceLoss(fac)
            fl = fac.Qrad + fac.Qconv;
        end
        
        function fac = updateTface(fac,T)
            fac.Temp_face = T;
            fac.Material = fac.Material.updateTface(fac.Temp_face);
            fac.Fluid = fac.Fluid.updateTface(fac.Temp_face);
            fac.Area = fac.get_Area();
            fac.Beta = fac.get_Beta();
            fac.Rayleigh = fac.get_Rayleigh();
            fac.Nusselt = fac.get_Nusselt();
            fac.ConvectionCoef = fac.get_ConvectionCoef();
            fac.Qrad = fac.get_Qrad();
            fac.Qconv = fac.get_Qconv();
            fac.FaceLoss = fac.get_FaceLoss();
        end
    end
end
