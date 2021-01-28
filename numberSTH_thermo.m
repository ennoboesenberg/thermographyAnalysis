function [addnum] = numberSTH_thermo(svDir)

A = 0;

file_list1        	= dir(fullfile(cd, '*.tif'));                           % find all tif files
num2find            = regexp(file_list1(1).name,'\d*','Match');           	% finds all numbers in foldername
name2find           = num2find{end-2};                                      % extract number of measurement
nameinquest         = ['*' name2find '*'];                                 	% make searchable string
file_list2           = dir(fullfile(svDir, nameinquest));                   % find old files
[atten, ~]          = size(file_list2);                                     % number of old files
if atten == 0
    addnum          = name2find;                                            % add new measurement
else
    for aa = 1:atten                                                        % list names of old measurements
        a           = file_list2(aa).name;
        b{aa}       = a;
    end
    c               = unique(b,'sorted');                                   % list names of unique old measurements
    c_char          = char(c);
    [c_index]       = cell2mat(strfind(c,name2find));
    
    [~, sizeofc]	= size(c);
    for bb = 1:sizeofc
        B           = sscanf(c_char(bb,c_index(bb)+length(name2find):end),...
                        strcat('_',"%d",'_',"%d",'.mp4'));                 	% scan for numbers in old file names
        if B > A                                                            % find highest number and therefore latest files
            A       = B;
        end
    end

    addnum          = [num2str(name2find) '_' num2str(A+1)];                % return what end of new file name should look like
end
end