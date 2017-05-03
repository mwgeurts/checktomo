function varargout = Initialize(obj, varargin)
% Initialize loads the necessary data for a 3D image viewer object. 
% The image viewer is capable of displaying two overlapping
% datasets (with adjustable transparency) as well as contours in the
% transverse, coronal, or sagittal views. This function can be called again
% to initialize a new overlay dataset over the original background.
%
% This function also prepares the datasets for faster viewing by detecting 
% if the secondary dataset is identical in dimension and position to the 
% primary dataset; if not, the secondary data is resampled using GPU (if 
% possible) to the primary dataset reference coordinate system.
%
% Subsequent updates to the viewer can be made directly via Update function
% by passing updated slice, transparency, and checkerboard values (all
% image data is stored in the object).  New image data should not be passed 
% directly to UpdateViewer; instead, this function should be called again.
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

% Apply variable input arguments
for i = 1:2:length(varargin)
    
    % If the obj.overlay arguments were passed
    if strcmpi(varargin{i}, 'overlay')
        obj.overlay = varargin{i+1};
        obj.overlayrange = [];
    elseif strcmpi(varargin{i}, 'overlayrange')
        obj.overlayrange = varargin{i+1};
    end
end

% Log start of initialization and start timer
if exist('Event', 'file') == 2
    Event('Initializing image viewer data sets');
    tic;
end

