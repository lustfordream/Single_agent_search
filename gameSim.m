% 11/24/2014
% this file is for the ME 290J course project
clc 
clearvars
clearvars -global % clear global variables
close all

%% Setup
scale = 1/3; % scale the size of the field
set(0,'DefaultFigureWindowStyle','docked');
%%% define agents %%%
% Human agent 1
h = agent('human');
h.currentPos = [30;10;0]*scale;%[290;30;0];%[3.5;15.5;pi/2]; % [x y heading]
% h.maxV = 1.5;
h.currentV = 1.5;
% h.dPsi = pi/2;
% h.maxDPsi = pi;

% Robot agent 1
r = agent('robot');
r.currentPos = [30;20;0]*scale;%[310;30;0]; %[23.5;0.5;0]; % [x y heading]
r.currentV = 1.5;
r.maxA = 0.5;
% r.dPsi = pi/2;
% r.maxDPsi = pi/4;

%%% Set field %%%
xLength = 300*scale; 
yLength = 300*scale; 
xMin = 0;
yMin = 0;
% tar_pos = [90,225,210,250,20;60,50,130,230,260]*scale; % target positions

%%% set way points
tar_pos = [90,230,210,250,20;60,30,130,230,260]*scale; % target positions
step_size = 1;
% manually pick the way pts for simulated human
% way_pts = [tar_pos(:,1:2),[190,190;90,110]*scale,tar_pos(:,3:4),[210,190;190,190]*scale,tar_pos(:,5)];
way_pts = getWayPts(tar_pos,scale,'h');

%%%

campus = field([xMin xMin+xLength/step_size yMin yMin+yLength/step_size],tar_pos);
campus.agentNum = 2;

obs_pos = cell(4,1); % vetices of obstacles
obs_pos(1) = {getWayPts(tar_pos,scale,'obs')};
obs_pos(2) = {[200,300,300,200;90,90,110,110]*scale};
obs_pos(3) = {[210,210,190,190;200,300,300,200]*scale};
obs_pos(4) = {[0,100,100,0;190,190,210,210]*scale};

%% Simulation
% simulation parameters
kf = 800; % simulation length (/s)
agents = [h r];
hor = 5; % MPC horizon (s)
pre_type = 'extpol'; % 'IMM' specify the method for predicting human motion
samp_rate = 20; % sampling rate (/Hz)
safe_dis = 3; %safe distance between human and robot
mpc_dt = 1; % sampling time for model discretization used in MPC

% initialize variables
obv_traj = zeros(2,0); % observed human trajectory
est_state = zeros(4,kf); % estimated human states for every second [x,vx,y,vy];
est_state(:,1) = [h.currentPos(1);h.currentV;h.currentPos(2);0]; % human starts with zero heading angle
pre_traj = zeros(2,hor+1,kf); % current and predicted future human trajectory
plan_state = zeros(3,hor+1,kf); % robot's current and planned future state [x,y,v]
r_state = zeros(3,kf); % robot's actual state [x,y,v]
r_input = zeros(2,kf); % robot's actual control input [psi,a]
wp_cnt = 1; % counter for waypoints
h_tar_wp = way_pts(:,wp_cnt); % the way point that the human is heading for

for k = 1:kf
    %% waypoint check
    % check if the human needs to choose the next way point
    display(k)
    inPara_ec = struct('h',agents(1),'way_pts',way_pts,'wp_cnt',wp_cnt,'mpc_dt',mpc_dt);
    [outPara_ec] = endCheck(inPara_ec);

    game_end = outPara_ec.game_end;
    arr_wp_flag = outPara_ec.arr_wp_flag; % the human has arrived at a way point
    
    if game_end == 1
        sprintf('total search time is %d',k-1)
        break
    end
    
    if arr_wp_flag == 1
        wp_cnt = wp_cnt+1;
        h_tar_wp = way_pts(:,wp_cnt);
    end
    
    %% both agents move
    % human moves to a way point and robot predicts and plans its own path
    inPara_ams = struct('agents',agents,'h_tar_wp',h_tar_wp,...
        'obv_traj',obv_traj,'est_state',est_state,...
        'pre_traj',pre_traj,'plan_state',plan_state,'r_state',r_state,'r_input',r_input,...
        'k',k,'hor',hor,'pre_type',pre_type,'samp_rate',samp_rate,...
        'safe_dis',safe_dis,'mpc_dt',mpc_dt);
    [outPara_ams] = agentMove(campus,inPara_ams);
    agents = outPara_ams.agents;
    obv_traj = outPara_ams.obv_traj; 
    est_state = outPara_ams.est_state; 
    pre_traj = outPara_ams.pre_traj; 
    plan_state = outPara_ams.plan_state; 
%     r_state = outPara_ams.r_state; 
%     r_input = outPara_ams.r_input; 
        
    %% plot trajectories
    % Plot future agent positions
    
    % plot specifications
    color_agent = {'r','g','r'};
    marker_agent = {'o','^','*'};
    line_agent = {'-','-','-'};
    orange = [1 204/255 0];
    color_target = {'m','b',orange};
    figure;
    hold on

    % draw targets
    for jj = 1:campus.targetNum
        h = plot(campus.targetPos(1,jj),campus.targetPos(2,jj),'MarkerSize',15);
        set(h,'Marker','p');
    end
    
    % draw obstacles
    for jj = 1:size(obs_pos)
        tmp_pos = obs_pos{jj};
        fill(tmp_pos(1,:),tmp_pos(2,:),'b');
    end
    
    xlim([0,campus.endpoints(2)]);
    ylim([0,campus.endpoints(4)]);
    
    % draw agent trajectory
    for ii = 1:length(agents)
        tmp_agent = agents(ii);
        h1 = plot(tmp_agent.traj(1,:),tmp_agent.traj(2,:),'markers',3);
        set(h1,'MarkerFaceColor',color_agent{ii});
        set(h1,'MarkerEdgeColor',color_agent{ii});
        set(h1,'Color',color_agent{ii});
        set(h1,'LineStyle',line_agent{ii});
        set(h1,'Marker',marker_agent{ii});
        h2 = plot(tmp_agent.currentPos(1),tmp_agent.currentPos(2),color_agent{ii},'markers',6);
        set(h2,'MarkerFaceColor',color_agent{ii});
        set(h2,'MarkerEdgeColor',color_agent{ii});
        set(h1,'Color',color_agent{ii});
        set(h2,'LineStyle',line_agent{ii});
        set(h2,'Marker',marker_agent{ii});
    end
    h3 = plot(pre_traj(1,:,k),pre_traj(2,:,k),color_agent{3},'markers',3);
    set(h3,'MarkerFaceColor',color_agent{3});
    set(h3,'MarkerEdgeColor',color_agent{3});
    set(h3,'Color',color_agent{3});
    set(h3,'LineStyle',line_agent{3});
    set(h3,'Marker',marker_agent{3});
    
    grid minor
    set(gca,'MinorGridLineStyle','-','XColor',[0.5 0.5 0.5],'YColor',[0.5 0.5 0.5])
    axis equal
    xlim([0,xLength]);ylim([0,yLength]);
    %}
end

%% save simulation result
%{
% save data
folder_path = ('.\sim_res');
file_name = fullfile (folder_path,'obv_traj.mat');
save (file_name,'obv_traj');

% save plot
folder_path = ('.\sim_res');
file_name = fullfile (folder_path,'agent_traj.fig');
h = gcf;
saveas (h,file_name);
% convert .fig to .pdf
file_name = fullfile (folder_path,'agent_traj');
h = gcf;
fig2Pdf(file_name,300,h);
%}