% Get file id and open in a reading mode 'r'
% fid = fopen('D:\Kinetix_Test_07112022\test13\ss_stack_0.prd', 'r');

% directory
dataDIR = 'D:\AJ_mouse_072922\';
runName = 'AJ_mouse_072922_run6';
directoryName = [dataDIR runName '\'];
infoName = [dataDIR runName '_info.mat']'
load(infoName);

% Get all files with this extension
Files = dir(strcat(directoryName, '*.prd'));
fileList = string.empty;
for k=1:length(Files)
        fileList(k) = strcat(directoryName, Files(k).name);
end

%% Read metadata
% Size of the images, t corresponds to the number of images to open
% this only works with matlab 2020 or later :')
metadata = readlines(strcat(directoryName, 'kinetixMetadata.txt'));
width = str2num(metadata(2));
height = str2num(metadata(3));
t = str2num(metadata(5));
gap = str2num(metadata(6));

%% Load data for reshaping
% load('‪D:\ex_vivo_brain\beads_1um_run1_info.mat');
pixelsPerVol = info.daq.pixelsPerLine;
runLength = info.daq.scanLength;
stepsPerVol = info.daq.scanRate;

%% The loop reads the number of 'pixels' given by width x height and reshapes
% them into a matrix of the appropriate size. Then the separation between 
% images is read to move the pointer and the image is displayed.
data = zeros(width,height,t*length(Files));
% data = [];
for k = 1:length(Files)
    fid = fopen(fileList(k), 'r');
    
    % restart pointer when reading file
    frewind(fid);
    
    % Read the header bytes first, since it is uint16 it needs two values 
    % because each value is 1 byte, that's why divide over 2.
    header = fread(fid, 8272/2, 'uint16');
    for i = 1:t
%         i
        tmpRead = fread(fid, width*height, 'uint16');
        if isempty(tmpRead)
            fprintf('Reached end of data');
            break;
        end
        tmp = reshape(tmpRead,[width, height]);


        space = fread(fid, gap/2, 'uint16');
        data(:,:,t*(k-1)+i) = tmp(:,:);
        
        figure(10);
        imagesc(data(:,:,i));
        colormap 'gray'
        caxis([0 300])

        pause(0.001);
    end
    k
end
        numvol = round(info.daq.scanRate*info.daq.scanLength);
        SCAPE_data = reshape(data(:,:,1:numvol*info.daq.pixelsPerLine), [width, height, info.daq.pixelsPerLine, numvol]);
