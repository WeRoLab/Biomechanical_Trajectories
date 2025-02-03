%% Generate periodic or smooth trajectories from raw literaure data
clc, clearvars, close all

tasks = {"run", "walk", "stairAscent", "stairDescent",...
    "sit_to_stand"};        % {run, walk, stairAscent, stairDescent, sit_to_stand}
joints = {'ankle', 'knee'}; % {hip, knee, ankle}
human.mass = 1;             % Mass of the user [Kg]
human.height = 1;           % Height of the user [m]
human.wSpeed = 'normal_cadence';  % {fast_cadence, slow_cadence, normal_cadence}
human.FourierFit = 0;       % Apply a Fourier fit (periodic trajectories)
human.nPoints = 300;        % Number of data points per trajectory

% Process all the tasks and joints
for i = 1:numel(tasks)
    for j = 1:numel(joints)
        human.task  = tasks{i};
        human.joint = joints{j}; 
        generateBiomechanicTrajectories(human)
    end
end
% Create CSV files
run("processed_data_from_literature\Mat2CSV.m")

%% Local function library
function generateBiomechanicTrajectories(human)
mass = human.mass;      % Mass of the user [Kg]
joint = human.joint;    % Joint to analyze {hip, knee, ankle}
nPoints = human.nPoints;

if strcmp(human.task, 'run')
    load('raw_data_from_literature/dataset_Novacheck.mat', ...
        'novacheck_running')
    ql       = novacheck_running.(joint).position *pi /180;
    torque   = novacheck_running.(joint).torque*mass;
    time     = novacheck_running.(joint).time;
    textFile = sprintf('%s_%s_%dkg', human.task, human.joint, human.mass);
elseif strcmp(human.task, 'walk')
    load('raw_data_from_literature/dataset_Winter.mat', 'level_walking')
    wSpeed = human.wSpeed;
    %-------------------------------WINTER'S DATA SCALING
    % Calculate sample time from cadence (steps per minute) Winter page 12
    if strcmp(wSpeed,'normal_cadence')        
        spm = 105;
        sT = 60/spm*2/1001;
    elseif strcmp(wSpeed,'fast_cadence')
        spm = 123;
        sT = 60/spm*2/1001;
    elseif strcmp(wSpeed,'slow_cadence')
        spm = 87;
        sT = 60/spm*2/1001;
    else
        error('Please select a walking speed, e.g., normal, fast');
    end
    ql       = level_walking.(wSpeed).(joint).position*pi/180;
    torque   = level_walking.(wSpeed).(joint).torque*mass;
    time     = (0:sT:sT*(1000))';
    textFile = sprintf('%s_%s_%s_%dkg', ...
        human.task, human.wSpeed, human.joint, human.mass);
elseif strcmp(human.task, 'stairAscent') || ...
        strcmp(human.task, 'stairDescent')
    load('raw_data_from_literature/dataset_Riener.mat', 'riener')
    ql       = riener.(human.task).(joint).position*pi/180;
    torque   = riener.(human.task).(joint).torque*mass;
    time     = riener.(human.task).(joint).time;
    textFile = sprintf('%s_%s_%dkg', ...
        human.task, human.joint, human.mass);
elseif strcmp(human.task, 'sit_to_stand')
    load('raw_data_from_literature/dataset_Roebroeck.mat', 'roebroeck')
    ql      = roebroeck.(joint).position.'*pi/180;
    torque  = roebroeck.(joint).torque.'*mass;
    time    = roebroeck.(joint).time.';
    textFile = sprintf('%s_%s_%dkg', ...
        human.task, human.joint, human.mass);
else
    error('Select adequate taks')
end
% Interpolate to normalize dimensions (arrays with nPoints)
timeInt     = linspace(time(1), time(end), nPoints).';
qlInt       = interp1(time, ql, timeInt);
torqueInt   = interp1(time, torque, timeInt);
delTim      = timeInt(2) - timeInt(1);

% Smooth data using least squares and get smooth time derivatives
smo = 5;    % Smoothing factor. The higher the smoother but less accurate
[qlDisc, qldDisc, qlddDisc] = smoothing(qlInt, smo, delTim);
[torqueDisc, torquedDisc, torqueddDisc] = smoothing(torqueInt, smo,delTim);

%----------------------- PLOTS FOR TROUBLESHOOTING
% figure, sgtitle(sprintf("Trajectory: %s", textFile))
% subplot(2,1,1), hold on, xlabel("Time [s]"), ylabel("First Derivative")
% plot(timeInt, qldDisc, "--")
% plot(time(1:end-1), diff(ql)./diff(time))
% legend("Smooth", "Original"), hold off
% subplot(2,1,2), hold on, xlabel("Time [s]"), ylabel("Second Derivative")
% plot(timeInt, qlddDisc, "--")
% plot(time(1:end-2), diff(diff(ql)./diff(time))./diff(time(1:end-1)))
% legend("Smooth", "Original"), hold off

% figure, sgtitle(sprintf("Trajectory: %s", textFile))
% subplot(1,2,1), hold on, xlabel("Time [s]"), ylabel("Position [deg.]")
% plot(timeInt, qlDisc*180/pi), hold off
% subplot(1,2,2), hold on, xlabel("Time [s]"), ylabel("Torque [Nm/Kg]")
% plot(timeInt, torqueDisc), hold off

