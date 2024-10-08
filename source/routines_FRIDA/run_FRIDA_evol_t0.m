function [OUTPUT_FRIDA]=run_FRIDA_evol_t0(meshData_pla,meshData_ext,Conductors,plaparameter,SETTINGS)

%%

% % fprintf('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n \n')
% % 
% % fprintf('\n\n\n')
% % fprintf('   F  FFFFFFFF     R  RRRRRRRR     I  IIIIIIII     D  DDDDDDDD     A  AAAAAAAA\n')
% % fprintf('   FF  FFFFFFFF    RR  RRRRRRRR    II  IIIIIIII    DD  DDDDDDDD    AA  AAAAAAAA\n')
% % fprintf('   FFF  FFFFFFF    RRR  RRRRRRR    III  IIIIIII    DDD  DDDDDDD    AAA  AAAAAAA\n')
% % fprintf('   FFF             RRR      RRR        I  I        DDD      DDD    AAA      AAA\n')
% % fprintf('   FFF             RRR      RRR        II          DDD      DDD    AAA      AAA\n')
% % fprintf('   FFFFFFF         RRRRRRR  RRR        IIII        DDD      DDD    AAAAAAA  AAA\n')
% % fprintf('   FFFFFFFF        RRRRRRRR RRR        IIII        DDD      DDD    AAAAAAAA AAA\n')
% % fprintf('   FFFFFFFFF       RRRRRRRRRRRR        IIII        DDD      DDD    AAAAAAAAAAAA\n')
% % fprintf('   FFF             RRR   RRR           IIII        DDD      DDD    AAA      AAA\n')
% % fprintf('   FFF             RRR    RRR      IIIIIIIIIII     DDDDDDDDDDDD    AAA      AAA\n')
% % fprintf('   FFF             RRR     RRR     IIIIIIIIIIII    DDDDDDDDDDDD    AAA      AAA\n')
% % fprintf('    FF              RR       RR     IIIIIIIIIII    DDDDDDDDDDD      AA       AA\n')
% % fprintf('\n\n\n')
% % 
% % fprintf('   FRee-boundary Integro-Differential Axisymmetric (solver)\n')
% % fprintf('   M. Bonotto, D. Abate\n\n')
% % fprintf('   2020/2021\n')
% % fprintf('   ver. 3.0\n')
% % 
% % 
% % fprintf('\n\n\n')
% % fprintf('\n\n\n')
% % 
% % fprintf('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n \n')
% % 
% % 
% % 
% % %% Load Data
% % load(['INPUT_FRIDA_equil_' SETTINGS.filename_save],'plaparameter', 'Conductors');



%%

% VIP quantity
mu0=4*pi*1.e-7;

%%% preliminary arraggements
meshData = meshData_ext;
meshData_loc = meshData_pla;

meshData_loc.ind_t_InFW = find(meshData_loc.type == -1);
meshData_loc.ind_n_InFW = unique(meshData_loc.t(meshData_loc.ind_t_InFW,:));



%% time for code execution

fprintf('\n\n\n')
fprintf('Starting execution of FRIDA code\n')

time_start_code = tic;


%%

Rplot=[min(meshData_loc.n(meshData_loc.ind_n_bc,1))...
    max(meshData_loc.n(meshData_loc.ind_n_bc,1))]+[-0.3 0.3];
Zplot=[min(meshData_loc.n(meshData_loc.ind_n_bc,2))...
    max(meshData_loc.n(meshData_loc.ind_n_bc,2))]+[-0.3 0.3];

rr=meshData_loc.n(:,1);
zz=meshData_loc.n(:,2);

rgrid=linspace(Rplot(1),Rplot(2),200);
zgrid=linspace(Zplot(1),Zplot(2),200);

[RR,ZZ] = meshgrid(rgrid,zgrid);

ind_figure=ceil(rand*100);
if SETTINGS.FIGURES == true
    figure(ind_figure)
    hold on;    grid on;   axis equal; colormap jet; box on
    hold on, xlabel('r [m]'), ylabel('z [m]');
    edges=pdemesh(meshData.n',meshData.e_interface',[]);
    % %     plot(meshData_loc.n(meshData_loc.ind_n_FW,1),meshData_loc.n(meshData_loc.ind_n_FW,2),'k')
    set(edges,'color','k')
    set(edges,'linewidth',1)
    axis([Rplot Zplot])
