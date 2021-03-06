
function  coefRec = FraRecML(U,framekd,Nlev)
    [D,R] = GenerateFrameletFilter(framekd); % to get  the tight frame filters.
    coefRec = FraRecMultiLevel(U,R,Nlev);
end

function [D,R] = GenerateFrameletFilter(frame)
% function [D,R]=GenerateFrameletFilter(frame)
% This function generate the Decomposition and Reconstruction
% (D and R respectively) coefficients of the framelet filters
% The available filters are:
% frame=0 : Haar wavelet
% frame=1 : Piecewise Linear Framelet
% frame=3 : Piecewise Cubic Framelet

if frame == 0          %Haar Wavelet
    D{1} = [0 1 1]/2;
    D{2} = [0 1 -1]/2;
    D{3} = 'cc';
    R{1} = [1 1 0]/2;
    R{2} = [-1 1 0]/2;
    R{3} = 'cc';
elseif frame == 1      %Piecewise Linear Framelet
    D{1} = [1 2 1]/4;
    D{2} = [1 0 -1]/4*sqrt(2);
    D{3} = [-1 2 -1]/4;
    D{4} = 'ccc';
    R{1} = [1 2 1]/4;
    R{2} = [-1 0 1]/4*sqrt(2);
    R{3} = [-1 2 -1]/4;
    R{4} = 'ccc';
elseif frame == 3      %Piecewise Cubic Framelet
    D{1} = [1 4 6 4 1]/16;
    D{2} = [1 2 0 -2 -1]/8;
    D{3} = [-1 0 2 0 -1]/16*sqrt(6);
    D{4} = [-1 2 0 -2 1]/8;
    D{5} = [1 -4 6 -4 1]/16;
    D{6} = 'ccccc';
    R{1} = [1 4 6 4 1]/16;
    R{2} = [-1 -2 0 2 1]/8;
    R{3} = [-1 0 2 0 -1]/16*sqrt(6);
    R{4} = [1 -2 0 2 -1]/8;
    R{5} = [1 -4 6 -4 1]/16;
    R{6} = 'ccccc';
end
end


function Rec = FraRecMultiLevel(C,R,L)
% function Rec=FraRecMultiLevel(C,R,L)
% This function implement framelet reconstruction up to level L.
% C ==== the data to be reconstructed, which are in cells in C{i,j} with
% C{1,1} being a cell.
% R ==== is the reconstruction filter in 1D. In 2D, it is generated by tensor
% product. The filter D must be symmetric or anti-symmetric, which
% are indicated by 's' and 'a' respectively in the last cell of R.
% L ==== is the level of the decomposition.
% Rec ==== is the reconstructed data.

nR = length(R);
for k = L:-1:2
    C{k-1}{1,1} = FraRec(C{k},R,k);
end
Rec = FraRec(C{1},R,1);
end

function Rec = FraRec(C,R,L)
% function Rec=FraRec(C,R,L)
% This function implement framelet reconstruction.
% C ==== the data to be reconstructed, which are in cells in C{i,j} with
% C{1,1} being a cell.
% R ==== is the reconstruction filter in 1D. In 2D, it is generated by tensor
% product. The filter D must be symmetric or anti-symmetric, which
% are indicated by 's' and 'a' respectively in the last cell of R.
% L ==== is the level of the decomposition.
% Rec ==== is the reconstructed data.

nR = length(R);
SorAS = R{nR};

ImSize = size(C{1,1});
Rec = zeros(ImSize);

for i = 1:nR-1
    temp = zeros(ImSize);
    for j = 1:nR-1
        M2 = R{j};
        temp = temp + (ConvSymAsym((C{i,j})',M2,SorAS(j),L))';
    end
    M1 = R{i};
    Rec = Rec + ConvSymAsym(temp,M1,SorAS(i),L);
end
end

function C = ConvSymAsym(A,M,b,L)
% function C=ConvSymAsym(A,M,b,L)
% The function implements 1D convolution with symmetric or antisymmetric
% boundary condition. The data are extened row by row, not block by block.
% For example, for the vector [1 2 3 4 5 6 7 8] and L=2, b='s', it is extended
% like [...4 3 2 1|1 2 3 4 5 6 7 8|8 7 6 5...], 
% not like [ 3 4:1 2|1 2 3 4 5 6 7 8|7 8:5 6....]
% A is the data, M is the filter, b is the boundary condition, L is the level.

[m,n] = size(A);
nM = length(M);
step = 2^(L-1);
ker = zeros(step*(nM-1)+1,1);
ker(1:step:step*(nM-1)+1,1) = M;
lker = floor(length(ker)/2);

if b == 'c'
    C = imfilter(A,ker,'circular');
else
    if b == 's'
        Ae=padarray(A,lker,'symmetric','both');
    elseif b=='a'
        Ae = padarray(A,lker,'symmetric','both');
        Ae(1:lker,:) = - Ae(1:lker,:);
        Ae(m+lker+1:m+2*lker,:) = - Ae(m+lker+1:m+2*lker,:);
    end
    C = conv2(Ae,ker,'valid');
end
end