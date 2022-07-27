classdef PlateLoss
    properties %(input)
       Temp_face {mustBeNumeric} % Temperature at the face [K]
       Temp_surr {mustBeNumeric} % Temperature of the surrounding [K]
       Temp_fluid {mustBeNumeric} % Temperature of the fluid leaking [K]
       Length {mustBeNumeric} % Length of the plate [m]
       Width {mustBeNumeric} % Width of the plate [m]
       Thickness {mustBeNumeric} % Thickness of the plate [m]
       Material % Material ['ss' 'in' 'hexane' 'n-dodecane' 'air']
       Fluid % Fluid ['hexane' 'n-dodecane']
       Orientation % Orientation of the Plate ['v' for Vertical else horizontal]
       Mass_rate % Mass flow rate of leakage[5.6e-5 - 1.7e-4 (kg/s) **CONVERT TO g/s
       Loss1 % Loss in a face
       Loss2 % Loss in a face
       Loss3 % Loss in a face
       Loss4 % Loss in a face
       Loss5 % Loss in a face
       Loss6 % Loss in a face
       PHeating % Thermal power of the heater -- for know assumed constant
    end
    properties %(dependent)
        TotalLoss % Heat losses of the system
    end
    methods
        function Loss = PlateLoss(m,f,Tsurr,Tface,Tfluid,l,w,t,o,Ph,mfr)
           if nargin > 0
           Loss.Material = m;
           Loss.Fluid = f;
           Loss.Temp_surr = Tsurr;
           Loss.Temp_face = Tface;
           Loss.Temp_fluid = Tfluid;
           Loss.Length = l;
           Loss.Width = w;
           Loss.Thickness = t;
           Loss.Orientation = o;
           Loss.Mass_rate = mfr;
           Loss.Loss1 = Impingement(Loss.Material,Loss.Fluid,Loss.Temp_fluid,Loss.Temp_face,Loss.Length,Loss.Width,Loss.Orientation,Loss.Mass_rate);
          % Loss.Loss1 = Faces(Loss.Material,'air',Loss.Temp_surr,Loss.Temp_face,Loss.Length,Loss.Width,Loss.Orientation);
           Loss.Loss2 = Faces(Loss.Material,'air',Loss.Temp_surr,Loss.Temp_face,Loss.Length,Loss.Width,Loss.Orientation);
           Loss.Loss3 = Faces(Loss.Material,'air',Loss.Temp_surr,Loss.Temp_face,Loss.Length,Loss.Thickness,Loss.Orientation);
           Loss.Loss4 = Faces(Loss.Material,'air',Loss.Temp_surr,Loss.Temp_face,Loss.Length,Loss.Thickness,Loss.Orientation);
           Loss.Loss5 = Faces(Loss.Material,'air',Loss.Temp_surr,Loss.Temp_face,Loss.Length,Loss.Thickness,Loss.Orientation);
           Loss.Loss6 = Faces(Loss.Material,'air',Loss.Temp_surr,Loss.Temp_face,Loss.Length,Loss.Thickness,Loss.Orientation);
           Loss.PHeating = Ph;
           end
        end
        function Tloss = get_TotalLoss(Loss)
            Tloss = (Loss.Loss1.TotalLoss +Loss.Loss2.FaceLoss + Loss.Loss3.FaceLoss + Loss.Loss4.FaceLoss + Loss.Loss5.FaceLoss + Loss.Loss6.FaceLoss)/1000;
        end
        function Loss = updateTface(Loss, T)
            Loss.Temp_face = T;
            Loss.Loss1 = Loss.Loss1.updateTface(Loss.Temp_face);
            Loss.Loss2 = Loss.Loss2.updateTface(Loss.Temp_face);
            Loss.Loss3 = Loss.Loss3.updateTface(Loss.Temp_face);
            Loss.Loss4 = Loss.Loss4.updateTface(Loss.Temp_face);
            Loss.Loss5 = Loss.Loss5.updateTface(Loss.Temp_face);
            Loss.Loss6 = Loss.Loss6.updateTface(Loss.Temp_face);
            Loss.TotalLoss = Loss.get_TotalLoss();
        end
        function RHS = ODERHS(Loss,T)
            Loss = Loss.updateTface(T);
            A = Loss.Loss1.Material.rho * Loss.Loss1.Material.capacity * Loss.Length * Loss.Width * Loss.Thickness;
            RHS = 1 / A * (Loss.PHeating - Loss.get_TotalLoss());
            % TODO: replace A by adequate quantities to match your ODE (Complete)
            % TODO: confirm that Loss.get_TotalLoss is a positive quantity (Complete as long as T > 298)
            end
        function TEq = TEquil(Loss)
            % TODO: implement function that returns TEq such that Loss.ODERHS(T) == 0
            fun = @(T) Loss.ODERHS(T); % function
            T0 = [298 1700]; % initial interval
            % options = optimset('Display','iter'); % show iterations
            TEq = fzero(fun,T0);
        end
        
        function [tvec,Tvec] = ODESolve(Loss,tmax,TStopCrit)
            % Solve the ODE equation dT/dt = Loss.ODERHS(T)
            % Return solution vectors tvec (time) and Tvec (temperature)
            % Initial solution T(t=0) = Loss.Tface
            % Stops solving the ODE at t_f such that T(t_f) > TStopCrit
            % tmax: max time up to which integration is conducted (in case TStopCrit is not reached)
            
            PlateLoss.setTStopCrit(TStopCrit);
            dummyfun = @(t,T) Loss.ODERHS(T);
            options = odeset('Events',@PlateLoss.stopODE);
            [tvec,Tvec] = ode45(dummyfun, [0 tmax], Loss.Temp_face,options);
                
            crit = Loss.TEquil * .99;
            time = interp1(Tvec,tvec,crit);
            disp(append('Time to heat ',string(time),' seconds'));
            
            plot(tvec,Tvec);
            grid on;
            xlabel('Time (s)');
            ylabel('Temeprature (K)');
            title(append(Loss.Material,' ','Plate Heating'));
        end
    end
    
    methods (Static)
      function out = setTStopCrit(Tstop)
         persistent TstopCrit;
         % Set the stopping criterion parameter for the ODE solver
         if nargin
            TstopCrit = Tstop;
         end
         out = TstopCrit;
      end
      function [value,isterminal,direction] = stopODE(t,y)
        % dummy function used within ODESolve
        stopT = PlateLoss.setTStopCrit();
        value = y - stopT;
        isterminal = 1;
        direction = 0;
      end
   end
   
end
