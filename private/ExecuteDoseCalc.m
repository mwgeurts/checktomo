function handles = ExecuteDoseCalc(handles)
% ExecuteDoseCalc is called by CheckTomo when the user clicks the Calculate
% Dose button. It retrieves the necessary calculation parameters from the
% UI, and then executes the calculation corresponding to the calculation
% method that is selected.
% 
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2017 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

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
if strcmpi(handles.doseStats.method(1:6), 'MATLAB')
    
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
    try
        if isfield(handles.config, 'MATLAB_POOL') && ...
                isempty(gcp('nocreate'))

            % Update progress bar
            waitbar(0.3, progress, 'Starting calculation pool...');

            % Log event
            Event(sprintf('Starting calculation pool with %i workers', ...
                str2double(handles.config.MATLAB_POOL)));

            % Start calculation pool
            handles.pool = parpool(str2double(handles.config.MATLAB_POOL));
        else

            % Store current value
            handles.pool = gcp('nocreate');
        end
     
    % If the parallel processing toolbox is not present, the above code
    % will fail
    catch
        handles.pool = [];
    end
    
    % Update progress bar
    waitbar(0.5, progress, 'Calculating Dose...');
    
    % Log event
    Event('Executing CheckTomoDose');

    % Start timer
    t = tic;
    
    % Execute dose calculation, using the reference dose and dose threshold
    % as a mask for dose volume determination
    handles.secondDose = CheckTomoDose(image, handles.plan, handles.pool, ...
        'downsample', handles.doseStats.downsample, 'reference_doserate', ...
        handles.doseStats.doserate, 'num_of_subprojections', ...
        handles.doseStats.supersample, 'outside_body', ...
        str2double(handles.config.MATLAB_OUTSIDE_BODY), 'density_threshold', ...
        str2double(handles.config.MATLAB_DENSITY_THRESH), 'mask', ...
        handles.referenceDose.data > ...
        (str2double(handles.config.DOSE_THRESHOLD) - 0.05) * ...
        max(max(max(handles.referenceDose.data))));
    
% Otherwise, if the user chose GPUSADOSE/SADOSE
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
        'raysteps', handles.doseStats.raysteps, 'modelfolder', ...
        handles.config.MODEL_PATH);
 
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
    
    % Crop differences where second calc is zero
    diff(handles.secondDose.data == 0) = 0;
    
    % Compute local or global relative difference based on setting
    if get(handles.local_menu, 'Value') == 1
        diff = diff / max(max(max(handles.referenceDose.data)));
    else
        diff = diff ./ handles.referenceDose.data;
    end
    
    % Apply threshold and store mean difference 
    handles.doseStats.meandiff = sum(diff(handles.referenceDose.data > ...
        str2double(handles.config.DOSE_THRESHOLD) * ...
        max(max(max(handles.referenceDose.data))))) / ...
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
    
    % Recalculate DVHs and update DVH plot, Dx/Vx table
    handles.dvh.Calculate('doseA', handles.referenceDose, 'doseB', ...
        handles.secondDose, 'legend', {'Planned', 'Re-calculated'});
    
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