function x_smooth = smooth2dNaN( x, niter );
if ~exist( 'niter' )  niter = 2; end
B = [ 0 0.1 0; 0.1 0.6 0.1; 0 0.1 0];
x_smooth = nanconv( x, B, 'noedge', 'nanout' );

for  n = 1:niter-1;  
  x_smooth = nanconv( x_smooth, B, 'noedge', 'nanout' );
end