function launch()

% Copyright (C) 2013 Georgia Tech Research Corporation
% see the LICENSE file included with this software

clear java;
clear classes;
close all

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

%% create arrays for changing variables

%changing the %random. each case in the array will be tested.
% it's a scale from 0-1. 1 is fully random, and 0 is no random.
random_span = [0 .3 .7];

%random_span = linspace(0,1,10); %11 is good for n

%blend characteristic
alpha = .4;

%how often clocky resets goal
filter = 30;

%changing the gains - I haven't worked this one out yet, but it'll likely
%take the spot of random in a parallel simulation. IR sensor gains [left - mid - right]
gain_span = [1 3 7 3 1];

%amount of times each simulation is run
redundancy = 2;

%number of initial conditions to run through. 1-..
initialConditions = 1;

%changing variable loop
for delta = 1:length(random_span)
    randomness = random_span(delta);
    gains = gain_span(1,:);
    
    %initial conditions loop
    for i = 1:initialConditions
        
        %redundancy loop
        for r = 1:redundancy
            %swap out .xml map for initial conditions 
            settings_file = strcat('settings', num2str(i), '.xml');

            %run the program
            app.ui_button_start([],[], settings_file); %this loads simulator & does inital conditions
            app.simulator_.stop();
            for z=1:10
                app.ui_button_zoom_out([],[]);
            end
            %% do something to change variables. You'll have access to pretty much
            %  access to anything since it's all been created (access to the
            %  creation will be much trickier

            % set clocky's percent randomness
            app.simulator_.world.robots.elementAt(1).supervisor.set_percent_random(randomness);
            % set clocky's filter
            app.simulator_.world.robots.elementAt(1).supervisor.set_filter(filter);
            % set clockys sensor gains
            app.simulator_.world.robots.elementAt(1).supervisor.controllers{5}.set_sensor_gains(gains);
            % set clocky's blend alpha
            app.simulator_.world.robots.elementAt(1).supervisor.controllers{5}.set_alpha(alpha);
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
        putvar(clockyFinalx);
        putvar(clockyFinaly);
        putvar(humanFinalx);
        putvar(humanFinaly);
        putvar(finalTime);
        putvar(humanPath);
        putvar(clockyPath);
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

%% plot - all end time plots together
close all

% endtime plot with error! that way we can see the spread of values
figure
colorVec = hsv(initialConditions);
legendString = [];
for i = 1:initialConditions
    y = mean(finalTime(i,:,:),3);
    x = random_span;
    e = std(finalTime(i,:,:),0,3);
    errorbar(x, y, e,'Color',colorVec(i,:), 'LineWidth', 2)
    hold on
    legendString{i} = strcat('initial condition # ',num2str(i));
end
legend(legendString)
xlabel('%randomness')
ylabel('Chase Time')
title('Chase time for changing randomness')

% %% individual survival time plots
% 
% for i = initialConditions
%     figure
%     y = mean(finalTime(i,:,:),3);
%     x = random_span;
%     e = std(finalTime(i,:,:),0,3);
%     errorbar(x, y, e, 'LineWidth', 2)
%     hold on
%     xlabel('%randomness')
%     ylabel('Chase Time')
%     title(strcat('Survival Time for Changing Randomness in Room ', num2str(i)))
%     saveas(gcf, strcat('plots/errorBars room', num2str(i), '.png'))
% end

%% something special for the paths
deltaVec = hsv(length(clockyPath(1,1,1,:,1)));
humanVec = hsv(redundancy);
legendString = [];

