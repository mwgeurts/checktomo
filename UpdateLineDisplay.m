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

% Clear and set reference to axis
cla(handles.line_axes, 'reset');
axes(handles.line_axes);
Event('Updating plot line_axes');

% Turn off the display while building
set(allchild(handles.line_axes), 'visible', 'off'); 
set(handles.line_axes, 'visible', 'off');
set(handles.line_slider, 'visible', 'off');

% Execute code block based on display GUI item value
switch get(handles.line_menu, 'Value')
    
    % X Profile
    case 1
       
        
    % Y Profile
    case 2
        
        
    % Z Profile
    case 3
       
end

% Log completion
Event(sprintf('Plot updated successfully in %0.3f seconds', toc));

% Return the modified handles
varargout{1} = handles; 

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end