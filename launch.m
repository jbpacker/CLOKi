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
settings_file = 'settings_empty.xml';
app.ui_button_start([],[], settings_file);

for z=1:10
    app.ui_button_zoom_out([],[]);
end

pause(1);


clockyPath = app.simulator_.clockyRec;
humanPath = app.simulator_.humanRec;

putvar(humanPath);
putvar(clockyPath);

%identify what/'s of current interest
cx = clockyPath(:,1);
cy = clockyPath(:,2);
gx = clockyPath(:,3);
gy = clockyPath(:,4);
hx = humanPath(:,1);
hy = humanPath(:,2);

%cut off trailing zeros
cx = cx(2:find(cx,1,'last'));
cy = cy(2:find(cy,1,'last'));
gx = gx(2:find(gx,1,'last'));
gy = gy(2:find(gy,1,'last'));
hx = hx(2:find(hx,1,'last'));
hy = hy(2:find(hy,1,'last'));

close all
plot(cx, cy, gx, gy, hx, hy, 'LineWidth', 2)
legend('clocky', 'goal', 'human')

% %% create arrays for changing variables
% 
% %changing the %random. each case in the array will be tested.
% % it's a scale from 0-1. 1 is fully random, and 0 is no random.
% random_span = linspace(0,1,3); %11 is good for n
% 
% %changing the gains - I haven't worked this one out yet, but it'll likely
% %take the spot of random in a parallel simulation. IR sensor gains [left - mid - right]
% gain_span = [1 2 3 2 1;
%     1 1 1 1 1;
%     1 1 3 1 1];
% 
% %amount of times each simulation is run
% redundancy = 3;
% 
% %number of initial conditions to run through. 1-..
% initialConditions = 2;
% 
% %changing variable loop
% for delta = 1:length(random_span)
%     randomness = random_span(delta);
%     gains = gain_span(1,:);
%     
%     %initial conditions loop
%     for i = 1:initialConditions
%         
%         %redundancy loop
%         for r = 1:redundancy
%             %swap out .xml map for initial conditions 
%             settings_file = strcat('settings', num2str(i), '.xml');
% 
%             %run the program
%             app.ui_button_start([],[], settings_file); %this loads simulator & does inital conditions
%             for z=1:10
%                 app.ui_button_zoom_out([],[]);
%             end
%             app.simulator_.stop();
%             %% do something to change variables. You'll have access to pretty much
%             %  access to anything since it's all been created (access to the
%             %  creation will be much trickier
% 
%             % set clocky's percent randomness
%             app.simulator_.world.robots.elementAt(1).supervisor.set_percent_random(randomness);
%             % set clockys sensor gains
%             app.simulator_.world.robots.elementAt(1).supervisor.controllers{5}.set_sensor_gains(gains);
%             %% re-start simulation
%             app.simulator_.start();
%             %detect collision or game ender
%             pause(1);
%             %% save variables
%             clockyFinalx(i, delta, r) = app.simulator_.world.robots.elementAt(1).pose.x;
%             clockyFinaly(i, delta, r) = app.simulator_.world.robots.elementAt(1).pose.y;
%             humanFinalx(i, delta, r) = app.simulator_.world.robots.elementAt(2).pose.x;
%             humanFinaly(i, delta, r) = app.simulator_.world.robots.elementAt(2).pose.y;
%             finalTime(i, delta, r) = 0.05*get(app.simulator_.clock, 'TasksExecuted');
% 
%             %right now only tracks the final loop's path.
%             clockyPath(:,:,i, delta, r) = app.simulator_.clockyRec;
%             humanPath(:,:,i, delta, r) = app.simulator_.humanRec;
% 
%             %go to 'home'
%             app.ui_button_home([],[]);
%         end
%     end
% end
% %% export to workspace (before plotting because errors)
% putvar(clockyFinalx);
% putvar(clockyFinaly);
% putvar(humanFinalx);
% putvar(humanFinaly);
% putvar(finalTime);
% putvar(humanPath);
% putvar(clockyPath);
% 
% %% plot
% close all
% 
% % endtime plot with error! that way we can see the spread of values
% figure
% colorVec = hsv(initialConditions);
% legendString = [];
% for i = 1:initialConditions
%     y = mean(finalTime(i,:,:),3);
%     x = random_span;
%     e = std(finalTime(i,:,:),0,3);
%     errorbar(x, y, e,'Color',colorVec(i,:), 'LineWidth', 2)
%     hold on
%     legendString{i} = strcat('initial condition # ',num2str(i));
% end
% legend(legendString)
% xlabel('%randomness')
% ylabel('Chase Time')
% title('Chase time for changing randomness')
% 
% %% something special for the paths
% deltaVec = hsv(length(clockyPath(1,1,1,:,r)));
% humanVec = hsv(redundancy);
% legendString = [];
% 
% for i = 1:initialConditions
%     figure
%     for delta = 1:length(clockyPath(1,1,1,:,r))
%         for r = 1:redundancy
%             %identify what/'s of current interest
%             cx = clockyPath(:,1,i,delta,r);
%             cy = clockyPath(:,2,i,delta,r);
%             hx = humanPath(:,1,i,delta,r);
%             hy = humanPath(:,2,i,delta,r);
% 
%             %cut off trailing zeros
%             cx = cx(2:find(cx,1,'last'));
%             cy = cy(2:find(cy,1,'last'));
%             hx = hx(2:find(hx,1,'last'));
%             hy = hy(2:find(hy,1,'last'));
% 
%             %plot, points represent finish points
%             plotVar = plot(cx, cy,'Color', deltaVec(delta,:), 'LineWidth', 2);
%             plot(hx, hy,'Color', deltaVec(delta,:), 'LineWidth', 2);
%             hold on
%                 
%             clockyPoint = scatter(clockyFinalx(i,delta,r), clockyFinaly(i,delta,r), 100, 'g');
%             humanPoint = scatter(humanFinalx(i,delta,r), humanFinaly(i,delta,r), 100, 'r');
%             legendAssist(delta) = plotVar;
%             legendString{delta} = strcat('%random:', num2str(random_span(delta)));
%         end
%     end
%     legendAssist(length(clockyPath(1,1,1,:,r))+1) = clockyPoint;
%     legendString{length(clockyPath(1,1,1,:,r))+1} = 'cloki end position';
%     legendAssist(length(clockyPath(1,1,1,:,r))+2) = humanPoint;
%     legendString{length(clockyPath(1,1,1,:,r))+2} = 'human end position';
%     legend(legendAssist, legendString)
%     xlabel('x position')
%     ylabel('y position')
%     title(strcat('initial condition #', num2str(i)))
% end
end