end

%%

fprintf('Equilibrium parameters \n \n')

disp(plaparameter)

fprintf('\n \n')


%%
% Vacuum solution
tic
[solk0] = fun_Vacuum_FRIDA(meshData,meshData_loc,Conductors,SETTINGS);
toc
fprintf('\n')



%
if SETTINGS.FIGURES_DEBUG == true
    figure
    subplot(1,2,1)
    edges=pdemesh(meshData.n',meshData.e_interface',[]);
    set(edges,'color','k')
    set(edges,'linewidth',1)
    axis equal;
    axis([Rplot Zplot]),  hold on, xlabel('r [m]'), ylabel('z [m]');
    PSI = griddata(rr,zz,solk0.Psi_MS,RR,ZZ);
    contour(RR,ZZ,PSI,50);
% %     plot(meshData_loc.n(meshData_loc.ind_n_FW,1),meshData_loc.n(meshData_loc.ind_n_FW,2),'.k')
    colormap('cool');
    title('Vacuum solution')
    colorbar vert
end

if SETTINGS.FIRST_SOLUTION == false    
    
    % First flux map
    fprintf('First flux map ... \n')
    tic
    [solk0] = fun_firstfluxmap(solk0,meshData,meshData_loc,plaparameter,SETTINGS);
    toc
    fprintf('\n')
    
    %
    if SETTINGS.FIGURES_DEBUG == true
        % %     figure
        subplot(1,2,2);
        edges=pdemesh(meshData_pla.n',meshData_pla.e_interface',[]);
        set(edges,'color','k')
        set(edges,'linewidth',1)
        axis equal;
        axis([Rplot Zplot]),  hold on, xlabel('r [m]'), ylabel('z [m]');
        PSI = griddata(rr,zz,solk0.Psi,RR,ZZ);
        contour(RR,ZZ,PSI,30);
% %         plot(meshData_loc.n(meshData_loc.ind_n_FW,1),meshData_loc.n(meshData_loc.ind_n_FW,2),'k')
% %         colormap('cool');
        title('First solution')
        colorbar vert
        
    end
    
    % First Magnetic Axis
    fprintf('First Magnetic Axis ... \n')

    [solk0.Psi_axis,ind_axis]=max(solk0.Psi);
    
    solk0.ind_n_axis = ind_axis;
    solk0.delta_a_weights = 1;
    solk0.Axis_RR = solk0.r0;
    solk0.Axis_ZZ = solk0.z0;
    
    toc
    fprintf('\n')
        
elseif SETTINGS.FIRST_SOLUTION == true
    
    xx_k = SETTINGS.xx_0;
    
    solk0.Psi      = xx_k(1:end-3);
    solk0.Psi_axis = xx_k(end-2);
    solk0.Psi_Bpla = xx_k(end-1);
    
    % First Magnetic Axis
    fprintf('First Magnetic Axis ... \n')
    [solk0]=fun_MagneticAxis(meshData_loc,solk0,SETTINGS);
    toc
    fprintf('\n')
    
end

% % figure
% % PSI1 = griddata(rr,zz,solk0.Psi_MS,RR,ZZ);
% % PSI2 = griddata(rr,zz,solk0.Psi_MS,RR,-ZZ);
% % contour(RR,ZZ,PSI1-PSI2,50);

%%% Compute grad(psi) at nodes 
fprintf('Compute grad(psi) at nodes ... \n')
tic
[solk0] = fun_GradientNodes(meshData_loc,solk0,SETTINGS);
toc


%%% Compute psi and grad(psi) at Gauss points
fprintf('Compute psi and grad(psi) at Gauss points ... \n')
tic
[solk0] = fun_FluxGauss(meshData_loc,solk0,SETTINGS);
[solk0] = fun_GradientGauss(meshData_loc,solk0,SETTINGS);
toc


%%% Compute psi and grad(psi) at the center of the triangles
fprintf('Compute psi and grad(psi) at the center of the triangles ... \n')
tic
[solk0] = fun_FluxTri(meshData_loc,solk0,SETTINGS);
[solk0] = fun_GradientTri(meshData_loc,solk0,SETTINGS);
toc


