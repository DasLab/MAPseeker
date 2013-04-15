function  classification = classify_signal_to_noise_ratio( SN_ratio );

classification = 'N/A';

if ( SN_ratio == 0 )
  classification = 'N/A';
elseif ( SN_ratio  <  1 )
  classification = 'poor';
elseif ( SN_ratio < 5 )
  classification = 'moderate';
elseif ( SN_ratio < 10 )
  classification = 'good';
else
  classification = 'high';
end