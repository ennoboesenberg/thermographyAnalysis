%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Thermography-Postprocessingprogramm 
%   by Enno Bösenberg
%   
%   Preparation:
%    1.	change 'svDir' to where you want your videos to be saved
%   
%   Optional:
%    1.	change filenames for any video in this script
%    2.	change 'fps' to adjust frames per second in all output videos
%    3.	change 'quali' to adjust video quality for all output videos
%    4. preset which area of the image should be analysed ('colstart_pt', 
%       'rowstart_pt' and 'rowend_pt')
%    5. should the program calculate a differential image or not ('diffim')
%    6. estimate the area taken by markers and select distance between the
%       markers ('markerSize' and 'markerDist')
%
%   Manual:
%    1.	folder including the measurements must be opened in Matlab.
%    2.	RUN script
%    3.	follow the instructions in COMMANDWINDOW (DO NOT PRESS ENTER AT
%       RANDOM*)
%    4. Results of the analysis are stored in THermotrans (column 1 to 4
%       include transition mid, end and start as well as a fourth column
%       for a possible lsb-criterium)
%
%   Automated operations (chronologically):
%    1.	user will be asked to answer a few important questions
%    2.	starting VIDEOWRITER
%    3.	PROCESSING starts
%    4.	output of information about remaining datasets, processes and time
%    5.	loading images
%    6.	turn images to grayscale (also getting rid of unit8)
%    7.	find relevant data (y-axis)
%    8.	smoothing data
%    9.	fit data
%   10.	derive fitted data
%   11. find transitionpoint (t-point)
%   12. find lower and upper boundaries of transition
%   13. adjust placement of t-point and its boundaries for original image
%   14. draw t-point and its boundaries
%   15. show and get frames using VideoWriter
%   16. analyses whether or not transitionline can be counted as such
%   17. repeating steps 4 to 16 untill all images were processed
%   18. closing VIDEOWRITER
%   
%   Original measurement framerate was 355Hz. During the process of saving
%   images from imageIR Software some images seem to get corrupted. Either
%   find a way to fix that or delete/replace all corrupted images.
%
%   *   pressing ENTER at random may cause singularities in space-time
%   continuum
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear
close all
clc

%% Starting main program

fps             = 71;                                                       % frames per second in VideoWriter
quali           = 99;                                                       % quality of VideoWriter
diffim          = 0;                                                        % create diff. image
smoothParameter = 0.0001;

colstart_pt    	= [100];                                                  	% which culomn in image should be the first to be analysed (if non leave it at [])	(automation possible)
rowstart_pt     = [1];                                                       % which row in image should be the first to be analysed (if non leave it at [])	(automation possible)
rowend_pt   	= [440];                                                       % which row in image should be the last to be analysed (if non leave it at [])	(automation possible)
chordlength     = 180;                                                      % chordlength in mm
angleoupsurface = -12.4561;                                                 % angle in degree old: -12.3415
markerSize      = 0.05;                                                      % 10% (e.g. 2DAG), 5% (e.g. noAG) of image lines include markers
markerDist      = 5;                                                        % distance between each marker in mm
scaleSetmode	= 1;                                                        % 0 = continues scale adjustment; 1 = sets the scale once (automatically)
scaleSet        = 0;                                                        % keep at 0 to get automated scale calculation

svDir           = 'G:\ProcessedVideos\';                                    % where to save videos
thermo_field    = 'Transitionline-smooth3';                                	% name of the video
thermo_data     = 'Thermography';

%% Checking for useful data in current directory

file_list 	= dir(fullfile(cd, '*.tif'));                                   % listing files from reference directory
if isempty(file_list)
	error('No valid data (.tif) found in this directory. Please change directory.');
end

%% User interrogation

[numoim, startim, stepsize, numorows] = userInput_thermo(file_list);        % interrogating user

%% Imagescale analyses (when differantial images have to be generated here)