% % fprintf('Compute psi and grad(psi) at Gauss points ... \n')
% % tic
% % Psi_nodes        = solk0.Psi;
% % tri              = meshData_loc.t;
% % shape_functions  = meshData_loc.shape_functions;
% % N_order          = meshData_loc.shape_functions_N_order;
% % n_Gauss          = meshData_loc.n_Gauss;
% % P_Gauss          = meshData_loc.nodes_Gauss_pla;
% % 
% % %%%
% % if SETTINGS.RUN_MEX_ROUTINE == false
% %     [Psi_Gauss] = fun_evaluateFluxGaussPoints_v2(tri,Psi_nodes,N_order,P_Gauss,n_Gauss,shape_functions);
% % elseif SETTINGS.RUN_MEX_ROUTINE == true
% %     [Psi_Gauss] = fun_evaluateFluxGaussPoints_v2_mex(tri,Psi_nodes,N_order,P_Gauss,n_Gauss,shape_functions);
% % end
% % solk0.Psi_Gauss = Psi_Gauss;
% % 
% % %%%
% % if SETTINGS.RUN_MEX_ROUTINE == false
% %     [Grad_Psi_Gauss] = fun_calcGradientGauss_FEM(tri,Psi_nodes,P_Gauss,shape_functions,N_order,n_Gauss);
% % elseif SETTINGS.RUN_MEX_ROUTINE == true
% %     [Grad_Psi_Gauss] = fun_calcGradientGauss_FEM_mex(tri,Psi_nodes,P_Gauss,shape_functions,N_order,n_Gauss);
% % end
% % solk0.Grad_psi_Gauss = Grad_Psi_Gauss;
% % toc
% % 
% % 
% % fprintf('Compute psi and grad(psi) at the center of the triangles ... \n')
% % tic
% % Psi_nodes        = solk0.Psi;
% % tri              = meshData_loc.t;
% % shape_functions  = meshData_loc.shape_functions;
% % N_order          = meshData_loc.shape_functions_N_order;
% % n_Gauss_fake     = 1;
% % P_Gauss_fake     = meshData_loc.c_t;
% % 
% % %%%
% % if SETTINGS.RUN_MEX_ROUTINE == false
% %     [Psi_c_t] = fun_evaluateFluxGaussPoints_v2(tri,Psi_nodes,N_order,P_Gauss_fake,n_Gauss_fake,shape_functions);
% % elseif SETTINGS.RUN_MEX_ROUTINE == true
% %     [Psi_c_t] = fun_evaluateFluxGaussPoints_v2_mex(tri,Psi_nodes,N_order,P_Gauss_fake,n_Gauss_fake,shape_functions);
% % end
% % solk0.Psi_c_t = Psi_c_t;
% % 
% % %%%
% % if SETTINGS.RUN_MEX_ROUTINE == false
% %     [Grad_Psi_c_t] = fun_calcGradientGauss_FEM(tri,Psi_nodes,P_Gauss,shape_functions,N_order,n_Gauss);
% % elseif SETTINGS.RUN_MEX_ROUTINE == true
% %     [Grad_Psi_c_t] = fun_calcGradientGauss_FEM_mex(tri,Psi_nodes,P_Gauss,shape_functions,N_order,n_Gauss);
% % end
% % solk0.Grad_Psi_c_t = Grad_Psi_c_t;
% % toc




% First XPoint/Limiter and separatrix
fprintf('First XPoint/Limiter and separatrix ... \n')
tic
SETTINGS.fac_tresh_SOL = 3;
[solk0] = fun_Separatrix(meshData_loc,solk0,SETTINGS);

if SETTINGS.FIGURES == true
    % %     contour(RR,ZZ,griddata(rr,zz,solk0.Psi,RR,ZZ),solk0.Psi_Bpla*[1 1], 'r', 'LineWidth',1);
    plot(solk0.Separatrix(:,1),solk0.Separatrix(:,2),'k-')
    plot(solk0.Axis_RR,solk0.Axis_ZZ,'ok')
    drawnow
end
toc

% Find nodes inside plasma and on plasma boundary
fprintf('Find nodes inside plasma and on plasma boundary ... \n')
tic
[meshData_loc]=fun_UpdateNodes(meshData_loc,solk0,SETTINGS);
toc
fprintf('\n')
pause(.0001)


