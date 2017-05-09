function varargout = UpdateLineDisplay(varargin)
% UpdateLineDisplay displays a line plot of the primary and secondary dose
% and Gamma index, if present. This function also uses/updates a slider UI
% handle specify which slice to display, as well as a menu UI handle to
% determine which axis to plot along. If called with no arguments, this
% function will return a cell array of strings indicating the menu list
% options. If called with one or two inputs, where the first is a guihandle
% input and the second is an optional flag (0 or 1, defaults to 1 if not 
% present), this function will render the plot to the axes UI handle 
% line_axis. The optional flag determines whether or not to update the
% associated TCS axes (a line is displayed on the corresponding TCS display
% indicating where the line plot is).
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
    'IEC X Profile'
    'IEC Y Profile'
    'IEC Z Profile'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the plot options
    varargout{1} = plotoptions;
    
    % Stop execution
    return;
    
% Otherwise, if 1, set the handles and update the plot
elseif nargin == 1
    
    % Set input variables
    handles = varargin{1};
    update = 1;

% Otherwise, if 2, set the handles/update flags and update the plot
elseif nargin == 2
    
    % Set input variables
    handles = varargin{1};
    update = varargin{2};

% Otherwise, throw an error
else 
    Event('Incorrect number of inputs to UpdateLineDisplay', 'ERROR');
end

% Start timer
tic;

% If the update flag is passed
if update == 1
    
    % Update all profiles
    handles.transverse.Update;
    handles.coronal.Update;
    handles.sagittal.Update;
end

% Clear and set reference to axis
cla(handles.line_axes, 'reset');
axes(handles.line_axes);
Event('Updating plot line_axes');

% Turn off the display while building
set(allchild(handles.line_axes), 'visible', 'off'); 
set(handles.line_axes, 'visible', 'off');
set(handles.line_slider, 'visible', 'off');

