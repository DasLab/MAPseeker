function  [dev2,d,signal_corrected,background_corrected] = reference_sequence_deviation( p, signal, background, first_reference_bins, second_reference_bins, CORRECT_BACKGROUND );

if ~exist( 'CORRECT_BACKGROUND', 'var' ) CORRECT_BACKGROUND = 1; end;

alpha = p(1);

signal_corrected     = get_corrected_reactivity( signal, alpha );

if CORRECT_BACKGROUND
  background_corrected = get_corrected_reactivity( background, alpha );
else
  background_corrected = get_corrected_reactivity( background );
end

d = signal_corrected - background_corrected;

dev = mean( d(first_reference_bins)) - mean(d(second_reference_bins) );

dev2 = dev*dev;