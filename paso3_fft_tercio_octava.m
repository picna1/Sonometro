

gap = f2(2)-f2(1);
xf2_promedio=zeros(31,1);
xf_promedio=zeros(31,1);
xf_desvio=zeros(31,1);
xf2_desvio=zeros(31,1);


for i=1:length(fnom)
    finf_lazo=find(f2>finf(i)-(2*gap/3) & f2<finf(i)+(2*gap/3),1);
    fsup_lazo=find(f2>fsup(i)-(2*gap/3) & f2<fsup(i)+(2*gap/3),1);
    fnom_lazo=find(f2>fnom(i)-(2*gap/3) & f2<fnom(i)+(2*gap/3),1);
    xf2_promedio(i)= mean(xf2_promedio(i)+mean(xf2(finf_lazo:fsup_lazo)));
    
end

for i=1:length(fnom)
    finf_lazo=find(f>finf(i)-(2*gap/3) & f<finf(i)+(2*gap/3));
    fsup_lazo=find(f>fsup(i)-(2*gap/3) & f<fsup(i)+(2*gap/3));
    fnom_lazo=find(f>fnom(i)-(2*gap/3) & f<fnom(i)+(2*gap/3));
    xf_promedio(i)=mean(xf_promedio(i)+mean(xf(finf_lazo:fsup_lazo)));
end




%igualo las funciones

xf2_promedio = 20*log10(xf2_promedio/p0);
xf_promedio = 20*log10(xf_promedio/p0);

xf_desvio=xf_promedio-mean(xf_promedio);

%%%%%%%%%%%%%%%%%%   A   %%%%%%%%%%%%%%%%%%%%%%%%%

xf2_promedio = xf2_promedio + ...
    (...
    A(find(ff>996 & ff<1004) )- ...
    xf2_promedio(find(fnom>900 & fnom<1100))...
    );

xf_promedio = xf_promedio + ...
    (...
    A(find(ff>996 & ff<1004) )- ...
    xf_promedio(find(fnom>900 & fnom<1100))...
    );

% figure;
% semilogx(...
%     ff,A, ...
%     wAd*Fs/pi/2,-20*log10(abs(hAd)/p0)+92,...
%     fnom,xf2_promedio,'x',...
%     fnom,xf_promedio);
% grid ON;
% hold;

for i=1:length(fnom)
    xf2_desvio(i) = xf2_promedio(i)...
    - A(find(ff>fnom(i)*0.98 & ff<fnom(i)*1.02,1) );
    %- xf_desvio(i) 
end
figure;
semilogx(fnom,xf2_desvio*0.1,fnom,xf_desvio*0.1);
grid ON;
hold;

%%%%%%%%%%%%%%%%%%%%%   C   %%%%%%%%%%%%%%%%%%%%555

% xf2_promedio = xf2_promedio + ...
%     (...
%     C(find(ff>996 & ff<1004) )- ...
%     xf2_promedio(find(fnom>900 & fnom<1100))...
%     );
% 
% xf_promedio = xf_promedio + ...
%     (...
%     C(find(ff>996 & ff<1004) )- ...
%     xf_promedio(find(fnom>900 & fnom<1100))...
%     );
% 
% figure;
% semilogx(...
%     ff,C, ...
%     wCd*Fs/pi/2,-20*log10(abs(hCd)/p0)+94,...
%     fnom,xf2_promedio,'x',...
%     fnom,xf_promedio);
% grid ON;
% hold;
% 
% for i=1:length(fnom)
%     xf2_desvio(i) = xf2_promedio(i)...
%     - C(find(ff>fnom(i)*0.98 & ff<fnom(i)*1.02,1) );
%     %- xf_desvio(i) 
% end
% figure;
% semilogx(fnom,xf2_desvio,fnom,xf_desvio);
% grid ON;
% hold;
