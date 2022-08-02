function varargout = SCAPE_DataLoader_v1_kinetix(varargin)

% This software allows you to view information about scans taken with SCAPE
% and read in raw data for further analysis, for making summary MIP movies/images
% and for writing tiff stacks. From here, you can call the visualization software
% and/or the color merge software for dual color scans.

% Developed by the Hillman Lab at Columbia University (2018)


% Last Modified by GUIDE v2.5 20-Jul-2022 10:40:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SCAPE_DataLoader_v1_kinetix_OpeningFcn, ...
    'gui_OutputFcn',  @SCAPE_DataLoader_v1_kinetix_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% End of initialization code - DO NOT EDIT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Open and Output Functions %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SCAPE_DataLoader_v1_kinetix_OpeningFcn(hObject, ~, handles, varargin)
    % This function has no output args, see OutputFcn.

    currentFolder = pwd;
    addpath(currentFolder);

    handles.initialfolder = 'C:\';
    set(handles.foldername, 'String', handles.initialfolder);

    % Choose default command line output for SCAPE_DataLoader_v1_kinetix
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

function varargout = SCAPE_DataLoader_v1_kinetix_OutputFcn(~, ~, handles)
    varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Callback Functions %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
function browse_Callback(hObject, eventdata, handles) %#ok<DEFNU>
    startDirectory = handles.initialfolder;
    directory = [uigetdir(startDirectory,'Select Experiment directory') '/'];
    directory = directory(1:end-1);
    set(handles.foldername,'String',directory);
    handles.directory = directory;
    handles.tiffdirectory = [handles.directory,filesep,'tiff_stacks',filesep];
    
    cd(directory);
    [handles] = refreshDirectory(hObject,handles);
    
    set(handles.listbox1,'Value',1);
    set(handles.listbox1,'String',handles.runNames);
    listbox1_Callback(hObject, eventdata, handles);

function SCAPE_data = GenerateSCAPEData_Kinetix(handles)
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
    parfor k = 1:length(Files)
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
        end
        k
    end
        numvol = round(info.daq.scanRate*info.daq.scanLength);
        SCAPE_data = reshape(data(:,:,1:numvol*info.daq.pixelsPerLine), [width, height, info.daq.pixelsPerLine, numvol]);

