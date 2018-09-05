%% Dynamic Orientation Target Averaging Simulation
% target orientation governed by an average of wind and vision targets.
% wind weight starts equal to vision, then decays. the result is a
% temporally-variable target orientation that gets compared to current
% orientation. orientation error is scaled to angular velocity.

close all
clear all

% variable model parameters
alpha_v=1;             % vision intensity term (deg/s per degree of error)
alpha_w=1;             % wind intensity term (deg/s per degree of error)
k=0;                   % relates error to turn rate
tau_w=0;               % negative (slow) wind filter time constant (sec)
beta_w=0;              % steady-state wind response

% targets
t_wind=180;
t_vis=0;

% fixed simulation terms
numtrial=2;             % number of trial per fly to simulate
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
    startpos=(-135:45:180);
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

% main output variable = heading over time
% dimensions = (time, trial number, condition number, fly number)
H_t=zeros(t_end/dt,numtrial,4,numfly);
dH_t=zeros((t_end/dt)-1,numtrial,4,numfly);

% filtered stimulus variables
S_v=zeros((t_end/dt)-1,numtrial,4,numfly);
S_w=zeros((t_end/dt)-1,numtrial,4,numfly);

% other outputs
e_t=zeros((t_end/dt)-1,numtrial,4,numfly);
target_t=zeros((t_end/dt)-1,numtrial,4,numfly);

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
                
                % apply filtered stimulus and alpha as weight to target
                % orientations, calculate error, and dH/dt
                if cond==1
                    target=H_t(t,trial,cond,fly);
                    e=mod((target-H_t(t,trial,cond,fly))+180,360)-180;
                elseif cond==2
                    target=(t_wind);
                    e=mod((target-H_t(t,trial,cond,fly))+180,360)-180;
                elseif cond==3
                    target=(t_vis);
                    e=mod((target-H_t(t,trial,cond,fly))+180,360)-180;
                elseif cond==4
                    target=mod(((Sw*alpha_w*t_wind + alpha_v*t_vis)/2)+180,360)-180;
                    e=mod((target-H_t(t,trial,cond,fly))+180,360)-180;
                end
                
                % linear spatial filter on error - proportionality constant
                dH=k*e;
                
                % cap dH/dt
                if dH>3
                    dH=3;
                elseif dH<-3
                    dH=-3;
                end
                
                % Heading update
                S_w(t,trial,cond,fly)=Sw;
                S_v(t,trial,cond,fly)=Sv;
                target_t(t,trial,cond,fly)=target;
                e_t(t,trial,cond,fly)=e;
                dH_t(t,trial,cond,fly)=dH;
                H_t(t+1,trial,cond,fly)=H_t(t,trial,cond,fly)+dH;
                H_t(t+1,trial,cond,fly)=mod(H_t(t+1,trial,cond,fly)+180,360)-180;
            end
        end
        if fly==numfly && cond~=1
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
subplot(2,3,3), hold on
plot(tvec,target_t(:,1,4),'k-','LineWidth',2)
plot([0 t_end],[0 0],'k:')
xlim([0 t_end])
xlabel('Time (sec)')
ylabel('Target Orientation')
