if SETTINGS.FIRST_SOLUTION == false% %     Psi_k=solk0.Psi;
% %     solk0.Psi_k=Psi_k;


    xx_k=[solk0.Psi([meshData_pla.ind_D; meshData_pla.ind_B]); solk0.Psi_axis; solk0.Psi_B; 1];
    
end


%% Iterative solution of FREE Boundary problem (FreeB)

SOLVER=SETTINGS.SOLVER;

solk0.lambda_star = xx_k(end); 
solk0.lambda = solk0.lambda_star/mu0;
solk0.xx_k=xx_k;
nn=meshData_loc.nn;

% CICLO ITERATIVO
TOLL               = SETTINGS.TOLL;
SCARTO             = SETTINGS.SCARTO;
ii_freeB_max       = SETTINGS.ii_freeB_max;
RESIDUO_ii         = 100;
RESIDUO_norm_ii    = 100;
SCARTO_norm_ii     = 100;
ii_freeB           = 1;
scarto_tot         = [];
residuo_tot        = [];
residuo_norm_tot   = [];
time_per_iteration = [];
time_solver        = [];

%
solk0.residuo      = RESIDUO_ii;
solk0.residuo_norm = RESIDUO_norm_ii;
solk0.scarto_norm  = SCARTO_norm_ii;
solk0.error_Ipla   = 0;
solk0.RR_psi_k_old = 0;

solk = solk0;



while RESIDUO_norm_ii > TOLL && SCARTO_norm_ii > SCARTO && ii_freeB <= ii_freeB_max
    
    time_start_iteration = tic;
    fprintf('\n');
    fprintf('Free Boundary iteration %i \n', ii_freeB);
    fprintf('\n');
    
    JP.faces           = meshData_loc.t(meshData_loc.ind_t_InFW,1:3);
    JP.vertices        = meshData_loc.n;
    JP.facevertexcdata = zeros(nn,1);
    
    %% Solver
    
    INPUT_solver.solk            = solk;
    INPUT_solver.meshData        = meshData;
    INPUT_solver.meshData_loc    = meshData_loc;
    INPUT_solver.plaparameter    = plaparameter;
    INPUT_solver.SETTINGS        = SETTINGS;
    INPUT_solver.ii_freeB        = ii_freeB;
    INPUT_solver.RESIDUO_norm_ii = RESIDUO_norm_ii;
    
    
    
    switch SOLVER
               
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'NR' % Newtok-Raphson
            [solk1]=fun_NR_FRIDA(INPUT_solver);
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'NK' % Newtok-Krylov
% %             [solk1]=fun_NK_FRIDA(INPUT_solver);  %  Newtok-Krylov scaled lambda
            
    end
    
    
    
    
% %         figure
% %         edges=pdemesh(meshData.n',meshData.e_interface',[]);
% %         set(edges,'color','k'); set(edges,'linewidth',1); axis equal;
% %         axis([Rplot Zplot]),  hold on,
% %         rr=meshData_loc.n(:,1);
% %         zz=meshData_loc.n(:,2);
% %         PSI = griddata(rr,zz,(solk1.Psi),RR,ZZ);
% %         contour(RR,ZZ,PSI,15);
% %         contour(RR,ZZ,PSI,[solk1.Psi_b solk1.Psi_b],'k');
% %         contour(RR,ZZ,PSI,[.1187 .1187],'k');
% %         colormap('cool'); colorbar vert;
    
    % % RESIDUO (R(psi)=0) E SCARTO (sol_k1-sol_k)
    % % RESIDUO_norm_ii = sum(abs(solk1.h_k(1:end-1)))/numel(solk1.h_k(1:end-1));
    
    % %     RESIDUO_ii      = norm(solk1.h_k);
    % % % %     RESIDUO_norm_ii = norm(solk1.h_k)/norm([solk1.xx_k(1:end-1); mu0*solk1.xx_k(end)]);
    % %     RESIDUO_norm_ii = norm(solk1.h_k)/norm(solk1.xx_k);
    % %     SCARTO_norm_ii  = norm(solk1.xx_k-solk.xx_k)/norm(solk1.xx_k);

    RESIDUO_ii      = norm(solk1.RR_psi_k);
    RESIDUO_norm_ii = norm(solk1.RR_psi_k)/norm(solk1.xx_k);
    SCARTO_norm_ii  = norm(solk1.h_k)/norm(solk1.xx_k);
    
    solk1.residuo = RESIDUO_ii;
    solk1.residuo_norm = RESIDUO_norm_ii;
    solk1.scarto_norm = SCARTO_norm_ii;
    
    fprintf('\n');
    
    %% Update quantities
    
    % Compute Gradient of Psi (on nodes)
