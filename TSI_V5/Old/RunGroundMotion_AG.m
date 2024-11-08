%% Run Multi Cases of Bridge Only Simulation
% clear, clc, close
nfig = 0;
showplot = 0;

%% Load Train Data
load WheelGeom
load RailGeom
load RailProps

%% Solution Parameters
dtt  = 5.0E-4;   % time step (sec) of train

% Train Finite Difference Sol. Parameters
psi = 0.5;
phi = 0.5;

g   = 9.81;       % m/s2
% Vel = 0.01/3.6;   % m/sec MODIFY!!!!!
CF  = 0.0;        % 1 for coupled analysis, 0 for uncoupled

%% Load Train Data
CreateWheelRailGeom

%% Mass, Stiffness and Damping Matrices
% Call the functions that create the stiffness and damping matrices

[K] = StiffnessMatrix(); 
[C] = DampingMatrix();
[M,Mc,Mt,Mw] = MassMatrix();

AddRayleighDamp = false;
if AddRayleighDamp
    w1 = 2*pi*100; %rad/sec
    a1 = 2/w1;
    C = C + a1*K;
end

%% Forcing parameters
% SF = 1.0; % PUT IN THE CALLING FUNCTION

% Resampling of Acceleration Time History

trec  = TimeAccelData(:,1);
tt = 0:dtt:trec(end);  % Time vector for train analysis

dtrec = trec(2)-trec(1);
agrec = SF*TimeAccelData(:,2)*9.81;

agtt  = interp1(trec,agrec,tt);
vgtt  = cumtrapz(agtt)*dtt;
ugtt  = cumtrapz(vgtt)*dtt;

X_Track = zeros(3,length(tt));
V_Track = zeros(3,length(tt));

X_Track(1,:) = ugtt';
V_Track(1,:) = vgtt';
Phi_Track = 0*X_Track(1,:);

tsteps = length(tt);

%% Initial conditions and prellocation of variables

X = zeros(9,tsteps); % Train Global Coordinates 
V = zeros(9,tsteps); % Train Velocities
A = zeros(9,tsteps); % Train Accelerations

load X_initial_DC

X0 = X_initial;             % Initial Global Coordinates
V0 = [0 0 0 0 0 0 0 0 0]';  % Initial Velocities
A0 = [0 0 0 0 0 0 0 0 0]';  % Initial Accelerations

X1 = X_initial;             % Initial Global Coordinates
V1 = [0 0 0 0 0 0 0 0 0]';  % Initial Velocities
A1 = [0 0 0 0 0 0 0 0 0]';  % Initial Accelerations

X(:,1) = X0; X(:,2) = X1;
V(:,1) = V0; V(:,2) = V1;
A(:,1) = A0; A(:,2) = A1;

% Extra output variables
Momt = [0 0 0 0]';
Creepforces = zeros(4,tsteps);
delta       = zeros(4,tsteps);
deltadotn_vec = [0 0 0 0];

%% Gravity Loading
F_ine = [0 Mc*g 0 0 Mt*g 0 0 Mw*g 0]'; % Inertial Forces (N)

%% Solution of the EOM

for it = 2:tsteps
    % Integration of Train EOM
    X2 = X1+V1*dtt+(0.5+psi)*A1*dtt^2-psi*A0*dtt^2;
    V2 = V1+(1+phi)*A1*dtt-phi*A0*dtt;
    
    % Update the force vector with Contact Algorithm
    [F,NF_L,NF_R,vec,Ft,delta(:,it-1),Momt] = ... 
        ContactForce(X2(7:9)', ...
                     V2(7:9)', ...
                     [X_Track(1,it-1), X_Track(2,it-1),Phi_Track(it-1)], ...
                     [V_Track(1,it-1), V_Track(2,it-1),Phi_Track(it-1)], ...
                     WheelGeom_pol, ...
                     RailGeom_pol,...
                     RailGeom_cur, ...
                     WheelGeom_cur, ...
                     RailProps, ...
                     showplot, ...
                     Vel, ...
                     delta(:,it-1), ...
                     Momt, ...
                     deltadotn_vec, ...
                     Rail_geom_fine, ...
                     LWheel_geom_fine, ...
                     RWheel_geom_fine);
    
    % Updated force vector
    Cont_Force = 10^6*[0 0 0 0 0 0 F']';
    F_ext =  F_ine + Cont_Force; % N
    
    % Variable storage
    % vrel(i) = V2(7)-vx_track(i); vect(i,:) = Ft;
    Left_Cont(it) = 1000*NF_L; Right_Cont(it) = 1000*NF_R;

    %Numerical integration of Train EOM
    A2 = M\(F_ext-K*X2-C*V2);
    X(:,it) = X2; V(:,it) = V2; A(:,it) = A2;
    
    % Update the state vectors
    X0 = X1; V0 = V1; A0 = A1;
    X1 = X2; V1 = V2; A1 = A2;
end

