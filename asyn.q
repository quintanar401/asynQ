/ Aync call - occupies one statement in ";", if, do, while, $ (case), looks like:
/   async exp / exec exp
/   : async exp / (also async : exp), exec and return val
/   async locOrGlob: exp / exec and assign
/ $ (case) should be like if statement, you can't use its value like 1+$[a;b;c]
/ you can't use async fns in QSQL and with adverbs, all cycles must be done via do/while or .as.over, .as.each and etc
/ where exp is:
/   fn arg
/   fn[arg;..]
/   @[fn;arg;handler]
/   .[fn;args;handler]
/ that is it should be one function call possibly wrapped into try expression, args and handler can be any expressions using assignments
/ fn is:
/   name - function name
/   {...} - raw function
/ functions can be:
/   simple functions
/   another async function (fn using async keyword)
/   special async function - it must have cont (current continuation) as the first arg: {[cont;arg;..]}, it may save cont for further use
/ functions can return:
/   val - simple value
/   exception - raise an exception as usual
/   `async - abort the current call at once. It may be coninued using the saved continuation.
/   (`asyncExc;val) - raise an exception, like simple exception but with any val
/ async proto: there are two steps - a function call and post proc call. The function call should return:
/   val - this means function is done with this return val
/   exception - fn is done with an exception
/   (`asyncExc;val) - fn is done with an exception
/   (`async;assign values;val) - one step is done with the returned value val and new local values
/   (`async;assign values;fn;args;exc) -  async call, fn[args] with exc handler
/   (`async;(stack;val)) - continuation
/ post proc function looks like {[args;lastval] ...} and returns:
/   val/`asyncExc as above to indicate that fn is done
/   (`async;-1;args) - move to the next block (its number is in the fn's map)
/   (`async;-2;args) - move to the next block (i+1) (this one exists for conditional statements)
/ continuation should be called:
/   from an async function AND immediately returned: async {...; : savedContinuation val; }, it will replace the current calculation in the exiting async loop
/   or using .as.resume[cont;val], it will start a new async loop !!!
.as.noc:{x[where 2=0 (0 0 1 1 0 3 0 0;0 0 1 1 2 3 0 0;0 0 2 2 2 2 2 2;3 3 3 3 3 0 4 3;3 3 3 3 3 3 3 3)\"\r\n\t /\"\\"?x]:" ";x}; / remove comments
.as.ps:{x:.as.noc x; x[where x in"\r\n"]:" "; parse x}; / parse str, remove comments
.as.split:{x:(0,where (x=";")&0=sums(not{$[x=2;1;x;$["\""=y;0;"\\"=y;2;1];1*"\""=y]}\[0;x])*(neg x in "})]")+x in "({[")_x;@[x;1_til count x;1_]};
.as.trim:{x[where(reverse&\[reverse v])|&\[v:(.as.noc x) in "\n\t\r "]]:" "; trim x};
.as.strip:{[t;p] 1_-1_.as.trim(count string p)_.as.trim t};
.as.extv:{$[-11=type x;(),x;1=count x;();type[x]in 0 11h;raze .z.s each x;()]};
.as.exta:{$[0=type x;$[(3=count x)&(101=type x 0)|x[0]~(:);$[20>value x 0;first x 1;()],raze .z.s each x;raze .z.s each x];()]};
.as.extt:{[p]
  if[not(1<c:count p)&type[p]in 0 11h;:`];
  if[`async~p0:p 0; :`async]; / async expr
  if[(2=c)&(":")~p0; if[(not 1=count p 1)&`async~first p 1; :`async]]; / : async ....
  if[(3=c)&(`async~p 1)&(:)~p0; : `async]; / async : expr
  : $[(3<c)&($)~p0;`c;p0~";";`b;any p[0]~/:(`if;`do;`while);p 0;`];
 };
 / classify 1 statement
.as.class1:{
  c:(.as.extt p;.as.exta p;.as.extv p:.as.ps x;x);
  if[c[0] in ``async; : (c 0;()),c];
  if[()~c2:.as.class[c 0] .as.strip[last c;c 0]; :(c 0;()),c];
  :(`async;c2),c;
 };
.as.DO:1000;
/ split and classify parts of a statement
.as.class:{
  c:flip `ty`bl`ty0`as`lo`txt!flip .as.class1 each .as.split y;
  if[not `async in c`ty;:()];
  c:update {x:.as.trim x; if[a:":"=first x; x:.as.trim 1_x]; (" :" a),5_x} each txt from c where ty0=`async; / remove async from exps
  c:{$[1=count x;[x:x 0;x[`txt]:(();x`txt);x];`ty`bl`ty0`as`lo`txt!(`;();`;distinct raze x`as;distinct raze x`lo;(";" sv -1_x`txt;last x`txt))]}
    each value c group $[x=`c;til count c;sums $[x in`while`do`if;@[;1;:;1b];::]prev[v]|v:`async=c`ty];
  if[x in`while`do;
    d:$[x=`do;`$"do_cnt",string .as.DO+:1;()];
    c:c,(`ty`bl`ty0`as`lo`txt!(`;();`;(),d;(),d;(();$[x=`do;string[d],"-:1";"(::)"]));`ty`bl`ty0`as`lo`txt!(`;();`;();();(();"(::)")));
  ];
  :c;
 };
/ block fmt:
/ ({...; (`async;assigns;) lastExpr};idx;assign names;cont)
.as.mkBlk:{[args;loc;fn;blk]
  dl:l where (l:blk`lo)like "do_cnt*";
  l:(dl,loc) inter blk`lo; ll:`x^last args; / used locals
  a:(loc,args,dl) inter blk`as;
  pref:"{",$[count args;"[",(";"sv string args),"]";"[x]"],"\n  ",(" "sv sl,'": ",/:string[ll],/:"`",/:(sl:string l,ll),\:";");
  if[`async=ty:blk`ty0; :.as.mkAsyncBlk[a;pref;fn;blk]];
  if[`async=blk`ty; :.as.mkCondBlk[args;loc;fn;blk]];
  if[`.z.s in blk`lo; '".z.s in async functions can be used with async keyword only!"];
  post:"(`async;",$[count a;"enlist[",(";"sv string a),"]";"()"],";)(",((b:blk`txt)1),")";
  :fn,enlist (value pref,$[count b 0;b[0],";\n  ";""],post,"}";1+count fn;a;{[d;v] (`async;-1;d)});
 };
.as.mkCondBlk:{[args;loc;fn;blk]
   v:{[args;loc;f;v] fn:.as.mkBlk[args;loc;f 0;v]; (fn;f[1],count fn)}[args;loc]/[(fn;(),count fn);blk`bl]; / count every block
   fn:v 0; bl:v 1;
   if[`b=ty:blk`ty0; :fn]; / simple ..;..;..;
   if[ty in `do`while; / jump back in while/do
     fn[i:-2+count fn;1]:bl `do=ty; / block num
     if[`do=ty; fn[i;3]: {[d;v] if[v; :(`async;-1;d)]; (`async;-2;d)}; fn[j:-1+bl 1;1]: i+1; fn[j;3]:{[dv;f;d;v] d[dv]:v; .as.cond[f;d;v]}[fn[i;2]0;fn[j;3]]; :fn]; / if do cnt is 0 go to the N+1
   ];
   if[ty in `if`while;
     fn[i:-1+bl 1;1]:count fn; / redirect the condition
     fn[i;3]: .as.cond fn[i;3];
     :fn;
   ];
   i:1+2*til count[blk`bl] div 2; / -1+bl[1] is the end of the first if
   fn[-1+bl i+1;1]: count fn; / body jump
   fn[iif:-1+bl i;1]: bl i+1; / cond jump
   fn[iif;3]: .as.cond@/:fn[iif;3]; / cont fn
   :fn;
  };
 / async block fmt:
 / ({...; (`async;assigns;func;args;excHandler)};goto idx;assign names;post proc fn)
.as.mkAsyncBlk:{[a;pref;fn;blk]
  t:.as.ps txt:.as.trim txt0:blk[`txt]1; ty:`e; v:`;
  if[f:":"~t 0; ty:`r; t:.as.ps txt:.as.trim 1_txt]; / : exp
  if[not[f]&((:)~t 0)|(::)~t 0; if[not -11=type v:t 1; '"bad async assign: ",txt0]; ty:`a; t:.as.ps txt:.as.trim (1+(::)~t 0)_ .as.trim (count string v)_ txt]; / v: exp
  if[f:4=count t; if[f:any t[0]~/:(@;.); txt:.as.split 2_-1_txt; if[(@)~t 0; txt[1]:"enlist ",txt 1]; t:enlist .as.ps .as.trim txt 0]]; / @[fn;arg;exc], arg - enlist arg
  if[not (type[t 0]in -11 100h)&type[t]in 0 11h; '"bad async call: ",txt0]; / exp -> func ....
  if[not f; txt:(f;"enlist ",(count f:string first t)_.as.trim txt;".as.exc")];
  if[".z.s"~txt 0;txt[0]:"`.z.s"];
  :fn,enlist (value pref,"(`async;",$[count a;"enlist[",(";"sv string a),"]";"()"],";",txt[0],";",txt[1],";",txt[2],")}";
    $[ty=`r;-1;1+count fn];a;$[ty=`e;{[x;y] (`async;-1;x)};ty=`r;{y};{$[x in key y;y[x]:z;x set z]; (`async;-1;y)}v]);
 };
.as.processFn:{[n]
  if[not 100=type x:$[-11=type n;get n;n]; '"not a function: ",string n];
  if[all((t?"[")#t:-1_1_ string x)in" \n\r"; t:(1+first where"]"=t)_t];
  l:(value[x]1 2)except\: `async;
  if[()~c:.as.class[`] t; .as.map[x]:(`f`c `cont=first l 0;x); :()];
  prx:"((),",(raze"`",/:string raze l),"`.aloc`.aexc)!(",(a:";"sv string l 0),$[count l 1;";",";"sv (count l 1)#enlist"()";""],";(),",(raze"`",/:string l 0),";.as.exc)";
  blk:.as.mkBlk[l 0;l 1]/[();c];
  blk[0],:x; / save x in case there is .z.s
  .as.map[x]: (`a;value "{[",a,"]",prx,"}";blk);
 };
.as.map:{x!x}(),(::);
.as.cond:{[f;args;v] r:f[args;v]; if[not `async~first r; :r]; if[v; r[1]:-2]; r};
.as.exc:{(`asyncExc;x)};
/ stack: list of (idx;args;map)
.as.loop:{[idx;stack;map;args]
  r:({[idx;stack;map;args]
    / 0N!`run,(idx;stack;args);
    if[idx=-1; :(idx;stack;map;args)];
    if[not `async~first r:.[(s:map idx)0;{(x -1_y),enlist x}[args;args`.aloc];.as.exc];
      if[`asyncExc~first r; .as.trap[stack,enlist(idx;args;map);r 1]];
      :.as.cont[stack;r]; / non async return value
    ];
    if[`async~r; :(-1;r;0;0)]; / abort
    if[2=count r; :.as.cont . r 1]; / continuation was called
    args[s 2]:r 1; / assigns
    if[5=count r; / async call (`async;assigns;func;args;excHandler)
      args[`.aexc]: r 4;
      s:$[((idx=-1+count map)|-1=s 1)&.as.exc~r 4;stack;stack,enlist(idx;args;map)]; / tail call elimination - last expr/: expr/no exc handlers
      if[`.z.s~f:r 2; f:last map 0];
      if[`a=(f:.as.getfn f) 0; / async function
        if[not 99=type a:.[f[1];r 3;::]; '"wrong number of args: ",.Q.s1 last first f 2]; / assign args
        :(0;s;f 2;a); / initiate a new call
      ];
      f:$[`c=f 0; f[1] {(`async;(x;y))}s;f 1]; / custom async func - {[cont;a1;...]}, it may use cont, return `async or a value
      r:.[f;r 3;.as.exc];
      if[`async~r; :(-1;r;0;0)]; / async fn took control over the continuation
      if[`async~first r; :$[2=count r;.as.cont . r 1;r 1]]; / continuation was called
      if[`asyncExc~first r; .as.trap[stack,enlist(idx;args;map);r 1]];
      : .as.cont[s;r];  / some value was returned - call the continuation explicitly
    ];
    if[not 3=count r; '"unexpected: ",.Q.s1 r];
    : .as.cont[stack,enlist(idx;args;map);r 2];
  }.)/[(idx;stack;map;args)];
  :r 1;
 };
.as.cont:{[stack;val]
  if[0=count stack; :(-1;val;0;0)];
  s:last stack; stack:-1_stack;
  if[`asyncExc~first val; val:@[s[1]`.aexc;val 1;.as.exc]; if[`asyncExc~first val; :.z.s[stack;val]]];
  v: (((m:s 2) i:s 0)3)[s 1;val];
  if[not `async~first v; :.z.s[stack;val]]; / unwind the stack
  if[count[m]<=b:.as.nextblk[m;i;v 1]; :.z.s[stack;val]];
  : (b;stack;m;v 2);
 };
.as.nextblk:{[map;i;v] $[v=-1;map[i] 1;i+1]};
.as.getfn:{[fn]
  if[-11=type fn; fn:@[get;fn;fn]];
  if[104=type fn; r:.z.s (v:value fn)0; :$[`a=first r;(`a;r[1]. 1_v;r 2);(r 0;fn)]];
  if[not 100=type fn; '"async requires a function with type 100: ",.Q.s1 fn];
  if[(::)~f:.as.map fn; .as.processFn fn; f:.as.map fn]; f};
.as.run:{[fn;args]
  if[-11=type fn; fn:get fn];
  if[not 100=type fn; '"not a function: ",.Q.s1 fn];
  if[not `a=(f:.as.getfn fn)0; : f[1]. (),args];
  :.as.loop[0;();f 2;f[1]. (),args];
 };
.as.run1:{[fn;arg] .as.run[fn;enlist arg]};
.as.resume:{[cont;val] .as.loop . .as.cont . (cont val) 1};
.as.callcc:{[fn;args] async cont:{[cont;x] (`asyncCont;cont)}[]; if[`asyncCont~first cont; : async .[fn;cont[1],(),args;.as.exc]]; : cont};
.as.show:{if[-11=type x; x:get x]; if[not 100=type x;'"type"]; $[`a=first f:.as.getfn x;f[2;;0];x]};
.as.debug:0b;
.as.err:-1;
.as.trap:{[stack;val]
  if[not .as.debug; :val];
  .as.err "Exception ",.Q.s1 val;
  {
    .as.err "  In ",string last first x[2];
    .as.err "  Args:";
    k:k where not(k:key x 1)like ".*";
    .as.err each "    ",/:(string k),'": ",/:.Q.s1 each x[1] k;
    .as.err "  Failed block:";
    .as.err "    ",string x[2][x 0;0];
  } each reverse stack;
  : val;
 };
/ .as.each[async fn;args]; args: enlist arg, (arg1;arg2;..)
.as.each:{
  if[98=type y:(),y;
    async res: .z.s[x;value each y;0];
    :(cols y)!res;
  ];
  if[any g:99=t:type each y;
    if[not((3>count y)&all g)|all b~\:k:distinct raze b:key each y w:where g;'`domain];
    y[w]:y[w]@\:k;
    async res: .z.s[x;$[98=type y;value flip y;y];0];
    :k!res;
  ];
  if[any t within 0 98h;
    y:flip y; j:-1; rr:(b:count y)#(::);
    do[b; async res: .[x;y j+:1;{'x}]; rr[j]: res];
    :rr;
  ];
  x . y
 };
.as.so:{
  p:({y};{x,enlist y})z; n:count value[x]1; k:count y; rr:();
  if[(k=1)&n=1; g:m:y 0; while[1; rr:p[rr;m]; async nm:x m; if[(g~nm)|nm~m; :rr]; m:nm]]; / iterate on val
  if[(k=2)&n=1; rr:p[rr;m:y 1]; $[type[a:y 0] in -7 -6h; do[a; async m:x m; rr:p[rr;m]]; while[async a m; async m:x m; rr:p[rr;m]]]; :rr]; / iterate N/cond
  if[any g:99=t:type each a:(k:k<>1)_y; / dict case
    if[not all kk[0]~/:kk:key each a w:where g;'`domain];
    $[98=type y;y:value each y;y[k+w]:value each a w];
    async m:.z.s[x;y;z];
    :$[z=1;![kk 0](),;::]m;
  ];
  if[not k;
    $[1=k:count y:y 0; :first y; 0=k; :(); 2=k; [async m:.[x;y;.as.exc]; :p[y 0;m]]; [y:(y 0;1_ y); rr:p[rr;y 0]]];
  ]; / adjust g[a] to g[a;b]
  if[any t within 0 98h;
    m:y 0; y:flip 1_y; j:-1;
    if[(z=0)&0=k:count y;:m];
    do[k; async m: .[x;enlist[m],y j+:1;.as.exc]; rr:p[rr;m]];
    :rr;
  ];
  async .[x;y;.as.exc]
 }; / scan/over
.as.scan:{async .as.so[x;(),y;1b]};
.as.over:{async .as.so[x;(),y;0b]};
.as.prior:{
  if[1=count value[x]1; : async .as.each[x;y]];
  if[99=type m:last y:(),y; y:(-1_y),enlist value m; async v:.z.s[x;y;z]; :(key m)!v]; / dict case
  if[all not(type each y)within 0 98h; $[1=count y;: y 0;: .[x;y;{'x}]]]; / atom case
  y:enlist[$[1=count y;$[98=type y 0;0#m -1;m -1];y 0]],m; j:0; rr:(count m)#(::);
  do[count m; async v:x[y j+:1;y j]; rr[j-1]:v];
  rr
 };
.as.elr:{
  if[99=t:type y z; k:key y z;y[z]:value y z; async v:.z.s[x;y;z]; :k!v];
  if[not(t within 0 98h); : async .[x;y;{'x}]];
  j:0; rr:(count y z)#(::);
  do[count y z; if[z; async v:x[y 0;y[1;j]]]; if[not z; async v:x[y[0;j];y 1]]; rr[j]:v; j+:1];
  rr
 }; / each right/left
.as.eachl:{async .as.elr[x;(),y;0b]};
.as.eachr:{async .as.elr[x;(),y;1b]};

/ iterators
/ async .as.iRet value;
.as.iRet:{[cont;val] (`async;(();((`asyncCont;cont);val)))};
/ .as.iCall[fn;arg];  where fn is an async fn or the result of .as.iRet
.as.iCall1:.as.run1;
.as.iCall:.as.run;
.as.iNext:{[f;a] if[`asyncCont~first first f; v:.as.resume[(last first f);a]; if[not `asyncCont~first first v; v:(();v)]; :v]; '"empty"};