%% Align secondary data
% If secondary data exists and follows the required format
if isstruct(obj.overlay) && isfield(obj.overlay, 'data')

    % If the image size, pixel size, or start differs between datasets, or
    % a registration adjustment exists
    if size(obj.background.data,1) ~= size(obj.overlay.data,1) ...
            || size(obj.background.data,2) ~= size(obj.overlay.data,2) ...
            || size(obj.background.data,3) ~= size(obj.overlay.data,3) ...
            || isequal(obj.background.width, obj.overlay.width) == 0 ...
            || isequal(obj.background.start, obj.overlay.start) == 0 || ...
            (isfield(obj.overlay, 'registration') && ...
            size(obj.overlay.registration,2) == 6 && ...
            ~isequal(obj.overlay.registration, [0 0 0 0 0 0]))

        % Check if the secondary dataset is an RGB datset (indicated by a
        % fourth dimension)
        if size(size(obj.overlay.data),2) > 3
            
            % Throw an error, as interpolation of RGB data is not currently
            % supported
            if exist('Event', 'file') == 2
                Event(['RGB images with different reference coordinates are', ...
                    ' not supported at this time'], 'ERROR');
            else
                error(['RGB images with different reference coordinates are', ...
                    ' not supported at this time']);
            end
        else
            % Otherwise, log that interpolation will be performed to align
            % secondary to primary dataset
            if exist('Event', 'file') == 2
                Event(['Secondary dataset includes non-zero registration, ', ...
                    'beginning interpolation']);
            end
        end

        % If a registration exists
        if isfield(obj.overlay, 'registration') && ...
            size(obj.overlay.registration,2) == 6 && ...
            ~isequal(obj.overlay.registration, [0 0 0 0 0 0])
        
            %% Generate homogeneous transformation matrix
            % Log task
            if exist('Event', 'file') == 2
                Event('Generating transformation matrix');
            end

            % Generate 4x4 transformation matrix given a 6 element vector of 
            % [pitch yaw roll x y z].  For more information, see S. M. LaVelle,
            % "Planning Algorithms", Cambridge University Press, 2006 at 
            % http://planning.cs.uiuc.edu/node102.html
            tform(1,1) = cos(obj.overlay.registration(3)) * ...
                cos(obj.overlay.registration(1));
            tform(2,1) = cos(obj.overlay.registration(3)) * ...
                sin(obj.overlay.registration(1)) * ...
                sin(obj.overlay.registration(2)) - ...
                sin(obj.overlay.registration(3)) * ...
                cos(obj.overlay.registration(2));
            tform(3,1) = cos(obj.overlay.registration(3)) * ...
                sin(obj.overlay.registration(1)) * ...
                cos(obj.overlay.registration(2)) + ...
                sin(obj.overlay.registration(3)) * ...
                sin(obj.overlay.registration(2));
            tform(4,1) = obj.overlay.registration(6);
            tform(1,2) = sin(obj.overlay.registration(3)) * ...
                cos(obj.overlay.registration(1));
            tform(2,2) = sin(obj.overlay.registration(3)) * ...
                sin(obj.overlay.registration(1)) * ...
                sin(obj.overlay.registration(2)) + ...
                cos(obj.overlay.registration(3)) * ...
                cos(obj.overlay.registration(2));
            tform(3,2) = sin(obj.overlay.registration(3)) * ...
                sin(obj.overlay.registration(1)) * ...
                cos(obj.overlay.registration(2)) - ...
                cos(obj.overlay.registration(3)) * ...
                sin(obj.overlay.registration(2));
            tform(4,2) = obj.overlay.registration(4);
            tform(1,3) = -sin(obj.overlay.registration(1));
            tform(2,3) = cos(obj.overlay.registration(1)) * ...
                sin(obj.overlay.registration(2));
            tform(3,3) = cos(obj.overlay.registration(1)) * ...
                cos(obj.overlay.registration(2));
            tform(4,3) = obj.overlay.registration(5);
            tform(1,4) = 0;
            tform(2,4) = 0;
            tform(3,4) = 0;
            tform(4,4) = 1;
        else
            tform = diag([1 1 1 1]);
        end
            
        %% Generate mesh grids for primary image
        % Log start of mesh grid computation and dimensions
        if exist('Event', 'file') == 2
            Event(sprintf(['Generating prinary mesh grid with dimensions', ...
                ' (%i %i %i 3)'], size(obj.background.data)));
        end

        % Generate x, y, and z grids using start and width structure fields
        [refX, refY, refZ] = meshgrid(obj.background.start(2) + ...
            obj.background.width(2) * (size(obj.background.data, 2) - 1): ...
            -obj.background.width(2):obj.background.start(2), ...
            obj.background.start(1):obj.background.width(1):obj.background.start(1) ...
            + obj.background.width(1) * (size(obj.background.data, 1) - 1), ...
            obj.background.start(3):obj.background.width(3):obj.background.start(3) ...
            + obj.background.width(3) * (size(obj.background.data, 3) - 1));

        % Generate unity matrix of same size as reference data to aid in
        % matrix transform
        ref1 = ones(size(obj.background.data));

        %% Generate meshgrids for secondary image
        % Log start of mesh grid computation and dimensions
        if exist('Event', 'file') == 2
            Event(sprintf(['Generating secondary mesh grid with dimensions', ...
                ' (%i %i %i 3)'], size(obj.overlay.data)));
        end
        
        % Generate x, y, and z grids using start and width structure fields
        [secX, secY, secZ] = meshgrid(obj.overlay.start(2) + ...
            obj.overlay.width(2) * (size(obj.overlay.data, 2) - 1): ...
            -obj.overlay.width(2):obj.overlay.start(2), ...
            obj.overlay.start(1):obj.overlay.width(1):obj.overlay.start(1) ...
            + obj.overlay.width(1) * (size(obj.overlay.data, 1) - 1), ...
            obj.overlay.start(3):obj.overlay.width(3):obj.overlay.start(3) ...
            + obj.overlay.width(3) * (size(obj.overlay.data, 3) - 1));

        %% Transform secondary image meshgrids
        % Log start of transformation
        if exist('Event', 'file') == 2
            Event('Applying transformation matrix to reference mesh grid');
        end
        
        % Separately transform each reference x, y, z point by shaping all
        % to vector form and dividing by transformation matrix
        result = [reshape(refX,[],1) reshape(refY,[],1) reshape(refZ,[],1) ...
            reshape(ref1,[],1)] / tform;

        % Reshape transformed x, y, and z coordinates back to 3D arrays
        refX = reshape(result(:,1), size(obj.background.data));
        refY = reshape(result(:,2), size(obj.background.data));
        refZ = reshape(result(:,3), size(obj.background.data));

        % Clear temporary variables
        clear result ref1 tform;

        %% Interpolate transformed secondary image
        % Log start of interpolation
        if exist('Event', 'file') == 2
            Event('Attempting interpolation of secondary image');
        end
        
        % Use try-catch statement to attempt to perform interpolation using
        % GPU.  If a GPU compatible device is not available (or fails due
        % to memory), automatically revert to CPU based technique
        try
            % Initialize device and clear GPU memory
            gpuDevice(1);

            % Interpolate the secondary dataset to the primary dataset's
            % reference coordinates using GPU linear interpolation, and 
            % store back to obj.overlay
            obj.overlay.data = gather(interp3(gpuArray(secX), ...
                gpuArray(secY), gpuArray(secZ), gpuArray(obj.overlay.data), ...
                gpuArray(refX), gpuArray(refY), gpuArray(refZ), 'linear', 0));

            % Clear GPU memory
            gpuDevice(1);

            % Log success of GPU method 
            if exist('Event', 'file') == 2
                Event('GPU interpolation completed');
            end
        catch
            % Otherwise, GPU failed, so notify user that CPU will be used
            if exist('Event', 'file') == 2
                Event(['GPU interpolation failed, reverting to CPU ', ...
                    'interpolation'], 'WARN');
            else
                warning(['GPU interpolation failed, reverting to CPU ', ...
                    'interpolation']);
            end

            % Interpolate secondary dataset to the reference coordinates
            % using linear interpolation, and store back to obj.overlay
            obj.overlay.data = interp3(secX, secY, secZ, ...
                obj.overlay.data, refX, refY, refZ, '*linear', 0);

            % Log completion of CPU method
            if exist('Event', 'file') == 2
                Event('CPU interpolation completed');
            end
        end
    end
