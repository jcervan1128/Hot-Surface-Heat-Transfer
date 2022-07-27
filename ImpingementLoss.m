classdef ImpingementLoss
    properties %(input)
       Temp_face {mustBeNumeric} % Temperature at the face [K]
       Temp_fluid {mustBeNumeric} % Temperature of the surrounding [K]
       Length {mustBeNumeric} % Length of the plate's side [m]
       Width {mustBeNumeric} % Width of the plate's side [m]
       Material % Material ['ss' 'in' 'hexane' 'n-dodecane' 'air']
       Fluid % Fuel that leaked ['hexane' 'n-dodecane']
       Orientation % Orientation of the Plate ['v' for Vertical else horizontal]
       Mass_rate % Mass flow rate of leakage[5.6e-5 - 1.7e-4 (kg/s) **CONVERT TO g/s when entering to maintain Watts output]
    end
    properties %(dependent)
       RCLoss % Losses due to radiation and natural convection
       VapLoss % Losses due to the vaporization of the leaked fuel
       TotalLoss % Sum of all losses associated to the face
    end
    methods
        function imp = ImpingementLoss(m,f,Tfluid,Tface,l,w,o,mfr)
           imp.Temp_fluid = Tfluid;
           imp.Temp_face = Tface;
           imp.Material = m;
           imp.Fluid = f;
           imp.Length = l;
           imp.Width = w;
           imp.Orientation = o;
           imp.Mass_rate = mfr;
           imp.RCLoss = Faces(m,'air',imp.Temp_fluid,imp.Temp_face,imp.Length,imp.Width,imp.Orientation);
        end
        function vap = get_VapLoss(imp)
            vap = imp.Mass_rate*(imp.Fluid.Latent+imp.Fluid.capacity*(imp.Fluid.CriticalTemp-imp.Temp_fluid));
        end
        function tloss = get_TotalLoss(imp)
            tloss = imp.RCLoss.FaceLoss + imp.VapLoss;
        end
        function imp = updateTface(imp,T)
            imp.Temp_face = T;
            imp.Material = imp.Material.updateTface(imp.Temp_face);
            imp.RCLoss = imp.RCLoss.updateTface(imp.Temp_face);
            imp.Fluid = imp.Fluid.updateTface(imp.Temp_face);
            imp.VapLoss = imp.get_VapLoss();
            imp.TotalLoss = imp.get_TotalLoss();
        end
    end
end
