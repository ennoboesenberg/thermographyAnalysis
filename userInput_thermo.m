function [numoim, startim, stepsize, numorows] = userInput_thermo(file_list)

[numofiles, ~] 	= size(file_list);                                          % number of files in current directory
fprintf('   The following number of\n   measurements was found: %d\n\n', numofiles);

%% Aquiring starting image

verificator                     =   0;
while verificator == 0
    prompt                      =	'   Enter number of starting image: ';
    wateysay                    =	input(prompt,'s');

    verificator                 =   all(ismember(wateysay,...
                                        '0123456789'));                     % is user input within resonable boundaries
end

if isempty(wateysay) || str2double(wateysay) >= numofiles
    startim                  	=	1;
else
    startim                  	=	str2double(wateysay);
end

%% Aquiring processing range

verificator                     =   0;
while verificator == 0
    prompt                      =	'   Enter number of images you wish to analyse: ';
    wateysay                    =	input(prompt,'s');

    if isempty(wateysay)
        wateysay                =	'355';
    end
    
    verificator                 =   all(ismember(wateysay,...
                                        '0123456789al'));                   % is user input within resonable boundaries
  	if verificator == 1 && numofiles < str2double(wateysay) + startim - 1
        verificator             =	0;
        fprintf('\n   That is EXCEEDING the NUMBER OF FILES by: %d\n\n', str2double(wateysay) + startim - numofiles);
    end
end

if strncmpi(wateysay,'all',1) || str2double(wateysay) >= numofiles
    numoim                      =	numofiles;
else
    numoim                  	=	str2double(wateysay) + startim - 1;
    if numoim > numofiles
        numoim                  =	numofiles;
    end
end

%% Aquiring stepsize

[t, ~] = imread(file_list(1).name);                                         % read Image from directory
I = rgb2gray(t);                                                            % create grayscale image
[numorows, ~] = size(I);                                                    % analysing imagesize

verificator                     =   0;
while verificator == 0
    prompt                      =	'   Enter number of lines to average over: ';
    wateysay                    =	input(prompt,'s');

    verificator                 =   all(ismember(wateysay,...
                                        '0123456789al'));                   % is user input within resonable boundaries
end

if isempty(wateysay)
    stepsize                  	=	4;
elseif strncmpi(wateysay,'all',1) || str2double(wateysay) >= numorows
    stepsize                  	=	numorows;
else
    stepsize                  	=	str2double(wateysay);
end

end












% date_info                       =   file_list(1).date;
% date_info_format                =   datestr(file_list(1).date, 29);

% %% Aquiring averaging type
% 
% numooper = 1;
% 
% verificator                     =   0;
% while verificator == 0
%     prompt                      =   'Type of averaging (AF, STD, RMS): ';
%     wateysay                    =   input(prompt,'s');
% 
%     verificator                 =   all(ismember(wateysay,...
%                                         '0123456789+-.alnofrms'));          % is user input within resonable boundaries
% end
% 
% if isempty(wateysay) || strncmpi(wateysay,'n',1) || str2double(wateysay) == 0
%     avgtype                  	=	'non';
% elseif strncmpi(wateysay,'all',2) || str2double(wateysay) > 3
%     avgtype                  	=	'all';
%     numooper = 3;
% elseif strncmpi(wateysay,'AF',2) || str2double(wateysay) == 1
%     avgtype                  	=	'AF';
% elseif strncmpi(wateysay,'RMS',2) || str2double(wateysay) == 2
%     avgtype                  	=	'RMS';
% elseif strncmpi(wateysay,'STD',2) || str2double(wateysay) == 3
%     avgtype                  	=	'STD';
% end
% 
% %% Aquiring averaging range
% 
% verificator                     =   0;
% while verificator == 0
%     prompt                      =   'Number of images to average over: ';
%     wateysay                    =   input(prompt,'s');
%     if isempty(wateysay)
%         wateysay               	=	'4';
%     end
%     verificator                 =   all(ismember(wateysay,...
%                                         '0123456789'));                     % is user input within resonable boundaries
% 
%     if verificator == 1                                                     % checks if number of files can be divided by avraging number without remainder
%         divider                 =	mod(numoim, str2double(wateysay));
%         if  divider == 0
%             verificator         =	1;
%         else
%             verificator         =	0;
%             fprintf('\n"NUMBER OF IMAGES" must be divisible without remainder\n by number of "IMAGES TO AVERAGE OVER".\n');
%         end
%     end
% end
% 
% 
% if strncmpi(wateysay,'all',1) || str2double(wateysay) >= numofiles
%     avgrange                  	=	numofiles;
% else
%     avgrange                  	=	str2double(wateysay);
% end

