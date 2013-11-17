function h = leasqr_q_hess( params, lambda );

global global_leasqr_Q_hess; % note that this requires running leasqr_Q.m first.
h = global_leasqr_Q_hess;