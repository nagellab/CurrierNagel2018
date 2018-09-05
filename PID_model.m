%% control theory model of multisensory integration
% feedback control model with classical proportional-integral-derivative
% control of angular velocity/orientation. includes modality-specific
% processing delays. turn rate is poroportional to orientation error.

close all
clear all

% variable model parameters
Tw=.02;         % wind processing delay (sec)
Tv=.1;          % visual processing delay (sec)
k_i_v=0;        % visual integral weight
k_p_v=0;        % visual proportional weight
k_d_v=0;        % visual derivative weight
k_i_w=-0;       % wind integral weight
k_p_w=0;        % wind proportional weight
k_d_w=-0;       % wind derivative weight

% fixed simulation terms
numtrial=2;         % number of trial per fly to simulate
numfly=1;           % number of flies to simulate
Htw=180;            % wind target orientation
Htv=0;              % visual target orientation
t_end=25;           % trial duration (sec)
dt=0.02;            % time step (sec)

% define starting positions
if numtrial==2
    startpos=[1 90];
elseif numtrial==8
    startpos=(-135:45:180);
end

% main output variable = heading over time
% dimensions = (time, trial number, condition number, fly number)
H_t=zeros(t_end/dt,numtrial,4,numfly);
dH_t=zeros((t_end/dt)-1,numtrial,4,numfly);
delta_t_w=zeros((t_end/dt)-1,numtrial,4,numfly);
delta_t_v=zeros((t_end/dt)-1,numtrial,4,numfly);

% convert delays to samples
wind_delay=round(Tw/dt);
vis_delay=round(Tv/dt);

simfig=figure;
% main simulation
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
                
                % calculate errors at appropriate delay
                % if not past delay length, assign no drive for modality
                % if not proper stimulus condition, assign no drive
                if t>wind_delay
                    if cond==2||cond==4
                        delta_w=mod(Htw-H_t(t-wind_delay,trial,cond,fly)+180,360)-180;
                    else
                        delta_w=0;
                    end
                else
                    delta_w=0;
                end
                if t>vis_delay
                    if cond==3||cond==4
                        delta_v=mod(Htv-H_t(t-vis_delay,trial,cond,fly)+180,360)-180;
                    else
                        delta_v=0;
                    end
                else
                    delta_v=0;
                end
                
                % proportional terms - current error
                dHp=k_p_w*delta_w+k_p_v*delta_v;
                
                % integral terms - full trial accumulated error
                if t==1
                    dHi=k_i_w*delta_w+k_i_v*delta_v;
                else
                    dHi=k_i_w*(delta_w+sum(delta_t_w(1:t-1,trial,cond,fly)))...
                        +k_i_v*(delta_v+sum(delta_t_v(1:t-1,trial,cond,fly)));
                end
                
                % derivative terms - instantaneous change in error
                if t==1
                    dHd=0;
                else
                    dHd=k_d_w*(delta_t_w(t-1,trial,cond,fly)-delta_w)...
                        +k_d_v*(delta_t_v(t-1,trial,cond,fly)-delta_v);
                end
                
                % compile terms and cap dH/dt
                dH=dHi+dHp+dHd;
                if dH>3
                    dH=3;
                elseif dH<-3
                    dH=-3;
                end
                
                % Heading update
                delta_t_w(t,trial,cond,fly)=delta_w;
                delta_t_v(t,trial,cond,fly)=delta_v;
                dH_t(t,trial,cond,fly)=dH;
                H_t(t+1,trial,cond,fly)=H_t(t,trial,cond,fly)+dH;
                H_t(t+1,trial,cond,fly)=mod(H_t(t+1,trial,cond,fly)+180,360)-180;
            end
        end
        if fly==numfly
            subplot(2,2,cond); hold on
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

