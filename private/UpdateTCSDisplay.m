function varargout = UpdateTCSDisplay(varargin)
% UpdateTCSDisplay is called by CheckTomo when initializing or
% updating the TCS plots.  When called with no input arguments, this
% function returns a string cell array of available plots that the user can
% choose from.  When called with a GUI handles structure, it will update
% the display based on the selected plot.
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

% Specify plot options and order
plotoptions = {
    'Planned Dose (Gy)'
    'Re-calculated Dose (Gy)'
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
    
% Otherwise, if 1
elseif nargin == 1
    
    % Set input variables
    handles = varargin{1};
    t = tic;
    
% Otherwise, throw an error
else 
    Event('Incorrect number of inputs to UpdateTCSDisplay', 'ERROR');
end

% Hide all axes and transparency
handles.transverse.Hide();
handles.coronal.Hide();
handles.sagittal.Hide();
set(handles.alpha, 'visible', 'off');

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
                
            % Initialize transverse axes with the planned dose
            handles.transverse.Initialize('overlay', handles.referenceDose);
            
            % Initialize coronal axes with the planned dose
            handles.coronal.Initialize('overlay', handles.referenceDose);
            
            % Initialize sagittal axes with the planned dose
            handles.sagittal.Initialize('overlay', handles.referenceDose);
            
            % Enable transparency input
            set(handles.alpha, 'visible', 'on');
        else
            % Log why plot was not displayed
            Event('Planned dose not displayed as no data exists');
        end
        
    % Re-calculated dose display
    case 2
        
        % Log plot selection
        Event('Re-calculated dose plot selected');
        
        % Check if the planned dose and image are loaded
        if isfield(handles, 'referenceImage') && ...
                isfield(handles.referenceImage, 'data') ...
                && isfield(handles, 'secondDose') && ...
                isfield(handles.secondDose, 'data')
                
            % Initialize transverse axes with the re-calculated dose
            handles.transverse.Initialize('overlay', handles.secondDose);
            
            % Initialize coronal axes with the re-calculated dose
            handles.coronal.Initialize('overlay', handles.secondDose);
            
            % Initialize sagittal axes with the re-calculated dose
            handles.sagittal.Initialize('overlay', handles.secondDose);
            
            % Enable transparency input
            set(handles.alpha, 'visible', 'on');
        else
            % Log why plot was not displayed
            Event('DQA dose not displayed as no data exists');
        end
        
    % Dose difference % display
    case 3
        
        % Log plot selection
        Event('Relative dose difference plot selected');
        
        % Check if the planned dose and image are loaded
        if isfield(handles, 'referenceDose') && ...
                isfield(handles.referenceDose, 'data') ...
                && isfield(handles, 'secondDose') && ...
                isfield(handles.secondDose, 'data')
            
            % Initialize difference structure
            diff.width = handles.referenceDose.width;
            diff.dimensions = handles.referenceDose.dimensions;
            diff.start = handles.referenceDose.start;
            
            % Store dose difference
            diff.data = handles.secondDose.data - handles.referenceDose.data;

            % Crop differences where second calc is zero
            diff.data(handles.secondDose.data == 0) = 0;
            
            % Compute local or global relative difference based on setting
            if get(handles.local_menu, 'Value') == 1
                diff.data = diff.data / ...
                    max(max(max(handles.referenceDose.data))) * 100;
            else
                diff.data = diff.data ./ handles.referenceDose.data * 100;
                diff.data(diff.data > 100) = 100;
            end
            
            % Initialize transverse axes with the relative doseDiff
            handles.transverse.Initialize('overlay', diff);
            
            % Initialize coronal axes with the relative doseDiff
            handles.coronal.Initialize('overlay', diff);
            
            % Initialize sagittal axes with the relative doseDiff
            handles.sagittal.Initialize('overlay', diff);
            
            % Enable transparency input
            set(handles.alpha, 'visible', 'on');
            
            % Clear temporary variable
            clear diff;
        else
            % Log why plot was not displayed
            Event('Dose difference not displayed as no data exists');
        end
        
    % Dose difference abs display
    case 4
        
        % Log plot selection
        Event('Absolute dose difference plot selected');
        
        % Check if the planned dose and image are loaded
        if isfield(handles, 'referenceDose') && ...
                isfield(handles.referenceDose, 'data') ...
                && isfield(handles, 'secondDose') && ...
                isfield(handles.secondDose, 'data')
            
            % Initialize difference structure
            diff.width = handles.referenceDose.width;
            diff.dimensions = handles.referenceDose.dimensions;
            diff.start = handles.referenceDose.start;
            
            % Store dose difference
            diff.data = handles.secondDose.data - ...
                handles.referenceDose.data;
            
            % Crop differences where second calc is zero
            diff.data(handles.secondDose.data == 0) = 0;
            
            % Initialize transverse axes with the relative doseDiff
            handles.transverse.Initialize('overlay', diff);
            
            % Initialize coronal axes with the relative doseDiff
            handles.coronal.Initialize('overlay', diff);
            
            % Initialize sagittal axes with the relative doseDiff
            handles.sagittal.Initialize('overlay', diff);
            
            % Enable transparency input
            set(handles.alpha, 'visible', 'on');
            
            % Clear temporary variable
            clear diff;
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
            
            % Initialize difference structure
            gamma.width = handles.referenceDose.width;
            gamma.dimensions = handles.referenceDose.dimensions;
            gamma.start = handles.referenceDose.start;
            gamma.data = handles.gamma;
            
            % Initialize transverse axes with the doseDiff
            handles.transverse.Initialize('overlay', gamma);
            
            % Initialize coronal axes with the doseDiff
            handles.coronal.Initialize('overlay', gamma);
            
            % Initialize sagittal axes with the doseDiff
            handles.sagittal.Initialize('overlay', gamma);
            
            % Enable transparency input
            set(handles.alpha, 'visible', 'on');
            
            % Clear temporary variable
            clear diff;
        else
            % Log why plot was not displayed
            Event('Gamma index not displayed as no data exists');
        end
end

% Log completion
Event(sprintf('Plots updated successfully in %0.3f seconds', toc(t)));

% Clear temporary variables
clear t;

% Return the modified handles
varargout{1} = handles; 