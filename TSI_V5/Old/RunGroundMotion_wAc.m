%% Solution of the equation of motion
% This code solves the equation of motion of the system, using an explicit
% scheme for the integration

nfig = 0;
showplot = 0;

%% Load Data
load WheelGeom
load RailGeom
load RailProps

%% Solution Parameters
dtt  = 5.0E-4;   % time step (sec) of train
dtb  = 5.0E-4;   % time step (sec) of bridge 

% Train Finite Difference Sol. Parameters
psi = 0.5;
phi = 0.5;

g   = 9.81;       % m/s2
Vel = 80/3.6;     % m/sec
CF  = 1.0;        % 1 for coupled analysis, 0 for uncoupled

%% Forcing parameters
SF = 2.65;
EQname = 'RSN182_IMPVALLH2';

load([cd,'\GMs\Used Records\',EQname])
ugddot = SF*TimeAccelData(:,2)*9.81;             % Acceleration Time-History

dtrec = round(TimeAccelData(2,1),3);        % Time step of record
trec  = 0:dtrec:dtrec*(length(ugddot)-1);   % Time vector 

ugdot  = dtrec*cumtrapz(ugddot);          % Velocity Time-History
urec   = dtrec*cumtrapz(ugddot);          % Displacement Time-History

% % urec = SF*TimeAccelData(:,2);   % Displacement Time-History
% % 
% % dtrec = round(TimeAccelData(2,1),3);                            % Time step of record
% % trec  = 0:dtrec:dtrec*(length(urec)-1);    % Time vector 
% % 
% % ugdot  = [0;  diff(urec)]/dtrec;          % Velocity Time-History
% % ugddot = [0; diff(ugdot)]/dtrec;          % Displacement Time-History

% Plot EQ record
% nfig = nfig + 1;

% %%
% nfig = 1
% figure(nfig)
% subplot(3,1,1), plot(trec,ugddot/9.81), xlabel('Time (sec)'), ylabel('Accel. (g)'), title('Ground Motion (LPE)')
% subplot(3,1,2), plot(trec,ugdot), xlabel('Time (sec)'), ylabel('Accel. (g)'), title('Ground Motion (LPE)')
% subplot(3,1,3), plot(trec,urec), xlabel('Time (sec)'), ylabel('Accel. (g)'), title('Ground Motion (LPE)')
% %%

% Resampling of Acceleration Time History
tt = 0:dtt:trec(end);  % Time vector for train analysis
tb = 0:dtb:trec(end);  % Time vector for bridge analysis

% Add 10 seconds of no-motion

ugddot  = interp1(trec,ugddot,tb);  % Excitation is required only for bridge
ugdot   = interp1(trec,ugdot,tb);   % Excitation is required only for bridge
urec    = interp1(trec,urec,tb);    % Excitation is required only for bridge

tsteps = length(tt);
bsteps = length(tb);

%% Load Train Data
CreateWheelRailGeom

%% Initialize Bridge Data
BM = 1;
if BM == 1 % BM = 1 --> Nonlinear || BM = 0 --> Linear Elastic
    InitializeBridgeModel
else
    InitializeBridgeModel_LE
end

%% Initial conditions and prellocation of variables

X = zeros(9,tsteps); % Train Global Coordinates 
V = zeros(9,tsteps); % Train Velocities
A = zeros(9,tsteps); % Train Accelerations

load X_initial

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
Left_Cont = zeros(1,tsteps); Right_Cont = zeros(1,tsteps);
Uplift = zeros(tsteps,2); 

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

% % EigenValue Analysis
% % Options for EigenValue Analysis
% showplot = false;
% EigenValueAnalysis;

%% Gravity Loading
Radius = 1360*0.3048; % m
Ac = Vel^2/Radius;

F_ine = [Mc*Ac Mc*g 0 0 Mt*g 0 0 Mw*g 0]'; % Inertial Forces (N)

%% Solution of the EOM
tic

ib = 2; tbridge = 0;
for it = 2:tsteps
    % Integration of Train EOM
    X2 = X1+V1*dtt+(0.5+psi)*A1*dtt^2-psi*A0*dtt^2;
    V2 = V1+(1+phi)*A1*dtt-phi*A0*dtt;
    
    % Update the force vector with Contact Algorithm
    [F,NF_L,NF_R,vec,Ft,delta(:,it-1),Momt,Uplift(it,:)] = ... 
        ContactForce(X2(7:9)', ...
                     V2(7:9)', ...
                     [BridgeResponse.X_Track(1,ib-1), BridgeResponse.X_Track(2,ib-1),-BridgeResponse.X(3,ib-1)], ...
                     [BridgeResponse.V_Track(1,ib-1), BridgeResponse.V_Track(2,ib-1),-BridgeResponse.Xdot(3,ib-1)], ...
                     WheelGeom_pol, ...
                     RailGeom_pol,...
                     RailGeom_cur, ...
                     WheelGeom_cur, ...
                     RailProps, ...
                     0, ...
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
    
    tbridge = tbridge + dtt;

    if tbridge >= dtb
        BridgeTimeIncrement
        UpdateX_Track;
        ib = ib + 1;
        tbridge = 0;
    end
    
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

toc

%%  Post Processing

% PostProcessingGM

% hold off
% figure(3)
% plot(t,vrel) %Relative velocity between wheelset and rail
% hold on
% plot(t,vect(:,1)) % Tangential force in the Y direction
% plot(t(1:end),Left_Cont/1000) % Left contact force
% plot(t(1:end),Right_Cont/1000) % Right contact force
% plot(t(1:end),A(7,:)/981)
% grid on
% legend('Relative velocity','Tangential force','Left normal force','Right normal force')
