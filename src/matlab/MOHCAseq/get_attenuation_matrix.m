function [A, A_err] = get_attenuation_matrix( R, B, Q, Q_err, rho );

N = length( R );
A = ones(N,N);
A_err2 = zeros(N,N);
for i = 1:N
  for j = i:N

    F_plaid(i,j) = R(i) * B(j);
    F(i,j) = F_plaid(i,j) + Q(i,j);

    for k = (i+1):(j-1)
      A(i,j) = A(i,j) * ( 1 - R(k) );
    end

    F_att(i,j) = F(i,j) * A(i,j);
   
    if B(j) == 0; continue;end;

    for k = (i+1):(j-1)
      A(i,j) = A(i,j) * ( 1 - (rho  * Q(i,k) * B(j)) / F(i,j) );
      A(i,j) = A(i,j) * ( 1 - (R(i) * Q(k,j)) / F(i,j) );
      
      % switch ( 1- x ) to exp(-x) to avoid negative values...
      %A(i,j) = A(i,j) * exp(  - (rho  * Q(i,k) * B(j)) / F(i,j) );
      %A(i,j) = A(i,j) * exp(  - (R(i) * Q(k,j)) / F(i,j) );
    
      A_err2(i,j) = A_err2(i,j) + ( rho  * Q_err(i,k) * B(j)/F(i,j) )^2;
      A_err2(i,j) = A_err2(i,j) + ( R(i) * Q_err(k,j) / F(i,j) )^2;
    end
      
  end
end

A_err = max(A .* sqrt( A_err2 ),0);