% If data exists
if isfield(handles, 'referenceDose') && ...
        isfield(handles.referenceDose, 'data')
    
    % Store maximum axes dimension
    m = max(handles.referenceDose.dimensions);
    
    % Execute code block based on display GUI item value
    switch get(handles.line_menu, 'Value')

        % X Profile
        case 1

            % Store x coordinates
            x = handles.referenceDose.start(1):...
                handles.referenceDose.width(1):...
                handles.referenceDose.start(1) + ...
                handles.referenceDose.width(1) * ...
                (handles.referenceDose.dimensions(1) - 1);
            
            % If slider min/max do not match this axis, update it (along
            % with the value)
            if (get(handles.line_slider, 'Max') - ...
                    get(handles.line_slider, 'Min') + 1) ~= ...
                    handles.referenceDose.dimensions(2)
                
                % Update slider Min/Max
                set(handles.line_slider, 'Min', 1);
                set(handles.line_slider, 'Max', ...
                    handles.referenceDose.dimensions(2));
                
                % Update value
                set(handles.line_slider, 'Value', ...
                    floor(handles.referenceDose.dimensions(2) / 2));
                
                % Update slider minor/major steps
                set(handles.line_slider, 'SliderStep', [1 / ...
                    (handles.referenceDose.dimensions(2) - 1) ...
                    10 / handles.referenceDose.dimensions(2)]);
            end
            
            % Turn on slider
            set(handles.line_slider, 'Visible', 'on');
            
            % Plot line profile along IEC X at slider position
            plot(x, handles.referenceDose.data(:, ...
                round(get(handles.line_slider, 'Value')), ...
                round(get(handles.trans_slider, 'Value'))), '-b');
            
            % Add legend entry
            l{1} = 'Planned';
            
            % Plot secondary dose, if it exists
            if isfield(handles, 'secondDose') && ...
                    isfield(handles.secondDose, 'data')

                % Hold plot build
                hold on;
                
                % Plot line profile along IEC X at slider position
                plot(x, handles.secondDose.data(:, ...
                    round(get(handles.line_slider, 'Value')), ...
                    round(get(handles.trans_slider, 'Value'))), '--b');
                
                % Add legend entry
                l{2} = 'Re-calculated';
                
                % Resume plot build
                hold off;
            end
            
            % Plot Gamma profile, if it exists
            if isfield(handles, 'gamma') && ~isempty(handles.gamma)

                % Hold plot build
                hold on;
                
                % Plot Gamma against second Y axis
                yyaxis right
                
                % Plot line profile along IEC X at slider position
                plot(x, handles.gamma(:, ...
                    round(get(handles.line_slider, 'Value')), ...
                    round(get(handles.trans_slider, 'Value'))), '-.r');
                
                % Add legend entry
                l{3} = 'Gamma';
                
                % Resume plot build
                hold off;
                
                % Adjust second axis display
                set(handles.line_axes, 'YColor', 'black');
                ylabel('Gamma Index');
                ylim([0 2]);
                
                % Go back to left axis
                yyaxis left
            end
            
            % Adjust plot display
            xlim([min(x) max(x)]);
            xlabel('X Axis Position (cm)');
            ylabel('Dose (Gy)');
            grid on;
            legend(l, 'Location', 'southwest');
            
            % Display line on TCS plot for current slice position
            axes(handles.trans_axes);
            hold on;
            plot([min(x) max(x)], [-(handles.referenceDose.start(2) + ...
                handles.referenceDose.width(2) * ...
                (m - round(get(handles.line_slider, 'Value')) + 0.5)) ...
                -(handles.referenceDose.start(2) + ...
                handles.referenceDose.width(2) * ...
                (m - round(get(handles.line_slider, 'Value')) + 0.5))], ...
                'Color', 'white', 'LineWidth', 1);
            hold off;
            
        % Y Profile
        case 2

            % Store x coordinates
            x = handles.referenceDose.start(3):...
                handles.referenceDose.width(3):...
                handles.referenceDose.start(3) + ...
                handles.referenceDose.width(3) * ...
                (handles.referenceDose.dimensions(3) - 1);
            
            % If slider min/max do not match this axis, update it (along
            % with the value)
            if (get(handles.line_slider, 'Max') - ...
                    get(handles.line_slider, 'Min') + 1) ~= ...
                    handles.referenceDose.dimensions(1)
                
                % Update slider Min/Max
                set(handles.line_slider, 'Min', 1);
                set(handles.line_slider, 'Max', ...
                    handles.referenceDose.dimensions(1));
                
                % Update value
                set(handles.line_slider, 'Value', ...
                    floor(handles.referenceDose.dimensions(1) / 2));
                
                % Update slider minor/major steps
                set(handles.line_slider, 'SliderStep', [1 / ...
                    (handles.referenceDose.dimensions(1) - 1) ...
                    10 / handles.referenceDose.dimensions(1)]);
            end
            
            % Turn on slider
            set(handles.line_slider, 'Visible', 'on');
            
            % Plot line profile along IEC X at slider position
            plot(x, squeeze(handles.referenceDose.data(...
                round(get(handles.line_slider, 'Value')), ...
                round(get(handles.cor_slider, 'Value')), :)), '-b');
            
            % Add legend entry
            l{1} = 'Planned';
            
            % Plot secondary dose, if it exists
            if isfield(handles, 'secondDose') && ...
                    isfield(handles.secondDose, 'data')

                % Hold plot build
                hold on;
                
                % Plot line profile along IEC X at slider position
                plot(x, squeeze(handles.secondDose.data(...
                    round(get(handles.line_slider, 'Value')), ...
                    round(get(handles.cor_slider, 'Value')), :)), '--b');
                
                % Add legend entry
                l{2} = 'Re-calculated';
                
                % Resume plot build
                hold off;
            end
            
            % Plot Gamma profile, if it exists
            if isfield(handles, 'gamma') && ~isempty(handles.gamma)

                % Hold plot build
                hold on;
                
                % Plot Gamma against second Y axis
                yyaxis right
                
                % Plot line profile along IEC X at slider position
                plot(x, squeeze(handles.gamma(...
                    round(get(handles.line_slider, 'Value')), ...
                    round(get(handles.cor_slider, 'Value')), :)), '-.r');
                
                % Add legend entry
                l{3} = 'Gamma';
                
                % Resume plot build
                hold off;
                
                % Adjust second axis display
                set(handles.line_axes, 'YColor', 'black');
                ylabel('Gamma Index');
                ylim([0 2]);
                
                % Go back to left axis
                yyaxis left
            end
            
            % Adjust plot display
            xlim([min(x) max(x)]);
            xlabel('Y Axis Position (cm)');
            ylabel('Dose (Gy)');
            grid on;
            legend(l, 'Location', 'southwest');
            
            % Display line on TCS plot for current slice position
            axes(handles.cor_axes);
            hold on;
            plot([-(handles.referenceDose.start(1) + ...
                handles.referenceDose.width(1) * ...
                (m - round(get(handles.line_slider, 'Value')))) ...
                -(handles.referenceDose.start(1) + ...
                handles.referenceDose.width(1) * ...
                (m - round(get(handles.line_slider, 'Value'))))], ...
                [min(x) max(x)], 'Color', 'white', 'LineWidth', 1);
            hold off;
            
        % Z Profile
        case 3

            % Store x coordinates
            x = handles.referenceDose.start(2):...
                handles.referenceDose.width(2):...
                handles.referenceDose.start(2) + ...
                handles.referenceDose.width(2) * ...
                (handles.referenceDose.dimensions(2) - 1);
            
            % If slider min/max do not match this axis, update it (along
            % with the value)
            if (get(handles.line_slider, 'Max') - ...
                    get(handles.line_slider, 'Min') + 1) ~= ...
                    handles.referenceDose.dimensions(3)
                
                % Update slider Min/Max
                set(handles.line_slider, 'Min', 1);
                set(handles.line_slider, 'Max', ...
                    handles.referenceDose.dimensions(3));
                
                % Update value
                set(handles.line_slider, 'Value', ...
                    floor(handles.referenceDose.dimensions(3) / 2));
                
                % Update slider minor/major steps
                set(handles.line_slider, 'SliderStep', [1 / ...
                    (handles.referenceDose.dimensions(3) - 1) ...
                    10 / handles.referenceDose.dimensions(3)]);
            end
            
            % Turn on slider
            set(handles.line_slider, 'Visible', 'on');
            
            % Plot line profile along IEC X at slider position
            plot(x, squeeze(handles.referenceDose.data(...
                round(get(handles.sag_slider, 'Value')), :, ...
                round(get(handles.line_slider, 'Value')))), '-b');
            
            % Add legend entry
            l{1} = 'Planned';
            
            % Plot secondary dose, if it exists
            if isfield(handles, 'secondDose') && ...
                    isfield(handles.secondDose, 'data')

                % Hold plot build
                hold on;
                
                % Plot line profile along IEC X at slider position
                plot(x, squeeze(handles.secondDose.data(...
                    round(get(handles.sag_slider, 'Value')), :, ...
                    round(get(handles.line_slider, 'Value')))), '--b');
                
                % Add legend entry
                l{2} = 'Re-calculated';
                
                % Resume plot build
                hold off;
            end
            
            % Plot Gamma profile, if it exists
            if isfield(handles, 'gamma') && ~isempty(handles.gamma)

                % Hold plot build
                hold on;
                
                % Plot Gamma against second Y axis
                yyaxis right
                
                % Plot line profile along IEC X at slider position
                plot(x, squeeze(handles.gamma(...
                    round(get(handles.sag_slider, 'Value')), :, ...
                    round(get(handles.line_slider, 'Value')))), '-.r');
                
                % Add legend entry
                l{3} = 'Gamma';
                
                % Resume plot build
                hold off;
                
                % Adjust second axis display
                set(handles.line_axes, 'YColor', 'black');
                ylabel('Gamma Index');
                ylim([0 2]);
                
                % Go back to left axis
                yyaxis left
            end
            
            % Adjust plot display
            xlim([min(x) max(x)]);
            xlabel('Z Axis Position (cm)');
            ylabel('Dose (Gy)');
            grid on;
            legend(l, 'Location', 'southwest');
            
            % Display line on TCS plot for current slice position
            axes(handles.sag_axes);
            hold on;
            plot([min(x) max(x)], [handles.referenceDose.start(3) + ...
                handles.referenceDose.width(3) * ...
                (round(get(handles.line_slider, 'Value')) - 1) ...
                handles.referenceDose.start(3) + ...
                handles.referenceDose.width(3) * ...
                (round(get(handles.line_slider, 'Value')) - 1)], ...
                'Color', 'white', 'LineWidth', 1);
            hold off;
    end
    
    % Clear temporary profiles
    clear x m;
end

% Log completion
Event(sprintf('Plot updated successfully in %0.3f seconds', toc));

% Return the modified handles
varargout{1} = handles; 

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end