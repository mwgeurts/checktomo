classdef ImageViewer
    
    % Define image viewer properties
    properties (Access = protected)
        axis
        tcsview = 'T'
        background = []
        overlay = []
        backgroundrange = []
        overlayrange = []
        alpha = 0.3
        structures = []
        structuresonoff = []
        slider = []
        slice = []
        zoom = 'on'
        pixelval = 'on'
        cbar = 'on'
    end
    
    % Define constructor/destructor function
    methods
        
        % Constructor function
        function obj = ImageViewer(varargin)
            % Inputs are provided to this function in name/value pairs,
            % where the name is an odd integer of nargin and equals the
            % string value of one of the properties above, and value is the
            % value to be stored.
            
            % Log action
            if exist('Event', 'file') == 2
                Event('Constructing image viewer');
            end
            
            % Loop through inputs
            for i = 1:2:nargin
                
                % If name matches a property
                if strcmpi(varargin{i}, 'axis')
                    obj.axis = varargin{i+1};
                elseif strcmpi(varargin{i}, 'tcsview')
                    obj.tcsview = varargin{i+1};
                elseif strcmpi(varargin{i}, 'background')
                    obj.background = varargin{i+1};
                elseif strcmpi(varargin{i}, 'overlay')
                    obj.overlay = varargin{i+1};
                elseif strcmpi(varargin{i}, 'backgroundrange')
                    obj.backgroundrange = varargin{i+1};
                elseif strcmpi(varargin{i}, 'overlayrange')
                    obj.overlayrange = varargin{i+1};
                elseif strcmpi(varargin{i}, 'alpha')
                    obj.alpha = varargin{i+1};
                elseif strcmpi(varargin{i}, 'structures')
                    obj.structures = varargin{i+1};
                elseif strcmpi(varargin{i}, 'structuresonoff')
                    obj.structuresonoff = varargin{i+1};
                elseif strcmpi(varargin{i}, 'slider')
                    obj.slider = varargin{i+1};
                elseif strcmpi(varargin{i}, 'slice')
                    obj.slice = varargin{i+1};
                elseif strcmpi(varargin{i}, 'zoom')
                    obj.zoom = varargin{i+1};
                elseif strcmpi(varargin{i}, 'pixelval')
                    obj.pixelval = varargin{i+1};
                elseif strcmpi(varargin{i}, 'cbar')
                    obj.cbar = varargin{i+1};
                end
            end
            
            % At least the axis must be defined here
            if isempty(obj.axis) || ~isgraphics(obj.axis, 'Axes')
                if exist('Event', 'file') == 2
                    Event(['An axis handle must be passed when creating ', ...
                        'an ImageViewer object'], 'ERROR');
                else
                    error(['An axis handle must be passed when creating ', ...
                        'an ImageViewer object']);
                end
            end
            
            % Start by hiding this display
            set(allchild(obj.axis), 'visible', 'off'); 
            set(obj.axis, 'visible', 'off');
            
            % If a slider was included, hide it too
            if ~isempty(obj.slider) && ishandle(obj.slider)
                set(obj.slider, 'visible', 'off');
            end
            
            % If a colorbar is on, turn that off too
            if strcmpi(obj.cbar, 'on')
                colorbar(obj.axis, 'off');
            end
            
            % If background data is provided, continue to auto-initialize
            % the image viewer
            obj = obj.Initialize();
        end
        
        % Destructor function
        function delete(obj)
            
            % Hide this display
            set(allchild(obj.axis), 'visible', 'off'); 
            set(obj.axis, 'visible', 'off');
            
            % If a slider was included, hide it too
            if ~isempty(obj.slider) && ishandle(obj.slider)
                set(obj.slider, 'visible', 'off');
            end
            
            % If a colorbar is on, turn that off too
            if strcmpi(obj.cbar, 'on')
                colorbar(obj.axis, 'off');
            end
        end
        
        % Hide function
        function Hide(obj)
            
            % Hide this display
            set(allchild(obj.axis), 'visible', 'off'); 
            set(obj.axis, 'visible', 'off');
            
            % If a slider was included, hide it too
            if ~isempty(obj.slider) && ishandle(obj.slider)
                set(obj.slider, 'visible', 'off');
            end
            
            % If a colorbar is on, turn that off too
            if strcmpi(obj.cbar, 'on')
                colorbar(obj.axis, 'off');
            end
        end 
    end
end