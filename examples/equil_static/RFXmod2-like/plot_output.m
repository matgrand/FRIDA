clc; clear; close all;

%load the file
load('out_frida_static_mg_frida_test.mat')
odf = OUT_FRIDA_TD; % more readable

r1 = odf.Grad_Gauss(:,1); % more readable
z1 = odf.Grad_Gauss(:,2);

%PSI_GAUSS
figure('Name', 'Psi Gauss on Grad Gauss grid')
scatter(r1,z1,[],odf.Psi_Gauss);
colormap jet
colorbar 
xlabel('R')
ylabel('Z')
axis equal
axis tight
grid on

% PSI_BAR
figure('Name', 'Psi bar on Grad Gauss grid')
scatter(r1,z1,[],odf.psi_bar);
colormap jet
colorbar 
xlabel('R')
ylabel('Z')
axis equal
axis tight
grid on

%Jphi
figure('Name', 'Jphi on Grad Gauss grid')
scatter(r1,z1,[],odf.Jphi);
colormap jet
colorbar
xlabel('R')
ylabel('Z')
axis equal
axis tight
grid on

%%
r2 = odf.Grad_c_t(:,1);
z2 = odf.Grad_c_t(:,2);


%grad_c_t
figure('Name', 'Psi c t on Grad c t grid')
scatter(r2,z2,[],odf.Psi_c_t);
colormap jet
colorbar 
xlabel('R')
ylabel('Z')
axis equal
axis tight
grid on

%%
r3 = odf.Grad_nodes(:,1);
z3 = odf.Grad_nodes(:,2);

%Iphi
figure('Name', 'Iphi on Grad Nodes')
scatter(r3,z3,[],odf.Iphi);
colormap jet
colorbar
xlabel('R')
ylabel('Z')
axis equal
axis tight
grid on

%%

%Separatrix
figure('Name', 'Separatrix')
plot(odf.Separatrix(:,1),odf.Separatrix(:,2))
xlabel('R')
ylabel('Z')
axis equal
axis tight
grid on
