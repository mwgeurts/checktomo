function varargout = CheckTomo(varargin)
% CHECKTOMO MATLAB code for CheckTomo.fig
%      CHECKTOMO, by itself, creates a new CHECKTOMO or raises the existing
%      singleton*.
%
%      H = CHECKTOMO returns the handle to a new CHECKTOMO or the handle to
%      the existing singleton*.
%
%      CHECKTOMO('CALLBACK',hObject,eventData,handles,...) calls the local_menu
%      function named CALLBACK in CHECKTOMO.M with the given input arguments.
%
%      CHECKTOMO('Property','Value',...) creates a new CHECKTOMO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CheckTomo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CheckTomo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CheckTomo

% Last Modified by GUIDE v2.5 03-May-2017 15:54:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CheckTomo_OpeningFcn, ...
                   'gui_OutputFcn',  @CheckTomo_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CheckTomo_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CheckTomo (see VARARGIN)

% Turn off MATLAB warnings
warning('off', 'all');

% Choose default command line output for DicomViewer
handles.output = hObject;

% Set version handle
handles.version = '0.1';

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Set current directory to location of this application
cd(path);

% Clear temporary variable
clear path;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'TomoTherapy Plan Second Dose Calculation'
    sprintf('Version: %s (%s)', handles.version, handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Log information
Event(string, 'INIT');

%% Add submodules
% Add matlab calculation submodule to search path
addpath('./thomas_tomocalc');

% Check if MATLAB can find CheckTomoDose
if exist('CheckTomoDose', 'file') ~= 2
    
    % If not, throw an error
    Event(['The thomas_tomocalc submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Add archive extraction submodule to search path
addpath('./tomo_extract');

% Check if MATLAB can find LoadPlan
if exist('LoadPlan', 'file') ~= 2
    
    % If not, throw an error
    Event(['The tomo_extract submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Add gamma submodule to search path
addpath('./gamma');

% Check if MATLAB can find CalcGamma
if exist('CalcGamma', 'file') ~= 2
    
    % If not, throw an error
    Event(['The gamma submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Add structure atlas submodule to search path
addpath('./structure_atlas');

% Check if MATLAB can find LoadDICOMImages
if exist('LoadAtlas', 'file') ~= 2
    
    % If not, throw an error
    Event(['The Structure Atlas submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

%% Load configuration settings
% Open file handle to config.txt file
fid = fopen('config.txt', 'r');

% Verify that file handle is valid
if fid < 3
    
    % If not, throw an error
    Event(['The config.txt file could not be opened. Verify that this ', ...
        'file exists in the working directory. See documentation for ', ...
        'more information.'], 'ERROR');
end

% Scan config file contents
c = textscan(fid, '%s', 'Delimiter', '=');

% Close file handle
fclose(fid);

% Loop through textscan array, separating key/value pairs into array
for i = 1:2:length(c{1})
    handles.config.(strtrim(c{1}{i})) = strtrim(c{1}{i+1});
end

% Clear temporary variables
clear c i fid;

% Log completion
Event('Loaded config.txt parameters');

%% Initialize UI and global variables
% Set version UI text
set(handles.version_text, 'String', ['Version ', handles.version]);

% Set default transparency
set(handles.alpha, 'String', handles.config.DEFAULT_TRANSPARENCY);

% Set initial dose calculation options (only MATLAB)
handles.methods = {
    'MATLAB Dose Calculator (no supersampling)'
    'MATLAB Dose Calculator (supersampling)'
};

% Test for connection to Standalone calculator
handles.gpudose = 0;

% Declare path to beam model folder (if not specified in config file, use
% default path of ./GPU)
if isfield(handles.config, 'MODEL_PATH')
    handles.modeldir = handles.config.MODEL_PATH;
else
    handles.modeldir = './model';
end

% Check for beam model files
if exist(fullfile(handles.modeldir, 'dcom.header'), 'file') == 2 && ...
        exist(fullfile(handles.modeldir, 'fat.img'), 'file') == 2 && ...
        exist(fullfile(handles.modeldir, 'kernel.img'), 'file') == 2 && ...
        exist(fullfile(handles.modeldir, 'lft.img'), 'file') == 2 && ...
        exist(fullfile(handles.modeldir, 'penumbra.img'), 'file') == 2

    % Log name
    Event('Beam model files verified for standalone calculator');
    
    % Check for presence of dose calculator
    handles.gpudose = CalcDose();
    
    % If calc dose was successful
    if handles.gpudose == 1

        % Log dose calculation status
        Event('Standalone GPU Dose calculation available');

        % Add GPU options
        handles.methods{length(handles.methods)+1} = ...
            'Standalone GPU Dose Calculator (fast)';
        handles.methods{length(handles.methods)+1} = ...
            'Standalone GPU Dose Calculator (full)';
        handles.methods{length(handles.methods)+1} = ...
            'Standalone CPU Dose Calculator';

    % Otherwise, calc dose was not successful
    else

        % Log dose calculation status
        Event('Standalone dose calculation engine not available', 'WARN');
        
        % Store status
        handles.gpudose = 0;
    end
else

    % Store status
    handles.gpudose = 0;

    % Throw a warning
    Event(sprintf(['Standalone dose calculation disabled, beam model ', ...
        'not found. Verify that %s exists and contains the necessary ', ...
        'model files'], handles.modeldir), 'WARN');
end

% Set calculation options
set(handles.method_menu, 'String', handles.methods);
set(handles.method_menu, 'Value', ...
    str2double(handles.config.DEFAULT_CALC_METHOD));
Event(['Default calculation method set to ', ...
    handles.methods{str2double(handles.config.DEFAULT_CALC_METHOD)}]);

% Set resolution options
handles.resolutions = {
    'Fine (1)'
    'Normal (2)'
    'Coarse (4)'
    'Extra Coarse (8)'
};
set(handles.resolution_menu, 'String', handles.resolutions);
set(handles.resolution_menu, 'Value', ...
    str2double(handles.config.DEFAULT_RESOLUTION));
Event(['Default resolution set to ', ...
    handles.resolutions{str2double(handles.config.DEFAULT_RESOLUTION)}]);

% Set Gamma criteria
set(handles.gamma_text, 'String', sprintf('%0.1f%%/%0.1f mm', ...
    str2double(handles.config.GAMMA_PERCENT), ...
    str2double(handles.config.GAMMA_DTA_MM)));
set(handles.gamma_text, 'enable', 'off');
set(handles.local_menu, 'String', {'Global', 'Local'});
set(handles.local_menu, 'Value', str2double(handles.config.GAMMA_LOCAL)+1);
set(handles.local_menu, 'enable', 'off');
if str2double(handles.config.GAMMA_LOCAL) == 0
    Event(sprintf('Gamma criteria set to %0.1f%%/%0.1f mm global', ...
        str2double(handles.config.GAMMA_PERCENT), ...
        str2double(handles.config.GAMMA_DTA_MM)));
else
    Event(sprintf('Gamma criteria set to %0.1f%%/%0.1f mm local', ...
        str2double(handles.config.GAMMA_PERCENT), ...
        str2double(handles.config.GAMMA_DTA_MM)));
end

% Set TCS display options
set(handles.tcs_menu, 'String', UpdateTCSDisplay());

% Set line display options
set(handles.line_menu, 'String', UpdateLineDisplay());

% Define default folder path when selecting input files
if strcmpi(handles.config.DEFAULT_PATH, 'userpath')
    handles.path = userpath;
else
    handles.path = handles.config.DEFAULT_PATH;
end
Event(['Default file path set to ', handles.path]);

% If an atlas file is specified in the config file
if isfield(handles.config, 'ATLAS_FILE')
    
    % Attempt to load the atlas
    handles.atlas = LoadAtlas(handles.config.ATLAS_FILE);
    
% Otherwise, declare an empty atlas
else
    handles.atlas = cell(0);
end

% Check for MVCT calculation flag
if isfield(handles.config, 'ALLOW_MVCT_CALC') && ...
        str2double(handles.config.ALLOW_MVCT_CALC) == 1
    
    % Log status
    Event('MVCT dose calculation enabled');
    
    % Enable MVCT dose calculation
    handles.mvctcalc = 1;

% If dose calc flag does not exist or is disabled
else
    
    % Log status
    Event('MVCT dose calculation disabled');
    
    % Disable MVCT dose calculation
    handles.mvctcalc = 0;
end

%% Clear UI, initializing plots
handles = clearData(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CheckTomo_OutputFcn(~, ~, ~) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcs_menu_Callback(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to tcs_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute UpdateTCSDisplay
handles = UpdateTCSDisplay(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcs_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to tcs_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line_menu_Callback(hObject, ~, handles)
% hObject    handle to line_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update line plot
handles = UpdateLineDisplay(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to line_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function browse_text_Callback(~, ~, ~)
% hObject    handle to browse_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function browse_text_CreateFcn(hObject, ~, ~)
% hObject    handle to browse_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function browse_button_Callback(hObject, ~, handles)
% hObject    handle to browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('Archive browse button selected');

% Warn the user that existing data will be deleted
if ~isfield(handles, 'plans') || ~isempty(handles.plans)

    % Ask user if they want to calculate dose
    choice = questdlg(['Existing plan data exists and will ', ...
        'be deleted. Continue?'], 'Confirm Erase', 'Yes', 'No', 'Yes');

    % If the user chose yes
    if strcmp(choice, 'Yes')
        
        % Execute clear function
        handles = clearData(handles);
        
        % Request the user to select the patient archive XML
        Event('UI window opened to select archive');
        [name, path] = uigetfile({'*_patient.xml', ...
            'Patient Archive (*.xml)'}, 'Select the Archive Patient XML', ...
            handles.path);
    else
        Event('User chose not to select new patient archive');
        name = 0;
    end
else
    % Request the user to select the patient archive XML
    Event('UI window opened to select archive');
    [name, path] = uigetfile({'*_patient.xml', 'Patient Archive (*.xml)'}, ...
        'Select the Archive Patient XML', handles.path);
end
    
% If the user selected a file
if ~isequal(name, 0)
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Update browse text box
    set(handles.browse_text, 'String', fullfile(path, name));
        
    % Extract plan list
    handles.plans = FindPlans(path, name); 
    
    % If LoadDailyQA was successful
    if ~isempty(handles.plans)
        
        % If more than one plan was found
        if length(handles.plans) > 1
            
            % Log event
            Event(['Multiple plans found, opening listdlg to prompt user ', ...
                'to select which one to load']);

            % Otherwise, prompt the user to select from handles.plans
            [id, ok] = listdlg('Name', 'Plan Selection', ...
                'PromptString', ['Multiple approved plans were found. ', ...
                'Choose which one to load:'],...
                    'SelectionMode', 'single', 'ListSize', [500 300], ...
                    'ListString', handles.plans);

            % If the user selected cancel, throw an error
            if ok == 0
                Event('No plan was chosen');
                return;
            
            % Otherwise, set the UID to the selected one
            else
                Event(sprintf('User selected delivery plan UID %i', ...
                    handles.plans{id}));
                
                handles.planuid = handles.plans{id};
            end

            % Clear temporary variables
            clear ok id;
        
        % Otherwise, only one plan exists
        else
            handles.planuid = handles.plans{1};
        end
        
        % Initialize progress bar
        progress = waitbar(0.1, 'Loading plan from patient archive...');
        
        % Log start
        Event(['Loading plan, planning image, and reference dose for ', ...
            'selected plan']);
        
        % Load the plan
        handles.plan = LoadPlan(path, name, handles.planuid);
        
        % Populate and enable the image list
        set(handles.image_menu, 'String', {'Planning CT'});
        set(handles.image_menu, 'Value', 1);
        
        % Update progress bar
        waitbar(0.2, progress, 'Loading image sets...');
        
        % Load the planning CT
        handles.referenceImage = LoadImage(path, name, handles.planuid);

        % Add MVCT images
        %
        %
        %
        %
        %
        %  
        
        % Enable the image menu
        set(handles.image_menu, 'Enable', 'On');
        
        % Update progress bar
        waitbar(0.4, progress, 'Loading structure set...');
        
        % Load the structure set
        handles.referenceImage.structures = LoadStructures(path, name, ...
            handles.referenceImage, handles.atlas);
        
        % Initialize statistics table
        set(handles.struct_table, 'Data', InitializeStatistics(...
            handles.referenceImage.structures, handles.atlas));
        
        % Update progress bar
        waitbar(0.6, progress, 'Loading planned dose...');
        
        % Load the reference dose
        handles.referenceDose = LoadPlanDose(path, name, handles.planuid);
        
        % Update progress bar
        waitbar(0.8, progress, 'Updating dose display...');
        
        % Display the planning dose by initializing new figure objects
        set(handles.tcs_menu, 'Value', 1);
        handles.transverse = ImageViewer('axis', handles.trans_axes, ...
            'tcsview', 'T', 'background', handles.referenceImage, ...
            'overlay', handles.referenceDose, 'alpha', ...
            sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
            'structures', handles.referenceImage.structures, ...
            'structuresonoff', handles.struct_table, ...
            'slider', handles.trans_slider, 'cbar', 'off');
        handles.coronal = ImageViewer('axis', handles.cor_axes, ...
            'tcsview', 'C', 'background', handles.referenceImage, ...
            'overlay', handles.referenceDose, 'alpha', ...
            sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
            'structures', handles.referenceImage.structures, ...
            'structuresonoff', handles.struct_table, ...
            'slider', handles.cor_slider, 'cbar', 'off');
        handles.sagittal = ImageViewer('axis', handles.sag_axes, ...
            'tcsview', 'S', 'background', handles.referenceImage, ...
            'overlay', handles.referenceDose, 'alpha', ...
            sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
            'structures', handles.referenceImage.structures, ...
            'structuresonoff', handles.struct_table, ...
            'slider', handles.sag_slider, 'cbar', 'on');
        set(handles.alpha, 'visible', 'on');

        % Update DVH plot
        [handles.referenceDose.dvh] = ...
            UpdateDVH(handles.dvh_axes, get(handles.struct_table, 'Data'), ...
            handles.referenceImage, handles.referenceDose);
        
        % Update Dx/Vx statistics
        set(handles.struct_table, 'Data', UpdateDoseStatistics(...
            get(handles.struct_table, 'Data'), [], ...
            handles.referenceDose.dvh, []));
        
        % Enable the results and display tables
        set(handles.stats_table, 'enable', 'on');
        set(handles.struct_table, 'enable', 'on');
        
        % Enable the display options
        set(handles.tcs_menu, 'Enable', 'On');
        set(handles.line_menu, 'Enable', 'On');
        
        % Update results table
        set(handles.stats_table, 'Data', UpdateResults(handles));
        
        % Update line plot
        handles = UpdateLineDisplay(handles, '0');
        
        % Enable the calculation options
        set(handles.method_menu, 'Enable', 'On');
        set(handles.resolution_menu, 'Enable', 'On');
        set(handles.dose_button, 'Enable', 'on');
        
        % Close progress bar
        close(progress);
        
        % Log completion
        Event(['Archive load completed successfully. You may now select ', ...
            'options and recalculate dose']);
        
    % Otherwise, no eligible plans were found
    else
        
        % Warn user
        Event('No plans were found. Select a new patient archive', 'WARN');
        msgbox('No plans were found. Select a new patient archive', ...
            'Load Warning');
    end
    
% Otherwise the user did not select a file
else
    Event('No archive file was selected');
end

% Clear temporary variables
clear name path progress;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function method_menu_Callback(hObject, ~, handles)
% hObject    handle to method_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log choice
Event(['User chose to calculate dose via ', ...
    handles.methods{get(hObject,'Value')}]);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function method_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to method_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function resolution_menu_Callback(hObject, ~, handles)
% hObject    handle to resolution_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log choice
Event(['User chose a resolution of ', ...
    handles.resolutions{get(hObject,'Value')}]);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function resolution_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to resolution_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gamma_text_Callback(hObject, ~, handles)
% hObject    handle to gamma_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Retrieve Gamma criteria
c = strsplit(get(hObject, 'String'), '/');

% If the user didn't include a /
if length(c) < 2

    % Throw a warning
    Event(['When entering Gamma criteria, you must provide the ', ...
        'form ##%/## mm'], 'WARN');
    
    % Display a message box
    msgbox(['When entering Gamma criteria, you must provide the ', ...
        'form ##%/## mm']);
    
    % Reset the gammav
    set(handles.gamma_text, 'String', sprintf('%0.1f%%/%0.1f mm', ...
        str2double(handles.config.GAMMA_PERCENT), ...
        str2double(handles.config.GAMMA_DTA_MM)));

% Otherwise two values were found
else
    
    % Parse values
    set(hObject, 'String', sprintf('%0.1f%%/%0.1f mm', ...
        str2double(regexprep(c{1}, '[^\d\.]', '')), ...
        str2double(regexprep(c{2}, '[^\d\.]', ''))));
    
    % Log change
    Event(['Gamma criteria set to ', get(hObject, 'String')]);
end

% Clear temporary variables
clear c;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gamma_text_CreateFcn(hObject, ~, ~)
% hObject    handle to gamma_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function local_menu_Callback(hObject, ~, handles)
% hObject    handle to local_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Retrieve options
contents = cellstr(get(hObject, 'String'));

% Log choice
Event(['Gamma absolute criteria set to ', ...
    contents{get(hObject,'Value')}, ' locale']);

% Clear temporary variables
clear contents;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function local_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to local_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dose_button_Callback(hObject, ~, handles)
% hObject    handle to dose_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Store method and resolution
handles.doseStats.method = ...
    handles.methods{get(handles.method_menu, 'Value')};
handles.doseStats.resolution = ...
    handles.resolutions{get(handles.resolution_menu, 'Value')};

% Store image options
images = get(handles.image_menu, 'String');

% If the selected image is the plannign CT
if strcmp(images{get(handles.image_menu, 'Value')}, 'Planning CT')
    
    % Store the planning image
    image = handles.referenceImage;
else
    
   % Add MVCT option here
   %
   %
   %
   %
   %
   %
    
end

% If a gamma calculation exists
if isfield(handles, 'gamma') && ~isempty(handles.gamma)
    
    % Clear it
    Event('Clearing existing Gamma map');
    handles.gamma = [];
end

% Log event
Event(['Starting dose calculation using the algorithm ', ...
    handles.doseStats.method, ' and resolution ', ...
    handles.doseStats.resolution]);

% If the user chose to use MATLAB
if strcmp(handles.doseStats.method(1:6), 'MATLAB')
    
    % Initialize progress bar
    progress = waitbar(0.1, 'Preparing dose calculation...');
    
    % Parse out the downsampling option
    c = regexp(handles.doseStats.resolution, '([0-9])');
    handles.doseStats.downsample = ...
        str2double(handles.doseStats.resolution(c:c));
    
    % If the downsampling factor is less than 4, confirm user wants this
    if handles.doseStats.downsample < 4
        
        % Ask user if they want to calculate at this resolution
        choice = questdlg(['Fine or normal resolution calculations can take ', ...
            'a long time in MATLAB and require significant memory. Are you ', ...
            'sure you want to continue?'], 'Confirm Resolution', ...
            'Yes', 'No', 'Yes');
    
        % If the user chose no
        if strcmp(choice, 'No')
            
            % Log choice
            Event(['User chose not to continue calculating ', ...
                'at this resolution']);
            
            % Close progress bar
            close(progress);
            
            % End execution
            return;
        end
    end
    
    % Parse out the supersampling option
    if strcmp(handles.doseStats.method(end-17:end), '(no supersampling)')
        handles.doseStats.supersample = 1;
    else
        handles.doseStats.supersample = 3;
    end
    
    % Set reference dose rate option (default to 8.5 Gy/min if not present)
    if isfield(handles.config, 'MATLAB_DOSE_RATE')
        handles.doseStats.doserate = ...
            str2double(handles.config.MATLAB_DOSE_RATE);
    else
        handles.doseStats.doserate = 8.5;
    end   
        
    % Start calculation pool, if configured
    if isfield(handles.config, 'MATLAB_POOL') && isempty(gcp('nocreate'))
        
        % Update progress bar
        waitbar(0.3, progress, 'Starting calculation pool...');
        
        % Log event
        Event(sprintf('Starting calculation pool with %i workers', ...
            str2double(handles.config.MATLAB_POOL)));
        
        % Start calculation pool
        handles.pool = parpool(str2double(handles.config.MATLAB_POOL));
    else
        
        % Store empty value
        handles.pool = gcp;
    end
    
    % Update progress bar
    waitbar(0.5, progress, 'Calculating Dose...');
    
    % Log event
    Event('Executing CheckTomoDose');

    % Start timer
    t = tic;
    
    % Execute dose calculation
    handles.secondDose = CheckTomoDose(image, handles.plan, handles.pool, ...
        'downsample', handles.doseStats.downsample, 'reference_doserate', ...
        handles.doseStats.doserate, 'num_of_subprojections', ...
        handles.doseStats.supersample);
    
% Otherwise, if the user chose 
elseif strcmp(handles.doseStats.method(1:10), ...
        'Standalone')

    % Initialize progress bar
    progress = waitbar(0.1, 'Preparing dose calculation...');
    
    % Parse out the downsampling option
    c = regexp(handles.doseStats.resolution, '([0-9])');
    handles.doseStats.downsample = ...
        str2double(handles.doseStats.resolution(c:c));
    
    % Parse out the GPU/CPU options
    c = regexp(handles.doseStats.method, 'GPU');
    
    % Set parameters for GPU fast option
    if ~isempty(c) && strcmp(handles.doseStats.method(end-5:end), '(fast)')
        handles.doseStats.supersample = 0;
        handles.doseStats.azimuths = 4;
        handles.doseStats.raysteps = 1;
        handles.doseStats.sadose = 0;
        
    % Set parameters for GPU full option
    elseif ~isempty(c)
        handles.doseStats.supersample = 1;
        handles.doseStats.azimuths = 16;
        handles.doseStats.raysteps = 1.5;
        handles.doseStats.sadose = 0;
        
    % Set parameters for CPU fast option
    else
        handles.doseStats.supersample = 0;
        handles.doseStats.azimuths = 4;
        handles.doseStats.raysteps = 1;
        handles.doseStats.sadose = 1;
    end
    
    % Update progress bar
    waitbar(0.3, progress, 'Calculating Dose...');
    
    % Log event
    Event('Executing CalcDose');

    % Start timer
    t = tic;
    
    % Execute dose calculation
    handles.secondDose = CalcDose(image, handles.plan, 'downsample', ...
        handles.doseStats.downsample, 'supersample', ...
        handles.doseStats.supersample, 'azimuths', ...
        handles.doseStats.azimuths, 'sadose', handles.doseStats.sadose, ...
        'modelfolder', handles.config.MODEL_PATH);
 
% Otherwise, we don't know what the option is
else
    Event('An unknown dose calculation option was chosen', 'ERROR');
end

% If a valid dose was returned
if isfield(handles, 'secondDose') && isstruct(handles.secondDose)
    
    % Stop timer and store computation time
    handles.doseStats.calctime = toc(t);
    
    % Update progress bar
    waitbar(0.8, progress, 'Calculating statistics...');
    
    % Log event
    Event('Computing dose difference statistics');
    
    % Store dose difference
    diff = handles.secondDose.data - handles.referenceDose.data;
    
    % Compute local or global relative difference based on setting
    if get(handles.local_menu, 'Value') == 1
        diff = diff / max(max(max(handles.referenceDose.data)));
    else
        diff = diff ./ handles.referenceDose.data;
    end
    
    % Apply threshold and store mean difference 
    handles.doseStats.meandiff = sum(reshape(diff .* (handles.referenceDose.data > ...
        str2double(handles.config.DOSE_THRESHOLD) * ...
        max(max(max(handles.referenceDose.data)))), 1, [])) / ...
        sum(reshape(handles.referenceDose.data > ...
        str2double(handles.config.DOSE_THRESHOLD) * ...
        max(max(max(handles.referenceDose.data))), 1, []));
    
    % Store dose grid size
    handles.doseStats.gridSize = image.width .* ...
        [handles.doseStats.downsample handles.doseStats.downsample 1];
    
    % Update progress bar
    waitbar(0.9, progress, 'Updating dose display...');
    
    % Execute UpdateTCSDisplay to update plots with second dose
    set(handles.tcs_menu, 'Value', 2);
    handles = UpdateTCSDisplay(handles);
    
    % Update DVH plot
    [handles.referenceDose.dvh, handles.secondDose.dvh] = ...
        UpdateDVH(handles.dvh_axes, get(handles.struct_table, 'Data'), ...
        handles.referenceImage, handles.referenceDose, ...
        handles.referenceImage, handles.secondDose);

    % Update Dx/Vx statistics
    set(handles.struct_table, 'Data', UpdateDoseStatistics(...
        get(handles.struct_table, 'Data'), [], ...
        handles.referenceDose.dvh, handles.secondDose.dvh));
    
    % Update line plot
    handles = UpdateLineDisplay(handles, '0');
    
    % Update results
    set(handles.stats_table, 'Data', UpdateResults(handles));
    
    % Enable Gamma options
    set(handles.gamma_text, 'Enable', 'on');
    set(handles.local_menu, 'Enable', 'on');
    set(handles.gamma_button, 'Enable', 'on');
    
    % Close progress bar
    close(progress);
end

% Clear temporary variables
clear t c downsample method resolution supersample image images doserate ...
    progress diff;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gamma_button_Callback(hObject, ~, handles)
% hObject    handle to gamma_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update progress bar
progress = waitbar(0.1, 'Calculating Gamma...');

% Retrieve Gamma criteria
c = textscan(get(handles.gamma_text, 'String'), '%f%%/%f mm');

% Execute CalcGamma using restricted 3D search
handles.gamma = CalcGamma(handles.referenceDose, ...
    handles.secondDose, c{1}, c{2}, ...
    'local', str2double(get(handles.local_menu, 'Value'))-1, 'refval', ...
    max(max(max(handles.referenceDose.data))), 'restrict', 1);

% Eliminate gamma values below dose threshold
handles.gamma = handles.gamma .* ...
    (handles.referenceDose.data > str2double(handles.config.GAMMA_THRESHOLD) * ...
    max(max(max(handles.referenceDose.data))));

% Store mean gamma 
handles.doseStats.meangamma = sum(reshape(handles.gamma, 1, [])) / ...
    sum(reshape(handles.referenceDose.data > ...
    str2double(handles.config.GAMMA_THRESHOLD) * ...
    max(max(max(handles.referenceDose.data))), 1, []));

% Store pass rate
handles.doseStats.passgamma = 1 - sum(reshape(handles.gamma, 1, []) > 1) / ...
    sum(reshape(handles.referenceDose.data > ...
    str2double(handles.config.GAMMA_THRESHOLD) * ...
    max(max(max(handles.referenceDose.data))), 1, []));

% Update progress bar
waitbar(0.9, progress, 'Updating statistics...');

% Execute UpdateTCSDisplay to update plots with gamma index
set(handles.tcs_menu, 'Value', 5);
handles = UpdateTCSDisplay(handles);

% Update results statistics
set(handles.stats_table, 'Data', UpdateResults(handles));

% Update line plot
handles = UpdateLineDisplay(handles, '0');

% Close progress bar
close(progress);

% Clear temporary variables
clear c;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trans_slider_Callback(hObject, ~, handles)
% hObject    handle to trans_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update transverse plot
handles.transverse.Update('slice', round(get(hObject, 'Value')));

% Update line plot
handles = UpdateLineDisplay(handles, '0');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trans_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to trans_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cor_slider_Callback(hObject, ~, handles)
% hObject    handle to cor_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update coronal plot
handles.coronal.Update('slice', round(get(hObject, 'Value')));

% Update line plot
handles = UpdateLineDisplay(handles, '0');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cor_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to cor_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sag_slider_Callback(hObject, ~, handles)
% hObject    handle to sag_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update sagittal plot
handles.sagittal.Update('slice', round(get(hObject, 'Value')));

% Update line plot
handles = UpdateLineDisplay(handles, '0');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sag_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to sag_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha_Callback(hObject, ~, handles)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If the string contains a '%', parse the value
if ~isempty(strfind(get(hObject, 'String'), '%'))
    value = sscanf(get(hObject, 'String'), '%f%%');
    
% Otherwise, attempt to parse the response as a number
else
    value = str2double(get(hObject, 'String'));
end

% Bound value to [0 100]
value = max(0, min(100, value));

% Log event
Event(sprintf('Dose transparency set to %0.0f%%', value));

% Update string with formatted value
set(hObject, 'String', sprintf('%0.0f%%', value));

% Update plots
handles.transverse.Update('alpha', value/100);
handles.coronal.Update('alpha', value/100);
handles.sagittal.Update('alpha', value/100);
  
% Clear temporary variable
clear value;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha_CreateFcn(hObject, ~, ~)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line_slider_Callback(hObject, ~, handles)
% hObject    handle to line_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call UpdateLineDisplay
handles = UpdateLineDisplay(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to line_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function image_menu_Callback(hObject, eventdata, handles)
% hObject    handle to image_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns image_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from image_menu


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function image_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to image_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function handles = clearData(handles)
% This function clears all data and resets all UI components. This function
% is also called during program initialization to set up the interface and
% all internal variables.

% Log action
Event('Resetting all variables and clearing display');

% Clear/initialize non-UI variables
handles.plans = [];
handles.plan = [];
handles.planuid = [];
handles.referenceImage = [];
handles.mergedImage = [];
handles.referenceDose = [];
handles.secondDose = [];
handles.doseStats = [];
handles.gamma = [];

% Disable plots
if isfield(handles, 'transverse')
    delete(handles.transverse);
else
    set(allchild(handles.trans_axes), 'visible', 'off'); 
    set(handles.trans_axes, 'visible', 'off');
    set(handles.trans_slider, 'visible', 'off');
end
if isfield(handles, 'coronal')
    delete(handles.coronal);
else
    set(allchild(handles.cor_axes), 'visible', 'off'); 
    set(handles.cor_axes, 'visible', 'off');
    set(handles.cor_slider, 'visible', 'off');
end
if isfield(handles, 'sagittal')
    delete(handles.sagittal);
else
    set(allchild(handles.sag_axes), 'visible', 'off'); 
    set(handles.sag_axes, 'visible', 'off');
    set(handles.sag_slider, 'visible', 'off');
end
set(handles.line_axes, 'visible', 'off');
set(allchild(handles.line_axes), 'visible', 'off'); 
set(handles.dvh_axes, 'visible', 'off');
set(allchild(handles.dvh_axes), 'visible', 'off'); 

% Disable sliders/alpha
set(handles.line_slider, 'visible', 'off');
set(handles.alpha, 'visible', 'off');

% Clear results table
set(handles.stats_table, 'Data', UpdateResults(handles));

% Disable tables and plot dropdowns
set(handles.stats_table, 'enable', 'off');
set(handles.struct_table, 'enable', 'off');
set(handles.method_menu, 'enable', 'off');
set(handles.resolution_menu, 'enable', 'off');
set(handles.line_menu, 'enable', 'off');
set(handles.tcs_menu, 'enable', 'off');
set(handles.image_menu, 'enable', 'off');
set(handles.image_menu, 'String', 'Planning CT');

% Disable calculation buttons
set(handles.dose_button, 'enable', 'off');
set(handles.gamma_button, 'enable', 'off');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function struct_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to dvh_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty 
%       if Data was not changed
%	Error: error string when failed to convert EditData to appropriate 
%       value for Data
% handles    structure with handles and user data (see GUIDATA)

% Get current data
stats = get(hObject, 'Data');

% Verify edited Dx value is a number or empty
if eventdata.Indices(2) == 3 && isnan(str2double(...
        stats{eventdata.Indices(1), eventdata.Indices(2)})) && ...
        ~isempty(stats{eventdata.Indices(1), eventdata.Indices(2)})
    
    % Warn user
    Event(sprintf(['Dx value "%s" is not a number, reverting to previous ', ...
        'value'], stats{eventdata.Indices(1), eventdata.Indices(2)}), 'WARN');
    
    % Revert value to previous
    stats{eventdata.Indices(1), eventdata.Indices(2)} = ...
        eventdata.PreviousData;
    
% Otherwise, if Dx was changed
elseif eventdata.Indices(2) == 3
    
    % Update edited Dx/Vx statistic
    stats = UpdateDoseStatistics(stats, eventdata.Indices);
    
% Otherwise, if display value was changed
elseif eventdata.Indices(2) == 2

    % Update the image plots are displayed
    if strcmpi(get(handles.alpha, 'visible'), 'on')
        
        % Update plots
        handles.transverse.Update('structuresonoff', stats);
        handles.coronal.Update('structuresonoff', stats);
        handles.sagittal.Update('structuresonoff', stats);
    end

    % Update DVH plot if it is displayed
    if strcmp(get(handles.dvh_axes, 'visible'), 'on')
        
        % Update DVH plot
        UpdateDVH(stats); 
    end
end

% Set new table data
set(hObject, 'Data', stats);

% Clear temporary variable
clear stats;

% Update handles structure
guidata(hObject, handles);