if diffim == 1
    ref_list        = dir(fullfile(cd, '*reference*'));
    if isempty(ref_list)
        ref_list        = dir(fullfile(cd, '*_0001_0001*'));
    end
    TRef            = imread(ref_list(end).name);
    
    % Adjusting for relevant data
    tref            = rgb2gray(TRef)';
    if isempty(rowend_pt)
        rowend_pt      = find(mean(tref) < ...
                        mean(mean(tref))-std(mean(tref))/2,1,'first');
    end
    
    tref_tp         = tref';
    mean_yvalI      = mean(tref);
    
  	[~, maxI]       = max(diff(mean_yvalI));
	[~, minI]       = min(diff(mean_yvalI));
    if maxI > minI
        [oo, p]         = islocalmin(mean(tref(:, minI:maxI),2),...
                            'MinProminence',10);
    else
        [oo, p]         = islocalmin(mean(tref(:, maxI:minI),2),...
                            'MinProminence',10);
    end
    
  	index           = find(oo == 1);
    visibleDistmm   = length(index)/2*10;                                   % visible surface in mm (e.g. 105mm)
    trueDistmm      = visibleDistmm*cos(angleoupsurface);                	% angle of airfoil uppersurface near trailing edge
  	mmSize          = index(end)/trueDistmm;                            	% [mm] = x[pixel]
end

%%  Small calculations to allow for some more satisfying processing

estprocTime         = numorows/stepsize;                                   	% educated guess as to how long the processing of one image will take
calculationTime     = ones(1,1+numoim-startim).*estprocTime;               	% includes all processingtimes
bub_vec             = zeros(numoim, 1);                                     % images including bubbles = 1
waitbarCreator      = waitbar(0,'1','Name','Processing time',...
                        'Position', [0 500 280 60]);                        % creates waitbar
%% find right structure to stop vectors from changing size
% t_frame             = zeros(numoim-startim+1, 1);
% d_frame             = t_frame;
% THermotrans         = zeros(numoim-startim+1, 4);


%% Create movie of the velocityfield

[addnum] = numberSTH_thermo(svDir);

ttitle                 = [svDir thermo_field '_' addnum];                   % 'E:\ProcessedVideos\just_velocityfield';
t_vid                  = VideoWriter(ttitle, 'MPEG-4');
t_vid.FrameRate        = fps;
t_vid.Quality          = quali;
open(t_vid);                                                                % open videofile to be written 

dtitle                 = [svDir thermo_data '_' addnum];                    % 'E:\ProcessedVideos\just_velocityfield';
d_vid                  = VideoWriter(dtitle, 'MPEG-4');
d_vid.FrameRate        = fps;
d_vid.Quality          = quali;
open(d_vid);                                                                % open videofile to be written 

%% 
%POSSIBLY FIND FILES TO PROCESS (SOME SEEMED TO BE CORRUPT)

%% Processing

if isempty(rowstart_pt)
    rowstart_pt = 1;                                                        % which row in image should be the first in processing
end

if isempty(rowend_pt)                                                       % which row in image should be the last in processing
    rowept_is_empty = 1;
else
    rowept_is_empty = 0;
end

for kk = startim:numoim
    tic
    working_stepsize	= stepsize;                                       	% adjust stepsize for userinput

    leftpar         = 1+numoim-kk;                                          % number of processes left
    
    [days_left, hours_left, minutes_left, seconds_left] =...
        processingTime(leftpar, calculationTime);                           % calculates estimated remainung time till finish
    
   	waitbar((kk-startim+1)/(numoim-startim), waitbarCreator, ...
        [num2str(leftpar) ' processes left. Remaining time: '...
        num2str(days_left) 'd ' num2str(hours_left) 'h '...
        num2str(minutes_left) 'min ' num2str(seconds_left) 's'])            % what should the waitbar show
    
    % Read image and adjust
    [t, ~]      = imread(file_list(kk).name);                              	% read image from directory
    if diffim == 1
        t       = imabsdiff(t,TRef);
    end
    
    I               = rgb2gray(t);                                      	% create grayscale image
    [xsz_I, ysz_I]  = size(I);
    I_tp            = I';
    
