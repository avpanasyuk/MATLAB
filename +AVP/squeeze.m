% MATLAB squeeze is inconsistent, works differently on 2D matrixes
function out=squeeze(x)
  dims = size(x);
  dims(dims==1)=[];
  out=reshape(x,[dims,1,1]);
end