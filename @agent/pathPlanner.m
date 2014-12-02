function outPara = pathPlanner(agent,inPara)
% include IPOPT in YALMIP
addpath('D:\Program Files\MATLAB\2013a_crack\IPOPT3.11.8');
% define input arguments
x_h = inPara.pre_traj; % predicted human trajectory
hor = inPara.hor;
safe_dis = inPara.safe_dis;
mpc_dt = inPara.mpc_dt;

% define MPC
x = sdpvar(3,hor+1); %[x,y,v]
u = sdpvar(2,hor); %[psi,a]
obj = 0;

% initial condition
constr = [x(:,1) == [agent.currentPos(1:2);agent.currentV]];

for ii = 1:hor
    obj = obj+sum((x(1:2,ii+1)-x_h(:,ii+1)).^2)+abs(u(2,ii));
    % constraints on robot dynamics
    constr = [constr,x(1:2,ii+1) == x(1:2,ii)+x(3,ii)*[cos(u(1,ii));sin(u(1,ii))]*mpc_dt,...
        x(3,ii+1) == x(3,ii)+u(2,ii)*mpc_dt];%,-agent.maxA<=u(2,ii)<=agent.maxA];   
    % constraint on safe distance
    constr = [constr,sum((x(1:2,ii+1)-x_h(:,ii+1)).^2) >= safe_dis^2];
    % constraint on obstacle avoidance
end
opt = sdpsettings('solver','ipopt','usex0',1);
sol = optimize(constr,obj,opt);
if sol.problem == 0
    fut_x = value(x); % current and future states
    fut_u = value(u); % future input
else
    display('Fail to solve MPC')
    sol.info
    yalmiperror(sol.problem)
end
outPara = struct('fut_x',fut_x,'fut_u',fut_u);