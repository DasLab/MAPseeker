function [D_correct, D_correct_err] = determine_corrected_reactivity(  D  );

if iscell( D )
  for j = 1 : length( D )
    [D_correct{j}, D_correct_err{j}] = get_corrected_reactivity( D{j} );
  end
else
  [D_correct, D_correct_err] = get_corrected_reactivity( D );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [D_correct, D_correct_err] = get_corrected_reactivity(  D  );

D(:,1) = D(:,1) + 0.0001; % prevent NaN
D_cumsum = cumsum(D, 2);
D_correct = D ./ D_cumsum;
D_correct_err = sqrt(D) ./ D_cumsum; % ignores error in denominator, which is correlated with error in numerator in a funny way that I need to work out.
