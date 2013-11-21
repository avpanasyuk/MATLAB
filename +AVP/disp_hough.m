function disp_hough(in,Ang,k,l)
J=[1:size(in,2)];
imagesc(in);  hold on
plot(J,-k/cos(Ang(l))+tan(Ang(l))*J); 
plot(J,k/cos(Ang(l))+tan(Ang(l))*J); 
hold off 
end
