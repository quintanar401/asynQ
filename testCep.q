\l asyn.q
\l cep.q

.cep.init[];

.cep.enqueue[`.test.fn1;100];

.test.fn1:{
  -1 "sync fn1: ",.Q.s1 x;
 };

.test.fn2:{
  -1 "fn2 start(",.Q.s1[x],"), wait 10 sec ",string .z.T;
  async .cep.delay x;
  -1  "fn2 end ",string .z.T;
 };

.cep.enqueue[`.test.fn2;0D00:00:10];
.cep.enqueue[`.test.fn2;.z.P+0D00:00:15];
.cep.enqueue[`.test.fn2;{0D00:00:20}];
.cep.enqueue[`.test.fn2;`.test.tm];
.test.tm:0D00:00:25;

.test.fn3:{
  -1 "fn3: allow fn4 to execute";
  async .cep.yield[];
  -1 "fn3: continue";
 };

.test.fn4:{ -1 "fn4 execued"};

.test.fn3x:{
  async .cep.delay 0D00:00:30; 
  .cep.enqueue[`.test.fn3;100];
  .cep.enqueue[`.test.fn4;100];
 };
.cep.enqueue[`.test.fn3x;100];

.test.fn5:{
  -1 "fn5: wait until fn6 sets var to 1b, check every 5 sec";
  async .cep.wait[{.test.v};0D00:00:05];
  -1 "fn5: done";
 };
.test.fn6:{
  -1 "fn6: delay for 8 sec";
  async .cep.delay 0D00:00:08;
  -1 "fn6: set var";
  .test.v:1b;
 };
.test.v:0b;
.test.fn5x:{
  async .cep.delay 0D00:00:32; 
  .cep.enqueue[`.test.fn5;100];
  .cep.enqueue[`.test.fn6;100];
 };
.cep.enqueue[`.test.fn5x;100];

.test.fn7:{
  -1 "fn7: fork normal fn8";
  async .cep.fork[`.test.fn8;m:.msg.makeMsg `zz`body!(1;"parent: fn7")];
  -1 "fn7: fork exceptional fn9";
  async .cep.fork[`.test.fn9;m];
  -1 "fn7: fork async exceptional fn10";
  async .cep.fork[`.test.fn10;m];
  -1 "fn7: done";
 };
.test.fn8:{
  -1 "fn8: msg received: ",.msg.getf[x;`body];
  async .cep.finish x;
 };
.test.fn9:{
  -1 "fn9: msg received: ",.msg.getf[x;`body];
  '"fn9 exception";
 };
.test.fn10:{
  -1 "fn10: msg received: ",.msg.getf[x;`body];
  async fakeFn ('"fn10 exception");
 };
.test.fn7x:{
  async .cep.delay 0D00:00:43; 
  .cep.enqueue[`.test.fn7;100];
 };
.cep.enqueue[`.test.fn7x;100];

.test.fn11:{
  -1 "fn11: enrich msg via fn12";
  async .cep.enrich[`.test.fn12;m:.msg.makeMsg `zz`body!(1;"parent: fn11");::];
  -1 "fn11: content is: ",.Q.s1 .msg.getf[m;`body];
  -1 "fn11: enrich msg via fn13, that will not finish msg explicitly, use sum as agg";
  async .cep.enrich[`.test.fn13;m;{[m;nm] .msg.set[m;sum .msg.getf[;`body]each (m;nm)]}];
  -1 "fn11: content is: ",.Q.s1 .msg.getf[m;`body];
  -1 "fn11: enrich msg via fn14 that will throw an exception";
  async .[.cep.enrich;(`.test.fn14;m;::);{-1 "fn11: exception is: ",$[.msg.isMsg x;.msg.str x;x]}];
  -1 "fn11: enrich msg via fn15 that will throw an exception";
  async .[.cep.enrich;(`.test.fn15;m;::);{-1 "fn11: exception is: ",$[.msg.isMsg x;.msg.str x;x]}];
  -1 "fn11: cancel this msg in fn16";
  async .[.cep.enrich;(`.test.fn16;m;::);{-1 "fn11: exception is: ",$[.msg.isMsg x;.msg.str x;x]}];
  -1 "fn11: done";
 };
.test.fn12:{
  -1 "fn12: starting, wait for 5 sec";
  .msg.gc[]; .msg.gc[]; / lets ensure gc will not collect any msg
  async .cep.delay 0D00:00:05;
  .msg.gc[]; .msg.gc[];
  -1 "fn12: set body to 100 and explicitly finish msg";
  .msg.set[x;100];
  async .cep.finish x;
 };
.test.fn13:{
  -1 "fn13: starting, set content to 200 and enqueue .test.gc with delay 1 sec that will ensure that this msg is finished";
  .msg.set[x;200];  
  .cep.enqueue[`.test.gc;::];
 };
.test.fn14:{
  -1 "fn14: throw an exception";
  async {x}[];
  '"fn 14 exception";
 };
.test.fn15:{
  -1 "fn15: throw an exception";
  '"fn 15 exception";
 };
.test.fn16:{
  -1 "fn16: cancel the parent msg";
  .cep.cancel enlist .msg.getf[x;`.parent];
  -1 "fn16: finish the current msg";
  async .cep.finish x;
 };
.test.gc:{async .cep.delay 0D00:00:01; -1 "execute gc 2 times"; .msg.gc[]; .msg.gc[]};
.test.fn11x:{
  async .cep.delay 0D00:00:45; 
  .cep.enqueue[`.test.fn11;100];
 };
.cep.enqueue[`.test.fn11x;100];

.test.fn17:{
  -1 "fn17: split msg into 5 msgs using 1 fn18";
  async .cep.split[m:.msg.makeMsg `zz`body!(1;"parent: fn17");`.test.fn18;til 5;::];
  -1 "fn17: content is: ",.Q.s1 .msg.getf[m;`body];
 };
.test.fn18:{
   -1 "fn18: will wait for ",string tm:0D0+`second$v:.msg.getf[x;`body];
   async .cep.delay tm;
   -1 "fn18: return 10*v";
   .msg.set[x;v*10];
   async .cep.finish x;
 };
.test.fn17x:{
  async .cep.delay 0D00:00:02; 
  .cep.enqueue[`.test.fn17;100];
 };
.cep.enqueue[`.test.fn17x;100];