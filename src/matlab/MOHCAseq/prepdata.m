function D_filter = prepdata( D, D_err, filt, smooth, scale, diff )

% Automated data preparation for 2D MOHCA-style plots:
%       1. Filter by signal-to-noise
%       2. Apply 2D smoothing
%       3. Scale data
%
% INPUT:
%       D       = Data matrix
%       D_err   = Error matrix
%       filt    = Signal-to-noise threshold for filtering
%       smooth  = Perform smoothing or not; default 1 to perform smoothing
%       scale   = Scale data or not; default 1 to perform scaling
%       diff    = For data with negative values; enter 1 for difference maps
%
% Clarence Cheng, 2014

if ~exist( 'filt', 'var' ); filt = 1; end
if ~exist( 'smooth', 'var' ); smooth = 1; end
if ~exist( 'scale', 'var' ); scale = 1; end
if ~exist( 'diff', 'var' ); diff = 0; end

D_filter = D;
if diff == 0
        % filter points with signal-to-noise < 1
    D_filter( find( (D./D_err) < filt ) ) = 0.0;  
elseif diff == 1
    D_abs = abs(D);
    D_filter( find( (D_abs./D_err) < filt ) ) = 0.0;
end
    % apply 2D smoothing
if smooth == 0
else
    D_filter = smooth2dNaN( D_filter );
end
    % auto scale
if scale == 1
    scalefactor = (1/5)/mean(mean(max(D_filter,0)));
    D_filter = D_filter * scalefactor;
% else
end
    % remove smoothing artifacts from diagonal
for i = 1:size(D_filter,1)
    for j = 1:size(D_filter,2)
        if j-2 <= i
            D_filter(i,j) = 0;
        else
        end
    end
end