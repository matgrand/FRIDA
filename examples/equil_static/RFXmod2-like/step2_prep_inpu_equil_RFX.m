%% Define Scenario data!

%% Format specifications
% -----------------------------------------------
% IE_evol (struct containing equil info (don't mind the _evol notation,
% it's the same across both static and evol versions.)
%     plaparameter: [1×1 struct] -> plasma info
%       Conductors: [1×1 struct] -> active coils' info
%
%
% IE_evol.plaparameter
%         Ipla: [1×1 double] -> plasma current during discharge
%       beta_0: [1×1 double] -> 1st current density param during discharge
%      alpha_M: [1×1 double] -> 2nd current density param during discharge
%      alpha_N: [1×1 double] -> 3rd current density param during discharge
%
% [in case we are using ff' and p' profiles rather than [beta_0, alpha_M,
% alpha_N] and defined, at each instant, by a vector of 101 points, we'll have
%
% IE_evol.plaparameter
%         Ipla: [1×1 double] -> plasma current during discharge
%          FdF: [101×1 double] -> ff' profile during discharge
%           dP: [101×1 double] -> p' profile during discharge
%
%
% IE_evol.Conductors
%     Nconductors: 64 -> total number of conductors
%          Nturns: [64×1 double] -> number of turns per each conductor
%        Currents: [64×1 double] -> coils' currents during discharge
% -----------------------------------------------

%% Collecting data

clc; clearvars; close all;

restoredefaultpath
dir_FRIDA = '../../../source/routines_FRIDA/';
addpath(genpath(dir_FRIDA))


set(groot,'defaulttextinterpreter','latex');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');


%% Set folders

dir_equil = '../../../data/equil/';
% % dir_sensosr = '../../../data/mod2_sensors_positions/';
dir_geo = '../../../data/geo/';
dir_in_FRIDA = './data_in_FRIDA/';


%% geometry per evol
% meshData_ext -> struct containing mesh data of active and passive
%                 conductors. Can be generated via the following script
%                 .geometry_generation/Matlab2Gmsh_RFX_VI.m
% meshdata_pla -> struct containing mesh data of plasma region only.
%                 Can be generated via the following script
%                 .geometry_generation/Matlab2Gmsh_RFX_plasma.m


% % load([input_Data, 'geo/', 'RFXmod2_mesh_VI_linear_cage_v2.mat'])
% % meshData_ext = meshData;
% % load([input_Data, 'geo/', 'DataRFX_mesh_pla.mat'])

load(['./data_in_FRIDA/', 'tmp_INPUT_FRIDA_geo.mat'])
% % load(['./data_in_FRIDA/', 'RFX_mesh_pla.mat'])



%% Load scenario data
n_time_new=1;
time_sim = 0.15;
flagRFP=1; % was 0, but I lack the file

if flagRFP == 1
    qq = load([dir_equil, '28906.mat']);
    [qq.t_p,ind] = unique(qq.t_p);
    qq.im = qq.im(ind,:);
    qq.ifs = qq.ifs(ind,:);
    iSC = zeros(1,2);
    qq.ipla_a = qq.i_pla;
    imm = double(interp1(qq.t_p,qq.im,time_sim));
    ifs = double(interp1(qq.t_p,qq.ifs,time_sim));
    ipla =double(interp1(qq.t_a,qq.ipla_a,time_sim));
    % ipla = ipla+ipla*10/100;
else
    qq = load([dir_equil, '36922.mat']); % MG: I don't have this
    [qq.t_p,ind] = unique(qq.t_ipla_at);
    qq.im = qq.imm_at(ind,:);
    qq.ifs = qq.ifs_at(ind,:);
    imm = double(interp1(qq.t_p,qq.im,time_sim));
    ifs = double(interp1(qq.t_p,qq.ifs,time_sim));
    iSC = interp1(qq.t_SC_ref,qq.SCCurrentRef_eda1,time_sim);
    ipla =double(interp1(qq.t_p,qq.ipla_at,time_sim));
    % ipla = ipla+ipla*7/100;
end

figure
subplot(2,1,1)
plot(qq.t_p,qq.im)
xlim(qq.t_p([1 end]))
subplot(2,1,2)
plot(qq.t_p,qq.ifs)
xlim(qq.t_p([1 end]))
%% Currents
load([dir_geo, 'Nturns_RFX_64'])
KONNAX_ACT = meshData.KONNAX_ACT;

Currents_evol = zeros(64,n_time_new);
for ii=1:n_time_new
    
    Currents = double([imm(ii,:) ifs(ii,:) iSC(ii,[1 2])]');
    % %     warning('imposing zero current on saddle coils')
    % Active Currents
    Currents_all = KONNAX_ACT'*Currents;
    
    % Currents_all(48) = 0;
    % Currents_all(50) = 0;
    
    % %     Currents_evol(:,ii) = Currents_all(1:56).*Nturns_RFX(1:56);
    Currents_evol(:,ii) = Currents_all.*Nturns_RFX;
end

Conductors.Nconductors = size(Currents_all,1);
Conductors.Currents = Currents_evol(:,1);
Conductors.Nturns = ones(size(Nturns_RFX));%Nturns_RFX;


%% Cast everything into IE_evol

IE_evol.plaparameter.Centroid = [2,0];
IE_evol.plaparameter.R_0 = [1.995,0];
IE_evol.plaparameter.beta_0 = .1;
IE_evol.plaparameter.alpha_M = 2;
IE_evol.plaparameter.alpha_N = .7;
IE_evol.plaparameter.Ipla = ipla;
ipla

IE_evol.Conductors.Nconductors  = Conductors.Nconductors;
IE_evol.Conductors.Nturns       = Conductors.Nturns;
IE_evol.Conductors.Currents     = Currents_evol;
IE_evol.time_sim                = nan;

%% Save
save([dir_in_FRIDA, 'tmp_INPUT_FRIDA_equil.mat'], 'IE_evol')