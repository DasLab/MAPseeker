function [Dout, Dout_err] = average_data( D1, D2, D1_err, D2_err );

% average, weighted by inverse errors.
Dout = (D1./D1_err.^2) + (D2./D2_err.^2);
Dout_err = 1./( 1./D1_err.^2   + 1./D2_err.^2 );
% divide by weights
Dout = Dout .* Dout_err;
Dout_err = sqrt( Dout_err );
