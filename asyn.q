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
.as.ps:{x:x where not 2=0 (0 0 1 1 0 3 0 0;0 0 1 1 2 3 0 0;0 0 2 2 2 2 2 2;3 3 3 3 3 0 4 3;3 3 3 3 3 3 3 3)\"\r\n\t /\"\\"?x; x[where x in"\r\n"]:" "; parse x}; / parse str, remove comments
.as.split:{x:(0,where (x=";")&0=sums(not{$[x=2;1;x;$["\""=y;0;"\\"=y;2;1];1*"\""=y]}\[0;x])*(neg x in "})]")+x in "({[")_x;@[x;1_til count x;1_]};
.as.trim:{x[where(reverse&\[reverse v])|&\[v:x in "\n\t\r "]]:" "; trim x};
.as.strip:{[t;p] 1_-1_.as.trim(count string p)_.as.trim t};
.as.extv:{$[-11=type x;(),x;1=count x;();type[x]in 0 11h;raze .z.s each x;()]};
.as.exta:{$[0=type x;$[(3=count x)&(101=type x 0)|x[0]~(:);(first x 1),raze .z.s each x;raze .z.s each x];()]};
.as.extt:{[p]
  if[not(1<c:count p)&type[p]in 0 11h;:`];
  if[`async~p0:p 0; :`async]; / async expr
  if[(2=c)&(":")~p0; if[`async~first p 1; :`async]]; / : async ....
  if[(3=c)&(`async~p 1)&(:)~p0; : `async]; / async : expr
  : $[(3<c)&($)~p0;`c;p0~";";`b;any p[0]~/:(`if;`do;`while);p 0;`];
 };
.as.class1:{
  c:(.as.extt p;.as.exta p;.as.extv p:.as.ps x;x);
  if[c[0] in ``async; : (c 0;()),c];
  if[()~c2:.as.class[c 0] .as.strip[last c;c 0]; :(c 0;()),c];
  :(`async;c2),c;
 };
.as.DO:1000;
.as.class:{
  c:flip `ty`bl`ty0`as`lo`txt!flip .as.class1 each .as.split y;
  if[not `async in c`ty;:()];
  c:update {x:.as.trim x; if[a:":"=first x; x:.as.trim 1_x]; (" :" a),5_x} each txt from c where ty0=`async; / remove async from exps
  c:{$[1=count x;[x:x 0;x[`txt]:(();x`txt);x];`ty`bl`ty0`as`lo`txt!(`;();`;distinct raze x`as;distinct raze x`lo;(";" sv -1_x`txt;last x`txt))]} each value c group $[x=`c;til count c;sums $[x in`while`do`if;@[;0;:;1b];::]prev[v]|v:`async=c`ty];
  if[x in`while`do;
    d:$[x=`do;`$"do_cnt",string .as.DO+:1;()];
    c:c,enlist`ty`bl`ty0`as`lo`txt!(`;();`;(),d;(),d;(();$[x=`do;string[d],"-:1";""]));
  ];
  :c; / ,enlist `ty`bl`ty0`as`lo`txt!(`;();`;();();(();":(::)"));
 };
