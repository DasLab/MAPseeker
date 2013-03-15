function  dev2 = reference_sequence_deviation( p, signal, background, first_reference_bins, second_reference_bins );

alpha = p(1);

signal_corrected     = get_corrected_reactivity( signal, alpha );
background_corrected = get_corrected_reactivity( background, alpha );

d = signal_corrected - background_corrected;

dev = mean( d(first_reference_bins)) - mean(d(second_reference_bins) );

dev2 = dev*dev;