% %     fprintf('Compute Gradient of Psi (on nodes) \n'); tic
% %     [solk1] = fun_GradientNodes(meshData_loc,solk1,SETTINGS);
% %     toc; fprintf('\n');

    %%% Compute grad(psi) at nodes
    fprintf('Compute grad(psi) at nodes ... \n')
    tic
    [solk1] = fun_GradientNodes(meshData_loc,solk1,SETTINGS);
    toc
    
    
    %%% Compute psi and grad(psi) at Gauss points
    fprintf('Compute psi and grad(psi) at Gauss points ... \n')
    tic
    [solk1] = fun_FluxGauss(meshData_loc,solk1,SETTINGS);
    [solk1] = fun_GradientGauss(meshData_loc,solk1,SETTINGS);
    toc
    
    
    %%% Compute psi and grad(psi) at the center of the triangles
    fprintf('Compute psi and grad(psi) at the center of the triangles ... \n')
    tic
    [solk1] = fun_FluxTri(meshData_loc,solk1,SETTINGS);
    [solk1] = fun_GradientTri(meshData_loc,solk1,SETTINGS);
    toc
% %     tic
% %     Psi_nodes        = solk1.Psi;
% %     tri              = meshData_loc.t;
% %     shape_functions  = meshData_loc.shape_functions;
% %     N_order          = meshData_loc.shape_functions_N_order;
% %     n_Gauss          = meshData_loc.n_Gauss;
% %     P_Gauss          = meshData_loc.nodes_Gauss_pla;
% % 
% %     if SETTINGS.RUN_MEX_ROUTINE == false
% %         [Psi_Gauss] = fun_evaluateFluxGaussPoints_v2(tri,Psi_nodes,N_order,P_Gauss,n_Gauss,shape_functions);
% %     elseif SETTINGS.RUN_MEX_ROUTINE == true
% %         [Psi_Gauss] = fun_evaluateFluxGaussPoints_v2_mex(tri,Psi_nodes,N_order,P_Gauss,n_Gauss,shape_functions);
% %     end
% %     solk1.Psi_Gauss = Psi_Gauss;
% %     toc; fprintf('\n');


    % Update Magnetic Axis
    fprintf('Update Magnetic Axis \n'); tic
    [solk1]=fun_MagneticAxis(meshData_loc,solk1,SETTINGS);
    toc; fprintf('\n');
    
    % Update XPoint/Limiter and separatrix
    fprintf('Update XPoint/Limiter and separatrix \n'); tic
    SETTINGS.fac_tresh_SOL = 1.05;
    [solk1]=fun_Separatrix(meshData_loc,solk1,SETTINGS);
