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
%loop
for i = 1:2
    %swap out .xml map for initial conditions 
    
    
    %run the program
    app.ui_button_start([],[]); %this loads simulator & does inital conditions
    for i=1:10
        app.ui_button_zoom_out([],[]);
    end
    app.simulator_.stop();
    %do something to change variables. You'll have access to pretty much
    %anything you want since it's all been created 
    %  (just displaying right now)
    app.simulator_.world.robots.elementAt(1).pose
    app.simulator_.world.robots.elementAt(2).pose
    
    %re-start
    app.simulator_.start();
    %detect collision or game ender
    pause(1);
    
    %save variables
    app.simulator_.world.robots.elementAt(1).pose
    app.simulator_.world.robots.elementAt(2).pose
    
    %go to 'home'
    app.ui_button_home([],[]);
end

%plot what we've learned

end
