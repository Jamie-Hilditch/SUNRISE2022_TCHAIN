function [lags,rhoyy, rhocrit, Ryy, N]= crosscorr_NAN42(a,b,mon)
    % Computes the cross correlation of two timeseries with NaNs
    % Ale Sanchez-Rios - January 2023


    rows=2*mon+2+2*mon;
    n=length(a);
    final=zeros(rows,n);
    final(:)=nan;
    c=1;
    
    for ji=-mon:0
        po=abs(ji);
        fa=a(1:n-po);
        fb=b(po+1:end);
        na=~isnan(fa);
        nb=~isnan(fb);
        non=na & nb;
        fa=fa(non);
        fb=fb(non);
        final(c,1:length(fa))=fa;
        final(c+1,1:length(fa))=fb;
        c=c+2;
    end
        
    clear na nb fb fa
    for ji=1:mon
        
        fa=a(ji+1:n);
        fb=b(1:n-ji);
        na=~isnan(fa);
        nb=~isnan(fb);
        non=na&nb;
        fa=fa(non);
        fb=fb(non);
        final(c,1:length(fa))=fa;
        final(c+1,1:length(fa))=fb;
        c=c+2;
    end
    lags=-mon:mon;
    mu=mean(final,2,'omitnan');
    stan=std(final,1,2,'omitnan');
    stanfin=stan.*circshift(stan,-1);
    stanfin=stanfin(1:2:end,:);
    prep=(final-mu(:,ones(1,n)));
    num=n-sum(isnan(prep),2);
    num=num(1:2:end,:);
    ryy=sum((prep.*circshift(prep,-1)),2,'omitnan');
    ryy=ryy(1:2:end,:);
    Ryy=(1./num).*ryy;
    N=num;
    rhoyy=(Ryy./stanfin);
    rhocrit=sqrt(finv(.95, 1,N-2)./N);
    lags = double(lags);

end





