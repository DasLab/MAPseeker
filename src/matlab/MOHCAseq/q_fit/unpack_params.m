function D_unpack = unpack_params( params_out, N, left_right_idx )

D_unpack = ones(N,N) * nan;
for i = 1:length(params_out);  
  D_unpack(left_right_idx(1,i), left_right_idx(2,i)) = params_out(i); 
end;
