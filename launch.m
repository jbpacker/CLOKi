function launch()

% Copyright (C) 2013 Georgia Tech Research Corporation
% see the LICENSE file included with this software

clear java;
clear classes;
close all
clear all
clc

if (isdeployed)
    [path, folder, ~] = fileparts(ctfroot);
    root_path = fullfile(path, folder);
else
    root_path = fileparts(mfilename('fullpath'));
end
addpath(genpath(root_path));

javaaddpath(fullfile(root_path, 'java'));

app = simiam.ui.AppWindow(root_path, 'launcher');
   
app.load_ui();
settings_file = 'settings8.xml';
app.ui_button_start([],[], settings_file);

%% create arrays for changing variables

%changing the %random. each case in the array will be tested.
% it's a scale from 0-1. 1 is fully random, and 0 is no random.
random_span = linspace(0,0,1); %set to 0 for sensor tuning

%changing the gains - I haven't worked this one out yet, but it'll likely
%take the spot of random in a parallel simulation. IR sensor gains [left - mid - right]
gain_span = [1 1 1 1 1;
    1 2 3 2 1;
    1 1 3 1 1;
    1 3 7 3 1;
    1 2 5 2 1;
    1 5 3 5 1;
    1 2 2 2 1;
    1 3 2 3 1;
    2 3 1 3 2;
    3 2 1 2 3;
    2 2 1 2 2;
    3 1 1 1 3];

%amount of times each simulation is run
%set to 1 for sensor tuning
redundancy = 1;

%number of initial conditions to run through. 1-..
initialConditions = 2;

%changing variable loop
for delta = 1:length(gain_span(:,1))
    randomness = 0;
    gains = gain_span(delta,:)
    
    %initial conditions loop
    for i = 1:initialConditions
        
        %redundancy loop
        for r = 1:redundancy
            %swap out .xml map for initial conditions 
            settings_file = strcat('settings', num2str(i), '.xml');

            %run the program
            app.ui_button_start([],[], settings_file); %this loads simulator & does inital conditions
            for z=1:10
                app.ui_button_zoom_out([],[]);
            end
            app.simulator_.stop();
            %% do something to change variables. You'll have access to pretty much
            %  access to anything since it's all been created (access to the
            %  creation will be much trickier

            % set clocky's percent randomness
            app.simulator_.world.robots.elementAt(1).supervisor.set_percent_random(randomness);
            % set clockys sensor gains
            app.simulator_.world.robots.elementAt(1).supervisor.controllers{5}.set_sensor_gains(gains);
            %% re-start simulation
            app.simulator_.start();
            %detect collision or game ender
            pause(1);
            %% save variables
            clockyFinalx(i, delta, r) = app.simulator_.world.robots.elementAt(1).pose.x;
            clockyFinaly(i, delta, r) = app.simulator_.world.robots.elementAt(1).pose.y;
            humanFinalx(i, delta, r) = app.simulator_.world.robots.elementAt(2).pose.x;
            humanFinaly(i, delta, r) = app.simulator_.world.robots.elementAt(2).pose.y;
            finalTime(i, delta, r) = 0.05*get(app.simulator_.clock, 'TasksExecuted');

            %right now only tracks the final loop's path.
            clockyPath(:,:,i, delta, r) = app.simulator_.clockyRec;
            humanPath(:,:,i, delta, r) = app.simulator_.humanRec;

            %go to 'home'
            app.ui_button_home([],[]);
        end
    end
end
%% export to workspace (before plotting because errors)
putvar(clockyFinalx);
putvar(clockyFinaly);
putvar(humanFinalx);
putvar(humanFinaly);
putvar(finalTime);
putvar(humanPath);
putvar(clockyPath);

%% plot
close all

% endtime plot with error! that way we can see the spread of values
figure
legendString = [];
bar(finalTime(:,:,1)')
hold on
for i = 1:initialConditions
    legendString{i} = strcat('initial condition # ',num2str(i));
end
legend(legendString)
xlabel('Sensor Set')
ylabel('Chase Time')
title('Chase time for changing sensor weightings')

%% something special for the paths
deltaVec = hsv(length(clockyPath(1,1,1,:,1)));
legendString = [];

for i = 1:initialConditions
    figure
    for delta = 1:length(clockyPath(1,1,1,:,1))
        %identify what/'s of current interest
        cx = clockyPath(:,1,i,delta,1);
        cy = clockyPath(:,2,i,delta,1);
        hx = humanPath(:,1,i,delta,1);
        hy = humanPath(:,2,i,delta,1);

        %cut off trailing zeros
        cx = cx(2:find(cx,1,'last'));
        cy = cy(2:find(cy,1,'last'));
        hx = hx(2:find(hx,1,'last'));
        hy = hy(2:find(hy,1,'last'));

        %plot, points represent finish points
        plotVar = plot(cx, cy,'Color', deltaVec(delta,:), 'LineWidth', 2);
        hold on
        plot(hx, hy,'Color', deltaVec(delta,:), 'LineWidth', 2);

        clockyPoint = scatter(clockyFinalx(i,delta,1), clockyFinaly(i,delta,1), 100, 'g');
        humanPoint = scatter(humanFinalx(i,delta,1), humanFinaly(i,delta,1), 100, 'r');
        legendAssist(delta) = plotVar;
        legendString{delta} = strcat('sensor configureation #', num2str(delta));
    end
    legendAssist(length(clockyPath(1,1,1,:,1))+1) = clockyPoint;
    legendString{length(clockyPath(1,1,1,:,1))+1} = 'cloki end position';
    legendAssist(length(clockyPath(1,1,1,:,1))+2) = humanPoint;
    legendString{length(clockyPath(1,1,1,:,1))+2} = 'human end position';
    legend(legendAssist, legendString)
    xlabel('x position')
    ylabel('y position')
    title(strcat('initial condition #', num2str(i)))
end
end
