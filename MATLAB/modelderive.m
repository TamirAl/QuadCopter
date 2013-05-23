X = sym('X',[16 1]);
Ts = sym('Ts');
Xdot = sym('X',[16 1]);

am = sym('am', [3 1]);
wm = sym('wm', [3 1]);

q = X(7:10);
w = wm - X(11:13);
a = am - X(14:16);


Omega = [0    -w(1) -w(2) -w(3); ...
         w(1)  0     w(3) -w(2); ...
         w(2) -w(3)  0     w(1); ...
         w(3)  w(2) -w(1)  0];

Xi = [-q(2) -q(3) -q(4); ...
       q(1) -q(4)  q(3); ...
       q(4)  q(1) -q(2); ...
      -q(3)  q(2)  q(1)];
  
%DCM = [1-2*q(3)*q(3)-2*q(4)*q(4) 2*q(2)*q(3)+2*q(4)*q(1) 2*q(2)*q(4)-2*q(3)*q(1);
%       2*q(2)*q(3)-2*q(4)*q(1) 1-2*q(2)*q(2)-2*q(4)*q(4) 2*q(3)*q(4)+2*q(2)*q(1);
%       2*q(2)*q(4)+2*q(3)*q(1) 2*q(3)*q(4)-2*q(2)*q(1) 1-2*q(2)*q(2)-2*q(3)*q(3)];

DCMderiv = [norm(q)^2-2*q(3)*q(3)-2*q(4)*q(4) 2*q(2)*q(3)+2*q(4)*q(1) 2*q(2)*q(4)-2*q(3)*q(1);...
       2*q(2)*q(3)-2*q(4)*q(1) norm(q)^2-2*q(2)*q(2)-2*q(4)*q(4) 2*q(3)*q(4)+2*q(2)*q(1);...
       2*q(2)*q(4)+2*q(3)*q(1) 2*q(3)*q(4)-2*q(2)*q(1) norm(q)^2-2*q(2)*q(2)-2*q(3)*q(3)];

   
Fvqparts = Xi * a;
Fvq = 2 .* [Fvqparts(2) -Fvqparts(1) Fvqparts(4) -Fvqparts(3); ...
            Fvqparts(3) -Fvqparts(4) -Fvqparts(1) Fvqparts(2); ...
            Fvqparts(4) Fvqparts(3) -Fvqparts(2) -Fvqparts(1)];
J = simple(jacobian(DCMderiv.' * a, q));

DeltaFvq = Fvq - J %#ok<NOPTS>



Fvba = -DCMderiv.';
Fqq = 0.5 .* Omega;
Fqbw = -0.5 .* Xi;

F = eye(16) + Ts.* [zeros(3) eye(3) zeros(3, 10); ...
                    zeros(3,6) Fvq zeros(3) Fvba; ...
                    zeros(4,6) Fqq Fqbw zeros(4,3); ...
                    zeros(6,16)];

%Pos
Xdot(1:3) = X(4:6);

%vel
Xdot(4:6) = DCMderiv.' * a;
Xdot(6) = Xdot(6) + 9.816;

%quat
Xdot(7:10) = 0.5 .* Xi * w;

%biases
Xdot(11:16) = 0;

Xnext = X + Xdot.*Ts;
%Xnext(7:10) = Xnext(7:10)/norm(Xnext(7:10));

%J = simple(jacobian(Xnext, X));
J = jacobian(Xnext, X);
deltaF = simple(F - J);
deltaF = deltaF %#ok<NOPTS>


syms q0 q1 q2 q3;
%syms a b c d e f g h k;
%DCM =  [2*(q0^2 + q1^2) - 1, 2*(q1*q2 + q0*q3), 2*(q1*q3 - q0*q2);...
%        2*(q1*q2 - q0*q3), 2*(q0^2 + q2^2) - 1, 2*(q2*q3 + q0*q1);...
%        2*(q1*q3 + q0*q2), 2*(q2*q3 - q0*q1), 2*(q0^2 + q3^2) - 1];
%DCM = [a b c; d e f; g h k];

%DCM = sym('DCM',[3,3]);

R0 = [eye(3) -X(1:3);...
      zeros(1,3) 1];

Rot4 = [DCMderiv zeros(3,1);...
        zeros(1,3) 1];

syms Nx Ny Nz D;
plane1 = [Nx Ny Nz D].';
%plane1 = sym('plane',[4,1]);

h = Rot4*R0*plane1;
J = simple(jacobian(h,[X; plane1]));
%H = Rot4*R0;
%Planeexpected = H*Plane1;

Xip = [-q(2) -q(3) -q(4); ...
       -q(1) -q(4)  q(3); ...
        q(4) -q(1) -q(2); ...
       -q(3)  q(2) -q(1)];

Hqparts = Xip * ([Nx; Ny; Nz] - D*X(1:3));
Hq = 2 .* [-Hqparts(2) -Hqparts(1) Hqparts(4) -Hqparts(3); ...
           -Hqparts(3) -Hqparts(4) -Hqparts(1) Hqparts(2); ...
           -Hqparts(4) Hqparts(3) -Hqparts(2) -Hqparts(1)];

H = [[-D.*DCMderiv; zeros(1,3)] zeros(4,3) [Hq; zeros(1,4)] zeros(4,3) zeros(4,3) [DCMderiv -DCMderiv*X(1:3); zeros(1,3) 1]];
deltaH = simple(H - J);
deltaH = deltaH %#ok<NOPTS>