for i = 1:initialConditions
    figure
    for delta = 1:length(clockyPath(1,1,1,:,1))
        for r = 1:redundancy
            %identify what/'s of current interest
            cx = clockyPath(:,1,i,delta,r);
            cy = clockyPath(:,2,i,delta,r);
            hx = humanPath(:,1,i,delta,r);
            hy = humanPath(:,2,i,delta,r);

            %cut off trailing zeros
            cx = cx(2:find(cx,1,'last'));
            cy = cy(2:find(cy,1,'last'));
            hx = hx(2:find(hx,1,'last'));
            hy = hy(2:find(hy,1,'last'));

            %plot, points represent finish points
            plotVar = plot(cx, cy,'Color', deltaVec(delta,:), 'LineWidth', 2);
            plot(hx, hy,'Color', deltaVec(delta,:), 'LineWidth', 2);
            hold on
                
            clockyPoint = scatter(clockyFinalx(i,delta,r), clockyFinaly(i,delta,r), 100, 'g');
            humanPoint = scatter(humanFinalx(i,delta,r), humanFinaly(i,delta,r), 100, 'r');
            legendAssist(delta) = plotVar;
            legendString{delta} = strcat('%random:', num2str(random_span(delta)));
        end
    end
    legendAssist(length(clockyPath(1,1,1,:,1))+1) = clockyPoint;
    legendString{length(clockyPath(1,1,1,:,1))+1} = 'cloki end position';
    legendAssist(length(clockyPath(1,1,1,:,1))+2) = humanPoint;
    legendString{length(clockyPath(1,1,1,:,1))+2} = 'human end position';
    legend(legendAssist, legendString)
    xlabel('x position')
    ylabel('y position')
    title(strcat('initial condition #', num2str(i)))
    axis([-2.5 2.5 -2 2])
end

% %% paths - but individual for each randomness in each room and robot
% deltaVec = hsv(length(clockyPath(1,1,1,:,1)));
% legendString = [];
% 
% % pick which rooms
% % initialConditions = 1:9;
% for i = initialConditions
%     for delta = 1:length(clockyPath(1,1,1,:,1))
%         for robot = 1:2
%             figure
%             for r = 1:redundancy
%                 %identify what/'s of current interest
%                 if robot == 1
%                     x = clockyPath(:,1,i,delta,r);
%                     y = clockyPath(:,2,i,delta,r);
%                 else
%                     x = humanPath(:,1,i,delta,r);
%                     y = humanPath(:,2,i,delta,r);
%                 end
% 
%                 %cut off trailing zeros
%                 x = x(2:find(x,1,'last'));
%                 y = y(2:find(y,1,'last'));
% 
%                 %plot, points represent finish points
%                 plotVar = plot(x, y,'Color', deltaVec(delta,:), 'LineWidth', 2);
%                 hold on
% 
%                 if robot == 1
%                     clockyPoint = scatter(clockyFinalx(i,delta,r), clockyFinaly(i,delta,r), 100, 'g');
%                 else
%                     humanPoint = scatter(humanFinalx(i,delta,r), humanFinaly(i,delta,r), 100, 'r');
%                 end
%                 legendAssist(delta) = plotVar;
%                 legendString{delta} = strcat('%random:', num2str(random_span(delta)));
%             end
%         xlabel('x position')
%         ylabel('y position')
%         if robot == 1
%             title(strcat('clocky, room #', num2str(i), ' %randomness: ', num2str(random_span(delta))));
%             t = strcat('room', num2str(i), ' rand', num2str(random_span(delta)), ' clocky');
%         else
%             title(strcat('human, room #', num2str(i), ' %randomness: ', num2str(random_span(delta))));
%             t = strcat('room', num2str(i), ' rand', num2str(random_span(delta)), ' human');
%         end
%         axis([-2.5 2.5 -2 2])
%         saveas(gcf, strcat('plots/', t, '.png'))
%         end
%     end
%     legendAssist(length(clockyPath(1,1,1,:,1))+1) = clockyPoint;
%     legendString{length(clockyPath(1,1,1,:,1))+1} = 'cloki end position';
%     legendAssist(length(clockyPath(1,1,1,:,1))+2) = humanPoint;
%     legendString{length(clockyPath(1,1,1,:,1))+2} = 'human end position';
% %     legend(legendAssist, legendString)
% 
% %     title(strcat('initial condition #', num2str(i)))
%     
% end

end
