/ async fn[args]
/ async a:fn[args]
/ : async fn[args]
/ async proto:
/ (`async;-1;assigned vars;v) - jump to the next block/use saved block num - internal
/ (`async;-2;ass vars;v`) - jump to the literally next block N+1
/ val - return a sync value
/ (`async;-3;`fn_name) - call another async function - internal
/ (`async;-4;dict) - for continuations, like 0 but with manually modified vars
/ `async - stop execution, to be continued by a continuation
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
  if[(3=c)&(`async~p 1)&(:)~p0; : `async]; / async : ff a
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
/ (fn;next blk;assigns;cont)
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
  t:.as.ps txt:blk[`txt]1; ty:`e; v:`;
  if[f:":"~t 0; ty:`r; t:.as.ps txt:1_.as.trim txt]; / : exp
  if[not[f]&((:)~t 0)|(::)~t 0; if[not -11=type v:t 1; '"bad async assign: ",txt]; ty:`a; t:.as.ps txt:(1+(::)~t 0)_ .as.trim (count string v)_ .as.trim txt]; / v: exp
  if[(not -11=type f:first t)|not type[t]in 0 11h; '"bad async call: ",txt]; / exp -> func ....
  txt:"enlist",(count f:string f)_.as.trim txt;
  :fn,enlist (value pref,"(`async;",$[count a;"enlist[",(";"sv string a),"]";"()"],";",txt,";`",f,")}";1+count fn;a;$[ty=`e;{[x;y] (`async;-1;x)};ty=`r;{y};{$[x in key y;y[x]:z;x set z]; (`async;-1;y)}v]);
 };
.as.processFn:{[n]
  if[not 100=type x:get n; '"not a function: ",string x];
  if[all((t?"[")#t:-1_1_ string x)in" \n\r"; t:(1+first where"]"=t)_t];
  if[()~c:.as.class[`] t; :()];
  l:(value[x]1 2)except\: `async;
  prx:"((),",(raze"`",/:string raze l),"`.aloc)!(",(a:";"sv string l 0),$[count l 1;";",";"sv (count l 1)#enlist"()";""],";(),",(raze"`",/:string l 0),")";
  .as.map[n]: (value "{[",a,"]",prx,"}";.as.mkBlk[l 0;l 1]/[();c]);
  n set value "{[",a,"] .as.run[0;();.as.map[`",string[n],";1];",prx,"]}";
 };
.as.map:0#.as;
.as.cond:{[f;args;v] r:f[args;v]; if[not `async~first r; :r]; if[v; r[1]:-2]; r};
/ stack: list of (idx;args;map)
.as.run:{[idx;stack;map;args]
  r:({[idx;stack;map;args]
    0N!`run,(idx;stack;args);
    if[idx=-1; :(idx;stack;map;args)];
    if[not `async~first r:.[(s:map idx)0;{(x -1_y),enlist x}[args;args`.aloc]];  :.as.cont[stack;r]]; / non async return value
    args[s 2]:r 1; / assigns
    if[4=count r; / async call
      if[(f:r 3)in key .as.map; / registered async function
        a:(f:.as.map f)[0]. r 2; / assign args
        :(0;stack,enlist(idx;args;map);f 1;a); / initiate a new call
      ];
      r:f[{(`async;.as.cont[x;y])}[s:stack,enlist(idx;args;map)]] . r 2; / unregistered async func - {[cont;a1;...]}, it may use cont, return `async or a value
      if[`async~r; :(-1;r;0;0)]; / async fn took control over the continuation
      if[`async~first r; :r 1]; / continuation was called right away
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
  if[not `async~first v:(last (m:s 2) i:s 0)[s 1;val]; :.z.s[stack;val]]; / run the continuation
  if[count[m]<=b:.as.nextblk[m;i;v 1]; :.z.s[stack;val]];
  : (b;stack;m;v 2);
 };
.as.nextblk:{[map;i;v] $[v=-1;map[i] 1;i+1]};

test1:{[a]
  if[a>10; :a];
  a+:1;
  : async test1 a;
 };
.as.processFn`test1;
test2:{[a]
  if[a>10; :a];
  a+:1;
  async v: test2 a+1;
  : v-1
 };
.as.processFn`test2;
test3:{
  a:1; b:2;
  async v: test2 a+b;
  v+a
 };
.as.processFn`test3;
test4:{
  a:1;
  async test2 a+5
 };
.as.processFn`test4;
test5:{
  a:1;
  async a:test2 a+5
 };
.as.processFn`test5;
test6:{
  async a:test2 5
 };
.as.processFn`test6;
test7:{
  if[1; : async test2 5]
 };
.as.processFn`test7;
test8:{
  if[1; async test2 v:5; :v]
 };
.as.processFn`test8;
test9:{
  if[async test2 v:5; async v2:test2 v; :v2]
 };
.as.processFn`test9;
test10:{
  $[1; async test2 v:5; 10]
 };
.as.processFn`test10;
test11:{
  $[async v2:test2 v:5; v2+v; 0]
 };
.as.processFn`test11;
test12:{async test2 5; 0};
.as.processFn`test12;
test13:{
  $[async test12 1; 1; 10]
 };
.as.processFn`test13;
test14:{
  $[async test2 1; 1; 10]
 };
.as.processFn`test14;
test15:{
  $[async test12 1; 1; async test2 2;2;3 ]
 };
.as.processFn`test15;
test16:{
  v:1;
  while[async test2 1; v+:1; if[v>10; :v]]
 };
.as.processFn`test16;
test17:{
  v:1;
  do[async test2 1; v+:1]; v
 };
.as.processFn`test17;
test18:{
  v:1;
  do[async test2 1; do[async test1 1; v+:1]]; v
 };
.as.processFn`test18;
test19:{
  tmp::1;
  async tmp::test2 1;
  tmp
 };
.as.processFn`test19;

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
