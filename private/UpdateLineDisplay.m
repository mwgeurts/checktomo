function varargout = UpdateLineDisplay(varargin)

% Run in try-catch to log error via Event.m
try

% Specify plot options and order
plotoptions = {
    'X Profile'
    'Y Profile'
    'Z Profile'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the plot options
    varargout{1} = plotoptions;
    
    % Stop execution
    return;
    
% Otherwise, if 3, set the input variable and update the plot
elseif nargin == 1
    
    % Set input variables
    handles = varargin{1};

    % Start timer
    tic;
    
% Otherwise, throw an error
else 
    Event('Incorrect number of inputs to UpdateLineDisplay', 'ERROR');
end

% Update TCS display
switch get(handles.line_menu, 'Value')

    % X Profile
    case 1
        handles.transverse.Update;
    
    % Y Profile
    case 2
        handles.coronal.Update;
    
    % Z Profile
    case 3
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
            
            % Plot line profile along IEC X at slider position
            plot(x, handles.referenceDose.data(:, ...
                round(get(handles.line_slider, 'Value')), ...
                round(get(handles.trans_slider, 'Value'))));
            xlim([min(x) max(x)]);
            xlabel('X Axis Position (cm)');
            ylabel('Dose (Gy)');
            grid on;
            
            % Turn on slider
            set(handles.line_slider, 'Visible', 'on');

            %
            %
            % Plot secondary data
            %
            %
            
            % Display line on TCS plot for current slice position
            axes(handles.trans_axes);
            hold on;
            plot([min(x) max(x)], [-(handles.referenceDose.start(2) + ...
                handles.referenceDose.width(2) * ...
                (handles.referenceDose.dimensions(2) - ...
                round(get(handles.line_slider, 'Value')) - 1)) ...
                -(handles.referenceDose.start(2) + ...
                handles.referenceDose.width(2) * ...
                (handles.referenceDose.dimensions(2) - ...
                round(get(handles.line_slider, 'Value')) - 1))], ...
                'Color', 'white', 'LineWidth', 1);
            hold off;
            
            
        % Y Profile
        case 2


        % Z Profile
        case 3

    end
end

% Clear temporary profiles
clear x;

% Log completion
Event(sprintf('Plot updated successfully in %0.3f seconds', toc));

% Return the modified handles
varargout{1} = handles; 

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end