function [yzfig,xyfig] = preview_Callback(~, ~, handles)
    SCAPE_data = GenerateSCAPEData_Kinetix(handles)

    yzfig = figure('units','normalized','outerposition',[.1 .1 .8 .8]);
    imagesc((squeeze(max(SCAPE_data(2:end-1,2:end-1,:),[],3))'));
%     axis image;
    colormap gray;colorbar;
    xlabel('Y (pixels)');ylabel('Z (pixels)');title('Y-Z MIP');
    xyfig = figure('units','normalized','outerposition',[.1 .1 .8 .8]);
    imagesc(squeeze(max(SCAPE_data(2:end-1,2:end-1,:),[],2))');
%     axis image;
    colormap gray;colorbar;
    xlabel('Y (pixels)');ylabel('X (pixels)');title('X-Y MIP');
    figure(xyfig);

function tiffstack_Callback(hObject, eventdata, handles) %#ok<DEFNU>
    [SELECTION,~] = listdlg('ListString',handles.runNames,'ListSize',[400 300],'InitialValue',get(handles.listbox1,'Value'));

    for i = 1:length(SELECTION)
        set(handles.listbox1,'Value',SELECTION(i));
        [volumesToLoad,BG_data,Ycrop,Xcrop] = LoadParameters(hObject, eventdata, handles);
        handles = guidata(hObject);
        numVolumeToLoad = length(volumesToLoad);
        framesPerScan = handles.info.info.daq.pixelsPerLine;
       
        %% Initialize Directory
        timestamp = datestr(now,'yy-mm-dd HHMMss');
        tiffstamp = [];
        tiff_info.orient_lat = get(handles.orient_lat,'Value');
        tiff_info.splitcols = get(handles.splitcols,'Value');
        tiff_info.skewbox = get(handles.skewbox,'Value');
        tiff_info.delta = str2double(get(handles.SkewAng,'String')); 
        if tiff_info.orient_lat
            tiffstamp = strcat(tiffstamp,'_flip');
        end
        if tiff_info.splitcols
            tiffstamp = strcat(tiffstamp,'_duo');
        end
        if tiff_info.skewbox
            delta = get(handles.SkewAng,'String'); 
            tiffstamp = strcat(tiffstamp,'_skewed',delta);
        end
        tiffstamp = strcat(tiffstamp,'_dsf',get(handles.dsf,'String'),'_',strrep(get(handles.secs,'String'),':','to'),'secs');

        filePath = [handles.tiffdirectory,handles.scanName,filesep,timestamp,tiffstamp,filesep];
        mkdir(filePath(1:end-1));
        transforms = [];
        if tiff_info.splitcols
            FilePath2 = fullfile(get(handles.foldername,'String'), 'RGBtransform.mat');
            if (2 == exist(FilePath2, 'file'))
                load(FilePath2,'transforms')
            else
                errordlg('RGBtransform.mat not found, please run Color Merge');
                return
            end
        end
        
        if get(handles.makeMIPMovie_checkbox, 'Value')
            MIPfolderPath = [handles.tiffdirectory,handles.scanName,filesep];
            MIP_top = squeeze(zeros(framesPerScan,Ycrop(2)-Ycrop(1)+1,numVolumeToLoad,'uint16'));%Used in writeMIPs
            MIP_SideY = squeeze(zeros(Xcrop(2)-Xcrop(1)+1,Ycrop(2)-Ycrop(1)+1,numVolumeToLoad,'uint16'));%Used in writeMIPs
            MIP_SideX = squeeze(zeros(Xcrop(2)-Xcrop(1)+1,framesPerScan,numVolumeToLoad,'uint16'));%Used in writeMIPs
        end

        %% Load Single Volume and Write Tiff
        tic
        % Load data 
        if ~handles.scanID               % Zyla
            %% Read Volume Spool number, start and end (Zyla) 
            VolIDFilePath = fullfile(handles.directory, [handles.scanName '_ZylaVolID.mat']);
            Zylaarray = load(VolIDFilePath,'startframe_array','startspool_array','endframe_array','endspool_array');
            startframe_array = Zylaarray.startframe_array;
            startspool_array = Zylaarray.startspool_array;
            endframe_array = Zylaarray.endframe_array;
            endspool_array = Zylaarray.endspool_array; % Necessary for parfor processing, telling Matlab these are variables
            %% Load Data
            if numVolumeToLoad == 1
                SCAPE_data = LoadSingleVol_Zyla(startframe_array(volumesToLoad),startspool_array(volumesToLoad),endframe_array(volumesToLoad),...
                    endspool_array(volumesToLoad),handles,BG_data);
                writeSINGLEtiff(filePath,SCAPE_data, tiff_info, handles, handles.scanName, transforms);
                if get(handles.makeMIPMovie_checkbox, 'Value')
                    MIP_top = squeeze(max(SCAPE_data,[],2))';
                    MIP_SideY = squeeze(max(SCAPE_data,[],3))';
                    MIP_SideX = squeeze(max(SCAPE_data,[],1));
                end
            else
                parfor_progress(numVolumeToLoad);
                parfor VolumeCounter = 1:numVolumeToLoad
                    currentVol = volumesToLoad(VolumeCounter)
                    SCAPE_data = LoadSingleVol_Zyla(startframe_array(currentVol),startspool_array(currentVol),endframe_array(currentVol),...
                        endspool_array(currentVol),handles,BG_data);
                    scanName_id = strcat(handles.scanName,sprintf('_t%012d', VolumeCounter));
                    writeSINGLEtiff(filePath, SCAPE_data, tiff_info, handles, scanName_id, transforms);
                    if get(handles.makeMIPMovie_checkbox, 'Value')
                        MIP_top(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],2))';
                        MIP_SideY(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],3))';
                        MIP_SideX(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],1));
                    end
                    parfor_progress;
                end
                parfor_progress(0);
            end

        else % HICAM
            if numVolumeToLoad == 1
                SCAPE_data = LoadSingleVol_HICAM(handles,volumesToLoad,BG_data);
                writeSINGLEtiff(filePath,SCAPE_data, tiff_info, handles, handles.scanName, transforms);
                if get(handles.makeMIPMovie_checkbox, 'Value')
                    MIP_top = squeeze(max(SCAPE_data,[],2))';
                    MIP_SideY = squeeze(max(SCAPE_data,[],3))';
                    MIP_SideX = squeeze(max(SCAPE_data,[],1));
                end
            else
                parfor_progress(numVolumeToLoad);
                parfor VolumeCounter = 1:numVolumeToLoad                
                    SCAPE_data = LoadSingleVol_HICAM(handles,volumesToLoad(VolumeCounter),BG_data);
                    scanName_id = strcat(handles.scanName,sprintf('_t%012d', VolumeCounter));
                    writeSINGLEtiff(filePath, SCAPE_data, tiff_info, handles, scanName_id, transforms);
                    if get(handles.makeMIPMovie_checkbox, 'Value')
                        MIP_top(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],2))';
                        MIP_SideY(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],3))';
                        MIP_SideX(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],1));
                    end
                    parfor_progress;
                end
                parfor_progress(0);
            end
        end
        toc
        disp('Finished Saving Scan');
        
        if get(handles.makeMIPMovie_checkbox, 'Value')
            writeMIPs(numVolumeToLoad,handles,MIPfolderPath,framesPerScan,Ycrop,Xcrop); 
        end
    end

