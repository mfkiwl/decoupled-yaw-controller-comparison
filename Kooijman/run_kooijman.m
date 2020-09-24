close all;
clear all;
addpath('../Common');
%% Simulation parameters
t = 0:0.01:10;
N = length(t);

param.m = 2;
param.g = 9.81;
param.d = 0.169;
param.c_tf = 0.0135;

J1 = 0.02;
J2 = 0.02;
J3 = 0.04;
param.J = diag([J1, J2, J3]);

%% Fixed disturbance
% Uncomment to use disturbances.
% param.use_disturbances = true;

% Uncomment to remove disturbances.
param.use_disturbances = false;

param.W_x = eye(3);
param.theta_x = [1, 0.8, -1]';

param.W_R = eye(3);
param.theta_R = [0.1, 0.1, -0.1]';

%% Controller gains
param.kp = 10;
param.kv = 4;
param.k1 = 6;
param.k2 = 2;

param.kW = 8;
param.kwy = 1;
%% Initial conditions
% x0 = [1, -1, 0]';
x0 = [0, 0, 0]';
v0 = [0, 0, 0]';
W0 = [0, 0, 0]';

e3 = [0, 0, 1]';
R0 = expm((pi - 0.01) * hat(e3));

X0 = [x0; v0; reshape(R0,9,1); W0];

%% Numerical integration
[t, X] = ode45(@(t, XR) eom_kooijman(t, XR, param), t, X0, ...
    odeset('RelTol', 1e-6, 'AbsTol', 1e-6));

%% Output arrays
% Create empty arrays to save data
[e, d, R, f, M] = generate_output_arrays(N);
%% Post processing
x = X(:, 1:3)';
v = X(:, 4:6)';
W = X(:, 16:18)';

thr = zeros(4, N);

avg_ex = 0;
avg_eR = 0;
avg_f = 0;

converge_t = 0;
is_converged = false;
converge_ex = 0.02;

for i = 1:N
    R(:,:,i) = reshape(X(i,7:15), 3, 3);
    b1(:,i) = R(:,1,i);
    b3(:,i) = R(:,3,i);
    
    desired = command(t(i));
    [f(i), M(:,i), err, calc] = position_control_kooijman(X(i,:)', ...
        desired, param);
    
    [f(i), M(:,i)] = saturate_fM(f(i), M(:,i), param);
    thr(:,i) = fM_to_thr(f(i), M(:,i), param);
    
    % Unpack errors
    e.x(:,i) = -err.x;
    e.v(:,i) = -err.v;
    
    % Unpack desired values
    d.x(:,i) = desired.x;
    d.v(:,i) = desired.v;
    
    % Find normalized errors
    norm_ex = norm(err.x);
    norm_eR = norm(err.R);
    
    avg_ex = avg_ex + norm_ex;
    avg_eR = avg_eR + norm_eR;
    
    norm_f = norm(thr(:,i));
    avg_f = avg_f + norm_f;
    
    if norm_ex < converge_ex
        if ~is_converged
            converge_t = t(i);
            is_converged = true;
        end
    end
end
avg_ex = avg_ex / N
avg_eR = avg_eR / N
avg_f = avg_f / N
converge_t

%% Plots

linetype = 'k';
linewidth = 1;
xlabel_ = 'time (s)';

figure(1);
plot_3x1(t, e.x, '', xlabel_, 'e_x', linetype, linewidth)
set(gca, 'FontName', 'Times New Roman');

figure(2);
plot_3x1(t, e.R, '', xlabel_, 'e_R', linetype, linewidth)
set(gca, 'FontName', 'Times New Roman');

figure(3);
plot_4x1(t, thr, '', xlabel_, 'f', linetype, linewidth)
set(gca, 'FontName', 'Times New Roman');

save('kooijman.mat')