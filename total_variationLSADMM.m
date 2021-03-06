function [x, history] = total_variationLSADMM(b, lambda, rho,r,alpha)
% total_variation  Solve total variation minimization via LSADMM
%
% [x, history] = total_variation(b, lambda, rho, alpha)
%
% Solves the following problem via LSADMM:
%
%   minimize  (1/2)||x - b||_2^2 + lambda * sum_i |x_{i+1} - x_i|
%
%OR minimize  (1/2)||y - b||_2^2 + lambda * ||Dy||_1
% where b in R^n.
%    Let x-Dy=0
%   Langrange(x,z)=1/2*|| y - b ||_2^2 + \lambda ||x||_1 - u^T(x-Dy) + rho/2*|| x - Dy ||_2^2
%
% solution of x-subproblem
% x=shrinkage(D*y+u/rho,lambda/rho);
%
% solution of y-subproblem
% y=1/(1+tau*r)*(b+y+1/(tau*r)*q);
% where
% r>rho||A^TA|| and tau\in[0.8,1) and q=-D'*（u-rho*(x-D*y)）
%
%updating of multiplier u
%u=u-rho*(x-D*y);

%
% history is a structure that contains the objective value, the primal and
% dual residual norms, and the tolerances for the primal and dual residual
% norms at each iteration.
%
% rho is the augmented Lagrangian parameter.
%
% alpha is the over-relaxation parameter (typical values for alpha are
% between 1.0 and 1.8).
%
%
% More information can be found in the paper linked at:
% http://www.stanford.edu/~boyd/papers/distr_opt_stat_learning_admm.html
%
tau=1;%因为是ADMM，所以tau相当于没有
t_start = tic;
%% Global constants and defaults

QUIET    = 0;
MAX_ITER = 1000;
ABSTOL   = 1e-4;
RELTOL   = 1e-2;
%% Data preprocessing

n = length(b);

% difference matrix
e = ones(n,1);
D = spdiags([e -e], 0:1, n,n);
%% ADMM solver

x = zeros(n,1);
z = zeros(n,1);
u = zeros(n,1);



I = speye(n);


for k = 1:MAX_ITER
    
    % x-update
    x=shrinkage(D*z+u/rho,lambda/rho);
    
    
    % u-update
    u=u-alpha*rho*(x-D*z);
    % z-update with relaxation
    zold = z;
    q=-D' * (u-rho*(x-D*z));
    z=1/(1+tau*r)*(b+z+1/(tau*r)*q);
    
    % u-update
    u=u-rho*(x-D*z);
    
    
    % diagnostics, reporting, termination checks
    history.objval(k)  = objective(b, lambda,  x, z);
    % history.primalDualError
    history.r_norm(k)  = norm(x - D*z);
    history.s_norm(k)  = norm(-rho*D'*(z - zold));
    
    history.eps_pri(k) = sqrt(n)*ABSTOL + RELTOL*max(norm(x), norm(D*z));
    history.eps_dual(k)= sqrt(n)*ABSTOL + RELTOL*norm(u);

    
    if (history.r_norm(k) < history.eps_pri(k) && ...
            history.s_norm(k) < history.eps_dual(k))
        history.iteration=k;
        history.time=toc(t_start);
        break;
    end
end

end

function obj = objective(b, lambda, x, y)
obj = .5*norm(y - b)^2 + lambda*norm(x,1);
end

function y = shrinkage(a, kappa)
y = max(0, a-kappa) - max(0, -a-kappa);
end
