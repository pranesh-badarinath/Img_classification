function overlapRatio = bboxOverlapRatio(bboxA, bboxB, varargin)


narginchk(2,3);
[bboxA, bboxB, ratioType, isUsingCodeGeneration] = iParseInputs(bboxA,bboxB,varargin{:});

if (isa(bboxA,'double') || isa(bboxB,'double'))
    bboxA = double(bboxA);
    bboxB = double(bboxB);
else
    bboxA = single(bboxA);
    bboxB = single(bboxB);    
end

if (isempty(bboxA) || isempty(bboxB))
    overlapRatio = zeros(size(bboxA, 1), size(bboxB, 1), 'like', bboxA);
    return;
end

% The width of the input determines the type of box.
switch size(bboxA,2)
    case 4 
        % axis-aligned rectangle
        overlapRatio = iOverlapRatioAxisAligned(bboxA, bboxB, ratioType, isUsingCodeGeneration);
        
    case 5 
        % rotated rectangle
        overlapRatio = iOverlapRatioRotatedRect(bboxA, bboxB, ratioType, isUsingCodeGeneration); 
        
    otherwise
        % Define all execution paths for codegen support. This codepath is
        % never executed because of runtime checks that ensure size(bboxA)
        % is 4.
        overlapRatio = zeros(size(bboxA, 1), size(bboxB, 1), 'like', bboxA);
end
end

%--------------------------------------------------------------------------
function [bboxA, bboxB, ratioType, isCodegen] = iParseInputs(bboxA, bboxB, varargin)
isCodegen = ~isempty(coder.target);
if isCodegen
     [bboxA, bboxB, ratioType] = validateAndParseInputsCodegen(bboxA, bboxB, varargin{:});
else
     [bboxA, bboxB, ratioType] = validateAndParseInputs(bboxA, bboxB, varargin{:});    
end
end

%--------------------------------------------------------------------------
function overlapRatio = iOverlapRatioAxisAligned(bboxA, bboxB, ratioType, isCodegen)

if isCodegen
    overlapRatio = bboxOverlapRatioCodegen(bboxA, bboxB, ratioType);
else
    if strncmpi(ratioType, 'Union', 1)
        overlapRatio = visionBboxIntersectByUnion(bboxA, bboxB);
    else
        overlapRatio = visionBboxIntersectByMin(bboxA, bboxB);
    end
end
end

%--------------------------------------------------------------------------
function iou = iOverlapRatioRotatedRect(bboxA, bboxB, ratioType, isCodegen)

if isCodegen
    % codgen not supported for rotated rectangles. 
    iou = zeros(size(bboxA,1),size(bboxB,1),'like',bboxA);
else
    % Convert to box vertices.
    [xa,ya] = vision.internal.bbox.bbox2poly(bboxA);
    [xb,yb] = vision.internal.bbox.bbox2poly(bboxB);
    
    [xaLim,yaLim] = iLimits(xa,ya);
    [xbLim,ybLim] = iLimits(xb,yb);
    [xlim ,ylim ] = iLimits([xaLim xbLim],[yaLim ybLim]);
    
    if strncmpi(ratioType, 'Union', 1)
        iou = visionRotatedBBoxIntersectByUnion(xa,ya,xb,yb,xlim,ylim);
    else
        iou = visionRotatedBBoxIntersectByMin(xa,ya,xb,yb,xlim,ylim);
    end

    
end
end

%--------------------------------------------------------------------------
function [xlim,ylim] = iLimits(x,y)
xlim = [min(x,[],'all') max(x,[],'all')];
ylim = [min(y,[],'all') max(y,[],'all')];
end

%--------------------------------------------------------------------------
function checkSameBoxFormat(bboxA,bboxB)
if ~isempty(bboxA) && ~isempty(bboxB)
if size(bboxA,2) ~= size(bboxB,2)
    error(message('vision:bbox:boxFormatMustMatch'));
end
end
end

%--------------------------------------------------------------------------
function checkInputBoxes(bbox)
% Validate the input boxes

validateattributes(bbox,{'uint8', 'int8', 'uint16', 'int16', 'uint32', ...
    'int32', 'single', 'double'}, {'real','nonsparse','finite','2d'}, ...
    mfilename);

if ~isempty(bbox)
if ~any(size(bbox,2) == [4 5])
   error(message('vision:bbox:invalidBoxFormat'));
end

