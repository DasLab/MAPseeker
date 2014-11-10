function [Pi, B, R] = lahtte(rraw, rreact, step_size)

% [Pi, B, R] = lahtte( rraw, rreact, step_size );
%
% LAHTTE (likelihood analysis of hydroxyl-induced tertiary contact
% estimation). This analysis optimizes the MOHCA 'master likelihood
% function' using stochastic gradient ascent.
%
% INPUT:
%  
%  rraw      = The raw count data,can be a string representing an rdat
%              filename or an rdat object.
%  
%  rreact    = The reactivities that will be used as a starting point for
%              the optimization routine. Also can be a string representing an rdat
%              filename or an rdat object.
%  
%  step_size = Optional, default is 1e-4. Adjust if convergence is too
%              slow, or too fast.
%
% OUTPUT:
%  Pi        = Probability matrix of source/cleavage (i.e. the 'contact
%              map'). This matrix is made symmetric.
%  R         = 1D stop probability
%  B         = 1D cleavage probability
%
% (C) Das lab, Stanford, 2013
if ischar(rraw)
	raw = read_rdat_file(rraw);
    react = read_rdat_file(rreact);
    fprintf(1, '\nReading RDAT file\n');
else 
	raw = rraw;
    react = rreact;
    fprintf(1, '\nReceived RDAT variable\n');
end
if ~exist('step_size')
    step_size = 1e-4;
end

data = raw.reactivity;
reacts = react.reactivity;
mindim = min(min(size(data)), min(size(reacts)));
data = data(1:mindim, 1:mindim);
reacts = reacts(1:mindim, 1:mindim);

data = symmetric(data);
reacts = symmetric(reacts);

max_iterations=5;
tol = 1e-5;
rho = 1.0;
epsilon = ones([size(data,1), 1]);

[Pi_0, B_0, R_0]  = initialize_vars(reacts);
[Pi, B, R] = sga(data, Pi_0, B_0, R_0, epsilon, rho, max_iterations, step_size, tol);

%x0 = to_flat_x(Pi_0, B_0, R_0);

% lb = zeros(1, prod(size(x0)));
% opts = optimset('Algorithm','interior-point');
% problem = createOptimProblem('fmincon','objective',...
%  @(x) loglike_wrapper(x, rho, epsilon, data) ,'x0',x0,'lb',lb,'options',opts);
% gs = GlobalSearch;
% [x_opt,f] = run(gs,problem);
% [Pi, B, R] = from_flat_x(x_opt, size(data,1));
figure(4)
plot_pi(Pi)
colormap(1-gray);
title('Final')
end



function [Pi_curr, B_curr, R_curr] = sga(data, Pi_0, B_0, R_0, epsilon, rho, max_iterations, step_size, tol)
% A simple stochastic gradient ascent algorithm
Pi_curr = Pi_0;
B_curr = B_0;
R_curr = R_0;



n = size(data,2)-1;
for iter=1:max_iterations
    fprintf(1, 'On round %d\n', iter);
    indices = randperm(n^2);
    jj = 1;
    ii = 0;
    figure(1)
    plot_pi(Pi_curr)
    colormap(1-gray)
    sidx = 0;
    for idx=indices
        ii = ii + 1;
        sidx = sidx + 1;
        if ii == 100
            fprintf(1, 'Sample %d\n', sidx);
            jj = jj + 1;
            figure(2)
            plot_pi(Pi_curr);
            colormap(1-gray);
            title('Pi')
            figure(3)
            subplot(2,1,1);           
            plot(B_curr);
            title('B')
            subplot(2,1,2);          
            plot(R_curr);
            title('R')
            ii = 0;
            step_size = step_size/1.5;
            if crit < tol
                break
            end
            %logl = loglike(Pi_curr, B_curr, R_curr, rho, epsilon, data)
        end
        i = mod(idx, n) + 1;
        j = floor(idx/n) + 1;

        %fprintf(1, 'Doing counts in index %d, for positions %d, %d\n', idx, i, j);
        [P, Q] = calculate_P_and_Q(Pi_curr, B_curr, R_curr, rho);
        Fij = calculate_F(P, Q, epsilon, i, j);
        if sum(Fij) == 0
            continue
        end
        Pi_prev = Pi_curr;
        B_prev = B_curr;
        R_prev = R_curr;
        % Do Pi
        Pi_curr = Pi_prev + step_size*Pi_gradient(data, P, Q, Pi_prev, B_prev, R_prev, epsilon, rho, Fij, i, j);
        % Do B
        B_curr = B_prev + step_size*B_gradient(data, P, Q, Pi_prev, B_prev, R_prev, epsilon, rho, Fij, i, j);
        % Do R
        R_curr = R_prev + step_size*R_gradient(data, P, Q, Pi_prev, B_prev, R_prev, epsilon, rho, Fij, i, j);

        
        % Enforce non-negativity
        %Pi_curr = abs(Pi_curr);
        %B_curr = abs(B_curr);
        %R_curr = abs(R_curr);
        Pi_curr(Pi_curr <= 0) = 1e-5;
        Pi_curr = symmetric(Pi_curr);
        B_curr(B_curr <= 0) = 1e-5;
        R_curr(R_curr <= 0) = 1e-5;
        
        Pi_curr(Pi_curr >= 1) = 0.99;
        B_curr(B_curr >= 1) = 0.99;
        R_curr(R_curr >= 1) = 0.99;
        crit = max(max(abs(Pi_curr - Pi_prev)));

    end
    if crit < tol
        break
    end
end
end
     

function [Pi_0, B_0, R_0] = initialize_vars(reacts)
Pi_0 = reacts;
% Normalize the 'reactivities' first, row-wise
for i=1:size(Pi_0, 1)
    nf = sum(Pi_0(i,i+1:end));
    if nf > 0
        Pi_0(i,i+1:end) = min(0.99, Pi_0(i,i+1:end)/nf);
    end
end
Pi_0 = symmetric(Pi_0);
B_0 = mean(Pi_0,1);
B_0 = ( B_0 )/ max(B_0);
B_0(B_0 <= 0) = 1e-5;
B_0(B_0 >= 1) = 0.99;
R_0 = B_0;
%B_0 = zeros([size(reacts,1),1]) + 0.1;
%R_0 = zeros([size(reacts,1),1]) + 0.1;
Pi_0(Pi_0 <= 0) = 1e-5;

end

function res = Pi_gradient(data, P, Q, Pi, B, R, epsilon, rho, Fij, i, j)
res = zeros(size(Pi));
for ip=1:size(Pi,1)
    for s=i+1:size(Pi,2)
        if s >= j
            Fgij = calculate_Fgrad_Pi(P, Q, B, R, rho, Fij, i, j, ip, s);
            res(ip,s) = data(i,j)*Fgij/sum(Fij) - Fgij;
        end
    end
end 
end

function B = B_gradient(data, P, Q, Pi, B, R, epsilon, rho, Fij, i, j)
for ip=1:size(B,1)
    Fgij = calculate_Fgrad_B(P, Q, Pi, rho, Fij, j, ip);
    B(ip) = data(i,j)*Fgij/sum(Fij) - Fgij;
end
end

function R = R_gradient(data, P, Q, Pi, B, R, epsilon, rho, Fij, i, j)
for ip=1:size(R,1)
    Fgij = calculate_Fgrad_R(P, Q, Pi, rho, Fij, i, ip);
    R(ip) = data(i,j)*Fgij/sum(Fij) - Fgij;
end
end

function [P, Q] = calculate_P_and_Q(Pi, B, R, rho)
P = zeros(size(Pi));
Q = zeros(size(Pi));
for i=1:size(P,1)
    for s=1:size(P,2)
        P(i,s) = (1-R(i))*(1-rho*Pi(i,s));
        Q(i,s) = (1-B(i))*(1-Pi(i,s));
        if P(i,s) <= 0 || P(i,s) >= 1
            R(i)
            Pi(i,s)
            P(i,s)
            pause
        end
        P(s,i) = P(i,s);
        Q(s,i) = Q(i,s);
    end
end
% P(P <= 0) = 1e-5;
% Q(Q <= 0) = 1e-5;
% P(P >= 1) = 0.99;
% Q(Q >= 1) = 0.99;
end

function F = calculate_F(P, Q, epsilon, i, j)
F = zeros([1,size(P,2)]);
lb = min(i,j);
up = max(i,j);
for s=1:size(P,2)
    if s <= lb || s >= up
        pprod =  P(i,s)*Q(j,s)*epsilon(s);
        for ip=i+1:j
            pprod = pprod * (1-P(ip,s));
        end
        F(s) = pprod;
    end
end
end

function Fg = calculate_Fgrad_Pi(P, Q, B, R, rho, Fij, i, j, ip, s)
if ip == i
    Fg = Fij(s)/P(ip,s);
    Fg = Fg*(1-R(ip))*rho;
elseif ip == j
    Fg = (Fij(s)/Q(ip,s));
    Fg = Fg*(1-B(ip));
else
    Fg = Fij(s)/(1-P(ip,s));
    Fg = Fg*(1-R(ip))*(-rho);
end
end

function Bg = calculate_Fgrad_B(P, Q, Pi, rho, Fij, j, ip)
Bg = 0;
if ip == j
    for s=1:size(P,2)
        if s >= j
            tmp = (Fij(s)/Q(ip,s))/P(ip,s);
            Bg = Bg + tmp*(1-Pi(ip,s));
        end
    end
else
    Bg = 0;
end
end

function Rg = calculate_Fgrad_R(P, Q, Pi, rho, Fij, i, ip)
Rg = 0;
if ip == i
    for s=1:size(P,2)
        if s <= i
        tmp = Fij(s)/P(ip,s);
        Rg = Rg + tmp*(1-rho*Pi(ip,s));
        end
    end
else
    for s=1:size(P,2)
        if s <= i
        tmp = Fij(s)/(1-P(ip,s));
        Rg = Rg + tmp*(-(1-rho*Pi(ip,s)));
        end
    end
end
end

function D = symmetric(D)
for i=1:size(D, 1)
    for j=i+1:size(D, 2)
        D(j,i) = D(i,j);
    end
end
end

function x = to_flat_x(Pi, B, R)
x = zeros(1,prod(size(Pi)) + prod(size(B)) + prod(size(R)));
ii = 1;
for i=1:size(Pi,1)
    for j=1:size(Pi,2)
        x(ii) = Pi(i,j);
        ii = ii + 1;
    end
end
for i=1:size(Pi,1)
    x(ii) = B(i);
    ii = i + 1;
    x(ii) = R(i);
    ii = i + 1;
end
end

function [Pi, B, R] = from_flat_x(x, n)
Pi = zeros(n);
B = zeros(n,1);
R = zeros(n,1);
ii = 1;
for i=1:size(Pi,1)
    for j=1:size(Pi,2)
        Pi(i,j) = x(ii);
        ii = ii + 1;
    end
end
for i=1:size(Pi,1)
    B(i) = x(ii);
    ii = i + 1;
    R(i) = x(ii);
    ii = i + 1;
end
end

function ll = loglike(Pi, B, R, rho, epsilon, data)
[P, Q] = calculate_P_and_Q(Pi, B, R, rho);
ll = 0;
for i=1:size(data,1)
    for j=1:size(data,2)
        if data(i,j) ~= 0
            Fij = calculate_F(P, Q, epsilon, i, j);
            ll = ll + data(i,j)*log(sum(Fij)) - sum(Fij);
        end
    end
end
end

function ll = loglike_wrapper(x, rho, epsilon, data)
[Pi, B, R] = from_flat_x(x, size(data,1));
ll = -loglike(Pi, B, R, rho, epsilon, data)
end

function ll = loglike_grad(Pi, B, R, rho, epsilon, data)
delta = 0.1;
llplus = loglike(Pi + delta, B + delta, R + delta, rho, epsilon, data)
llminus = loglike(Pi - delta, B - delta, R - delta, rho, epsilon, data)
ll = (llplus - llminus)/2*delta;
end

function plot_pi(Pi)
iptsetpref('ImshowAxesVisible','on');
imshow(Pi, [0, mean2(Pi) + std2(Pi)]);
end
        