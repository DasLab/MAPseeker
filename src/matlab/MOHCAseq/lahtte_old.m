function [P, P_err] = latte(rin, rinbg)
if ischar(rin)
	r = read_rdat_file(rin);
    fprintf(1, '\nReading RDAT file\n');
else 
	r = rin;
    fprintf(1, '\nReceived RDAT variable\n');
end

if ~exist('rinbg')
	rbg = [];
else
	if ischar(rinbg)
		rbg = read_rdat_file(rinbg);
        fprintf(1, '\nReading background RDAT file\n');
	else 
		rbg = rinbg;
        fprintf(1, '\nReceived background RDAT variable\n');
	end
end

data = r.reactivity;

fprintf(1, '\nDone reading data, starting background sparsity optimization\n');
options = optimset('Display', 'iter-detailed');
xopt = fminsearch(@(x) score_fun(x, data, rbg), [0.05, 0.05], options);
fprintf(1, '\nDone!\n');
[P, P_err] = get_P(data, rbg, xopt(1), xopt(2));


end

function score = score_fun(x, data, rbg)
[P, P_err] = get_P(data, rbg, x(1), x(2));
score = sum(sum(abs(P)));
end

function [P, P_err] = get_P(data, rbg, x, y)
[epsilon, alpha, gamma] = calculate_background_vars(data, rbg, x, y);
P = zeros(size(data));
P_err = zeros(size(data));
A = zeros(size(data));
B = zeros(size(data));
for j=1:size(data,1)
	for i=j+1:size(data,2)
		A(j,i) = epsilon(j)*(1 - gamma(j))*(1 - alpha(j)) - (1 - epsilon(j))*gamma(j)*(1 - alpha(j))*(1 - alpha(i)/(1 - alpha(i)));
		B(j,i) = (1 - epsilon(j))*gamma(j)*(1 - alpha(j))*(1 - alpha(i)/(1 - alpha(i)));
	end
end
for j=1:size(data,1)
	for i=j+1:size(data,2)
		X = max(sum(data(1:j,i)) + sum(data(j,i+1:end)), 1);
		P(j,i) = max(0, abs(data(j,i)*A(j,i) - X*B(j,i))/(2*A(j,i)*X));
		P(j,i) = min(P(j,i), 0.9999);
		P(i,j) = P(j,i);
		C = P(j,i)*epsilon(j)*(1 - gamma(j))*(1 - alpha(j)) - (1 - P(j,i))*(1 - epsilon(j))*gamma(j)*(1 - alpha(j))*(1 - alpha(i)/(1 - alpha(i)));
		if( P(j,i) == 0 )
			P_err(j,i) = 0;
		else
			P_err(j,i) = max(1e-10, X/(1 - P(j,i))^2 - (A(j,i)/C)^2);
			P_err(j,i) = sqrt(1/P_err(j,i));
			P_err(i,j) = P_err(j,i);
		end
	end
end
end

function [epsilon, alpha, gamma]  = calculate_background_vars(data, rbg, x, y, z)
epsilon = zeros(size(data, 1),1);
alpha = zeros(size(data, 1),1);
gamma = zeros(size(data, 1),1);
if ~isempty( rbg )
	background = rbg.reactivity;
	for i=1:size(data,1)
	    for j=i+1:size(data,2)
            alpha(j) = background(i,j);
            epsilon(i) = epsilon(i) + background(i,j);
        end
    end
	epsilon = sum(background, 1)./sum(background);
	epsilon = epsilon./sum(epsilon);
    alpha = alpha./sum(alpha);
else
	alpha(:) = x;
	epsilon(:) = y;
end
gamma = 0.01*epsilon;
epsilon = 0.9*epsilon;
alpha = 0.5*alpha;
gamma(gamma == 0) = 1e-10;
epsilon(epsilon == 0) = 1e-10;
alpha(alpha == 0) = 1e-10;
end