if (any(bbox(:,3)<=0) || any(bbox(:,4)<=0))
    error(message('vision:visionlib:invalidBboxHeightWidth'));
end
end
end

%-------------------------------------------------------------------------- 
function checkRatioType(value)
% Validate the input ratioType string

list = {'Union', 'Min'};
validateattributes(value, {'char','string'}, {'nonempty'}, mfilename, 'RatioType');

validatestring(value, list, mfilename, 'RatioType');
end

%--------------------------------------------------------------------------
function [bboxA, bboxB, ratioType] = validateAndParseInputs(bboxA,bboxB,varargin)
% Validate and parse optional inputs

% Setup parser
parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = mfilename;

parser.addRequired('bboxA', @checkInputBoxes);
parser.addRequired('bboxB', @checkInputBoxes);
parser.addOptional('RatioType', 'Union', @checkRatioType);

% Parse input
parser.parse(bboxA,bboxB,varargin{:});

bboxA = parser.Results.bboxA;
bboxB = parser.Results.bboxB;
ratioType = char(parser.Results.RatioType);

checkSameBoxFormat(bboxA, bboxB);
            
end

%--------------------------------------------------------------------------
function checkInputBoxesCodegen(bbox)
% Validate the input boxes
if size(bbox,2) ~= 4
    error(message('vision:bbox:codegenSupportsAxisAlignedOnly'));
end

validateattributes(bbox,{'uint8', 'int8', 'uint16', 'int16', 'uint32', ...
    'int32', 'single', 'double'}, {'real','nonsparse','finite','size',[NaN, 4]}, ...
    mfilename);

coder.internal.errorIf((any(bbox(:,3)<=0) || any(bbox(:,4)<=0)), ...
                        'vision:visionlib:invalidBboxHeightWidth');
end

%--------------------------------------------------------------------------
function [bboxA, bboxB, ratioType] = validateAndParseInputsCodegen(bboxA,bboxB,varargin)
% Validate and parse optional inputs

eml_lib_assert(nargin >= 2, 'vision:visionlib:NotEnoughArgs', 'Not enough input arguments');
eml_lib_assert(nargin <= 3, 'vision:visionlib:TooManyArgs', 'Too many input arguments.');

checkInputBoxesCodegen(bboxA);
checkInputBoxesCodegen(bboxB);

if nargin == 3
    ratioType = varargin{1};
    validateattributes(ratioType, {'char'}, {'nonempty'}, mfilename, 'ratioType');
    validatestring(ratioType, {'Union', 'Min'}, mfilename, 'ratioType');
else
    ratioType = 'Union';
end

end

%-------------------------------------------------------------------------- 
function overlapRatio = bboxOverlapRatioCodegen(bboxA, bboxB, ratioType)
% Compute the overlap ratio between every row in bboxA and bboxB

% left top corner
x1BboxA = bboxA(:, 1);
y1BboxA = bboxA(:, 2);
% right bottom corner
x2BboxA = x1BboxA + bboxA(:, 3);
y2BboxA = y1BboxA + bboxA(:, 4);

x1BboxB = bboxB(:, 1);
y1BboxB = bboxB(:, 2);
x2BboxB = x1BboxB + bboxB(:, 3);
y2BboxB = y1BboxB + bboxB(:, 4);

% area of the bounding box
areaA = bboxA(:, 3) .* bboxA(:, 4);
areaB = bboxB(:, 3) .* bboxB(:, 4);

overlapRatio = zeros(size(bboxA,1),size(bboxB,1), 'like', bboxA);

for m = 1:size(bboxA,1)
    for n = 1:size(bboxB,1)
        % compute the corners of the intersect
        x1 = max(x1BboxA(m), x1BboxB(n));
        y1 = max(y1BboxA(m), y1BboxB(n));
        x2 = min(x2BboxA(m), x2BboxB(n));
        y2 = min(y2BboxA(m), y2BboxB(n));

        % skip if there is no intersection
        w = x2 - x1;
        if w <= 0
            continue;
        end
        
        h = y2 - y1;
        if h <= 0
            continue;
        end
        
        intersectAB = w * h;
        if strncmpi(ratioType, 'Union', 1) % divide by union of bboxA and bboxB
            overlapRatio(m,n) = intersectAB/(areaA(m)+areaB(n)-intersectAB);
        else % divide by minimum of bboxA and bboxB
            overlapRatio(m,n) = intersectAB/min(areaA(m), areaB(n));
        end
    end
end

end
