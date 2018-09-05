%% Import LabView Data
% This is the basic script used to read-in data from LabView. Specify the 
% folder containing the experiment to analyze as categorystr. That folder
% should be located in the basepath parent directory. Copyright Nagel Lab
% and TAC, 2018.

basepath='EXPERIMENTS_ROOT_DIRECTORY';
categorystr='SPECIFIC_EXPERIMENT_NAME';

fullpath=[basepath categorystr '/'];
cd(fullpath);
E=dir(fullpath);

% if 1, make a basic plot of each flies' raw behavior
plotfigs=1;

numsession=0;
numfly=0;

for m=1:length(E)
    
    % move to folder m in directory if it starts with '2' (i.e., 2016),
    % which means that folder contains data
    e=E(m);
    if strcmp(e.name(1),'2')
        flypath=[fullpath e.name];
        cd(flypath)
        D=dir(flypath);
        
        numfly=numfly+1;
        
        % move to and process each session folder (begins with 'E' under 
        % my naming conventions - this is the "Experiment Name" string in
        % the core LabView script)
        for n=1:length(D)
            d=D(n);
            if strcmp(d.name(1),'E')
                numsession=numsession+1;
                cd([flypath '/' d.name])
                
                % import experiment information
                A=importdata('experiment_information');
                data.date=A.textdata(1,1);    % YYYY.MM.DD format
                data.flyID=A.textdata(2,1);   % fly name
                data.expt=A.textdata(3,1);    % experiment name
                data.flyage=A.data(1,1);      % fly age (DSE)
                data.starved=A.data(2,1);     % starvation time (hr)
                data.numtrials=A.data(3,1);   % number of trials
                data.trialdura=A.data(4,1);   % trial duration (sec)
                data.odoron=A.data(5,1);      % odor onset time (sec)
                data.useodor=A.data(6,1);     % boolean, 1=odor session
                data.usewind=A.data(7,1);     % boolean, 1=wind session
                data.randwind=A.data(8,1);    % boolean, 1=wind randomized
                data.fs=A.data(9,1);          % data sample rate (Hz)
                data.motorfs=A.data(10,1);    % motor stepping rate (Hz)
                data.maxsteps=A.data(11,1);   % maximum steps per sample
                data.k=A.data(12,1);          % deltaWBA scale factor
                data.RT=A.data(13,1);         % boolean, 1=reverse tethered
                data.uselight=A.data(14,1);   % boolean, 1=light session
                data.randlight=A.data(15,1);  % boolean, 1=light randomized
                if length(A.data)>15
                    data.varyint=A.data(16,1);% boolean, 1=varied intensity
                end
                
                % read-in wind intensities by trial
                if data.usewind==1;
                    fid=fopen('wind_boolean','r');
                    data.windbool=fread(fid,inf,'int16','b');
                    data.windbool=data.windbool(1:data.numtrials);
                    fclose all;
                end
                
                % read-in light intensities by trial
                if data.uselight==1;
                    fid=fopen('light_intensities','r');
                    data.lightV=fread(fid,inf,'double','b');
                    data.lightV=data.lightV(1:data.numtrials);
                    fclose all;
                end
                
                % define data structure
                data.trials.H=zeros((data.trialdura*data.fs),data.numtrials);
                data.trials.x=data.trials.H;
                data.trials.dWBA=data.trials.H;
                data.trials.LWBA=data.trials.H;
                data.trials.RWBA=data.trials.H;
                
                % raw data read-in and write to data structures
                for i=1:data.numtrials
                    eval(['fid=fopen(''trial ' num2str(i) ...
                        ' unfiltered deltaWBA'',''r'');'])
                    eval(['t' num2str(i) 'dWBA=fread(fid,inf,''double'',''b'');'])
                    fclose all;
                    eval(['data.trials.dWBA(:,' num2str(i) ')=t' num2str(i) ...
                        'dWBA(1:(data.trialdura*data.fs),1);'])
                    eval(['fid=fopen(''trial ' num2str(i) ' LWBA_data'',''r'');'])
                    eval(['t' num2str(i) 'LWBA=fread(fid,inf,''double'',''b'');'])
                    fclose all;
                    eval(['data.trials.LWBA(:,' num2str(i) ')=t' num2str(i) ...
                        'LWBA(1:(data.trialdura*data.fs),1);'])
                    eval(['fid=fopen(''trial ' num2str(i) ' RWBA_data'',''r'');'])
                    eval(['t' num2str(i) 'RWBA=fread(fid,inf,''double'',''b'');'])
                    fclose all;
                    eval(['data.trials.RWBA(:,' num2str(i) ')=t' num2str(i) ...
                        'RWBA(1:(data.trialdura*data.fs),1);'])
                    eval(['fid=fopen(''trial ' num2str(i) ' heading_data'',''r'');'])
                    eval(['t' num2str(i) 'H=fread(fid,inf,''double'',''b'');'])
                    fclose all;
                    eval(['data.trials.H(:,' num2str(i) ')=t' num2str(i) ...
                        'H(1:(data.trialdura*data.fs),1);'])
                    eval(['fid=fopen(''trial ' num2str(i) ' x_data'',''r'');'])
                    eval(['t' num2str(i) 'x=fread(fid,inf,''double'',''b'');'])
                    fclose all;
                    eval(['data.trials.x(:,' num2str(i) ')=t' num2str(i) ...
                        'x(1:(data.trialdura*data.fs),1);'])
                    
                end
                
                % combined wind/light analysis
                if data.usewind==1 && data.randwind==1 &&...
                        data.uselight==1 && data.randlight==1
                    
                    % sort all data by stimulus condition
                    data.WL.H=[];
                    data.NWL.H=[];
                    data.WNL.H=[];
                    data.NWNL.H=[];
                    data.WL.dH=[];
                    data.NWL.dH=[];
                    data.WNL.dH=[];
                    data.NWNL.dH=[];
                    for t=1:data.numtrials
                        if data.windbool(t)==1 && data.lightV(t)>1
                            data.WL.H(:,end+1)=data.trials.H(:,t);
                            data.WL.dH(:,end+1)=data.trials.dWBA(:,t);
                        elseif data.windbool(t)==1 && data.lightV(t)<1
                            data.WNL.H(:,end+1)=data.trials.H(:,t);
                            data.WNL.dH(:,end+1)=data.trials.dWBA(:,t);
                        elseif data.windbool(t)==0 && data.lightV(t)>1
                            data.NWL.H(:,end+1)=data.trials.H(:,t);
                            data.NWL.dH(:,end+1)=data.trials.dWBA(:,t);
                        elseif data.windbool(t)==0 && data.lightV(t)<1
                            data.NWNL.H(:,end+1)=data.trials.H(:,t);
                            data.NWNL.dH(:,end+1)=data.trials.dWBA(:,t);
                        end
                    end
                    
                    % plot heading timecourses by condition
                    if plotfigs==1
                        flyfig=figure;
                        subplot(2,2,1), hold on
                        plot((1/data.fs):(1/data.fs):data.trialdura,data.NWNL.H,'k.');
                        ylabel('Heading (deg)')
                        xlabel('Time (sec)')
                        title(['W-/L- Heading for Fly ' e.name(end-2:end) ', session ' d.name(1:2)])
                        ylim([-180 180])
                        xlim([0 data.trialdura])
                        subplot(2,2,2), hold on
                        plot((1/data.fs):(1/data.fs):data.trialdura,data.WNL.H,'k.');
                        ylabel('Heading (deg)')
                        xlabel('Time (sec)')
                        title(['W+/L- Heading for Fly ' e.name(end-2:end) ', session ' d.name(1:2)])
                        ylim([-180 180])
                        xlim([0 data.trialdura])
                        subplot(2,2,3), hold on
                        plot((1/data.fs):(1/data.fs):data.trialdura,data.NWL.H,'k.');
                        ylabel('Heading (deg)')
                        xlabel('Time (sec)')
                        title(['W-/L+ Heading for Fly ' e.name(end-2:end) ', session ' d.name(1:2)])
                        ylim([-180 180])
                        xlim([0 data.trialdura])
                        subplot(2,2,4), hold on
                        plot((1/data.fs):(1/data.fs):data.trialdura,data.WL.H,'k.');
                        ylabel('Heading (deg)')
                        xlabel('Time (sec)')
                        title(['W+/L+ Heading for Fly ' e.name(end-2:end) ', session ' d.name(1:2)])
                        ylim([-180 180])
                        xlim([0 data.trialdura])
                    end
                    
                    % if you want to perform single-fly analyses or save
                    % single-fly data to a larger cross-fly matrix, add
                    % that here
                    
                    
                    
                end
            end
        end
    end
end
