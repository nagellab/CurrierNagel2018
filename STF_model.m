%% Spatiotemporal Filtering Model Simulation
% incoming sensory vectors are filtered in space and time to yield turn
% commands, which are summed to produce multisensory turn rate.

close all
clear all

% simulation type
shift_stim=0;           % if 1, circularly shift wind D-function and run -90/90

% variable model parameters
alpha_v=0;             % vision intensity term (deg/s)
alpha_w=0;             % wind intensity term (deg/s)
tau_w=0;               % negative (slow) wind filter time constant (sec)
beta_w=0;             % steady-state wind response

% fixed simulation terms
numtrial=8;             % number of trial per fly to simulate
numfly=1;               % number of flies to simulate
t_end=25;               % trial duration (sec)
dt=0.02;                % time step (sec)
tvec=(dt:dt:t_end);     % vector of time points in simulation
H=-180:0.1:180;         % possible headings vector
filt_noise_scale=0; % noise scaling factor (unitless) - set to 0 to remove

% define starting positions
if numtrial==2
    startpos=[1 90];
elseif numtrial==8
    startpos=(-136:45:180);
elseif numtrial==10
    startpos=[1 1 1 1 1 90 90 90 90 90];
end

% convert time constants to samples
tau_w=tau_w/dt;
Wr=1-beta_w;

% define standardized D-functions for wind (Gauss*step) and vision
% (Gauss*line)
curve=normpdf(H,0,60)/max(normpdf(H,0,60));
line=linspace(-100,100,length(H));
step=[-1*ones(1,1800) 0 ones(1,1800)];
D_w=step.*curve;
D_v=-line.*curve/max(-line.*curve);

% circular shift in D_w if applicable
if shift_stim==1
    D_w=circshift(D_w,-900,2);
    numtrial=10;
    startpos=[-90 -90 -90 -90 -90 90 90 90 90 90];
end

% main output variable = heading over time
% dimensions = (time, trial number, condition number, fly number)
H_t=zeros(t_end/dt,numtrial,4,numfly);
dH_t=zeros((t_end/dt)-1,numtrial,4,numfly);

% filtered stimulus variables
S_v=zeros((t_end/dt)-1,numtrial,4,numfly);
S_w=zeros((t_end/dt)-1,numtrial,4,numfly);

% main simulation
simfig=figure;
subplot(2,3,1), hold on
plot(H,D_w,'b-','LineWidth',2)
plot(H,D_v,'r-','LineWidth',2)
plot([-180 180],[0 0],'k:')
plot([0 0],[-1 1],'k:')
axis([-180 180 -1 1])
xlabel('H (deg)')
ylabel('Normalized D-function')
for fly=1:numfly
    for cond=1:4
        for trial=1:numtrial          
            
            % initial conditions
            if numtrial==8 || numtrial==2 || numtrial==10
                H_t(1,trial,cond,fly)=startpos(trial);
            else
                H_t(1,trial,cond,fly)=-180+trial*(360/numtrial);
            end
            
            % sim loop
            for t=1:1:t_end/dt
                
                % calculate filtered stimulus for each modality
                if t==1
                    Sv=1;
                    Sw=1;
                else
                    Sv=1;
                    Sw=S_w(t-1,trial,cond,fly)+(beta_w-S_w(t-1,trial,cond,fly))/tau_w;
                end
                
                % apply filtered stimulus to D-function
                ind=find(round(H,1)==round(H_t(t,trial,cond,fly),1));
                if cond==2 || cond==4
                    dHw=alpha_w*Sw*D_w(ind)*dt;
                else
                    dHw=0;
                end
                if cond==3 || cond==4
                    dHv=alpha_v*Sv*D_v(ind)*dt;
                else
                    dHv=0;
                end
                
                % compile terms and cap dH/dt
                dH=dHw+dHv;
                if dH>3
                    dH=3;
                elseif dH<-3
                    dH=-3;
                end
                
                % Heading update
                S_w(t,trial,cond,fly)=Sw;
                S_v(t,trial,cond,fly)=Sv;
                dH_t(t,trial,cond,fly)=dH;
                H_t(t+1,trial,cond,fly)=H_t(t,trial,cond,fly)+dH;
                H_t(t+1,trial,cond,fly)=mod(H_t(t+1,trial,cond,fly)+180,360)-180;
            end
        end
        if fly==numfly
            subplot(2,3,cond+2); hold on
            for kk=1:numtrial
                plot(0:dt:t_end,H_t(:,kk,cond,fly)',...
                    '-','Color',[0 kk/numtrial 0])
            end
            plot([0 t_end],[0 0],'k:')
            ylim([-180 180])
            xlim([0 t_end])
            ylabel('H (deg)')
            xlabel('t (sec)')
        end
    end
end
subplot(2,3,2), hold on
plot(tvec,S_w(:,1,2),'b-','LineWidth',2)
plot(tvec,S_v(:,1,3),'r-','LineWidth',2)
plot([0 t_end],[0 0],'k:')
xlim([0 t_end])
xlabel('Time (sec)')
ylabel('Normalized Filtered Stimulus')

