function makeavi_Callback(hObject, eventdata, handles) %#ok<DEFNU>
    
    [SELECTION,~] = listdlg('ListString',handles.runNames,'ListSize',[400 300],'InitialValue',get(handles.listbox1,'Value'));
    for i = 1:length(SELECTION)
        set(handles.listbox1,'Value',SELECTION(i));
        [volumesToLoad,BG_data,Ycrop,Xcrop] = LoadParameters(hObject, eventdata, handles);
        handles = guidata(hObject);
        numVolumeToLoad = length(volumesToLoad);
        framesPerScan = handles.info.info.daq.pixelsPerLine;
        
        folderPath = [handles.tiffdirectory,handles.scanName,filesep];
        if(isfolder(folderPath ) == 0)
            mkdir(folderPath);
        end
        
        MIP_top = squeeze(zeros(framesPerScan,Ycrop(2)-Ycrop(1)+1,numVolumeToLoad,'uint16'));
        MIP_SideY = squeeze(zeros(Xcrop(2)-Xcrop(1)+1,Ycrop(2)-Ycrop(1)+1,numVolumeToLoad,'uint16'));
        MIP_SideX = squeeze(zeros(Xcrop(2)-Xcrop(1)+1,framesPerScan,numVolumeToLoad,'uint16'));
        
        %% Load Single Volume and calculate MIPs
        disp('Starting MIP loading');
        tic
        % Load data 
        if ~handles.scanID               % Zyla
            %% Read Volume Spool number, start and end (Zyla) 
            VolIDFilePath = fullfile(handles.directory, [handles.scanName '_ZylaVolID.mat']);
            Zylaarray = load(VolIDFilePath,'startframe_array','startspool_array','endframe_array','endspool_array');
            startframe_array = Zylaarray.startframe_array;
            startspool_array = Zylaarray.startspool_array;
            endframe_array = Zylaarray.endframe_array;
            endspool_array = Zylaarray.endspool_array; % Necessary for parfor processing, telling Matlab these are variables
            %% Load Data
            if numVolumeToLoad == 1
                SCAPE_data = LoadSingleVol_Zyla(startframe_array(volumesToLoad),startspool_array(volumesToLoad),endframe_array(volumesToLoad),...
                    endspool_array(volumesToLoad),handles,BG_data);
                MIP_top = squeeze(max(SCAPE_data,[],2))';
                MIP_SideY = squeeze(max(SCAPE_data,[],3))';
                MIP_SideX = squeeze(max(SCAPE_data,[],1));
            else
                parfor_progress(numVolumeToLoad);
                parfor VolumeCounter = 1:numVolumeToLoad
                    currentVol = volumesToLoad(VolumeCounter)
                    SCAPE_data = LoadSingleVol_Zyla(startframe_array(currentVol),startspool_array(currentVol),endframe_array(currentVol),...
                        endspool_array(currentVol),handles,BG_data);
                    MIP_top(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],2))';
                    MIP_SideY(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],3))';
                    MIP_SideX(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],1));
                    parfor_progress;
                end
                parfor_progress(0);
            end

        else % HICAM
            if numVolumeToLoad == 1
                SCAPE_data = LoadSingleVol_HICAM(handles,volumesToLoad,BG_data);
                MIP_top = squeeze(max(SCAPE_data,[],2))';
                MIP_SideY = squeeze(max(SCAPE_data,[],3))';
                MIP_SideX = squeeze(max(SCAPE_data,[],1));
            else
                parfor_progress(numVolumeToLoad);
                parfor VolumeCounter = 1:numVolumeToLoad                
                    SCAPE_data = LoadSingleVol_HICAM(handles,volumesToLoad(VolumeCounter),BG_data);
                    MIP_top(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],2))';
                    MIP_SideY(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],3))';
                    MIP_SideX(:,:,VolumeCounter) = squeeze(max(SCAPE_data,[],1));
                    parfor_progress;
                end
                parfor_progress(0);
            end
        end
        toc
        disp('Finished MIP loading');
        
        writeMIPs(numVolumeToLoad,handles,folderPath,framesPerScan,Ycrop,Xcrop);         
    end

