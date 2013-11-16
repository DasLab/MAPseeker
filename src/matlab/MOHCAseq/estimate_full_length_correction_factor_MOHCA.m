function [alpha,gp] = estimate_full_length_correction_factor_MOHCA( D );
% alpha = estimate_full_length_correction_factor_MOHCA( D );
%
% The total number of cleavage products at any position should be roughly constant.
% Estimate scale factor for full-length extenstion products that makes this so.
%
%  D = input data matrix in which first column is full-length extension.
%
% Note: First five and last ten cleavage positions ignored.
%
% (C) R. Das, Nov. 2013

A = D(1,:);
B = sum(D(2:end,:));

%five_prime_inset  = 5;
%three_prime_inset = 10;
%A = A( five_prime_inset : end-three_prime_inset);
%B = B( five_prime_inset : end-three_prime_inset)

[~,~,~,gp] = filter_outliers( B ,3 )
A = A( gp );
B = B( gp );

delA = A - mean(A);
delB = B - mean(B);

alpha = -sum( delA .* delA ) / sum( delA .* delB );