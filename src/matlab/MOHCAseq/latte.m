function [P, P_err] = latte(rin, rinbg)
if ischar(rin) & ~isstruct(rin)
	r = read_rdat_file(rin);
else 
	r = rin;
end
if ~exist('rinbg')
	rbg = -1;
else
	if ischar(rbgin) & ~isstruct(rbgin)
		rbg = read_rdat_file(rbgin);
	else 
		rbg = rbgin;
	end
end

data = r.reactivity;
[epsilon, alpha, gamma] = calculate_background_vars(data, rbg);
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

function [epsilon, alpha, gamma]  = calculate_background_vars(data, rbg)
epsilon = zeros(size(data, 1));
alpha = zeros(size(data, 1));
gamma = zeros(size(data, 1));
if rbg ~= -1
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
	alpha(:) = 0.1;
	epsilon(:) = 0.1;
end
gamma = 0.01*epsilon;
epsilon = 0.9*epsilon;
alpha = 0.5*alpha;
gamma(gamma == 0) = 1e-10;
epsilon(epsilon == 0) = 1e-10;
alpha(alpha == 0) = 1e-10;
end