% %     [solk0] = fun_Separatrix_v2(meshData_loc,solk0,SETTINGS);
    toc; fprintf('\n');
    
    fprintf('Update Nodes inside plasma and on plasma boundary \n'); tic
    % Update Nodes inside plasma and on plasma boundary
    [meshData_loc]=fun_UpdateNodes(meshData_loc,solk1,SETTINGS);
    toc; fprintf('\n');
    
    % Update Centroid
    fprintf('Update Centroid \n'); tic
    % %     [solk1]=fun_Centroid(meshData_loc,solk1);
    [r_C,z_C,Psi_C]=fun_Centroid_def(meshData_loc,solk1);
    solk1.Centroid_RR = r_C;
    solk1.Centroid_ZZ = z_C;
    solk1.Centroid_Psi = Psi_C;

    toc; fprintf('\n');
    

    %% Plot results
    
    if SETTINGS.FIGURES_DEBUG == true
        figure
        subplot(1,3,1)
        edges=pdemesh(meshData.n',meshData.e_interface',[]);
        set(edges,'color','k'); set(edges,'linewidth',1); axis equal;
        axis([Rplot Zplot]),  hold on,
        PSI = griddata(rr,zz,solk1.Psi,RR,ZZ);
        contour(RR,ZZ,PSI,100);
        colormap('cool'); colorbar vert;
        % %         plot(meshData_loc.n(meshData_loc.ind_n_FW,1),meshData_loc.n(meshData_loc.ind_n_FW,2),'k.')
        plot(solk1.Separatrix(:,1),solk1.Separatrix(:,2),'-k');
        
        subplot(1,3,2)
        F = scatteredInterpolant(meshData_loc.nodes_Gauss_pla(:,1),meshData_loc.nodes_Gauss_pla(:,2),solk1.Jphi);
        J_interp = zeros(meshData_loc.nn,1);
        J_interp(meshData_loc.ind_n_INpla) = F(meshData_loc.n(meshData_loc.ind_n_INpla,1),meshData_loc.n(meshData_loc.ind_n_INpla,2));
        JP.facevertexcdata=J_interp;
        hh=patch(JP,'facecolor','interp','edgecolor','none');
        axis equal;  hold on; colorbar vert; % title('j_\phi');
        axis([Rplot Zplot]),  hold on,
        axis square;  hold on;  colorbar vert; box on;
        edges=pdemesh(meshData.n',meshData.e_interface',[]);
        set(edges,'color','k'); set(edges,'linewidth',1)
        axis equal; axis([Rplot Zplot]),  hold on,
        % %         plot(meshData_loc.n(meshData_loc.ind_n_FW,1),meshData_loc.n(meshData_loc.ind_n_FW,2),'k.')
        plot(solk1.Separatrix(:,1),solk1.Separatrix(:,2),'-k');
        
        subplot(1,3,3)
        H_K=JP;
        H_K.facevertexcdata=solk1.h_k(1:end-3);
        hh=patch(H_K,'facecolor','interp','edgecolor','none');
        axis square;  hold on;  colorbar vert; box on;
        edges=pdemesh(meshData.n',meshData.e_interface',[]);
        set(edges,'color','k'); set(edges,'linewidth',1)
        axis equal; axis([Rplot Zplot]),  hold on,
        % %         plot(meshData_loc.n(meshData_loc.ind_n_FW,1),meshData_loc.n(meshData_loc.ind_n_FW,2),'k.')
        plot(solk1.Separatrix(:,1),solk1.Separatrix(:,2),'-k');
        
    end
    
    if SETTINGS.FIGURES == true
        h_psi = figure(ind_figure);
        [RR,ZZ] = meshgrid(rgrid,zgrid);
        rr = meshData_loc.n(:,1);
        zz = meshData_loc.n(:,2);
        PSI = griddata(rr,zz,solk1.Psi,RR,ZZ);
        % %         contour(RR,ZZ,PSI,100);
        % %         hold on
        % %         contour(RR,ZZ,PSI,[min(solk1.Psi_B) max(solk1.Psi_B)],'k');
        plot(solk1.Separatrix(:,1),solk1.Separatrix(:,2),'-k');
        % %         plot(meshData_loc.n(meshData_loc.ind_n_FW,1),meshData_loc.n(meshData_loc.ind_n_FW,2),'k.')
        plot(solk1.Axis_RR,solk1.Axis_ZZ,'ko')
        plot(solk1.XP_RR,solk1.XP_ZZ,'ko')
        drawnow
        
    end
    
    % %     if ii_freeB == 20
    % %         pause
    % %     end
    
    %%
    if SETTINGS.FIRST_SOLUTION == false    
        solk1.Psi_MS  = solk0.Psi_MS;
    end
    solk1.Psi_loc = solk.Psi;
    
    solk = solk1;
    
    fprintf(' \n')
    fprintf('RESIDUO                     %1.4e \n', RESIDUO_ii);
    fprintf('RESIDUO NORM                %1.4e \n', RESIDUO_norm_ii);
    fprintf('SCARTO                      %1.4e \n', SCARTO_norm_ii);
    fprintf('Check total plasma current  %10.10e \n', solk1.Ipla_check);
    
    time_end_iteration = toc(time_start_iteration);
    fprintf('Time per iteration is %5.6f seconds \n',  time_end_iteration)
    fprintf('\n \n');
    
    scarto_tot         = [scarto_tot; SCARTO_norm_ii];
    residuo_tot        = [residuo_tot; RESIDUO_ii];
    residuo_norm_tot   = [residuo_norm_tot; RESIDUO_norm_ii];
    time_per_iteration = [time_per_iteration; time_end_iteration];
    time_solver        = [time_solver; solk1.time_solver];
    
    ii_freeB = ii_freeB+1;
    
    
