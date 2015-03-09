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
settings_file = 'settings_test.xml';
app.ui_button_start([],[], settings_file);
app.simulator_.stop();
for z=1:10
    app.ui_button_zoom_out([],[]);
end
 % change variables
randomness = 0;
gains = [1 3 7 3 1];
alpha = .4;
filter = 30;
 
% set clocky's percent randomness
app.simulator_.world.robots.elementAt(1).supervisor.set_percent_random(randomness);
% set clockys sensor gains
app.simulator_.world.robots.elementAt(1).supervisor.controllers{5}.set_sensor_gains(gains);
% set clockys alpha
app.simulator_.world.robots.elementAt(1).supervisor.controllers{5}.set_alpha(alpha);
% set clocky's filter value
app.simulator_.world.robots.elementAt(1).supervisor.set_filter(filter);

fprintf('variables loaded\n')

% re-start simulation
app.simulator_.start();



%let it run
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

end
