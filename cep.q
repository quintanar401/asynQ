/ basic cron service
.cep.cron.interval:100;
.cep.cron.jobs:(); / (time;func;args)
.cep.cron.init:{ .z.ts:.cep.cron.ts; system "t ",string .cep.cron.interval};
.cep.cron.ts:{
  if[0=count i:where .z.P>=(j:.cep.cron.jobs)[;0]; :()];
  .cep.cron.jobs:j (til count j) except i;
  {.[$[-11=type x;get x;x];(),y;{.cep.log "Cron job ",.Q.s1[x]," failed with ",y}x]}./:1_/:j i;
 };
.cep.cron.add:{[tm;fn;arg] if[-16=type tm; tm:.z.P+tm]; .cep.cron.jobs,:enlist(tm;fn;arg)};

/ basic persistent messages
.msg.j:0;
.msg.makeMsg:{n set (enlist[`body]!enlist()),x,``msgName`pointer`time`cont`status`.links!(::;n;enlist n:`$".msgs.","msg",string "j"$.z.P+.msg.j+:1;.z.P;::;`ok;0);n`pointer};
.msg.rc:{-1+-16!(x 0)`pointer};  / number of pointers
.msg.gc:{
  if[count k:k where 3>=(.msgs[k;`.links])+(-16!)each .msgs[k:1_key .msgs;`pointer];
    if[count kk:k where `ok~/:.msgs[k]@\:`status; k:k except kk; .cep.finish0 each .msgs[kk]@\:`pointer];
    if[count k; ![`.msgs;();0b;k];.cep.log "Deleted: ",string count k];
  ];
 };
.msg.get:{get x 0};
.msg.getf:{(get x 0)y};
.msg.getfOpt:{$[y in key o:get x 0;o y;z]};
.msg.name:{x 0};
.msg.setf:{[m;f;v] @[m 0;f;:;v]; m};
.msg.set:.msg.setf[;`body];
.msg.copy:{.msg.makeMsg .msg.get x};
.msg.str:{m:.msg.get x; ", "sv(string key m),'": ",/:.Q.s1 each value m};
.msg.isMsg:{if[(1=count x)&11=type x; x:@[get;x 0;::]]; if[not 99=type x; :0b]; if[not 11=type key x; :0b]; all `msgName`pointer`status in key x};
.msg.eq:{.msg.getf[x;`msgName]=.msg.getf[y;`msgName]};
.msgs:1#.msg;

.cep.mainQueue:();

/ clone a msg, send it somewhere and forget about it. It is not an async fn and it doesn't require async keyword.
/ .cep.fork[.log.msg;m];
.cep.fork:{[fn;m]  nm:.msg.copy m;  .cep.enqueue[fn;nm]; };

/ Execute an async fn with a copy of msg and aggregate the result.
/ async .cep.enrich[`.calc.something;msg;{[m;newm] .msg.setf[m;.msg.getf[m;`body],.msg.getf[newm;`body]]}]
/ if agg is (::) then .cep.agg (substitute body) will be used
/ throws an anync exception with a bad message or text
.cep.enrich:{[fn;m;agg]
  nm:.msg.setf[.msg.copy m;`.links`.parent;(-3;.msg.getf[m;`msgName])];  / there are 3 additional refs - nm in stack, nm in exc handler and cont
  if[(::)~agg; agg:.cep.agg1];
  async r:.[.cep.enqueue0;(fn;nm);{y;(`asyncExc;x)}nm];
  if[r~(); :`async]; / wait for the response
  async .cep.failCheck[m;nm]; / exception if either m or nm are in a wrong state
  agg[m;nm];
  : m;
 };

/ Generalization of .cep.enrich. Split msg into several messages and send them via several routes. Once they are done, aggregate the result.
/ msg - current message, fn - list or one function/name for the new msgs, split - new msgs or their `body content. agg - aggregation function.
/ if agg is (::) then .cep.agg1 (substitute body with raze applied to the result bodies) will be used
/ throws an anync exception with a bad message or text
/ async .cep.split[msg;`.some.fn;msg`body;::]; / split body(list) into elements and process uniformly using .some.fn
/ async .cep.split[msg;`fn1`fn2`fn3;3#enlist msg`body;.agg.fn]; / another case - enrich msg using 3 different funcs
.cep.split:{[m;fn;split;agg]
  split:(),split; fn:(),fn;
  if[not .msg.isMsg first split; split:{nm:.msg.copy x; .msg.set[nm;y]}[m] each split];
  .msg.setf[;`.links`.parent;(-3;.msg.getf[m;`msgName])] each split;
  if[.msg.eq[m;first split]; '"split message is the parent message"];
  if[(::)~agg; agg:.cep.agg];
  .msg.setf[m;`.resultsCnt;0]; i:-1; fn:count[split]#fn;
  do[count split;
    async r:.[.cep.enqueue0;(fn i;split i+:1);{(::)}]; / do not allow exceptions
    if[not ()~r;
      .msg.setf[m;`.resultsCnt;c:1+.msg.getf[m;`.resultsCnt]];
      if[c>count split; :`async]; / there was an exception and this is a late response
      / if there is a problem, cancel all remaining msgs, mark msg to stop all further processing, throw an exc
      async .[.cep.failCheck;(m;split i);{.cep.cancel y; .msg.setf[x;`.resultsCnt;count y]; (`asyncExc;z)}[m;split]];
      if[c=count split; / we are done
        agg[m;split];
        :m;
      ];
      :`async; / not all responses are ready
    ];
  ];
  :`async; / stop
 };

/ Suspend the execution to allow other functions to run. Like .cep.delay 0D0
/ async .cep.yield[]
.cep.yield:{[cont;x]
  .cep.mainQueue,:enlist (.cep.resumeCont1;cont);
  :`async;
 };

/ delay an async fn for some time: fn, var with time or fn, span, stamp
/ async .cep.delay 0D00:01
.cep.delay:{[cont;tm]
  if[-11=type tm; tm:get tm];
  if[100=type tm; tm:tm[]];
  if[type[tm]in -16 -19h; tm:.z.P+tm];
  if[not -12=type tm; '"wrong time: ",.Q.s1 tm];
  .cep.cron.add[tm;.cep.resumeCont;(cont;::)];
  :`async;
 };

/ wait until pred is true with time intervals: tm
/ async .cep.wait[{count queue};0D00:03]
.cep.wait:{[pred;tm]
  if[pred[]; :1b];
  async .cep.delay tm;
  : async .cep.wait[pred;tm];
 };

/ End the msg. If this is a child msg the result will be returned to the caller. Clear body for non-child msgs.
/ if msg is not finished explicitly it will be finished automatically (if there are no links to it)
/ async .cep.finish msg; / may not return
.cep.finish:{[m]
  async {x}[]; / to ensure finish is called with async keyword
  if[not (::)~c:.cep.finishx m; :c[]]; / call continuation if available
  .msg.set[m;()]; / clear data otherwise
 };
.cep.finish0:{[m] if[not (::)~c:.cep.finishx m; .cep.enqueue[{: x[]};c]]};
/ reset cont and links fields
.cep.finishx:{[m] if[not `ok=.msg.getf[m;`status]; :(::)]; .msg.setf[m;`status;`done]; if[not (::)~c:.msg.getf[m;`cont]; .msg.setf[m;`cont`.links;((::);0)]; :c]};

/ two versions. 1) enqueues the msg and returns to allow to check the result, 2) just redirects the msg and terminates
.cep.enqueue0:{[cont;fn;m] .cep.mainQueue,:enlist (fn;.msg.setf[m;`cont;cont]); ()};
.cep.enqueue:{[fn;m] .cep.mainQueue,:enlist (fn;m); `async};

.cep.log:-1;
.cep.resumeCont:{[c;v] .cep.exec ({: x[0] x 1};(c;v))}; / to be executed by external funcs - starts a new async loop
.cep.resumeCont1:{[c] : c[]}; / to be executed from mainQueue
.cep.agg1:{[m;nm] .msg.set[m;.msg.getf[nm;`body]]}; / defaul agg - subst body
.cep.agg:{[m;nm] .msg.set[m;raze .msg.getf[;`body]each nm]}; / defaul agg - subst body
.cep.failCheck:{[m;nm] if[not `ok=.msg.getf[m;`status]; '"parent: wrong state"]; if[not `done=.msg.getf[nm;`status]; :(`asyncExc;nm)]; m}; / check that both parent and child are ok
.cep.cancel:{{if[`ok=.msg.getf[x;`status]; .msg.setf[x;`status;`cancelled]]}each $[.msg.isMsg x;enlist x;x]}; / cancel children

.cep.init:{
  .cep.cron.init[];
  .cep.cron.add[0D0;`.cep.loop;::];
  .cep.cron.add[0D00:01;`.cep.gc;::];
 };

 .cep.loop:{
   .cep.loopQ/[{count .cep.mainQueue};::];
   .cep.cron.add[0D00:00:00.100;`.cep.loop;::];
 };

 .cep.loopQ:{
   j:first .cep.mainQueue; .cep.mainQueue:1_ .cep.mainQueue;
   .cep.exec j;
 };

.cep.exec:{[arg]
  r:.[.as.run;(`.cep.exec1;arg);{(`asyncExc;x)}];
  if[`asyncExc~first r; .cep.log "Unexpected exception: ",.Q.s1 r 1];
 };

.cep.exec1:{[fn;arg]
  async r:@[fn;arg;.cep.execTrap arg];
 };
.cep.execTrap:{
  / propagate exc if there is a cont
  if[mx:.msg.isMsg x;
    if[not (::)~c:.cep.finishx x;
      .msg.setf[x;`status`exc;(`exc;y)];
      : .cep.enqueue[{: x[0] x 1};(c;(`asyncExc;y))];
    ];
  ];
  e:$[f:.msg.isMsg y;.msg.str y;y];
  .cep.log "Unexpected exception: ",e;
  if[not mx; :()];
  if[f; if[.msg.eq[x;y]; :()]];
  .cep.log "  happened in ",.msg.str x;
 };

.cep.gc:{ .msg.gc[]; .cep.cron.add[0D00:01;`.cep.gc;::];}; / remove processed msgs
