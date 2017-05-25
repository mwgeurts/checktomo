function handles = BrowsePatientArchive(handles)
% BrowsePatientArchive is called by CheckTomo when the user presses the
% Browse button to load a patient archive. This function will prompt the
% user to select the _patient.xml, then load the XML contents, and finally
% update the UI to display the planned dose and DVH.
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

% Warn the user that existing data will be deleted
if ~isfield(handles, 'plans') || ~isempty(handles.plans)

    % Ask user if they want to calculate dose
    choice = questdlg(['Existing plan data exists and will ', ...
        'be deleted. Continue?'], 'Confirm Erase', 'Yes', 'No', 'Yes');

    % If the user chose yes
    if strcmp(choice, 'Yes')
        
        % Execute clear function
        handles = ClearAllData(handles);
        
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
    handles.plans = FindPlans(path, name, 'Helical'); 
    
    % If LoadDailyQA was successful
    if ~isempty(handles.plans)
        
        % If more than one plan was found
        if size(handles.plans, 1) > 1
            
            % Log event
            Event(['Multiple plans found, opening listdlg to prompt user ', ...
                'to select which one to load']);

            % Otherwise, prompt the user to select from handles.plans
            [id, ok] = listdlg('Name', 'Plan Selection', ...
                'PromptString', 'Multiple approved plans were found:',...
                    'SelectionMode', 'single', 'ListSize', [200 100], ...
                    'ListString', handles.plans(:,2));

            % If the user selected cancel, throw an error
            if ok == 0
                Event('No plan was chosen');
                return;
            
            % Otherwise, set the UID to the selected one
            else
                Event(sprintf('User selected delivery plan UID %i', ...
                    handles.plans{id}));
                
                handles.planuid = handles.plans{id,1};
            end

            % Clear temporary variables
            clear ok id;
        
        % Otherwise, only one plan exists
        else
            handles.planuid = handles.plans{1,1};
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

        % Update progress bar
        waitbar(0.6, progress, 'Loading planned dose...');
        
        % Load the reference dose
        handles.referenceDose = LoadPlanDose(path, name, handles.planuid);
        
        % Update progress bar
        waitbar(0.8, progress, 'Updating dose display...');
        
        % Update DVH plot
        handles.dvh = DVHViewer('axis', handles.dvh_axes, ...
            'structures', handles.referenceImage.structures, ...
            'doseA', handles.referenceDose, 'table', handles.struct_table, ...
            'atlas', handles.atlas, 'columns', 6);
        
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