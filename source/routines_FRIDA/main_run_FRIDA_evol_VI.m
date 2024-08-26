function [OUT] = main_run_FRIDA_evol_VI(SETTINGS)

fprintf('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n \n')
fprintf('\n\n\n')
fprintf('   F  FFFFFFFF     R  RRRRRRRR     I  IIIIIIII     D  DDDDDDDD     A  AAAAAAAA\n')
fprintf('   FF  FFFFFFFF    RR  RRRRRRRR    II  IIIIIIII    DD  DDDDDDDD    AA  AAAAAAAA\n')
fprintf('   FFF  FFFFFFF    RRR  RRRRRRR    III  IIIIIII    DDD  DDDDDDD    AAA  AAAAAAA\n')
fprintf('   FFF             RRR      RRR        I  I        DDD      DDD    AAA      AAA\n')
fprintf('   FFF             RRR      RRR        II          DDD      DDD    AAA      AAA\n')
fprintf('   FFFFFFF         RRRRRRR  RRR        IIII        DDD      DDD    AAAAAAA  AAA\n')
fprintf('   FFFFFFFF        RRRRRRRR RRR        IIII        DDD      DDD    AAAAAAAA AAA\n')
fprintf('   FFFFFFFFF       RRRRRRRRRRRR        IIII        DDD      DDD    AAAAAAAAAAAA\n')
fprintf('   FFF             RRR   RRR           IIII        DDD      DDD    AAA      AAA\n')
fprintf('   FFF             RRR    RRR      IIIIIIIIIII     DDDDDDDDDDDD    AAA      AAA\n')
fprintf('   FFF             RRR     RRR     IIIIIIIIIIII    DDDDDDDDDDDD    AAA      AAA\n')
fprintf('    FF              RR       RR     IIIIIIIIIII    DDDDDDDDDDD      AA       AA\n')
fprintf('\n\n\n')
fprintf('   FRee-boundary Integro-Differential Axisymmetric (solver) - Time Domain\n\n')
fprintf('   M. Bonotto, D. Abate\n')
fprintf('   Consorzio RFX \n\n')
fprintf('   4/2024\n')
fprintf('   ver. 3.3\n')
fprintf('\n\n\n')
fprintf('\n\n\n')
fprintf('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n \n')
%%% set Latex as default figure font/interpreter
set(groot,'defaulttextinterpreter','latex');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

% load equil data
load(['./data_in_FRIDA/INPUT_FRIDA_equil_', SETTINGS.filename, '.mat'], 'IE_evol')
plaparameter = IE_evol.plaparameter;
Conductors = IE_evol.Conductors;

% load geometry data
load(['./data_in_FRIDA/INPUT_FRIDA_geo_', SETTINGS.filename, '.mat'], 'meshData_pla', 'meshData', 'sensors')
meshData_ext = meshData;
if isfield(sensors, 'pickup')
    SETTINGS.pickup = sensors.pickup;
end
if isfield(sensors, 'pickup')
    SETTINGS.flux_loops = sensors.flux_loops;
end

%% RUN TYPE % 0 -> static vacuum; 1 -> static plasma; 2 -> evol vacuum; 3 -> evol plasma
if SETTINGS.RUN == 2 || SETTINGS.RUN == 3 % evol vacuum or evol plasma
    SETTINGS.IS_EVOL = 1;
else
    SETTINGS.IS_EVOL = 0;
end

run_initialize_SETTINGS % initialize settings and inputs

%%% Pre-processing
if SETTINGS.PREPROC
    fprintf('\n\n\n==============================================\n*** RUNNING PRE-PROCESSING *** \n')
    time_start_preproc = tic;
    run_FRIDA_evol_preprocessing
    fprintf('\n*** --> PRE-PROCESSING DONE!!! *** \n');
    time_end_preproc = toc(time_start_preproc);
    fprintf('    TOTAL Eelapsed time is %5.1f seconds \n',  time_end_preproc)
    fprintf('==============================================\n\n\n')
else
    fprintf('\n\n\n==============================================\n*** SKIPPING PRE-PROCESSING *** \n')
    if SETTINGS.IS_EVOL
        load(['./data_in_FRIDA/INPUT_FRIDA_geo_preproc_',SETTINGS.filename,'.mat'], 'meshData_pla', 'meshData_ext', 'meshData_pas')
    else
        load(['./data_in_FRIDA/INPUT_FRIDA_geo_preproc_',SETTINGS.filename,'.mat'], 'meshData_pla', 'meshData_ext')
    end
    fprintf('\n')
    fprintf('==============================================\n')
    fprintf('\n\n')    
end

%% Matrix for Crank-Nicolson
if SETTINGS.IS_EVOL
    fprintf('\n')
    disp('Computing matrices for Crank�Nicolson method ...')
    tic
    compute_Crank_Nicolson_matrices
    toc
end

%% Run simulation 
if SETTINGS.RUN == 0 || SETTINGS.RUN == 2 % Vacuum static || Evol
    OUT = run_FRIDA_vacuum(meshData_ext, IE_evol, IE_evol.Conductors, SETTINGS);
elseif SETTINGS.RUN == 1 || SETTINGS.RUN == 3 % Plasma static || Evol
    OUT = run_FRIDA_plasma(meshData_pla, meshData_ext, IE_evol, IE_evol.Conductors, SETTINGS);
end
end
