end

%% Impose zero current density outside separatrix (only for plotting purposes)
Boundary = solk1.Separatrix;
nodes_Gauss_pla = meshData_loc.nodes_Gauss_pla;
ind_Gauss_INpla=find(inpolygon(nodes_Gauss_pla(:,1),nodes_Gauss_pla(:,2),Boundary(:,1),Boundary(:,2)));

Jpla = zeros(size(nodes_Gauss_pla,1),1);
Jpla(ind_Gauss_INpla) = solk1.Jphi(ind_Gauss_INpla);

solk1.Jphi = Jpla;

% % F = scatteredInterpolant(meshData_loc.nodes_Gauss_pla(:,1),meshData_loc.nodes_Gauss_pla(:,2),solk1.Jphi);
% % J_interp = zeros(meshData_loc.nn,1);
% % J_interp = F(meshData_loc.n(:,1),meshData_loc.n(:,2));
% % 
% % Jpla.faces=meshData_loc.t(meshData_loc.ind_t_InFW,1:3);
% % Jpla.vertices=meshData_loc.n;
% % Jpla.facevertexcdata=J_interp;
% % 
% % figure
% % edges=pdemesh(meshData.n',meshData.e_interface',[]);
% % set(edges,'color','k'); set(edges,'linewidth',1); axis equal;
% % axis([Rplot Zplot]),  hold on,
% % hh=patch(Jpla,'facecolor','interp','edgecolor','none');
% % axis equal;  hold on; colorbar vert; % title('j_\phi');
% % axis([Rplot Zplot])
% % 
% % figure
% % plot3(meshData_loc.nodes_Gauss_pla(:,1),meshData_loc.nodes_Gauss_pla(:,2),solk1.Jphi,'o')

%%
fprintf(' \n');
fprintf('--> Done !!! \n');
time_end = toc(time_start_code);

fprintf('    TOTAL Eelapsed time is %5.1f seconds \n',  time_end)


%% Post-processing

% % if SETTINGS.POSTPROC == true
% %     
% %     fprintf('\n\n\n')
% %     fprintf('Running Postprocessing \n')
% %     
% %     time_start_postproc = tic;
% %     
% %     run_FRIDA_postprocessing
% %     
% %     fprintf(' \n');
% %     fprintf('--> Done Post-processing!!! \n');
% %     
% %     time_end_postproc = toc(time_start_postproc);
% %     
% %     fprintf('    TOTAL Eelapsed time is %5.1f seconds \n',  time_end_postproc)
% %     
% % else
% %     
% %     POSTPROC = [];
% % end


%% Save output

if any(strcmp('GG_BEM',fieldnames(meshData_loc)))
    meshData_loc = rmfield(meshData_loc,'GG_BEM');
end

OUTPUT_FRIDA.plaparameter       = plaparameter;
OUTPUT_FRIDA.meshData           = meshData;
OUTPUT_FRIDA.meshData_loc       = meshData_loc;
OUTPUT_FRIDA.Conductors         = Conductors;
OUTPUT_FRIDA.solk1              = solk1;
OUTPUT_FRIDA.scarto_tot         = scarto_tot;
OUTPUT_FRIDA.residuo_tot        = residuo_tot;
OUTPUT_FRIDA.residuo_norm_tot   = residuo_norm_tot;
OUTPUT_FRIDA.time_per_iteration = time_per_iteration;
OUTPUT_FRIDA.time_solver        = time_solver;
OUTPUT_FRIDA.ii_freeB           = ii_freeB;
OUTPUT_FRIDA.ind_figure         = ind_figure;
% % OUTPUT_FRIDA.POSTPROC           = POSTPROC;


if SETTINGS.SAVE_OUTPUT == true
    
    save(['OUTPUT_FRIDA' SETTINGS.filename_out],'OUTPUT_FRIDA')
    
end

% % restoredefaultpath



