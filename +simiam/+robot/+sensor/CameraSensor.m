classdef CameraSensor < simiam.ui.Drawable
    
% Copyright (C) 2013, Georgia Tech Research Corporation
% see the LICENSE file included with this software

    properties
        type
        
        min_range   % minimum range of proximity sensor
        max_range   % maximum range of proximity sensor
        spread      % view angle of proximity sensor
        location    % placement location on robot
        danger      % true if human is visible
        
        map         % if sensor is not natively [m], convert to [raw]
        
        noise_model
    end
    
    properties (Access = private)
        range       % measured range to detected object
    end
    
    methods
        
        function obj = CameraSensor(parent, type, r_pose, pose, r_min, r_max, phi, varargin)
            obj = obj@simiam.ui.Drawable(parent, r_pose);
            
            obj.type = type;
            obj.location = pose;
            obj.danger = 0; %false, not in danger
            
            T = obj.location.get_transformation_matrix();
            r = r_max;
            r1 = r*tan(phi/4);
            r2 = r*tan(phi/2);
            camera_cone =  [              0     0   1;
                             sqrt(r^2-r2^2)    r2   1;
                             sqrt(r^2-r1^2)    r1   1;
                                          r     0   1;
                             sqrt(r^2-r1^2)   -r1   1;
                             sqrt(r^2-r2^2)   -r2   1];
            obj.add_surface(camera_cone*T', [1 1 1], 0);
            set(obj.surfaces.head_.key_.handle_, 'EdgeColor', [0 0 0]);%'b');
            
            obj.range = r;
            obj.spread = phi;
            
            obj.max_range = r_max;
            obj.min_range = r_min;
            
            switch(length(varargin))
                case 0 
                    obj.map = str2func('simiam.robot.sensor.CameraSensor.identity_map');
                case 1 
                    if (isa(varargin{1}, 'simiam.robot.sensor.noise.NoiseModel'))
                        obj.map = str2func('simiam.robot.sensor.CameraSensor.identity_map');
                        obj.noise_model = varargin{1};
                    else
                        obj.map = str2func(varargin{1});
                        obj.noise_model = simiam.robot.sensor.noise.GaussianNoise(0,0.0);
                    end
                case 2
                    if (isa(varargin{1}, 'simiam.robot.sensor.noise.NoiseModel'))
                        obj.map = str2func(varargin{2});
                        obj.noise_model = varargin{1};
                    else
                        obj.map = str2func(varargin{1});
                        obj.noise_model = varargin{2};
                    end
            end
        end
               
        function update_range(obj, distance)
            obj.range = obj.limit_to_sensor(obj.noise_model.apply_noise(distance));            
            distance = obj.range;
            
            r1 = distance*tan(obj.spread/4);
            r2 = distance*tan(obj.spread/2);
            camera_cone =  [                     0    0   1;
                             sqrt(distance^2-r2^2)   r2   1;
                             sqrt(distance^2-r1^2)   r1   1;
                                          distance    0   1;
                             sqrt(distance^2-r1^2)  -r1   1;
                             sqrt(distance^2-r2^2)  -r2   1];
            T = obj.location.get_transformation_matrix();
%             surface = obj.surfaces.get_iterator().next();
            surface = obj.surfaces.head_.key_;
%             surface.geometry_ = sensor_cone*T';
            surface.update_geometry(camera_cone*T');
            
            if (distance < obj.max_range && obj.danger == 1)
                set(surface.handle_, 'EdgeColor', 'r');
                set(surface.handle_, 'FaceColor', 'w');%[1 0.8 0.8]);
            else
                set(surface.handle_, 'EdgeColor', [0 0 0]);
                set(surface.handle_, 'FaceColor', 'w');%[0 1 1]);
            end
            obj.draw_surfaces();
        end
        
        function raw = get_range(obj)
            s = obj.map;
            raw = s(obj.range);
        end
        
        function distance = limit_to_sensor(obj, distance)
            distance = min(max(distance, obj.min_range), obj.max_range);
        end
        
    end
    
    methods (Static)
        
        function raw = identity_map(varargin)
            distance = cell2mat(varargin);
            raw = distance;
        end
    end
end