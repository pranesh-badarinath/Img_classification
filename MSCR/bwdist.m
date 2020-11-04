function varargout = bwdist(varargin)
[BW,method] = parse_inputs(varargin{:});

% Computing the nearest-neighbor transform is expensive in memory, so we
% only want to call the lower-level function ddist with two output
% arguments if we have been called with two output arguments. Also, for the
% Euclidean case, bwdistComputeEDTFT will be called instead of
% bwdistComputeEDT, when there are two output arguments.
if nargout <= 1
    varargout = cell(1,1);
else
    varargout = cell(1,2);
end

if strcmp(method,'euclidean')
    % Use fast methods for multidimensional Euclidean distance
    % transforms and Euclidean closest feature transforms.
    if (nargout == 2)
        numOfElements = numel(BW);
        if(numOfElements <= intmax('uint32'))
            outType = uint32(1);
        else
            outType = uint64(1);
        end
        [D, IDX] = builtin('_bwdistComputeEDTFT', BW, outType);
        varargout{1} = sqrt(D);
        varargout{2} = IDX;
    else
        D = builtin('_bwdistComputeEDT', BW);
        varargout{1} = sqrt(D);
    end
else
    % All methods other than Euclidean use the same algorithm,
    % implemented in private/ddist.  The only difference is in the
    % connectivity and weights used.
    [weights,conn] = images.internal.computeChamferMask(ndims(BW),method);

    % Postprocess the weights to make sure the center weight is
    % zero.
    weights((end+1)/2) = 0.0;

    % Call the dual-scan neighborhood based algorithm.
    [varargout{:}] = builtin('_ddist', BW,conn,weights);
end

%--------------------------------------------------

function [BW,method] = parse_inputs(varargin)

narginchk(1,2);
validateattributes(varargin{1}, {'logical','numeric'}, {'nonsparse', 'real'}, ...
              mfilename, 'BW', 1);

BW = varargin{1} ~= 0;

if nargin < 2
    method = 'euclidean';
else
    valid_methods = {'euclidean','cityblock','chessboard','quasi-euclidean'};
    method = validatestring(varargin{2}, valid_methods, ...
                          mfilename, 'METHOD', 2);
end