%% Creating figure of thermography image (including markers)

    figure(1);
    imagesc(I)
    colormap('gray')
    
    % Find relevant x-values (no valid charaterization yet)
    mean_xvalI	= mean(I(end,:));
    std_xvalI	= floor(std(double(I(end,:))));
    irr_xvalI	= find(I(1,:) < mean_xvalI - std_xvalI/2);
	
	if isempty(colstart_pt)
        colstart_pt    = double(min(mean(I(1:16,:)))) + 1;                	% max(I(1,:)) can still be zero so + 1 for safety
	end


	if diffim ~= 1 && scaleSet == 0
        % Find relevant y-values (no valid charaterization yet)
        mean_yvalI      = mean(I_tp);
        
        Ms              = sort(mean_yvalI,'descend');
    	Result          = Ms(1:ceil(length(Ms)*markerSize));                % find the markers for image scale
        
        if rowept_is_empty == 1
            rowend_pt  = find(mean_yvalI == Result(end), 1,'first');
        end
        
        max_yvalI	= find(mean_yvalI == Result(1));
        
        minI        = find(mean_yvalI(1:max_yvalI) >= Result(end), 1,'first');
        
        if isempty(minI)
            x_step      = 1:length(mean_yvalI);
            McStepy     = fit(x_step',mean_yvalI','smoothingspline',...
                            'SmoothingParam', smoothParameter);            	% simplifymarkerfinding
            [d_rive1_step]   = differentiate(McStepy, x_step);
            minI        = find(d_rive1_step == max(d_rive1_step));
        end
        
        maxI        = find(mean_yvalI(max_yvalI:end)<= Result(end), 1,'first')...
                        + max_yvalI - 1;
        
        if isempty(maxI)
            x_step      = 1:length(mean_yvalI);
            McStepy     = fit(x_step',mean_yvalI','smoothingspline',...
                            'SmoothingParam', smoothParameter);            	% simplifymarkerfinding
            [d_rive1_step]   = differentiate(McStepy, x_step);
            maxI        = find(d_rive1_step == min(d_rive1_step));
        end
                    
        if maxI > minI
            [oo, p]	= islocalmax(mean(I_tp(:, minI:maxI),2),...
                            'MinProminence',10);
        else
            [oo, p]	= islocalmax(mean(I_tp(:, maxI:minI),2),...
                            'MinProminence',10);
        end
        
        index           = find(oo == 1);
      	visibleDistmm   = length(index)*markerDist;                       	% visible surface in mm (e.g. 105mm)
        trueDistmm      = visibleDistmm*cos(angleoupsurface);           	% angle of airfoil uppersurface near trailing edge (e.g. 6.2986)
        mmSize          = index(end)/trueDistmm;
        
        
        switch scaleSetmode
            case 0
                scaleSet        = 0;                                    % will continue to adjust scale for each image
            case 1
                scaleSet        = 1;                                    % will set scale once and keep it for all following images
        end
	end
    
    % Labeling of the axes
    tix         = 0:mmSize*10:ysz_I;
    lblxng      = round((chordlength-tix./mmSize)/chordlength*100)/100;
    lblx      	= {num2str(lblxng')};
    
    tiy         = 0:mmSize*10:xsz_I;
    lblyng      = round((tiy./mmSize/chordlength)*100)/100;
    lbly      	= {num2str(lblyng')};
    
    xticks(tix)
    xticklabels(lblx)
    xlabel('x / c')
    
    yticks(tiy)
    yticklabels(lbly)
    ylabel('y / c')

    
    % What if there is no end_pt
    if isempty(rowend_pt)
        y = I(1:end, colstart_pt:end);                                  	% get array of valid data ( (1:end_pt,start_pt:end) )
    else
        y = I(rowstart_pt:rowend_pt, colstart_pt:end);                      
    end
    
    [a,b]=size(y);                                                          % get size of valid data array to adjust x-vector
    if working_stepsize > a
        working_stepsize = a;
    end
    
    x           = 1:b;                                                  	% create x-vector
    x_s         = 1:b+colstart_pt-1;
    dataLock1	= zeros(a, 4);                                              % semipreallocate dataLock1 matrix
    
    ii = 0;
    while ii < a
        % Starting to go through rows set to be analysed
        % Checking whether next step might exceed number of rows in image
        ii_check	= ii + working_stepsize;
        if a < ii_check
            working_stepsize	= a - ii;
        end
        
        hold on

        dim_chg = y(1+ii:ii+working_stepsize,:);                            % changing dimension of y
        if working_stepsize > 1                                                     
            smoothable	= mean(dim_chg);                                    % avg over rows to be processed
            place     	= 1+ii:ii+working_stepsize;                         % numbers of rows to be marked
        else
            smoothable	= dim_chg;                                          
            place       = 1+ii;                                               
        end

%         % Linear adjustment for heat gradient
%         if diffim == 1
%             diff_vec = [1, double(smoothable(1))] - [length(x), double(smoothable(length(x)))];
%             linslope = diff_vec(2)/diff_vec(1);
% 
%             x_vec = double(smoothable(1)):linslope:double(smoothable(length(x)));
%             if ~isempty(x_vec)
%                 smoothable = double(smoothable(x)) - x_vec;
%             end
%         end
        
        McSmooth = fit(x',smoothable','smoothingspline',...
            'SmoothingParam', smoothParameter);                           	% smoothing data
        [d_rive1, d_rive2] = differentiate(McSmooth, x);                 	% derive fitted smoothed data
        
        mean_estxvalI	= mean(d_rive1(:));                              	% calculate avg value
        std_estxvalI	= std(double(d_rive1(:)));                       	% calculate std value
        
        if diffim == 1
            eststart_pt     = find(d_rive1 > ...
                                mean_estxvalI - std_estxvalI,1,'first');
        else
            try
                rel_estxvalI	= find(abs(d_rive1(:)) < ...
                                    mean_estxvalI + std_estxvalI);            	% find relevant data
                eststart_pt     = rel_estxvalI(1);                            	% starting point of relevant data
            catch
             	eststart_pt = 1;
            end
        end
        
        d_rive1        	= d_rive1(eststart_pt:end);                         % adjust dataset
        d_rive2         = d_rive2(eststart_pt:end);                         % adjust dataset
        
        % Common criterium for transitionline
        if diffim == 1                                                      % diffim inverts criterium
            [maxPkt, where] = min(d_rive1);
            
            % New criteria for transitionline boundaries
            below0_top      = where +...
                                find(round(d_rive1(where:end).*100) >= 0, 1,'first');	% criterium for lower end of t-line
            below0_bot      = where -...
                                find(round(d_rive1(where:-1:1).*100) >= 0, 1,'first');	% criterium for upper end of t-line
            
            if isempty(below0_top)
                below0_top	= 0;
            end
            if isempty(below0_bot)
                below0_bot	= 0;
            end
        else
            [maxPkt, where] = max(d_rive1);
            
           	% New criteria for transitionline boundaries
            [maxPts, below0_bot]	= max(d_rive2);                     	% criterium for lower end of t-line
            [minPts, below0_top]	= min(d_rive2);                       	% criterium for upper end of t-line
        end

        % New criterium for a seperation bubble detection
        if diffim == 1
            bubplace        = find(islocalmin(d_rive1(where:end),...
                                'MinProminence', 0.01), 1, 'first')+where;  % MUST BE ADJUSTED for wind direction
        else
            bubplace     	= find(islocalmax(d_rive1(where:end),...
                                'MinProminence', 0.02))+where-1;          	% MUST BE ADJUSTED for wind direction
        end
        
        % Checking for empty criteria
        if isempty(where)
            where           = 0;
        end
        
        if isempty(below0_bot)
            below0_bot    	= 0;
        end
        
        if isempty(below0_top)
            below0_top    	= 0;
        end
        
        if isempty(bubplace)
            bubplace        = 0;
        end

      	if isempty(eststart_pt)
            eststart_pt    	= 0;
        end
        
        if isempty(colstart_pt)
            colstart_pt        = 0;
        end
        
        % Adjustment of locations
        adjusting_dist      = eststart_pt-1+colstart_pt-1;                 	% adjust for all changes to original row size

        transLine           = where + adjusting_dist;                     	% adjusting transitionline marker
        lowerEnd            = below0_bot + adjusting_dist;               	% adjusting lowerlimit marker
        upperEnd            = below0_top + adjusting_dist;               	% adjusting upperlimit marker
        bubplace            = bubplace + adjusting_dist;                    % adjusting seperation bubble marker

        [~, sz_place]       = size(place);                                  % number of rows to be marked
        for pp = 1:sz_place
            dataLock1(place(pp),1:4)	= [transLine lowerEnd upperEnd...
                                            bubplace(1)];                   % which rows should be marked
        end

        ii          = ii + working_stepsize;
    end
%%	Transitionline Criteria

% 	if std(dataLock1(:,1)) > 60                                             % criteria for whether or not a consistent transition zone can be found
%             fprintf('%d   There is NO consistent TRANSITIONZONE.\n', kk);
%     else
          	[numpts, ~]	= size(dataLock1);
          	ploty       = rowstart_pt:numpts + rowstart_pt - 1;
            
            meanTrans   = mean(dataLock1(:,1));                             
            meanLow     = mean(dataLock1(:,2));                             
            meanUp      = mean(dataLock1(:,3));                              

            if meanTrans <= meanLow || meanUp < meanLow || meanTrans >= meanUp  % MUST BE ADJUSTED for wind direction
                fprintf('%d   There is NO consistent TRANSITIONZONE.\n', kk);
            else
                set(legend,'visible','off')
                plot(dataLock1(:,3), ploty, 'r.', dataLock1(:,2), ploty, 'b.')
                
                if diffim == 1
                    bplacev = dataLock1(:,4);
                   	ix1	= (dataLock1(:,1) < bplacev < dataLock1(:,3));
                	ix2 = (bplacev > adjusting_dist);
                  	ix  = logical(ix1.*ix2);
                    
                    
                    % Plot if a bubble was found (diffim)
                    if mean(bplacev(ix1)) > meanTrans ...
                            && mean(bplacev(ix1)) < meanUp ...
                            && round(std(bplacev(ix1))/10)*10 ...
                            <= 4*ceil(std(dataLock1(:,3))/10)*10          	% 18.2520 < 17.0450

%                         plot(dataLock1(ix,4), ploty(ix), 'y.')
                        bub_vec(kk) = 1;
                    end
                    plot(dataLock1(:,1), ploty, 'g.')
                end
                
                if diffim ~= 1
                    % Plot if a bubble was found (no diffim)
                    ix=(dataLock1(:,4) ~= 0);
                    if mean(dataLock1(:, 4)) > ...
                        meanTrans && mean(dataLock1(:, 4)) > meanLow
                    
%                         plot(dataLock1(ix,4), ploty(ix), 'y.')
                        bub_vec(kk) = 1;
                    end
                
                    plot(dataLock1(:,1), ploty, 'g.')
                end
            end
% 	end
    view(180, 90);
    hold off
    
    t_frame(kk)                           = getframe(gcf);                	% get frame from figure
    writeVideo(t_vid, t_frame(kk));                                       	% save frame to video

%% Creating figure of averaged data and markers

    figure(2);
    clf
 	ylim([0 240]);
	xlim([0 640]);
    
    tix2inv	= 0:mmSize*10:ysz_I;
    tix2    = tix2inv(end:-1:1);
    xticks(tix)
    lblx2	= lblxng;
    xticklabels(lblx2)
    xlabel('x / c')
    
%     yticks(tiy)
%     yticklabels(lbly)
    ylabel('Temperature / counts')
    
    hold on
    plot(x + colstart_pt, McSmooth(x));                                 	% plot(x+colstart_pt-1, McSmooth(x));
    plot(dataLock1(end,1), McSmooth(dataLock1(end,1) - colstart_pt), 'go');	% plot(mean(dataLock1(:,1)), McSmooth(mean(dataLock1(:,1))-colstart_pt-1), 'go');
    plot(dataLock1(end,2), McSmooth(dataLock1(end,2) - colstart_pt), 'bo');	% plot(mean(dataLock1(:,2)), McSmooth(mean(dataLock1(:,2))-colstart_pt-1), 'bo');
    plot(dataLock1(end,3), McSmooth(dataLock1(end,3) - colstart_pt), 'ro');	% plot(mean(dataLock1(:,3)), McSmooth(mean(dataLock1(:,3))-colstart_pt-1), 'ro');
                                                                            % plot(mean(dataLock1(:,4)), McSmooth(mean(dataLock1(:,4))-start_pt-1), 'yo');
    view(180, 270);
    hold off
    
    d_frame(kk)                      	= getframe(gcf);
    writeVideo(d_vid, d_frame(kk));
    
    THermotrans(1+kk-startim, :)      	= mean(dataLock1(:,:));
    
    calculationTime(1+kk-startim)       = toc;                            	% determine processing time
    calculationTime(2+kk-startim:end)   = ceil(mean(calculationTime(1:1+kk-startim))*10)/10;	% adjust estimated calculationtime

end
close(t_vid);
close(d_vid);
delete(waitbarCreator);

avgcalTime               	=	mean(calculationTime);                      % average processing time

%% Calculate screentime of separation bubble

if ~isempty(bub_vec)
    bubirel	= find(bub_vec == 0, 1,'first');                                % cut out start for it is usually 1
    bubsta	= find(bub_vec(bubirel:end) == 1, 1,'first');                   % find first time bubble is detected
  	bubnum	= find(bub_vec == 1, 1, 'last');                                % find last time bubble is detected
    
    try
        bublength	= bubnum(end) - bubsta(1);                              % calculate fps depended length of bubble
        bubtime     = bublength/355;                                       	% adjust for fps
        fprintf('A separation bubble was detected for: %d s\n', bubtime);
    catch
        fprintf('NO separation BUBBLE was DETECTED.');
    end
end


fprintf('\n...done!\n\n');
fprintf('Average processing time was: %d s\n', avgcalTime);












