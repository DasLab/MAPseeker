function [D_correct, D_correct_err] = get_corrected_reactivity(  D, full_extension_correction_factor  );
% [D_correct, D_correct_err] = get_corrected_reactivity(  D, full_extension_correction_factor  );

if nargin==0; help( mfilename ); return; end;

D(1,:) = D(1,:) + 0.0001; % prevent NaN
D(1,:) = D(1,:) / full_extension_correction_factor;
D_cumsum = cumsum( D );
D_correct = D ./ D_cumsum;

% ignores error in denominator, which is assumed to be much larger than numerator, and to have
% significantly less (statistical) fractional error than numerator.
% padding with 1 count to determine error (this is kind of a 'prior' on bins with no counts)
D_correct_err = ( sqrt(D) + 1)./ D_cumsum; 