end

%% Set default slice
% Set slider controls/default slice depending on TCS viewer setting using
% switch statement
switch obj.tcsview

% If set to Transverse view
case 'T'
    
    % If a slice selection handle was provided
    if ~isempty(obj.slider) && ishandle(obj.slider)
        
        % Set the slider range to the dimensions of the reference image
        set(obj.slider, 'Min', 1);
        set(obj.slider, 'Max', size(obj.background.data,3));

        % Set the slider minor/major steps to one slice and 10 slices
        set(obj.slider, 'SliderStep', [1 / (size(obj.background.data, 3) - 1) ...
            10 / size(obj.background.data, 3)]);

        % If not set, start at the center slice
        if isempty(obj.slice)
            obj.slice = round(size(obj.background.data, 3) / 2);
        end
        
        % Set the slider position
        set(obj.slider, 'Value', obj.slice);
    end
    
% If set to Coronal view
case 'C'
    
    % If a slice selection handle was provided
    if ~isempty(obj.slider) && ishandle(obj.slider)
        
        % Set the slider range to the dimensions of the reference image
        set(obj.slider, 'Min', 1);
        set(obj.slider, 'Max', size(obj.background.data, 2));

        % Set the slider minor/major steps to one slice and 10 slices
        set(obj.slider, 'SliderStep', [1 / (size(obj.background.data, 2) - 1) ...
            10 / size(obj.background.data, 2)]);

        % If not set, start at the center slice
        if isempty(obj.slice)
            obj.slice = round(size(obj.background.data, 2) / 2);
        end
        
        % Set the slider position
        set(obj.slider, 'Value', obj.slice);
    end
    
% If set to Sagittal view
case 'S'
    
    % If a slice selection handle was provided
    if ~isempty(obj.slider) && ishandle(obj.slider)
        
        % Set the slider range to the dimensions of the reference image
        set(obj.slider, 'Min', 1);
        set(obj.slider, 'Max', size(obj.background.data, 1));

        % Set the slider minor/major steps to one slice and 10 slices
        set(obj.slider, 'SliderStep', [1 / (size(obj.background.data, 1) - 1) ...
            10 / size(obj.background.data, 1)]);

        % If not set, start at the center slice
        if isempty(obj.slice)
            obj.slice = round(size(obj.background.data, 1) / 2);
        end
        
        % Set the slider position
        set(obj.slider, 'Value', obj.slice);
    end

% Otherwise throw an error  
otherwise
    if exist('Event', 'file') == 2
        Event('Incorrect TCS value passed to ImageViewer', 'ERROR');
    else
        error('Incorrect TCS value passed to ImageViewer');
    end
end

%% Set Image Ranges
% If an image range is not defined
if isempty(obj.backgroundrange)
    
    % Calculate new min/max values for background
    obj.backgroundrange = [min(min(min(obj.background.data))) ...
        max(max(max(obj.background.data)))]; 
end

% If overlay data exists and a range is not defined
if isstruct(obj.overlay) && isfield(obj.overlay, 'data') && ...
        isempty(obj.overlayrange)
    
    % Calculate new min/max values for background
    obj.overlayrange = [min(min(min(obj.overlay.data))) ...
        max(max(max(obj.overlay.data)))]; 
end
    

%% Finish initialization
% Log successful completion of InitializeViewer 
if exist('Event', 'file') == 2
    Event(sprintf(['Image viewer initialization completed successfully ', ...
        'in %0.3f seconds'], toc));
end

% Call Update class function
obj.Update();

% If return argument exists
if nargout == 1
    varargout{1} = obj;
end