function [Dout, Dout_err] = average_data( arg1, arg2, arg3, arg4 );
%
% [Dout, Dout_err] = average_data( D1, D2, D1_err, D2_err );
%  where D1, D2 are matrices with the two data sets, and D1_err and D2_err are matrices with corresponding errors.
%
%   or
%
% [Dout, Dout_err] = average_data( all_D, all_D_err );
%  where all_D is a cell with all the matrices to be averaged, and all_D_err is a cell with the corresponding error matrices
%
%

if nargin == 4
  all_D = {arg1, arg2 };
  all_D_err = {arg3, arg4 };
elseif nargin == 2
  all_D = arg1;
  all_D_err = arg2;
else
  help( mfilename );
  return;
end
  
% average, weighted by inverse errors.
Dout = all_D{1} * 0;
Dout_err = Dout * 0;
for m = 1:length (all_D)

  D = all_D{m};
  D_err = all_D_err{m};

  Dout = Dout + (D./D_err.^2);
  Dout_err = Dout_err + ( 1./D_err.^2);

end

% divide by weights
Dout = Dout ./ Dout_err;
Dout_err = 1 ./ sqrt( Dout_err );
