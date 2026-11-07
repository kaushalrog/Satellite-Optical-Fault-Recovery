w=2.45e-3;al=2.6e-4;worst=0;rel=0;
for H=[1e-4 1e-3 1e-2 .1];for W=[1e-4 1e-3 1e-2];for a=[.5 1 3 10 30 60]
 c=W+w*H;ex=exp(w*a)*H+c*(exp(w*a)-1)/w+al*(exp(w*a)-1-w*a)/w^2;
 Eimp=exp(w*a)*(H*(1+w*a)+W*a+al*a^2/2);Eunp=exp(w*a)*H*(1+w*a)+W*a+al*a^2/2;
 worst=min(worst,Eunp-ex);rel=max(rel,(Eimp-ex)/ex);
end;end;end
fprintf('age<=60s: min(E_unparenthesised-exact)=%.3e rad ; max relative looseness of E_impl over exact=%.3e\n',worst,rel);
