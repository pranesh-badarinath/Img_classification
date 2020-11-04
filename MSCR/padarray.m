function b = padarray(varargin)

args = matlab.images.internal.stringToChar(varargin);

[a, method, padSize, padVal, direction, catConverter] = ParseInputs(args{:});

b = padarray_algo(a, padSize, method, padVal, direction);

if ~isempty(catConverter)
    b = catConverter.numeric2Categorical(b);
end

%%%
%%% ParseInputs
%%%
function [a, method, padSize, padVal, direction, catConverter] = ParseInputs(varargin)

narginchk(2,4);

% fixed syntax args
a         = varargin{1};
padSize   = varargin{2};

% default values
method    = 'constant';
padVal    = 0;
direction = 'both';
catConverter = [];
isCategoricalInput = false;

if iscategorical(a)
    categoriesIn = categories(a);
    catConverter = images.internal.utils.CategoricalConverter(categoriesIn);
    a = catConverter.categorical2Numeric(a);
    isCategoricalInput = true;
end

validateattributes(padSize, {'double'}, {'real' 'vector' 'nonnan' 'nonnegative' ...
    'integer'}, mfilename, 'PADSIZE', 2);

% Preprocess the padding size
if (numel(padSize) < ndims(a))
    padSize           = padSize(:);
    padSize(ndims(a)) = 0;
end


if nargin > 2
    
    firstStringToProcess = 3;
    
    if ~ischar(varargin{3})
        % Third input must be pad value.
        
        padVal = varargin{3};
        
        if isCategoricalInput
            % For categorical inputs, padVal of missing corresponds to <undefined> no
            % other numeric value is valid
            if ~isnumeric(padVal) && ismissing(padVal)
                padVal = 0;
            else
                error(message('images:padarray:invalidPadvalOrDir',2,padVal))
            end
                
        else
            validateattributes(padVal, {'numeric' 'logical'}, {'scalar'}, mfilename, 'PADVAL', 3);
        end
        firstStringToProcess = 4;
        
    end
    
    % Arg 3 and 4, both can take METHOD and DIRECTION interchangeably. This
    % is NOT a bug, the feature was designed this way. One thing to note is
    % ARG 4 cannot be PADVAL
    for k = firstStringToProcess:nargin
        
        validStrings = {'circular' 'replicate' 'symmetric' 'pre' 'post' 'both'};
        
        if isCategoricalInput && k == 3
            validStrings = [categoriesIn', validStrings]; %#ok<AGROW>
            try
                strVal = validatestring(varargin{k}, validStrings);
            catch 
                error(message('images:padarray:invalidPadvalOrDir',k,varargin{k}))
            end
        else
            strVal = validatestring(varargin{k}, validStrings, mfilename, 'METHOD or DIRECTION', k);
        end
        
        switch strVal
            case {'circular' 'replicate' 'symmetric'}
                method = strVal;
                
            case {'pre' 'post' 'both'}
                direction = strVal;
                
            otherwise
                % categorical pad value 
                % Validate case-sensitivity of input padval as
                % validatestring is case-insensitive. Also use varargin{k}
                % instead of strVal, as validatestring always returns lowercase
                % string
                if ~any(strcmp(varargin{k},categoriesIn))
                    error(message('images:padarray:invalidPadvalOrDir',k,varargin{k}))
                end
                padVal = catConverter.getNumericValue(strVal);
                
        end
    end
end

% Check the input array type
if strcmp(method,'constant') && ~(isnumeric(a) || islogical(a))
    error(message('images:padarray:badTypeForConstantPadding'))
end
