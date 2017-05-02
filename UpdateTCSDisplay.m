function varargout = UpdateTCSDisplay(varargin)
% UpdateTCSDisplay is called by CheckTomo when initializing or
% updating a TCS plot.  When called with no input arguments, this
% function returns a string cell array of available plots that the user can
% choose from.  When called with a GUI handles structure, axis handle, and 
% slider handle  will update the axes based on the value of tcs_menu.
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

% Run in try-catch to log error via Event.m
try

% Specify plot options and order
plotoptions = {
    'Planned Dose (Gy)'
    'DQA Dose (Gy)'
    'Dose Difference (%)'
    'Dose Difference (Gy)'
    'Gamma Comparison'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the plot options
    varargout{1} = plotoptions;
    
    % Stop execution
    return;
    
% Otherwise, if 3, set the input variable and update the plot
elseif nargin == 3
    
    % Set input variables
    handles = varargin{1};
    
    % Set axes handle
    axis = varargin{2};
    
    % Set slider handle
    slider = varargin{3};

    % Start timer
    tic;
    
% Otherwise, throw an error
else 
    Event('Incorrect number of inputs to UpdateTCSDisplay', 'ERROR');
end

% Clear and set reference to axis
cla(axis, 'reset');
axes(axis);
Event(['Updating plot ', get(axis, 'Tag')]);

% Turn off the display while building
set(allchild(axis), 'visible', 'off'); 
set(axis, 'visible', 'off');
set(slider, 'visible', 'off');

% Execute code block based on display GUI item value
switch get(handles.tcs_menu, 'Value')
    
    % Planned dose display
    case 1
        % Log plot selection
        Event('Planned dose plot selected');
        
        % Check if the planned dose and image are loaded
        if isfield(handles, 'referenceImage') && ...
                isfield(handles.referenceImage, 'data') ...
                && isfield(handles, 'referenceDose') && ...
                isfield(handles.referenceDose, 'data')
                
            % Enable Image Viewer UI components
            set(allchild(axis), 'visible', 'on'); 
            set(axis, 'visible', 'on');
            set(slider, 'visible', 'on');
            
            % Set references to currently displayed data
            image1.data = handles.referenceImage.data;
            image1.width = handles.referenceImage.width;
            image1.start = handles.referenceImage.start;
            image1.structures = handles.referenceImage.structures;
            image1.stats = get(handles.dvh_table, 'Data');
            image2.data = handles.referenceDose.data;
            image2.width = handles.referenceDose.width;
            image2.start = handles.referenceDose.start;
            image2.registration = [];
            
            % Initialize image viewer
            InitializeViewer(axis, handles.tcsview, ...
                sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
                image1, image2, slider);
        else
            % Log why plot was not displayed
            Event('Planned dose not displayed as no data exists');
        end
        
    % DQA dose display
    case 2
        % Log plot selection
        Event('DQA dose plot selected');
        
        % Check if the planned dose and image are loaded
        if isfield(handles, 'referenceImage') && ...
                isfield(handles.referenceImage, 'data') ...
                && isfield(handles, 'dqaDose') && ...
                isfield(handles.dqaDose, 'data')
                
            % Enable Image Viewer UI components
            set(allchild(axis), 'visible', 'on'); 
            set(axis, 'visible', 'on');
            set(slider, 'visible', 'on');
            
            % If a merged MVCT was generated
            if handles.mvctcalc == 1 && isfield(handles, 'mergedImage') && ...
                    isfield(handles.mergedImage, 'data')
                
                % Use merged MVCT
                image1.data = handles.mergedImage.data;
                image1.width = handles.mergedImage.width;
                image1.start = handles.mergedImage.start;
            else
                
                % Use plan CT
                image1.data = handles.referenceImage.data;
                image1.width = handles.referenceImage.width;
                image1.start = handles.referenceImage.start;
            end
            
            % Set references to currently displayed data
            image1.structures = handles.referenceImage.structures;
            image1.stats = get(handles.dvh_table, 'Data');
            image2.data = handles.dqaDose.data;
            image2.width = handles.dqaDose.width;
            image2.start = handles.dqaDose.start;
            image2.registration = [];
            
            % Initialize image viewer
            InitializeViewer(axis, handles.tcsview, ...
                sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
                image1, image2, slider);
        else
            % Log why plot was not displayed
            Event('DQA dose not displayed as no data exists');
        end
        
    % Dose difference % display
    case 3
        % Log plot selection
        Event('Relative dose difference plot selected');
        
        % Check if the planned dose and image are loaded
        if isfield(handles, 'referenceImage') && ...
                isfield(handles.referenceImage, 'data') ...
                && isfield(handles, 'doseDiff') && ...
                ~isempty(handles.doseDiff)
                
            % Enable Image Viewer UI components
            set(allchild(axis), 'visible', 'on'); 
            set(axis, 'visible', 'on');
            set(slider, 'visible', 'on');
            
            % If a merged MVCT was generated
            if handles.mvctcalc == 1 && isfield(handles, 'mergedImage') && ...
                    isfield(handles.mergedImage, 'data')
                
                % Use merged MVCT
                image1.data = handles.mergedImage.data;
                image1.width = handles.mergedImage.width;
                image1.start = handles.mergedImage.start;
            else
                
                % Use plan CT
                image1.data = handles.referenceImage.data;
                image1.width = handles.referenceImage.width;
                image1.start = handles.referenceImage.start;
            end
            
            % Set references to currently displayed data
            image1.structures = handles.referenceImage.structures;
            image1.stats = get(handles.dvh_table, 'Data');
            image2.data = handles.doseDiff ./ image1.data .* ...
                (image1.data > 1) * 100;
            image2.width = handles.referenceImage.width;
            image2.start = handles.referenceImage.start;
            image2.registration = [];
            
            % Initialize image viewer
            InitializeViewer(axis, handles.tcsview, ...
                sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
                image1, image2, slider);
        else
            % Log why plot was not displayed
            Event('Dose difference not displayed as no data exists');
        end
        
    % Dose difference abs display
    case 4
        % Log plot selection
        Event('Absolute dose difference plot selected');
        
        % Check if the planned dose and image are loaded
        if isfield(handles, 'referenceImage') && ...
                isfield(handles.referenceImage, 'data') ...
                && isfield(handles, 'doseDiff') && ...
                ~isempty(handles.doseDiff)
                
            % Enable Image Viewer UI components
            set(allchild(axis), 'visible', 'on'); 
            set(axis, 'visible', 'on');
            set(slider, 'visible', 'on');
            
            % If a merged MVCT was generated
            if handles.mvctcalc == 1 && isfield(handles, 'mergedImage') && ...
                    isfield(handles.mergedImage, 'data')
                
                % Use merged MVCT
                image1.data = handles.mergedImage.data;
                image1.width = handles.mergedImage.width;
                image1.start = handles.mergedImage.start;
            else
                
                % Use plan CT
                image1.data = handles.referenceImage.data;
                image1.width = handles.referenceImage.width;
                image1.start = handles.referenceImage.start;
            end
            
            % Set references to currently displayed data
            image1.structures = handles.referenceImage.structures;
            image1.stats = get(handles.dvh_table, 'Data');
            image2.data = handles.doseDiff;
            image2.width = handles.referenceImage.width;
            image2.start = handles.referenceImage.start;
            image2.registration = [];
            
            % Initialize image viewer
            InitializeViewer(axis, handles.tcsview, ...
                sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
                image1, image2, slider);
        else
            % Log why plot was not displayed
            Event('Dose difference not displayed as no data exists');
        end
    
    % Gamma display
    case 5
        % Log plot selection
        Event('Gamma index plot selected');
        
        % Check if the planned dose and image are loaded
        if isfield(handles, 'referenceImage') && ...
                isfield(handles.referenceImage, 'data') ...
                && isfield(handles, 'gamma') && ...
                ~isempty(handles.gamma)
                
            % Enable Image Viewer UI components
            set(allchild(axis), 'visible', 'on'); 
            set(axis, 'visible', 'on');
            set(slider, 'visible', 'on');
            
            % If a merged MVCT was generated
            if handles.mvctcalc == 1 && isfield(handles, 'mergedImage') && ...
                    isfield(handles.mergedImage, 'data')
                
                % Use merged MVCT
                image1.data = handles.mergedImage.data;
                image1.width = handles.mergedImage.width;
                image1.start = handles.mergedImage.start;
            else
                
                % Use plan CT
                image1.data = handles.referenceImage.data;
                image1.width = handles.referenceImage.width;
                image1.start = handles.referenceImage.start;
            end
            
            % Set references to currently displayed data
            image1.structures = handles.referenceImage.structures;
            image1.stats = get(handles.dvh_table, 'Data');
            image2.data = handles.gamma;
            image2.width = handles.referenceImage.width;
            image2.start = handles.referenceImage.start;
            image2.registration = [];
            
            % Initialize image viewer
            InitializeViewer(axis, handles.tcsview, ...
                sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
                image1, image2, slider);
        else
            % Log why plot was not displayed
            Event('Gamma index not displayed as no data exists');
        end
end

% Clear temporary variables
clear image image2;

% Log completion
Event(sprintf('Plot updated successfully in %0.3f seconds', toc));

% Return the modified handles
varargout{1} = handles; 

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end