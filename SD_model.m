%% Spatial Filter Model w/ Sensory Delay Lines
% Time invariant multisensory summation w/ modality-specific processing
% delays

close all
clear all

% variable model parameters
alpha_v=0;              % vision intensity term (deg/s)
alpha_w=0;              % wind intensity term (deg/s)
T_w=.02;                % wind delay (sec)
T_v=.1;                 % vision delay (sec)

% fixed simulation terms
numtrial=8;             % number of trial per fly to simulate
numfly=1;               % number of flies to simulate
t_end=25;               % trial duration (sec)
dt=0.02;                % time step (sec)
tvec=(dt:dt:t_end);     % vector of time points in simulation
H=-180:0.1:180;         % possible headings vector

% define starting positions
if numtrial==8
    startpos=(-135:45:180)-1;
end
if numtrial==2
    startpos=[1 90];
end

% convert delays to samples
wind_delay=round(T_w/dt);
vis_delay=round(T_v/dt);

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
            if numtrial==8 || numtrial==2
                H_t(1,trial,cond,fly)=startpos(trial);
            else
                H_t(1,trial,cond,fly)=-180+trial*(360/numtrial);
            end
            
            % sim loop
            for t=1:1:t_end/dt
                
                % calculate turn rate from D-functions at appropriate delay
                if cond==2 || cond==4
                    if t>wind_delay
                        ind=find(round(H,1)==round(H_t(t-wind_delay,trial,cond,fly),1));
                        dHw=alpha_w*D_w(ind)*dt;
                    else
                        dHw=0;
                    end
                else
                    dHw=0;
                end
                if cond==3 || cond==4
                    if t>vis_delay
                        ind=find(round(H,1)==round(H_t(t-vis_delay,trial,cond,fly),1));
                        dHv=alpha_v*D_v(ind)*dt;
                    else
                        dHv=0;
                    end
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

