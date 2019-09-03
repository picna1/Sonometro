fs=48000;
p0=20e-6;
presure_peak=30;

% r=randn(200000,1);
% r=r./max(abs(r));
% p= presure_peak.*r; %la señal debe excursionar desde 20uPa hasta 20Pa

p=wgn(48000,1,10);
%p=p.*hamming(length(p));
p=p.*1600; %con esto llevo el valor de decimal a lo que seria resultado del conversor
p=ceil(p);

pf = filter(numA , denA, p); % weighting
%pf = filter(numC , denC, p); % weighting

pf2=pf.^2;

pft= filter(numF, denF, pf2);
%pft= filter(numS, denS, pf2);

pft_sqrt=sqrt(pft);

pftdb=20*log10(pft_sqrt/p0)-0;


figure;
plot(p);
title('p');
xlabel('Numero de muestras');
ylabel('Magnitud [veces]');
figure;
plot(pf);
title('pf');
xlabel('Numero de muestras');
ylabel('Magnitud [veces]');
figure;
plot(pf2);
title('pf2');
xlabel('Numero de muestras');
ylabel('Magnitud [veces]');
figure;
plot(pft);
title('pft');
xlabel('Numero de muestras');
ylabel('Magnitud [veces]');
figure;
plot(pft_sqrt);
title('pft_sqrt');
xlabel('Numero de muestras');
ylabel('Magnitud [veces]');
figure;
plot(pftdb);
title('pftdb');
xlabel('Numero de muestras');
ylabel('Magnitud [db]');

% pafdb(length(pafdb))


xf2=fft(pf);
xf2=xf2(1:floor(length(xf2)/2),:);
xf2=abs(xf2);
%xf2=20.*log10(xf2/p0);
% xf2=decimate(xf2,20);
% xf2=xf2+15;
f2=0:(fs/2)/length(xf2):fs/2;
f2=f2(:,1:length(f2)-1);

xf=fft(p);
xf=xf(1:floor(length(xf)/2),:);
xf=abs(xf);
%xf=20.*log10(xf/p0);
% xf2=decimate(xf2,20);
% xf2=xf2+15;
f=0:(fs/2)/length(xf):fs/2;
f=f(:,1:length(f)-1);





























% instrreset
% 
% s = serial('COM10');
% set(s,'BaudRate',250000);
% fopen(s);
% rx=zeros(500,1);
% pause(1);   %con este retardo se estabiliza el serial
% 
% tic;
% for i=1:length(p)
%     
%     %fprintf(s,'%.4f\n',i/10000);
%     fprintf(s,'%e\n',p(i));
%     %pause(0.01);
%     out = fscanf(s);
%     rx(i)= str2double(out);
%     %pause(0.1);
% end
% 
% time=toc;
% fclose(s);
% delete(s);
% clear s;
% 
% figure;
% plot(pftdb,'x');
% hold;
% %figure;
% plot(rx);
% rx;
% time
% 
% 