function PreviewSkew_Callback(~, ~, handles) %#ok<DEFNU>
    if ~handles.scanID
        VolIDFilePath = fullfile(handles.directory, [handles.scanName '_ZylaVolID.mat']);
        load(VolIDFilePath,'Vol_array','startframe_array','startspool_array','endframe_array','endspool_array');
        [SCAPE_data] = LoadSingleVol_Zyla(startframe_array(1),startspool_array(1),endframe_array(1),endspool_array(1),handles);
    else
        SCAPE_data = LoadSingleVol_HICAM(handles);
    end

    conversionFactors = [handles.info.info.cal.ylat; handles.info.info.cal.zdep; handles.info.info.cal.xwid];
    SCAPE_data = permute(SCAPE_data, [3 1 2]);

    R = imref3d(size(SCAPE_data), conversionFactors(1), conversionFactors(3), conversionFactors(2));

    figure(99); subplot(2,2,1)
    imagesc([0:size(SCAPE_data, 1)-1]*conversionFactors(2),[0:size(SCAPE_data, 3)-1]*conversionFactors(2), log(double(squeeze(max(SCAPE_data(:,round(end/3):round(end/2), :), [], 2))))')
    colormap gray; axis image; title('Raw')
    subplot(2,2,2)
    imagesc([0:size(SCAPE_data, 2)-1]*conversionFactors(1),[0:size(SCAPE_data, 1)-1]*conversionFactors(3), log(double(squeeze(max(SCAPE_data(:,:,round(end/3):round(2*end/3)), [], 3)))))
    colormap gray; axis image;

    delta = str2num(get(handles.SkewAng,'String'));

    affineMatrix = [1 0 0 0;
        0 1 0 0;
        0 cotd(delta) 1 0;
        0 0 0 1];
    tform = affine3d(affineMatrix);
    [SCAPE_data, ~] = imwarp(SCAPE_data, R, tform);

    figure(99); subplot(2,2,3)
    imagesc([0:size(SCAPE_data, 1)-1]*conversionFactors(3),[0:size(SCAPE_data, 3)-1]*conversionFactors(2), log(double(squeeze(max(SCAPE_data(:,round(end/3):round(end/2), :), [], 2))))')
    colormap gray; axis image; title('Skew Corrected')
    subplot(2,2,4)
    imagesc([0:size(SCAPE_data, 2)-1]*conversionFactors(1),[0:size(SCAPE_data, 1)-1]*conversionFactors(3), log(double(squeeze(max(SCAPE_data(:,:,round(end/3):round(2*end/3)), [], 3)))))
    colormap gray; axis image;

    disp('Skew correction applied')

function quickviewer_Callback(hObject, eventdata, handles) %#ok<DEFNU>
    loaddata_Callback(hObject, eventdata, handles);
    handles.info.info.storage_dir = get(handles.foldername,'String');
    
    if get(handles.dualcolorQV, 'Value')
        FilePath2 = fullfile(handles.info.info.storage_dir, 'RGBtransform.mat');

        if (2 == exist(FilePath2, 'file'))
            SCAPE_QuickView_v1(1)
        else
            msgbox('Please run SCAPE_ColorMerge_v1 (RGB Merge) first to define color transform (or copy from prior day). Loading data to workspace... ')
        end

    else
        SCAPE_QuickView_v1_kinetix(0)
    end

function RGBmerge_Callback(~, ~, handles) %#ok<DEFNU>
    SCAPE_ColorMerge_v1(handles)

function listbox1_Callback(hObject, ~, handles)
    set(handles.listbox1,'Enable','off'); %Disable listbox temporarily 
    [handles] = refreshDirectory(hObject, handles);
    listbox_currentvalue = get(handles.listbox1,'Value');
    scanName = handles.runNames{listbox_currentvalue};
%     scanID = handles.runNames_ID{listbox_currentvalue}; % 0 for Zyla, 1 for HICAM
    handles.scanName = scanName;
%     handles.scanID = scanID;
    directory = handles.directory;
    
    %% Load info file
    infoFilePath = fullfile(directory, [scanName '_info.mat']);
    if exist(infoFilePath, 'file')
        handles.info = load(infoFilePath);
    else
        error('No info file found for this run');
    end
    handles.info.info.daq.scanRate = handles.info.info.camera.framerate/handles.info.info.daq.pixelsPerLine;
    
    %% Pixel Calibration 
    try
        handles.info.info.cal.ylat = handles.info.info.GUIcalFactors.y_umPerPix;
        handles.info.info.cal.zdep = handles.info.info.GUIcalFactors.z_umPerPix;
        handles.info.info.cal.xwid = handles.info.info.GUIcalFactors.x_umPerPix;
    catch
        disp('! calibration factors not found, using 1.4 y um/pix, 1.15 z um/pix, and 315 x um/volt');
        handles.info.info.cal.ylat = 1.4;
        handles.info.info.cal.zdep = 1.13;
        handles.info.info.cal.xfact = 315;
        handles.info.info.cal.xwid = handles.info.info.cal.xfact*handles.info.info.daq.scanAngle/handles.info.info.daq.pixelsPerLine;
    end
  
    %% Access Camera Settings and Display Experiment Info
        %% Access kinetix metadata file (.ini)
        kinetixInfoFilePath = strcat(directory, scanName, '/kinetixMetadata.txt');
        if (2 == exist(kinetixInfoFilePath,'file'))
            S = readlines(kinetixInfoFilePath);
            handles.info.info.camera.yROI = s(3);
            handles.info.info.camera.xROI = s(2);
            kinetix.ImageSize = s(3)*s(2)*2; % size of image in stack = # of pixels * 2
            kinetix.numFramesPerSpool = s(5);

            %% Set Spool files parameters (Kinetix)
            handles.info.kinetix = kinetix;
            numSpoolfilesPerVolume1 = handles.info.info.daq.pixelsPerLine/zyla.numFramesPerSpool;
            numActual_spoolfiles = length(dir([directory,'/',scanName,'/*.dat']));
            numSpoolfilesPerVolume = ceil(numSpoolfilesPerVolume1);
            numspools = numSpoolfilesPerVolume*handles.info.info.daq.scanRate*handles.info.info.daq.scanLength;

        else
            disp('No metadata file found for this run');
        end
        
        %% Display Experiment Info
        infotext{1} = sprintf('Scan Rate: %.2f VPS',handles.info.info.daq.scanRate);
        infotext{2} = sprintf('Scan Duration: %.2f secs',handles.info.info.daq.scanLength);
        infotext{3} = sprintf('X-steps: %d, X-range: %.4f V',handles.info.info.daq.pixelsPerLine,handles.info.info.daq.scanAngle);
        infotext{4} = sprintf('Camera Frame Rate: %.2f Hz',handles.info.info.camera.framerate);
        infotext{5} = sprintf('Camera height: %d, Width: %d, Left: %d',handles.info.info.camera.yROI,handles.info.info.camera.xROI,handles.info.info.camera.x_left);
        infotext{7} = sprintf('Calibration factors: y: %.2f  x: %.2f z: %.2f um/pix',handles.info.info.cal.ylat, handles.info.info.cal.xwid,handles.info.info.cal.zdep);
        infotext{8} = sprintf('Field of view: y: %.2f  x: %.1f z: %.1f um',handles.info.info.cal.ylat*handles.info.info.camera.xROI, handles.info.info.cal.xwid*handles.info.info.daq.pixelsPerLine,handles.info.info.camera.yROI*handles.info.info.cal.zdep);
        infotext{6} = sprintf('Scan date and time: %s',handles.info.info.scanStartTimeApprox);
        infotext{9} = sprintf('Est whole dataset file: %.1f Mb',handles.info.info.camera.xROI*handles.info.info.camera.yROI*str2double(handles.info.info.camera.kineticSeriesLength)/1000000);
%         infotext{10} = sprintf('(camfile) Est whole dataset file: %.1f Mb',handles.info.kinetix.ImageSize*str2double(handles.info.info.camera.kineticSeriesLength)/1000000);
%         if numspools>numActual_spoolfiles
%             infotext{10} = sprintf('POSSIBLE FAILED RUN (%g files out of %g)',numActual_spoolfiles, ceil(numspools));
%             handles.pf = 'pf';
%             handles.info.info.daq.scanLength = floor(numActual_spoolfiles/(numSpoolfilesPerVolume*handles.info.info.daq.scanRate));
%         else
%             handles.pf = '';
%         end
%         if isfield(handles.info.info,'blue_laser_output_power_actual')
%             infotext{11} = sprintf('Blue laser power (after FW): %.2f mW', handles.info.info.blue_laser_output_power_actual);
%         else
%             infotext{11} = sprintf('Blue laser power: %.2f mW', handles.info.info.blue_laser_output_power);
%         end
%         if isfield(handles.info.info,'yellow_laser_output_power')
%             infotext{12} = sprintf('Yellow laser power: %.2f mW',handles.info.info.yellow_laser_output_power);
%         end
%         infotext{13} = sprintf('Experiment Notes: %s',mat2str(handles.info.info.experiment_notes(1,:)));
%         for kk = 2:size(handles.info.info.experiment_notes,1)
%             infotext{kk+11} = sprintf('%s',mat2str(handles.info.info.experiment_notes(kk,:)));
%         end
        
        %% Write Volume Log
%         VolIDFilePath = fullfile(directory, [scanName '_ZylaVolID.mat']);
%         if ~exist(VolIDFilePath, 'file')
%             Vol_array = 1:floor(handles.info.info.daq.scanLength*handles.info.info.daq.scanRate);
%             if isempty(Vol_array)
%                 Vol_array = 1;
%             end
%             startframe_array = rem((Vol_array-1) * handles.info.info.daq.pixelsPerLine+1,zyla.numFramesPerSpool);
%             startspool_array = floor(((Vol_array-1) * handles.info.info.daq.pixelsPerLine+1)/zyla.numFramesPerSpool);
%             endframe_array = rem(Vol_array * handles.info.info.daq.pixelsPerLine,zyla.numFramesPerSpool);
%             endspool_array = floor(Vol_array * handles.info.info.daq.pixelsPerLine/zyla.numFramesPerSpool);
%             save(VolIDFilePath,'startframe_array','startspool_array','endframe_array','endspool_array');
%         end
    %% Existing TIFF
    m=1;
    existing{1} = 'no TIFF stacks found';
    if isdir([directory,'/tiff_stacks'])
        tiffs = dir([directory,'/tiff_stacks']);
        for i = 1:length(tiffs)
            if strfind(tiffs(i).name,scanName)
                numtiffs = dir([directory,'/tiff_stacks/',tiffs(i).name,'/*.tiff']);
                existing{m} = sprintf('%s  (%d files)',tiffs(i).name, length(numtiffs));
                m=m+1;
            end
        end
    end
    set(handles.existing_tiff,'String',existing);

    %% Existing AVI & JPG
    m=1;
    set(handles.existing_avi,'Value',1);
    existing_avi{1} = 'none';
    avis = dir([directory,'/*.avi']);
    pics = dir([directory,'/*.jpg']);
    for i = 1:length(avis)
        if strfind(avis(i).name,scanName)
            existing_avi{m} = sprintf('%s',avis(i).name);
            m=m+1;
        end
    end
    for i = 1:length(pics)
        if strfind(pics(i).name,scanName)
            existing_avi{m} = sprintf('%s',pics(i).name);
            m=m+1;
        end
    end
    set(handles.existing_avi,'String',existing_avi);
    set(handles.text2,'String',infotext);
    
    set(handles.listbox1,'Enable','on'); %Disable listbox temporarily 
    guidata(hObject,handles);
    
function loaddata_Callback(hObject, eventdata, handles)
    %% Read User Input and load parameters
    [volumesToLoad,BG_data,Ycrop,Xcrop] = LoadParameters(hObject, eventdata, handles);
    numVolumeToLoad = length(volumesToLoad);
    framesPerScan = handles.info.info.daq.pixelsPerLine;
    
    %% Load data 
    tic
    clear SCAPE_data
    SCAPE_data = GenerateSCAPEData_Kinetix(handles);
    
    %% Assign variables to Base Workspace
    assignin('base','SCAPE_data',SCAPE_data);
    handles.info.info.listbox = get(handles.text2,'String');
    handles.info.info.storage_dir = get(handles.foldername,'String');
    assignin('base','info',handles.info.info);
%     if ~handles.scanID
%         assignin('base','zyla',handles.info.zyla);
%     end
    h = waitbar(1,'SCAPE data written to workspace');
    pause(1);
    close(h);

    guidata(hObject,handles);
    
function HICAMFramestart_Callback(hObject, eventdata, handles) %#ok<DEFNU>
    try
        FrameIDFilePath = fullfile(handles.directory, [handles.scanName '_frameID.mat']);
        startframe = str2double(get(handles.HICAMFramestart,'String')); 
        save(FrameIDFilePath,'startframe','-append');
    catch
        disp('Error while initializing. First frame not saved...');
    end

function crop_Callback(hObject, eventdata, handles) %#ok<DEFNU>
    [yzfig,xyfig] = preview_Callback(hObject, eventdata, handles);
    figure(yzfig);
    title('Crop in Z+Y: click upper-left and bottom right of ROI')
    [YY, xx] = ginput(2);
    Ycrop(1) = ceil(min(YY));
    Ycrop(2) = floor(max(YY));
    Xcrop(1) = ceil(min(xx));
    Xcrop(2) = floor(max(xx));
    pause(.1)
    close(yzfig);close(xyfig);
    handles.Ycrop = Ycrop;
    handles.Xcrop = Xcrop;
    guidata(hObject,handles);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Frequently Used Commands %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeSINGLEtiff(filePath,SCAPE_data, tiff_info, handles, scanName, transforms)

    conversionFactors = [handles.info.info.cal.ylat; handles.info.info.cal.zdep; handles.info.info.cal.xwid];
    if ~tiff_info.splitcols
        imgToSave = [filePath, scanName,'.tiff'];
        [SCAPE_data] = imgprocess(SCAPE_data,tiff_info.skewbox,tiff_info.delta,tiff_info.orient_lat,conversionFactors);
        for j = 1:size(SCAPE_data, 3) % Write TIFF
            imwrite(uint16(SCAPE_data(:, 2:end-1, j)), imgToSave, 'tif', 'Compression', 'none', 'WriteMode', 'Append');
        end
    else
        xg = transforms.xg;
        xr = transforms.xr;
        yr = transforms.yr;
        yg = transforms.yg;
        zr = transforms.zr;
        zg = transforms.zg;
        scaleR = transforms.scaleR;   % The code is RED/GREEN shifted!!
%         %% Temp Code for worm analysis June 2019
%         z_center = round(size(SCAPE_data,2)/2);
%         SCAPE_data = SCAPE_data(:,z_center-47:z_center+48,:);
        %%
        left = floor(min([xg xr]))-1;
        right = floor(size(SCAPE_data,1)-xr);
        top = floor(min([zr zg]))-1;
        bot = floor(size(SCAPE_data,2)-max([zr zg]));
        topy = floor(min([yr yg]))-1;
        boty = floor(size(SCAPE_data,3)-max([yr yg]));
        imgToSaveR = [filePath,'R_' scanName, '.tiff'];
        imgToSaveG = [filePath,'G_' scanName, '.tiff'];
        red = (SCAPE_data(round(xg+[-left:right]),round(zg+[-top:bot]),round(yg+[-topy:boty])));
        green = (SCAPE_data(round(xr+[-left:right]),round(zr+[-top:bot]),round(yr+[-topy:boty])));
        %% scale correction for 1st gen imagesplitter
        if scaleR~=1
            red = imresize(red,scaleR*[size(red,1) size(red,2)]);
            if scaleR <1
                dif1 = size(green,1) - size(red,1);
                dif2 =  size(green,2) - size(red,2);
                x1 = floor(dif1/2) ;
                x2 = ceil(dif1/2);
                y1 = floor(dif2/2);
                y2 = ceil(dif2/2);
                red = padarray(red,[x1 y1],0,'pre');
                red = padarray(red,[x2 y2],0,'post');
            else
                dif1 = size(red,1) - size(green,1);
                dif2 =  size(red,2) - size(green,2);
                x1 = floor(dif1/2)+1; x2 = ceil(dif1/2);
                y1 = floor(dif2/2)+1; y2 = ceil(dif2/2);
                red = red(x1:end-x2,y1:end-y2,:);
            end
        end
        
%         %% Temp Code for worm analysis June 2019
% %         red = medfilt3(red,[17 5 5],'replicate');
%         green = medfilt3(green,[17 5 5],'replicate');

        %%
        red = imgprocess(red,tiff_info.skewbox,tiff_info.delta,tiff_info.orient_lat,conversionFactors);
        green = imgprocess(green,tiff_info.skewbox,tiff_info.delta,tiff_info.orient_lat,conversionFactors);

        for j = 1:size(red, 3) % Write TIFF
            imwrite(uint16(green(:, 2:end-1, j)), imgToSaveG, 'tif', 'Compression', 'none', 'WriteMode', 'Append');
            imwrite(uint16(red(:, 2:end-1, j)), imgToSaveR, 'tif', 'Compression', 'none', 'WriteMode', 'Append');
        end
    end
    
function [img] = imgprocess(img,skew_flag,skewAng,orientLAT_flag,conversionFactors)
    if skew_flag
        %Correct for skew
        affineMatrix = [1 0 0 0; 0 1 0 0; 0 cotd(skewAng) 1 0; 0 0 0 1];
        tform = affine3d(affineMatrix);                
        img = flip(flip(img(:,:,:),2),3);
        img = permute(img, [3 1 2]);
        R = imref3d(size(img), conversionFactors(1), conversionFactors(3), conversionFactors(2));
        [img, ~] = imwarp(img, R, tform);
    elseif orientLAT_flag
        % Coordinate System Correction
        img = flip(flip(img(:,:,:),2),3);
        img = permute(img, [3 1 2]);
    end

function [data] = LoadSingleSpool(loadfile,scanPath,numRows,numColumns,numFramesPerSpool,Ycrop,Xcrop)
    filePath = fullfile(scanPath, loadfile);
    FID = fopen(filePath, 'r');
    rawData = fread(FID, 'uint16=>uint16');
    fclose(FID);
    % Find better way to avoid reshape
    rawData = reshape(rawData(1:(numRows*numColumns*numFramesPerSpool)), [numRows,numColumns,numFramesPerSpool]);
    data = rawData(Ycrop(1):Ycrop(2),Xcrop(1):Xcrop(2),:);

function [temp_16bitdata] = conversion_12to16(lateral,depths,frames,temp_8bitdata)
    temp_16bitdata = zeros(lateral*depths*frames,1,'uint16');
    % Add 3 zeros in the end for 12 bit to uint16 conversion, the data is caped at 2^15 = 32768
    temp_16bitdata(1:2:end) = temp_8bitdata(1:3:end)*8 + mod(temp_8bitdata(2:3:end),16)*2048;
    temp_16bitdata(2:2:end) = idivide(temp_8bitdata(2:3:end),16)*8 + temp_8bitdata(3:3:end)*128;
  
function [handles] = refreshDirectory(hObject,handles)
    filesInDataDirectory = dir('*info.mat');
    [~,idx] = sort({filesInDataDirectory.date});
    filesInDataDirectory = filesInDataDirectory(idx);
    
    nameCounter=0;
    for i = 1:length(filesInDataDirectory)
        temp_name = filesInDataDirectory(i).name;
        temp_name = temp_name(1:end-9);
        % Is it Zyla?
        if 7 == exist(temp_name,'dir')
            nameCounter=nameCounter+1;
            runNames{nameCounter} = temp_name;
            runNames_ID{nameCounter} = 0;
        elseif 2 == exist(strcat(temp_name,'.fli'))
        % Is it HICAM?
            nameCounter=nameCounter+1;
            runNames{nameCounter} = temp_name;
            runNames_ID{nameCounter} = 1;
        % It's Superman!
        end
    end

    handles.runNames = runNames;
    handles.runNames_ID = runNames_ID;
    set(handles.listbox1,'String',handles.runNames);
    guidata(hObject,handles);
    
function [volumesToLoad,BG_data,Ycrop,Xcrop] = LoadParameters(hObject, eventdata, handles)
    % Read User Input
    listbox1_Callback(hObject, eventdata, handles);
    handles = guidata(hObject);
    dsf = str2double(get(handles.dsf,'String'));
    numSecondsToLoad = get(handles.secs,'String');
    if strcmp(numSecondsToLoad,'all')
        numSecondsToLoad = handles.info.info.daq.scanLength;
    else
        numSecondsToLoad = eval(numSecondsToLoad);
    end
    
    %% Initialize Parameters
    scanRate = handles.info.info.daq.scanRate;               % Volumetric Scan Rate (VPS)     
    numDepths = handles.info.info.camera.yROI;
    numLatPix = handles.info.info.camera.xROI;
    directory = handles.directory;
    scanName = handles.scanName;
    scanPath = fullfile(directory,scanName);
   
    if (length(numSecondsToLoad) == 1)
        volumesToLoad = 1:dsf:round(numSecondsToLoad*scanRate);
    else
        volumesToLoad = 1+(round(numSecondsToLoad(1)*scanRate):dsf:round(numSecondsToLoad(end)*scanRate));
    end
    numVolumeToLoad = length(volumesToLoad);
    handles.numVolumeToLoad = numVolumeToLoad;
    if isempty(volumesToLoad)
        fprintf('NOTHING TO LOAD: %s\n',handles.info.info.scanName);
        return;
    end
    
    numColumns = numDepths;
    numRows = numLatPix;

    %% Crop Images
    if get(handles.loadcrop,'Value') == 1
        Ycrop = handles.Ycrop;
        Xcrop = handles.Xcrop;
    else
        Ycrop = [1 numRows];
        Xcrop = [1 numColumns];
    end

    %% Grab background 
%     if get(handles.subbg,'Value')
%         if ~handles.scanID               % Zyla
%             p=0;
%             bgtoload = floor(100/numFramesPerSpool);
%             BG_data = zeros(Ycrop(2)-Ycrop(1)+1, Xcrop(2)-Xcrop(1)+1, bgtoload*numFramesPerSpool, 'uint16');
%             if numActual_spoolfiles>bgtoload
%                 for spoolFileCounter = numActual_spoolfiles+(-bgtoload+1:0)-1 % BG frames at the end
%                     spoolToLoad = strcat(flip(sprintf('%010d',spoolFileCounter)),'spool.dat');
%                     BG_data(:,:,p+(1:numFramesPerSpool)) = LoadSingleSpool(spoolToLoad,...
%                         scanPath,numRows,numColumns,numFramesPerSpool,Ycrop,Xcrop);
%                     p=numFramesPerSpool+p;
%                 end
%             else
%                 error('no background frames found')
%             end
%         else %HICAM
%             background_count = 400;
%             HICAMFilePath = fullfile(handles.directory, [handles.scanName,'.fli']);
%             fileID = fopen(HICAMFilePath,'r');
%             pixelInFrame_bit8 = (numRows*numColumns)/2*3;
%             ByteToSkip = background_count*pixelInFrame_bit8;
%             fseek(fileID,-ByteToSkip,'eof');  % Find the last 2000 frames
%             [temp_8bitdata,datacount] = fread(fileID,pixelInFrame_bit8*background_count,'uint8=>uint16');
%             if datacount == pixelInFrame_bit8*background_count    %Successful read of full volume?
%                 temp_16bitdata = conversion_12to16(numRows,numColumns,background_count,temp_8bitdata);
%                 BG_data = reshape(temp_16bitdata,numRows,numColumns,background_count);
%                 BG_data = BG_data(Ycrop(1):Ycrop(2), Xcrop(1):Xcrop(2), :);
%             else
%                 error('Data ends while reading'); % Fix this bug
%             end 
%             fclose(fileID);
%         end
%     else
        BG_data = zeros(Ycrop(2)-Ycrop(1)+1, Xcrop(2)-Xcrop(1)+1,1, 'uint16');       
%     end
    assignin('base','BG_data',BG_data);
    BG_data = mean(BG_data,3); %double

function writeMIPs(numVolumeToLoad,handles,folderPath,framesPerScan,Ycrop,Xcrop)
    dsf = str2double(get(handles.dsf,'String'));
    MIP_top = evalin('caller','MIP_top');
    MIP_SideY = evalin('caller','MIP_SideY');
    MIP_SideX = evalin('caller','MIP_SideX');
    %% Write MIP movie and Tiffs
    h = waitbar(1,'Writing movie');
    if numVolumeToLoad == 1  % Single time point
        imgToSave_topMIP = fullfile(folderPath, [handles.scanName '_topMIP_quickMIP.tiff']);
        imgToSave_sideYMIP = fullfile(folderPath, [handles.scanName '_sideYMIP_quickMIP.tiff']);
        imgToSave_sideXMIP = fullfile(folderPath, [handles.scanName '_sideXMIP_quickMIP.tiff']);

        imwrite(MIP_top, imgToSave_topMIP, 'tif', 'Compression', 'none');
        imwrite(MIP_SideY, imgToSave_sideYMIP, 'tif', 'Compression', 'none');
        imwrite(MIP_SideX, imgToSave_sideXMIP, 'tif', 'Compression', 'none');
    else            
        filename =  fullfile(folderPath, [handles.scanName '__dsf',num2str(dsf), '_',num2str(handles.info.info.daq.scanRate),'VPS_',...
            strrep(get(handles.secs,'String'),':','to'),'secs_quikmovie.avi']);
        imgToSave_topMIP = fullfile(folderPath, [handles.scanName '_topMIP_dsf',num2str(dsf), '_',num2str(handles.info.info.daq.scanRate),'VPS_',...
            strrep(get(handles.secs,'String'),':','to'),'secs_quickMIP.tiff']);
        imgToSave_sideYMIP = fullfile(folderPath, [handles.scanName '_sideYMIP_dsf',num2str(dsf), '_',num2str(handles.info.info.daq.scanRate),'VPS_',...
            strrep(get(handles.secs,'String'),':','to'),'secs_quickMIP.tiff']);
        imgToSave_sideXMIP = fullfile(folderPath, [handles.scanName '_sideXMIP_dsf',num2str(dsf), '_',num2str(handles.info.info.daq.scanRate),'VPS_',...
            strrep(get(handles.secs,'String'),':','to'),'secs_quickMIP.tiff']);
        if exist(filename, 'file')
            disp('Movie already exists - skipping');
        else
            clear tempMIPs
            [a,b] = hist(reshape(double(MIP_SideY),[1,numel(MIP_SideY)]),200);
            cc1 = b(min(find(a>0.01*mean(a))))*.95;
            cc2 = b(max(find(a>0.01*mean(a))))*.95;
            disp('Writing MIP movie..')
            vidObj = VideoWriter(filename, 'Uncompressed AVI');
            vidObj.FrameRate = handles.info.info.daq.scanRate/dsf;
            open(vidObj);
            MIPmovie = zeros(framesPerScan+Xcrop(2)-Xcrop(1)+3,+Xcrop(2)-Xcrop(1)+Ycrop(2)-Ycrop(1)+4,1,numVolumeToLoad,'uint8');
            for volumeCounter = 1:numVolumeToLoad
                imwrite(uint16(MIP_top(:,:,volumeCounter)), imgToSave_topMIP, 'tif', 'Compression', 'none', 'WriteMode', 'Append');
                imwrite(uint16(MIP_SideY(:,:,volumeCounter)), imgToSave_sideYMIP, 'tif', 'Compression', 'none', 'WriteMode', 'Append');
                imwrite(uint16(MIP_SideX(:,:,volumeCounter)), imgToSave_sideXMIP, 'tif', 'Compression', 'none', 'WriteMode', 'Append');
                tempMIPs = squeeze(MIP_top(:,:,volumeCounter));
                tempMIPs = cat(1,tempMIPs,65536*ones(2,Ycrop(2)-Ycrop(1)+1));
                tempMIPs = cat(1,tempMIPs, MIP_SideY(:,:,volumeCounter));
                tempMIPs = cat(2,tempMIPs,65536*ones(framesPerScan+Xcrop(2)-Xcrop(1)+3,2));
                temp_sideX = squeeze(MIP_SideX(:,:,volumeCounter));
                temp_sideX = cat(1,temp_sideX',65536*ones(2,Xcrop(2)-Xcrop(1)+1));
                temp_sideX = cat(1,temp_sideX,zeros(Xcrop(2)-Xcrop(1)+1));
                tempMIPs = cat(2,tempMIPs,temp_sideX);
                MIPmovie(:,:,1,volumeCounter) = uint8((256/(cc2-cc1))*(tempMIPs-cc1));
            end
%                     im2frame(uint8((256/(cc2-cc1))*(tempy-cc1)),map);
            writeVideo(vidObj,MIPmovie);
            close(vidObj)
            disp('done')
        end
    end
    close(h)                    
