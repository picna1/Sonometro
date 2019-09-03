Fs = 48000;
%NNff = 2.^8;


%ff = 0.02*2.^(0:.01:16.8); 
ff = 2*2.^(0:.01:13.4252); 

C = 12194^2 * ff.^2 ./ (ff.^2 + 20.6^2) ./ (ff.^2 + 12194^2); 
A = ff.^2 .* C ./ sqrt(ff.^2 + 107.7^2) ./ sqrt(ff.^2 + 737.9^2); 
%A = 1.25766693643638 * A; 
A=20*log10(A);
C=20*log10(C);






% numS = [1 -1];
% denS = [1.13377E-05 1.13377E-05];
% numF = [1 -1];
% denF = [9.06947E-05 9.06947E-05];
%%%%%%%%%%%%%%%%%    F    %%%%%%%%%%%%%%%%%%%%

tau=0.125;
num = [0, 1];
den = [tau, 1];

[numF,denF] = bilinear(num,den,Fs);   % Analog to digital conversion

hF = freqz(numF,denF,ff,Fs); % Frequency response of filter
%[hF,wF] = freqz(numF,denF,2.^18); % Frequency response of filter
figure
semilogx(ff, 20*log10(abs(hF)),'b');
%semilogx(wF*Fs/pi/2, 20*log10(abs(hF)));
title('respuesta de frecuencia filtro 125ms');
hold;
grid;

%%%%%%%%%%%%%%         S             %%%%%%%%%

tau=1;
num = [0, 1];
den = [tau, 1];

[numS,denS] = bilinear(num,den,Fs);   % Analog to digital conversion

[hS,wS] = freqz(numS,denS,ff,Fs); % Frequency response of filter
%[hS,wS] = freqz(numS,denS,2.^18); % Frequency response of filter
%figure;
semilogx(ff, 20*log10(abs(hS)),'r');
%semilogx(wS*Fs/(pi*2), 20*log10(abs(hS)),'r');
title('respuesta de frecuencia filtro 1s');

%%%%%%%%%%%%%%%    A       %%%%%%%%%%%%%%%%%%

k = 1.2588*12200^2*(2*pi)^2;
%k=7.396668110841547e+09;
z = [0; 0; 0; 0]; 
p = [-20.60*2*pi -20.60*2*pi ...
    -107.7*2*pi -737.9*2*pi ...
    -12194*2*pi -12194*2*pi];
p = p.';
% Fs = 0.5;                             % Sampling frequency
[num,den] = zp2tf(z,p,k);             % Convert to transfer function form
[numA,denA] = bilinear(num,den,Fs);   % Analog to digital conversion
%fvtool(numd,dend)  



 [hAd,wAd] = freqz(denA,numA,2.^14); % Frequency response of filter
 figure;
 semilogx(ff,A+2,'b',wAd*Fs/pi/2,-20*log10(abs(hAd)),'r');
 title('respuesta de frecuencia filtro A discreto');
 hold;
 plot(freqnom,maxA,'y');
 plot(freqnom(3:33),minA,'y');
 
 %semilogx(wA*Fs/pi/2,-abs(hA),'r');

 [hA,wA] = freqs(den,num); % Frequency response of filter
 figure;
 semilogx(ff,A+2,'b',wA/pi/2,-20*log10(abs(hA)),'r');
 title('respuesta de frecuencia filtro A analogico');
 hold;
 plot(freqnom,maxA,'y');
 plot(freqnom(3:33),minA,'y');
 
 %semilogx(wA*Fs/pi/2,-abs(hA),'r');
 
 
%%%%%%%%%%%%%%       C           %%%%%%%%%%%%%%%%%%%


k = 12194^2*(2*pi)^2;
z = [0; 0]; 
p = [-20.60*2*pi -20.60*2*pi...
    -12194*2*pi -12194*2*pi];
p = p.';
% Fs = 0.5;                             % Sampling frequency
[num,den] = zp2tf(z,p,k);             % Convert to transfer function form
[numC,denC] = bilinear(num,den,Fs);   % Analog to digital conversion
%fvtool(numd,dend)  



 [hCd,wCd] = freqz(denC,numC,2.^14); % Frequency response of filter
 figure;
 semilogx(ff,C,'b',wCd*Fs/pi/2,-20*log10(abs(hCd)),'r');
 title('respuesta de frecuencia filtro c discreto');
 %semilogx(wA*Fs/pi/2,-abs(hA),'r');
 hold;
 plot(freqnom,maxC,'y');
 plot(freqnom(3:33),minC,'y');

 [hC,wC] = freqs(den,num); % Frequency response of filter
 figure;
 semilogx(ff,C,'b',wC/pi/2,-20*log10(abs(hC)),'r');
 title('respuesta de frecuencia filtro c analogico');
 %semilogx(wA*Fs/pi/2,-abs(hA),'r');
 hold;
 plot(freqnom,maxC,'y');
 plot(freqnom(3:33),minC,'y');
 
 
 
 
 
 
