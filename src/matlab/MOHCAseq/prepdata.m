function D_filter = prepdata( D, D_err, filt, diff, noscale )

% Automated data preparation for 2D MOHCA-style plots:
%       1. Filter by signal-to-noise
%       2. Apply 2D smoothing
%       3. Scale data
%
% INPUT:
%       D       = Data matrix
%       D_err   = Error matrix
%       filt    = Signal-to-noise threshold for filtering
%       diff    = For data with negative values, enter 1 for difference maps
%       noscale = Specify not to scale data
%
% Clarence Cheng, 2014

if ~exist( 'filt', 'var' ); filt = 1; end
if ~exist( 'diff', 'var' ); diff = 0; end

if ~exist( 'noscale', 'var' )
    noscale = 0;
else
    noscale = 1;
end

D_filter = D;
if diff == 0
        % filter points with signal-to-noise < 1
    D_filter( find( (D./D_err) < filt ) ) = 0.0;  
elseif diff == 1
    D_abs = abs(D);
    D_filter( find( (D_abs./D_err) < filt ) ) = 0.0;
end
    % apply 2D smoothening
D_filter = smooth2dNaN( D_filter );
    % auto scale
if noscale == 1
else
    scalefactor = (1/5)/mean(mean(max(D_filter,0)));
    D_filter = D_filter * scalefactor;
end
    % remove smoothening artifacts from diagonal
for i = 1:size(D_filter,1)
    for j = 1:size(D_filter,2)
        if j-2 <= i
            D_filter(i,j) = 0;
        else
        end
    end
end