/ block fmt:
/ (fn;assigns;cont)
.as.mkBlk:{[args;loc;fn;blk]
  dl:l where (l:blk`lo)like "do_cnt*";
  l:(dl,loc) inter blk`lo; ll:`x^last args; / used locals
  a:(loc,args,dl) inter blk`as;
  pref:"{",$[count args;"[",(";"sv string args),"]";"[x]"],"\n  ",(" "sv sl,'": ",/:string[ll],/:"`",/:(sl:string l,ll),\:";");
  if[`async=ty:blk`ty0; :.as.mkAsyncBlk[a;pref;fn;blk]];
  if[`async=blk`ty;
    v:{[args;loc;f;v] fn:.as.mkBlk[args;loc;f 0;v]; (fn;f[1],count fn)}[args;loc]/[(fn;(),count fn);blk`bl]; / count every block
    fn:v 0; bl:v 1;
    if[`b=ty; :fn]; / simple ..;..;..;
    if[ty in `do`while; / jump back in while/do
      fn[i:-1+count fn;1]:bl `do=ty; / block num
      if[`do=ty; fn[i;3]: {[d;v] if[v; :(`async;-1;d)]; (`async;-2;d)}; fn[j:-1+bl 1;1]: i+1; fn[j;3]:{[dv;f;d;v] d[dv]:v; .as.cond[f;d;v]}[fn[i;2]0;fn[j;3]]; :fn]; / if do cnt is 0 go to the N+1
    ];
    if[ty in `if`while;
      fn[i:-1+bl 1;1]:count fn; / redirect the condition
      fn[i;3]: .as.cond fn[i;3];
      :fn;
    ];
    i:2*til count[blk`bl] div 2;
    fn[i+1;1]: count fn; / body jump
    fn[i;1]: bl i+2; / cond jump
    fn[i;3]: .as.cond@/:fn[i;3]; / cont fn
    :fn;
  ];
  post:"(`async;",$[count a;"enlist[",(";"sv string a),"]";"()"],";)(",((b:blk`txt)1),")";
  :fn,enlist (value pref,$[count b 0;b[0],";\n  ";""],post,"}";1+count fn;a;{[d;v] (`async;-1;d)});
 };
.as.mkAsyncBlk:{[a;pref;fn;blk]
  t:.as.ps txt:txt0:blk[`txt]1; ty:`e; v:`;
  if[f:":"~t 0; ty:`r; t:.as.ps txt:1_.as.trim txt]; / : exp
  if[not[f]&((:)~t 0)|(::)~t 0; if[not -11=type v:t 1; '"bad async assign: ",txt0]; ty:`a; t:.as.ps txt:(1+(::)~t 0)_ .as.trim (count string v)_ .as.trim txt]; / v: exp
  if[f:3=count t; if[f:t[0]~/:(@;.); txt:.as.split 2_-1_txt; if[(@)~t 0; txt[1]:"enlist ",txt 1]; t:enlist .as.ps .as.trim txt 0]]; / @[fn;arg;exc], arg - enlist arg
  if[not (type[t 0]in -11 100h)&type[t]in 0 11h; '"bad async call: ",txt0]; / exp -> func ....
  if[not f; txt:0N!(f;"enlist ",(count f:string first t)_.as.trim txt;"(::)")];
  / ({...; (`async;assigns;func;args;excHandler)};goto idx;assign names;post proc fn)
  :fn,enlist (value pref,"(`async;",$[count a;"enlist[",(";"sv string a),"]";"()"],";",txt[0],";",txt[1],";",txt[2],")}";1+count fn;a;$[ty=`e;{[x;y] (`async;-1;x)};ty=`r;{y};{$[x in key y;y[x]:z;x set z]; (`async;-1;y)}v]);
 };
.as.processFn:{[n]
  if[not 100=type x:$[-11=type n;get n;n]; '"not a function: ",string n];
  if[all((t?"[")#t:-1_1_ string x)in" \n\r"; t:(1+first where"]"=t)_t];
  l:(value[x]1 2)except\: `async;
  if[()~c:.as.class[`] t; .as.map[x]:(`f`c `cont=first l 0;x); :()];
  prx:"((),",(raze"`",/:string raze l),"`.aloc)!(",(a:";"sv string l 0),$[count l 1;";",";"sv (count l 1)#enlist"()";""],";(),",(raze"`",/:string l 0),")";
  .as.map[x]: (`a;value "{[",a,"]",prx,"}";.as.mkBlk[l 0;l 1]/[();c];value "{[",a,"] .as.run[0;();.as.map[`",string[n],";1];",prx,"]}");
 };
.as.map:{x!x}(),(::);
.as.cond:{[f;args;v] r:f[args;v]; if[not `async~first r; :r]; if[v; r[1]:-2]; r};
/ stack: list of (idx;args;map)
.as.loop:{[idx;stack;map;args]
  r:({[idx;stack;map;args]
    0N!`run,(idx;stack;args);
    if[idx=-1; :(idx;stack;map;args)];
    if[not `async~first r:.[(s:map idx)0;{(x -1_y),enlist x}[args;args`.aloc];{(`asyncExc;x)}];  :.as.cont[stack;r]]; / non async return value
    if[`async~r; :(-1;r;0;0)]; / abort
    if[2=count r; :.as.cont . r 1]; / continuation was called
    args[s 2]:r 1; / assigns
    if[5=count r; / async call (`async;assigns;func;args;excHandler)
      args[`.aexc]: r 4;
      s:stack,enlist(idx;args;map);
      if[`a=(f:.as.getfn r 2) 0; / async function
        a:f[1]. r 3; / assign args
        :(0;s;f 2;a); / initiate a new call
      ];
      if[`c=f 0; f:f {(`async;(x;y))}s]; / custom async func - {[cont;a1;...]}, it may use cont, return `async or a value
      r:.[f;r 3;{(`asyncExc;x)}];
      if[`async~r; :(-1;r;0;0)]; / async fn took control over the continuation
      if[`async~first r; :$[2=count r;.as.cont . r 1;r 1]]; / continuation was called
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
  v:$[`asyncExc~first val;@[s[1]`.aexc;val;{(`asyncExc;x)}];(last (m:s 2) i:s 0)[s 1;val]];
  if[not `async~first v; :.z.s[stack;val]]; / unwind the stack
  if[count[m]<=b:.as.nextblk[m;i;v 1]; :.z.s[stack;val]];
  : (b;stack;m;v 2);
 };
.as.nextblk:{[map;i;v] $[v=-1;map[i] 1;i+1]};
.as.getfn:{[fn] if[(::)~f:.as.map fn; .as.processFn fn; f:.as.map fn]; f};
.as.run:{[fn;args]
  if[-11=type fn; fn:get fn];
  if[not 100=type fn; '"not a function: ",.Q.s1 fn];
  if[not `a=(f:.as.getfn fn)0; : f[1]. (),args];
  :.as.loop[0;();f 2;f[1]. (),args];
 };
.as.run1:{[fn;arg] .as.run[fn;enlist arg]};
.as.resume:{[cont;val] .as.loop . .as.cont . (cont val) 1};
/ .as.each[async fn;args]; args: enlist arg, (arg1;arg2;..)
.as.each:{
  if[98=type y;
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
  if[(k=2)&n=1; rr:p[rr;m:y 1]; $[-7=type a:y 0; do[a; async m:x m; rr:p[rr;m]]; while[a m; async m:x m; rr:p[rr;m]]]; :rr]; / iterate N/cond
  if[any g:99=t:type each a:(k:k<>1)_y; / dict case
    if[not all kk[0]~/:kk:key each a w:where g;'`domain];
    $[98=type y;y:value each y;y[k+w]:value each a w];
    async m:.z.s[x;y;z];
    :$[z=2;![kk 0](),;::]m;
  ];
  if[not k;
    $[1=k:count y:y 0; :first y; 0=k; :(); 2=k; [async m:.[x;y;{'x}]; :p[y 0;m]]; [y:(y 0;1_ y); rr:p[rr;y 0]]];
  ]; / adjust g[a] to g[a;b]
  if[any t within 0 98h;
    m:y 0; y:flip 1_y; j:-1;
    if[(z=1)&0=k:count y;:m];
    do[k; async m: .[x;enlist[m],y j+:1;{'x}]; rr:p[rr;m]];
    :rr;
  ];
  x . y
 }; / scan/over
.as.scan:{async .as.so[x;y;1b]};
.as.over:{async .as.so[x;y;0b]};
.as.prior:{
  if[1=count value[x]1; : async .as.each[x;y]];
  if[99=type m:last y; y:(-1_y),enlist value m; async v:.z.s[x;y;z]; :(key m)!v]; / dict case
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
.as.eachl:{async .as.elr[x;y;0b]};
.as.eachr:{async .as.elr[x;y;1b]};


test1:{[a]
  if[a>10; :a];
  a+:1;
  : async test1 a;
 };
test2:{[a]
  if[a>10; :a];
  a+:1;
  async v: test2 a+1;
  : v-1
 };
test3:{
  a:1; b:2;
  async v: test2 a+b;
  v+a
 };
test4:{
  a:1;
  async test2 a+5
 };
test5:{
  a:1;
  async a:test2 a+5
 };
test6:{
  async a:test2 5
 };
test7:{
  if[1; : async test2 5]
 };
test8:{
  if[1; async test2 v:5; :v]
 };
test9:{
  if[async test2 v:5; async v2:test2 v; :v2]
 };
test10:{
  $[1; async test2 v:5; 10]
 };
test11:{
  $[async v2:test2 v:5; v2+v; 0]
 };
test12:{async test2 5; 0};
test13:{
  $[async test12 1; 1; 10]
 };
test14:{
  $[async test2 1; 1; 10]
 };
test15:{
  $[async test12 1; 1; async test2 2;2;3 ]
 };
test16:{
  v:1;
  while[async test2 1; v+:1; if[v>10; :v]]
 };
test17:{
  v:1;
  do[async test2 1; v+:1]; v
 };
test18:{
  v:1;
  do[async test2 1; do[async test1 1; v+:1]]; v
 };
test19:{
  tmp::1;
  async tmp::test2 1;
  tmp
 };

test:{
  x+1;
  a:q;
  if[a;c:b+1];
  $[1;2];
  $[1;2;3];
  do[1;2];
  while[1;2];
  [1;2;3];
  async : f a;
  async f[a];
  : async f a;
  async a:f a;
  if[async f a;2];
  1+1;
  2+2;
  do[10;
    async a:fn a;
    2+3;
    2+3;
  ];
 }
