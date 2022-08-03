classdef Materials
    properties %(input)
        Tface {mustBeNumeric} % Temperature of material[K]
        Material % Material ['ss' 'in' 'hexane' 'n-dodecane' 'air']
        Tsurr {mustBeNumeric} % Temperature of surrounding[K]
    end
    properties %(constants)
        rho % Desity of the material[kg/m^3]
        Latent % Latent heat of the fuel[J/g]
        CriticalTemp % Critical temperature of a fuel [K]
    end
    properties %(dependent)
        Tfilm % Film Temperature
        capacity % Heat Capacity of material[J/gK]
        emissivity % Emissivity of Material
        viscosity % Kinematic Viscosity[m^2/s]
        k_conductivity % Thermal Conductivity of Fluid[W/mK]
        Prandtl % Prandtl Number of Fluid
        airDtabase % Table of air properties
    end
    methods
        function mat = Materials(m,Tface,Tsurr,e)
            if nargin > 0
            mat.Tface = Tface;
            mat.Tsurr = Tsurr;
            m = lower(m);
            % Data for the rest of this function was obtained from the nist
            % database.
            if strcmp(m,'ss')
                mat.Material = 'Stainless Steel 304';
                mat.rho = 8000;
                mat.Emissivity = e;
            elseif strcmp(m,'in')
                mat.Material = 'Inconel 601';
                mat.rho = 8192;
                mat.Emissivity = e;
            elseif strcmp(m,'hexane')
                mat.Material = 'Hexane';
                mat.Latent = 371.337; 
                mat.CriticalTemp = 342.2;
            elseif strcmp(m,'n-dodecane')
                mat.Material = 'n-Dodecane';
                mat.Latent = 363.988;
                mat.CriticalTemp = 491;
            elseif strcmp(m,'air')
                mat.Material = 'Air';
                mat.airDtabase = load('airDtabase.mat');
            else
                error('Material not recognized');
            end
            end
        end
        
        function ftemp = get_Tfilm(mat)
            ftemp = (mat.Tface+mat.Tsurr)/2; % P.406 (Bergman et al.)
        end
        
%         function eval = get_emissivity(mat)
%             if strcmp(mat.Material,'Stainless Steel 304')
%                 eval = .61; 
%             elseif strcmp(mat.Material,'Inconel 601')
%                 eval = .7;
%             else
%                 eval = 0;
%             end
%         end
        
        function val = get_capacity(mat)
            if strcmp(mat.Material,'Stainless Steel 304')
                val = .433+2e-4*mat.Tface-8e-10*mat.Tface^2; % ASM Handbook Volume 15 P.472
            elseif strcmp(mat.Material,'Inconel 601')
                val = .65; % ASM Handbook Volume 15 P.472
            elseif strcmp(mat.Material,'Hexane')
                val = 2.26; % Engineering Toolbox
            elseif strcmp(mat.Material,'n-Dodecane')
                val = 2.21; % Engineering Toolbox
            else
                val = 0;
            end
        end
        
% The following three values were extracted from the textbook data on air.
% P.995 Fundamentals of Heat and Mass Transfer 7th Edition(Bergman et al.)
        function vval = get_viscosity(mat)
            if strcmp(mat.Material,'Air')
                vval = interp1(mat.airDtabase.Temp,mat.airDtabase.kviscosity,mat.Tfilm);
            else
                vval = 0;
            end
        end
        function kval = get_k_conductivity(mat)
            if strcmp(mat.Material,'Air')
                kval = interp1(mat.airDtabase.Temp,mat.airDtabase.kconductivity,mat.Tfilm);
            else
                kval = 0;
            end
        end
        function pval = get_Prandtl(mat)
            if strcmp(mat.Material,'Air')
                pval = interp1(mat.airDtabase.Temp,mat.airDtabase.prandtl,mat.Tfilm);
            else
                pval = 0;
            end
        end
        
        function mat = updateTface(mat,T)
            mat.Tface = T;
            mat.Tfilm = mat.get_Tfilm();
%             mat.emissivity = mat.get_emissivity();
            mat.capacity = mat.get_capacity();
            mat.viscosity = mat.get_viscosity();
            mat.k_conductivity = mat.get_k_conductivity();
            mat.Prandtl = mat.get_Prandtl();
        end
    end
end
