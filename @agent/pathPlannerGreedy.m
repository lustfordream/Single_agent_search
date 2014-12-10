function outPara = pathPlannerGreedy(agent,inPara)
% define input arguments
plan_type = inPara.plan_type;
if strcmp(plan_type,'greedy1')
    x_h = inPara.pre_traj(:,2); % predicted human trajectory at one step ahead
elseif strcmp(plan_type,'greedy0')
    x_h = inPara.pre_traj(:,1); % no prediction. reflex-based robot
end
hor = inPara.hor;
safe_dis = inPara.safe_dis;
mpc_dt = inPara.mpc_dt;
h_v = inPara.h_v; % human current speed
obs_info = inPara.obs_info;
safe_marg = inPara.safe_marg;

% define parameters
% non_intersect_flag = 0; % flag for showing whether imposing the non-intersection constraint
dt = 0.05; % time interval for sampling the points on the line of the robot's path. used for imposing non-intersection constriant
safe_marg2 = 0.1; % margin for the robot's path line from the obstacle

x_r = agent.currentPos(1:2);
r_v = agent.currentV;
maxA = agent.maxA;
h_hd = calAngle(h_v); % human heading

% safety constraint
% collision avoidance with human
rh_dis = sqrt(sum((x_r(1:2) - x_h(1:2)).^2)); % distance between robot's current and human's position

if (rh_dis >= safe_dis) % if robot is outside of the collision region
    % determine robot heading and the furthest feasible next position
    theta = calAngle(x_h-x_r);
    
    x_r_feas_next = x_r+r_v*[cos(theta);sin(theta)]*mpc_dt;
    rh_next_feas_dis = sqrt(sum((x_r_feas_next(1:2) - x_h(1:2)).^2)); % distance between robot's next and human's position
    rr_next_feas_dis = sqrt(sum((x_r_feas_next(1:2) - x_r(1:2)).^2)); % distance between robot's current and next position
    if (rh_next_feas_dis < safe_dis) && (rr_next_feas_dis < rh_dis)
        % if the next waypoint is inside the safe distance around the human and not
        % crossing the human
        
        % get the robot's safe travel distance
        %     r_dis = sqrt(sum((x_r(1:2)-x_h(1:2)).^2)) - safe_dis;
        %     x_r_feas_next = r_dis/sqrt(sum((x_r(1:2)-x_r_feas_next(1:2)).^2))*(x_r_feas_next-x_r)+x_r;
        
        % get robot's new heading
        d_theta = acos((rh_dis^2+rr_next_feas_dis^2-safe_dis^2)/(2*rh_dis*rr_next_feas_dis));
        posb_theta = theta+[1;-1]*d_theta; % possible robot heading
        [~,tmp_idx] = min(abs(posb_theta-h_hd)); % choose the one that is closer to human's heading
        theta = posb_theta(tmp_idx);
        x_r_next = x_r+r_v*[cos(theta);sin(theta)]*mpc_dt;
    elseif (rr_next_feas_dis >= rh_dis)
        % if robot will cross human
        d_theta = asin(safe_dis/rh_dis);
        posb_theta = theta+[1;-1]*d_theta; % possible robot heading
        [~,tmp_idx] = min(abs(posb_theta-h_hd)); % choose the one that is closer to human's heading
        theta = posb_theta(tmp_idx);
        x_r_next = x_r+r_v*[cos(theta);sin(theta)]*mpc_dt;
    else
        x_r_next = x_r_feas_next;
    end
else %if robot is inside the collision region
    % for simplicity, just let the robot move opposite to human's next
    % position. can consider improving this later.
    theta = -calAngle(x_h-x_r); % 
    x_r_feas_next = x_r+r_v*[cos(theta);sin(theta)]*mpc_dt;
%     rh_next_feas_dis = sqrt(sum((x_r_feas_next(1:2) - x_h(1:2)).^2)); % distance between robot's next and human's position
%     rr_next_feas_dis = sqrt(sum((x_r_feas_next(1:2) - x_r(1:2)).^2)); % distance between robot's current and next position
%     if (rh_next_feas_dis <= safe_dis) 
        % if the next waypoint is still inside the safe distance around the human
        
        % get the robot's safe travel distance
        %     r_dis = sqrt(sum((x_r(1:2)-x_h(1:2)).^2)) - safe_dis;
        %     x_r_feas_next = r_dis/sqrt(sum((x_r(1:2)-x_r_feas_next(1:2)).^2))*(x_r_feas_next-x_r)+x_r;
        
        % get robot's new heading
        x_r_next = x_r_feas_next;
end

% obstacle avoidance
%{
for jj = 1:size(obs_info,2)
%     if sum((x(1:2,ii+1)-obs_info(1:2,jj)).^2) - (obs_info(3,jj)+safe_marg)^2 < 0
        
    if non_intersect_flag == 1
        % line not intersecting with the obstacle
        n = floor(mpc_dt/dt);
        x0 = obs_info(1,jj); y0 = obs_info(2,jj);
        r = obs_info(3,jj);
        for kk = 0:n
            constr = [constr,sum((kk/n*x(1:2,ii+1)+(n-kk)/n*x(1:2,ii)-obs_info(1:2,jj)).^2)>=(r+safe_marg2)^2];
        end
    end
%     end
%}

% chang robot speed to match human's current estimated speed
min_v = r_v - maxA*mpc_dt;
max_v = r_v + maxA*mpc_dt;
if norm(h_v,2) >= max_v
    r_v_next = max_v;
elseif norm(h_v,2) <= min_v
    r_v_next = min_v;
else
    r_v_next = norm(h_v,2);
end
%}

% a snippet for changing robot speed using constant acceleration. Not
% compatiable with the idea of discretized speed that is constant between
% each time step
%{
r_dis2 = norm(x_r(1:2)-x_r_feas_next(1:2),2);
max_dis = r_v*mpc_dt+1/2*maxA*mpc_dt^2;% max distance that robot can travel using r_v and maxA within mpc_dt
if max_dis < r_dis2 % robot uses max acceleration
    r_a = maxA;
    r_v_next = r_v+maxA*mpc_dt;
    x_r_next = x_r(1:2)+
else
    r_a = 2*(r_dis2-r_v*mpc_dt)/mpc_dt^2;
    r_v_next = r_v+r_a*mpc_dt;
end
%}
opt_x = [[x_r;r_v],[x_r_next*ones(1,hor);r_v_next,zeros(1,hor-1)]];
opt_u = [[theta;(r_v_next-r_v)/mpc_dt],zeros(2,hor-1)];
outPara = struct('opt_x',opt_x,'opt_u',opt_u);
end

function dis = dis_pl(p,v1,v2) % point-to-line distance
% define line equation: ax+by+c = 0
a = v2(2)-v1(2);
b = v1(1)-v2(1);
c = v1(2)*v2(1)-v2(2)*v1(1);
% poin-to-line distance
dis = (a*p(1)+b*p(2)+c)^2/(a^2+b^2);
end

function [a,b,c] = getLine(v1,v2)
% define line equation: ax+by+c = 0
a = v2(2)-v1(2);
b = v1(1)-v2(1);
c = v1(2)*v2(1)-v2(2)*v1(1);
end