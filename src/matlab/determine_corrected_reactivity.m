function [D_correct, D_correct_err] = determine_corrected_reactivity(  D, full_extension_correction_factor  );
%
% [D_correct, D_correct_err] = determine_corrected_reactivity(  D, full_extension_correction_factor  );
%
% D   =  input matrix (each row is an RNA, and each column is site of
%         stop from 0, 1, ... N). Can also be a cell of such matrices.
%
% full_extension_correction_factor
%     =  amount to increase value of counts at site 0. Correction for 
%        empirically observed low ssDNA ligation efficiency by circLigase
%        to 'full-length' complementary DNA created by SSIII.
%        [NOTE!!! Default is 2.0, not 1.0]
%
% Correction formula is exact:
%
%  R(i) = F(i) / [ F(0) + F(1) + ... F(i) ]
%
% i.e. the fraction of reverse transcription that stops at residue i, compared
% to the total number of cDNAs that have been reverse transcribed up to 
% residue i or beyond
%
% (C) R. Das, 2012-2013
% 


if ~exist( 'full_extension_correction_factor' ) full_extension_correction_factor = 2.0; end;

if iscell( D )
  for j = 1 : length( D )
    [D_correct{j}, D_correct_err{j}] = get_corrected_reactivity( D{j}, full_extension_correction_factor );
  end
else
  [D_correct, D_correct_err] = get_corrected_reactivity( D, full_extension_correction_factor );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [D_correct, D_correct_err] = get_corrected_reactivity(  D, full_extension_correction_factor  );

D(:,1) = D(:,1) + 0.0001; % prevent NaN
D(:,1) = D(:,1) * full_extension_correction_factor;
D_cumsum = cumsum(D, 2);
D_correct = D ./ D_cumsum;

% ignores error in denominator, which is assumed to be much larger than numerator, and to have
% significantly less (statistical) fractional error than numerator.
% padding with 1 count to determine error (this is kind of a 'prior' on bins with no counts)
D_correct_err = ( sqrt(D) + 1)./ D_cumsum; 