% %% Find reference picture
% 
% 
% mydir       = cd;                                                           % keeping old directory to return to
% cd(refDir)
% file_list   = dir(fullfile(cd));                                            % listing files from reference directory
% numofile    = size(file_list);
% for aa = 1:numofile                                                         
%     a                           =	file_list(aa).date;
%     b{aa}                       =	a;
% end
% c                               =	char(unique(b,'sorted'));               % finding unique dates in folder
% 
% fprintf('The following measurement dates were found:\n\n');
% for aa = 1:size(c)
%     fprintf('%s \n', c(aa,:));                                              % listing measurementdates
% end
% fprintf('Recommended (and default): %s\n', date_info);
% 
% if strcmp(refDir, verify_refDir)
%     cd(refDir)
% 	fileEnding                  =	formatFile;
%     filetypeindex               =   1;
% 
%     verificator              	=   0;
%     while verificator == 0
%         prompt                	=   '\nYear of measurement (e.g. 08): ';
%         ang_yea               	=   input(prompt,'s');
%         
%         if isempty(ang_yea)
%             ang_yea           	=	date_info_format(3:4);
%         end
%         verificator            	=   all(ismember(ang_yea,...
%                                             '0123456789+- '));              % is user input within resonable boundaries
%     end
% 
%     verificator                	=	0;
%     while verificator == 0
%         prompt                	=   'Month of measurement (e.g. 08): ';
%         ang_mon               	=   input(prompt,'s');
%         
%       	if isempty(ang_mon)
%             ang_mon            	=	date_info_format(6:7);
%         end
%         verificator            	=   all(ismember(ang_mon,...
%                                     	'0123456789+- '));                  % is user input within resonable boundaries
%     end
% 
%     verificator                	=   0;
%     while verificator == 0
%         prompt                 	=   'Day of measurement (e.g. 08): ';
%         ang_day                	=   input(prompt,'s');
%         
%        	if isempty(ang_day)
%             ang_day           	=	date_info_format(9:10);
%         end
%         verificator            	=   all(ismember(ang_day,...
%                                     	'0123456789+- '));                  % is user input within resonable boundaries
%     end
%     
%     nam                       	=	['.\*' ang_yea ang_mon ang_day...
%                                         '_Time=*'];
% 
%   	findIm                     	=	dir(fullfile(cd, nam,...
%                                         ['*B*' fileEnding]));               % ['E:\Enno_DU95W180_Mono\Live images\Live Image Date=180818_Time=175121'];
%                                     
% else
%     cd(mydir)
% 	fileEnding                	=	'.vc7';
%     filetypeindex               =   0;
%     
%     findIm                     	=	dir(fullfile(cd, ['B*' num2str(numoim)...
%                                         fileEnding]));                  % ['E:\Enno_DU95W180_Mono\Live images\Live Image Date=180818_Time=175121'];
% end
% 
% cd(findIm(1).folder)
% sample_pic                      =	loadvec(findIm(1).name);            % loading samplepicture to define a mask from
% 
% cd(mydir)
% file_list                       =	dir(fullfile(cd,'*.vc7'));
% [chosen_file, ~] = size(file_list);
% lonam                           =	{['B[' num2str(chosen_file) '].vc7']};  % get filenames
% reference_pic                   =	loadvec(lonam);



