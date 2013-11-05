function [A, A_err] = get_Q_over_R_attenuation_matrix( R, B, Q, Q_err, rho );

N = length( R );
A = ones(N,N);
A_err2 = zeros(N,N);
for i = 1:N
  for j = i:N

    %if R(i) == 0; continue; end;

    for k = (i+1):(j-1)
      A(i,j)      = A(i,j) * exp( - (rho  * Q(i,k)) / ( R(i) + Q(i,j)/B(j)) );    
      A_err2(i,j) = A_err2(i,j) + ( rho  * Q_err(i,k)/R(i) )^2;
    end
      
  end
end

A_err = max(A .* sqrt( A_err2 ),0);