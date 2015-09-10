function Dynamics(nsteps,dt,nprint,maxit,tol,relax,damp,nsd,ned,nen,materialprops,gravity,nn,coords,nel,connect,no_bc1,bc1,no_bc2,bc2)
%% MAIN FEM ANALYSIS PROCEDURE 
% Augmented Lagrangian Method is NOT used in this code

% Newmark parameters
gamma = 0.5;
beta = 0.25;

% initialization
w = zeros(ned*nn,1);
un = zeros(nn*ned,1);
vn = zeros(nn*ned,1);
vxy = zeros(2,nsteps);

% write ensight case and original values
write_results(nsteps,nprint,dt,nsd,ned,nn,coords,nel,nen,connect,materialprops,w,0);

% mass matrix and external force vector are constant
M = mass(nsd,ned,nn,coords,nel,nen,connect,materialprops);
Fext = externalforce(nsd,ned,nn,nel,nen,no_bc2,materialprops,gravity,coords,connect,bc2);

% initial Fint
Fint = internalforce(nsd,ned,nn,coords,nel,nen,connect,materialprops,w);
F = Fext - Fint;

% in order to get an right, need to modify
for i=1:no_bc1
    row = ned*(bc1(1,i)-1) + bc1(2,i);
    for col=1:nn*ned
        M(row,col) = 0.;
        M(col,row) = 0.;
    end
        M(row,row) = 1.;
        F(row) = 0.;
end

% initial acceleration
an = M\F;

count = 0;
for n = 1:nsteps
    err1 = 1.;
    err2 = 1.;
    nit = 0;
    % let the external traction go after the first time step
    %if n == 2 Fext = Fbody; end  
    w = un;
    while (((err1>tol)||(err2>tol)) && (nit<maxit))
        nit = nit + 1;
        an1 = (w - (un+dt*vn+0.5*dt^2*(1-2*beta)*an))/(beta*dt^2);
        vn1 = vn + (1-gamma)*dt*an + gamma*dt*an1;
        
        K = Kint(nsd,ned,nn,coords,nel,nen,connect,materialprops,w);
        Fint = internalforce(nsd,ned,nn,coords,nel,nen,connect,materialprops,w);
        F = Fext - Fint - damp*vn1;
        R = M*an1 - F; 
        % modify to get A and R right
        for i=1:no_bc1
            row = (bc1(1,i)-1)*ned + bc1(2,i);
            for col=1:nn*ned 
                K(row,col)=0.;
                K(col,row)=0.;
            end
            K(row,row)=1-1./(beta*dt^2);
            R(row) = w(row) - bc1(3,i);
        end
        % Jacobian
        A = (M+damp*gamma*dt*eye(nn*ned))/(beta*dt^2) + K;       
        % solve for the correction
        dw = -A\R;
        % check for convergence
        w = w + relax*dw;
        wnorm = dot(w,w);
        err1 = dot(dw,dw);
        err2 = dot(R,R);
        err1 = sqrt(err1/wnorm);
        err2 = sqrt(err2)/(ned*nn);
    end
    fprintf('End of time step %6d, iterated %2d times, err1 = %12.5e, err2 = %12.5e\n',n,nit,err1,err2);
    % once converged, we have un1, which is w, then update
    vn = vn1;
    un = w;
    an = an1;
    vxy(1,n) = n*dt;
    vxy(2,n) = un(2*nn);
    
    % write output files
    if mod(n,nprint)==0
        write_results(nsteps,nprint,dt,nsd,ned,nn,coords,nel,nen,connect,materialprops,w,n/nprint);
    end
    
    %
    % plotting mesh every nprint steps
    if count == nprint
        defcoords = zeros(nsd,nn);
        for i = 1:nsd
            for j = 1:nn
                defcoords(i,j) = coords(i,j) + un((j-1)*ned+i);
            end
        end
        clf
        axis([0,11,-5.5,5.5])
        plotmesh(defcoords,nsd,connect,nel,nen,'r');
        pause(0.025);
        count = 0;
    end
    count = count + 1;
end
%% plot the displacement in y direction of the end node vs time    
figure
plot(vxy(1,:),vxy(2,:))
xlabel({'Time/s'},'FontSize',16);
ylabel({'End displacement/m'},'FontSize',16);
end