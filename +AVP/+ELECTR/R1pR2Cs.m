function [Z,R2,C] = R1pR2Cs(Iw1,Iw2,Rw2,cg,cg1)
% File degerated by DesignFiles\HumanModelTwoFreq1.mw
Z = (Iw1 .* Rw2 .* cg .^ 2 - Iw2 .* Rw2 .* cg .* cg1 - sqrt(-Iw1 .^ 2 .* Iw2 .^ 2 .* cg .^ 2 .* cg1 .^ 2 + Iw1 .* Iw2 .^ 3 .* cg .^ 3 .* cg1 + Iw1 .* Iw2 .^ 3 .* cg .* cg1 .^ 3 - Iw2 .^ 4 .* cg .^ 2 .* cg1 .^ 2)) ./ cg ./ (Iw1 .* cg - Iw2 .* cg1);
R2 = -(-2 .* Iw1 .^ 2 .* Iw2 .^ 4 .* Rw2 .* cg .^ 2 .* cg1 .^ 2 + Iw1 .^ 2 .* Iw2 .^ 4 .* Rw2 .* cg1 .^ 4 + Iw1 .^ 2 .* Iw2 .^ 4 .* Z .* cg .^ 2 .* cg1 .^ 2 - 2 .* Iw1 .^ 2 .* Iw2 .^ 2 .* Rw2 .^ 3 .* cg .^ 4 + Iw1 .^ 2 .* Iw2 .^ 2 .* Rw2 .^ 2 .* Z .* cg .^ 4 + Iw1 .^ 2 .* Iw2 .^ 2 .* Rw2 .^ 2 .* Z .* cg .^ 2 .* cg1 .^ 2 - Iw1 .^ 2 .* Rw2 .^ 5 .* cg .^ 4 + Iw1 .^ 2 .* Rw2 .^ 4 .* Z .* cg .^ 4 + 2 .* Iw1 .* Iw2 .^ 5 .* Rw2 .* cg .^ 3 .* cg1 - Iw1 .* Iw2 .^ 5 .* Z .* cg .^ 3 .* cg1 - Iw1 .* Iw2 .^ 5 .* Z .* cg .* cg1 .^ 3 + 4 .* Iw1 .* Iw2 .^ 3 .* Rw2 .^ 3 .* cg .^ 3 .* cg1 - 3 .* Iw1 .* Iw2 .^ 3 .* Rw2 .^ 2 .* Z .* cg .^ 3 .* cg1 - Iw1 .* Iw2 .^ 3 .* Rw2 .^ 2 .* Z .* cg .* cg1 .^ 3 + 2 .* Iw1 .* Iw2 .* Rw2 .^ 5 .* cg .^ 3 .* cg1 - 2 .* Iw1 .* Iw2 .* Rw2 .^ 4 .* Z .* cg .^ 3 .* cg1 - Iw2 .^ 6 .* Rw2 .* cg .^ 2 .* cg1 .^ 2 + Iw2 .^ 6 .* Z .* cg .^ 2 .* cg1 .^ 2 - 2 .* Iw2 .^ 4 .* Rw2 .^ 3 .* cg .^ 2 .* cg1 .^ 2 + 2 .* Iw2 .^ 4 .* Rw2 .^ 2 .* Z .* cg .^ 2 .* cg1 .^ 2 - Iw2 .^ 2 .* Rw2 .^ 5 .* cg .^ 2 .* cg1 .^ 2 + Iw2 .^ 2 .* Rw2 .^ 4 .* Z .* cg .^ 2 .* cg1 .^ 2) ./ (cg .^ 2 - cg1 .^ 2) ./ Iw2 .^ 2 ./ Iw1 ./ (Iw1 .* Iw2 .^ 2 .* cg1 .^ 2 - 3 .* Iw1 .* Rw2 .^ 2 .* cg .^ 2 + 2 .* Iw1 .* Rw2 .* Z .* cg .^ 2 - Iw2 .^ 3 .* cg .* cg1 + 3 .* Iw2 .* Rw2 .^ 2 .* cg .* cg1 - 2 .* Iw2 .* Rw2 .* Z .* cg .* cg1);
C = (Iw1 .* Iw2 .^ 2 .* cg1 .^ 2 - 3 .* Iw1 .* Rw2 .^ 2 .* cg .^ 2 + 2 .* Iw1 .* Rw2 .* Z .* cg .^ 2 - Iw2 .^ 3 .* cg .* cg1 + 3 .* Iw2 .* Rw2 .^ 2 .* cg .* cg1 - 2 .* Iw2 .* Rw2 .* Z .* cg .* cg1) ./ (Iw1 .^ 2 .* Iw2 .^ 4 .* cg1 .^ 4 + 2 .* Iw1 .^ 2 .* Iw2 .^ 2 .* Rw2 .^ 2 .* cg .^ 2 .* cg1 .^ 2 + Iw1 .^ 2 .* Rw2 .^ 4 .* cg .^ 4 - 2 .* Iw1 .* Iw2 .^ 5 .* cg .* cg1 .^ 3 - 2 .* Iw1 .* Iw2 .^ 3 .* Rw2 .^ 2 .* cg .^ 3 .* cg1 - 2 .* Iw1 .* Iw2 .^ 3 .* Rw2 .^ 2 .* cg .* cg1 .^ 3 - 2 .* Iw1 .* Iw2 .* Rw2 .^ 4 .* cg .^ 3 .* cg1 + Iw2 .^ 6 .* cg .^ 2 .* cg1 .^ 2 + 2 .* Iw2 .^ 4 .* Rw2 .^ 2 .* cg .^ 2 .* cg1 .^ 2 + Iw2 .^ 2 .* Rw2 .^ 4 .* cg .^ 2 .* cg1 .^ 2) ./ cg1 .* Iw1 .* Iw2 .* (cg .^ 2 - cg1 .^ 2);
end

function test
Zf = @(w,R1,R2,C) 1/(1/R1+1/(R2+1/(i*w*C)))
Zl = Zf(1000*2*pi,10000,2000,200e-10)
Zh = Zf(50000*2*pi,10000,2000,200e-10)
[R1,R2,C] = CAP_COMP.R1pR2Cs(imag(Zh),imag(Zl),real(Zl),50000*2*pi,1000*2*pi)
end