time        = timeInt;
if human.FourierFit
    periodic_ql = fFourierDecomposition(time, ql, 10);
    periodic_torque = fFourierDecomposition(time, torque, 10);

    %-- Find the lowest frequency different from 0
    freqs = periodic_ql.freq;
    delFreq = min( freqs (freqs > 0 ) );

    time = linspace(0, 1/delFreq, nPoints);
    ql = periodic_ql.signalAnalytic;
    torque = periodic_torque.signalAnalytic;

    syms x

    qld = diff(ql,x);
    qldd = diff(qld,x);
    torqueD = diff(torque,x);
    torqueDD = diff(torqueD,x);

    qlDisc = zeros(1,nPoints);
    qldDisc = zeros(1,nPoints);
    qlddDisc = zeros(1,nPoints);
    torqueDisc = zeros(1,nPoints);
    torquedDisc = zeros(1,nPoints);
    torqueddDisc = zeros(1,nPoints);

    tic
    for i = 1:length(time)
        qlDisc(i) = round(double(subs(ql,time(i))),10);
        qldDisc(i) = round(double(subs(qld,time(i))),10);
        qlddDisc(i) = round(double(subs(qldd,time(i))),10);
        torqueDisc(i) = round(double(subs(torque,time(i))),10);
        torquedDisc(i) = round(double(subs(torqueD,time(i))),10);
        torqueddDisc(i) = round(double(subs(torqueDD,time(i))),10);
    end
    toc
end
save("processed_data_from_literature\" + textFile, 'qlDisc', 'qldDisc',...
    'qlddDisc', 'torqueDisc', 'torquedDisc', 'torqueddDisc', 'time');
end
function [x, xd, xdd] = smoothing(sig, alp, deltaTime)
% Find a set of points that are close to sig but minimize jerk

%-Create derivative operator Matrix (Center difference)
n = length(sig);
e = ones(n,1);

% First derivative
D1          = spdiags([-e 0*e e], -1:1, n, n);
D1(1,:)     = D1(2,:);
D1(end,:)   = D1(end-1,:);

% Second derivative
D2          = spdiags([e -2*e e], -1:1, n, n);
D2(1,:)     = D2(2,:);
D2(end,:)   = D2(end-1,:);

% Third derivative (Jerk)
D3 = D1*D2;

% Minimize the norm of signal fit and jerk
[m,~] = size(D3);
A   = [eye(n); alp*D3];
y   = [sig; zeros(m,1)];
x   = A\y;                  % Least squares power!

% Evaluate fit - warn if the RMS position error is higher than 1 deg.
res = sig - x;              % Residual on position fit
if ( (sqrt(res.'*res/n)) > 1*pi/180 )
    warning("Smooting: the RMS position error fit is higher than 1 deg")
end
xd  = 1/(2*deltaTime)*D1*x;     % First order time derivative
xdd = 1/(deltaTime^2)*D2*x;     % Second order time derivative
end
function [reconstructedSignal] = fFourierDecomposition(...
    time,inputSignal,numberOfComponents)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
time = time - time(1);

L = length(time);
sampleT  = time(2)-time(1);
Fs = 1/sampleT;

fftSignal = fft(inputSignal);
fftMagnitude = abs(fftSignal/L);
fftMagnitude = fftMagnitude(1:floor(L/2+1));
fftMagnitude(2:end-1) = 2*fftMagnitude(2:end-1);
fftPhase = angle(fftSignal);

f = Fs*(0:(L/2))/L;

mainComponents = unique(fftMagnitude);
numOfMainComponents = numberOfComponents;
fourierSignal = zeros(size(inputSignal));

magniComponent = zeros(numOfMainComponents,1);
mainFreq = zeros(numOfMainComponents,1);
phaseComponent  = zeros(numOfMainComponents,1);

fourierSignalAnalytic = 0;

syms x;

for i = 1:numOfMainComponents
    magniComponent(i) = mainComponents(end-numOfMainComponents+i);
    indxFreq = find(fftMagnitude == magniComponent(i));
    mainFreq(i) = f(indxFreq);
    phaseComponent(i) = fftPhase(indxFreq);
    fourierSignal = magniComponent(i)*cos(2*pi*mainFreq(i)*time + ...
        phaseComponent(i))+fourierSignal;
    fourierSignalAnalytic = magniComponent(i)*cos(2*pi*mainFreq(i)*x + ...
        phaseComponent(i))+fourierSignalAnalytic;
end

reconstructedSignal.magnitude = magniComponent;
reconstructedSignal.freq = mainFreq;
reconstructedSignal.phase = phaseComponent;
reconstructedSignal.signal = fourierSignal;
reconstructedSignal.signalAnalytic = fourierSignalAnalytic;

figure, hold on, grid on
title('Original vs Fourier version')
plot(time,inputSignal)
plot(time,fourierSignal)
xlabel('Time [s]')
legend('InputSignal','Fourier approximation')

% figure
% plot(f,fftMagnitude) 
% title('Single-Sided Amplitude Spectrum of Input(t)')
% xlabel('f (Hz)')
% ylabel('|P1(f)|')
end