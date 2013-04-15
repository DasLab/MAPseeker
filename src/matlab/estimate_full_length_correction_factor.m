function alpha = estimate_full_length_correction_factor( signal, background, sequence, reference_sequence );
%
% alpha = estimate_full_length_correction_factor( signal, background, sequence, reference_sequence );
%
%
%
% signal     = raw counts for modification pattern for RNA with reference hairpins. The first position should
%                correspond to the fully extended primer.
% background = raw counts for 'no modification' control.
% sequence   = sequence of RNA.
% reference_sequence = [optional] sequence of reference segment, which needs to be repeated exactly twice
%                      in the full RNA sequence. Default is 'GAGUA'.
%

if ~exist( 'reference_sequence', 'var' ) reference_sequence = 'GAGUA'; end
   
gp = strfind( sequence, reference_sequence );
alpha = 0.0;
if length( gp ) ~= 2; fprintf( 'Did not find exactly two copies of %s in reference sequence!!\n', reference_sequence ); return; end;

% note offset by one, since first site in signal or background is '0'.
first_reference_bins  = gp(1) + [ 1: length( reference_sequence )];
second_reference_bins = gp(2) + [ 1: length( reference_sequence )];

%p0 = [0.01:0.01:1];
%for i = 1:length(p0)
%  x(i) = reference_sequence_deviation( p0(i), signal, background, first_reference_bins, second_reference_bins );
%end
%plot( p0, x );

p = fminbnd( 'reference_sequence_deviation', 0, 1.0, [], signal, background, first_reference_bins, second_reference_bins );
alpha = p;

[dev2,d,signal_corrected,background_corrected] = reference_sequence_deviation( alpha, signal, background, first_reference_bins, second_reference_bins );

subplot(2,1,1);
plot( 1:length( signal ), signal, 'r', 'linew',2); hold on
plot( 1:length( signal ), background, 'b', 'linew',2); hold off
ymax = max( [signal(2:end) background(2:end)] );
ylim( [-ymax*0.1, ymax*1.1] );

subplot(2,1,2);
plot( 1:length( signal ), signal_corrected, 'r', 'linew',2); hold on
plot( 1:length( signal ), background_corrected, 'b', 'linew',2); 
plot( 1:length( signal ), d, 'k', 'linew',2); 
area( first_reference_bins, d( first_reference_bins), 'facecolor', [0.5 0.5 0.5] );
area( second_reference_bins, d( second_reference_bins), 'facecolor', [0.5 0.5 0.5] );
ymax = max( [signal_corrected(2:end) background_corrected(2:end)] );
ylim( [-ymax*0.1, ymax*1.1] );
hold off