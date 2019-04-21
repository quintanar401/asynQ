\l asyn.q
run1:{[f;a] r1: .[.as.run;(get f;enlist a);100500]; r2:@[get string[f],"S";a;100500]; if[not r1~r2; -1 "ERROR(",string[f],"): ",.Q.s1[r1]," vs ",.Q.s1 r2]};

test1:{[a]
  if[a>10; :a];
  a+:1;
  : async test1 a;
 };
test1S:{[a]
  if[a>10; :a];
  a+:1;
  : test1S a;
 };
run1[`test1;0]

test1v1:{[a]
  if[a>10; :a];
  a+:1;
  : async {[a] if[a>10; :a]; a+:1; : async .z.s a} a;
 };
test1v1S:{[a]
  if[a>10; :a];
  a+:1;
  : {[a] if[a>10; :a]; a+:1; : .z.s a} a;
 };
run1[`test1v1;0]

test1v2:{[a]
  if[a>10; :a];
  f:{[a] if[a>10; :a]; a+:1; : async .z.s a};
  a+:1;
  : async f a;
 };
test1v2S:{[a]
  if[a>10; :a];
  f:{[a] if[a>10; :a]; a+:1; : .z.s a};
  a+:1;
  : f a;
 };
run1[`test1v2;0]

test2:{[a]
  if[a>10; :a];
  a+:1;
  async v: test2 a+1;
  : v-1
 };
test2S:{[a]
  if[a>10; :a];
  a+:1;
  v: test2S a+1;
  : v-1
 };
run1[`test1;0]

test3:{
  a:1; b:2;
  async v: test2 a+b;
  v+a
 };
test3S:{
  a:1; b:2;
  v: test2S a+b;
  v+a
 };
run1[`test3;0]

test4:{
  a:1;
  async test2 a+5
 };
test4S:{
  a:1;
  test2S a+5
 };
run1[`test4;0]

test5:{
  a:1;
  async a:test2 a+5
 };
test5S:{
  a:1;
  a:test2S a+5
 };
run1[`test5;0]

test6:{
  async a:test2 5
 };
test6S:{
  a:test2S 5
 };
run1[`test6;0]

test7:{
  if[1; : async test2 5]
 };
test7S:{
  if[1; : test2S 5]
 };
run1[`test7;0]

test8:{
  if[1; async test2 v:5; :v]
 };
test8S:{
  if[1; test2S v:5; :v]
 };
run1[`test8;0]

test9:{
  if[async test2 v:5; async v2:test2 v; :v2]
 };
test9S:{
  if[test2S v:5; v2:test2S v; :v2]
 };
run1[`test9;0]

test10:{
  $[1; async test2 v:5; 10]
 };
test10S:{
  $[1; test2S v:5; 10]
 };
run1[`test10;0]

test11:{
  $[async v2:test2 v:5; v2+v; 0]
 };
test11S:{
  $[v2:test2S v:5; v2+v; 0]
 };
run1[`test11;0]

test12:{async test2 5; 0};
test12S:{test2S 5; 0};
run1[`test12;0]

test13:{
  $[async test12 1; 1; 10]
 };
test13S:{
  $[test12S 1; 1; 10]
 };
run1[`test13;0]

test14:{
  $[async test2 1; 1; 10]
 };
test14S:{
  $[test2S 1; 1; 10]
 };
run1[`test14;0]

test15:{
  $[async test12 1; 1; async test2 2;2;3 ]
 };
test15S:{
  $[test12S 1; 1; test2S 2;2;3 ]
 };
run1[`test15;0]

test16:{
  v:1;
  while[async test2 1; v+:1; if[v>10; :v]]
 };
test16S:{
  v:1;
  while[test2S 1; v+:1; if[v>10; :v]]
 };
run1[`test16;0]

test17:{
  v:1;
  do[async test2 1; v+:1]; v
 };
test17S:{
  v:1;
  do[test2S 1; v+:1]; v
 };
run1[`test17;0]

test18:{
  v:1;
  do[async test2 1; do[async test1 1; v+:1]]; v
 };
test18S:{
  v:1;
  do[test2S 1; do[test1S 1; v+:1]]; v
 };
run1[`test18;0]

test19:{
  tmp::1;
  async tmp::test2 1;
  tmp
 };
test19S:{
  tmp::1;
  tmp::test2S 1;
  tmp
 };
run1[`test19;0]

test20:{ .z.s 1; async {x} 10};
test20S:{'"aaa"};
run1[`test20;0]

test21:{
  if[x=10000; :x];
  if[x mod 2; : async .z.s x+1];
  async .z.s x+1
 };
test21S:{10000};
run1[`test21;0]

test22:{
  f:{ '"zzz"; async {x} 1};
  async r:@[f;1;{x,"aaa"}];
  r
 };
test22S:{
  f:{ '"zzz"; {x} 1};
  r:@[f;1;{x,"aaa"}];
  r
 };
run1[`test22;0]

test23:{
  f:{y; '"zzz"; async {x} 1};
  async r:.[f;1 2;{x,"aaa"}];
  r
 };
test23S:{
  f:{y; '"zzz"; {x} 1};
  r:.[f;1 2;{x,"aaa"}];
  r
 };
run1[`test23;0]

test24:{
  f:{ '"zzz"; async {x} 1};
  async @[f;1;{x,"aaa"}]
 };
test24S:{
  f:{ '"zzz"; {x} 1};
  @[f;1;{x,"aaa"}]
 };
run1[`test24;0]

test25:{
  g:{ f:{ '"zzz"; async {x} 1}; async f 1; 0};
  async @[g;1;{x,"aaa"}]
 };
test25S:{
  g:{ f:{ '"zzz"; {x} 1}; f 1; 0};
  @[g;1;{x,"aaa"}]
 };
run1[`test25;0]

test26:{
  f:{ '"zzz"; async {x} 1};
  : async @[f;1;{x,"aaa"}];
 };
test26S:{
  f:{ '"zzz"; {x} 1};
  : @[f;1;{x,"aaa"}];
 };
run1[`test26;0]

test27:{
  f:{[cont;x] g:{[cont;x] test27C::cont; async v:test1 x; : cont v*10}; async g[cont;x]; `never_reached};
  async .as.callcc[f;1]
 };
test27S:{110};
run1[`test27;1]

test28:{
   async .as.each[{async test1 x};enlist 1 2 3]
 };
test28S:{
  {test1S x} each 1 2 3
 };
run1[`test28;1]

test29:{
   async .as.each[{async v1:test1 x; async v2:test1 y; v1+v2};(1 2 3;3 2 1)]
 };
test29S:{
  {test1S[x]+test1S[y]}'[1 2 3;3 2 1]
 };
run1[`test29;1]

test30:{
   async .as.each[{async v1:test1 x; async v2:test1 y; v1+v2};(`a`b!(1 2 3;3 2 1);4 5)]
 };
test30S:{
  {test1S[x]+test1S[y]}'[`a`b!(1 2 3;3 2 1);4 5]
 };
run1[`test30;1]

test31:{
   async .as.each[{async v1:test1 x; async v2:test1 y; v1+v2};(`a`b!(1 2 3;3 2 1);`a`b!(4 5 6;6 5 4))]
 };
test31S:{
  {test1S[x]+test1S[y]}'[`a`b!(1 2 3;3 2 1);`a`b!(4 5 6;6 5 4)]
 };
run1[`test31;1]

test32:{
   async .as.over[{async test1 x};1]
 };
test32S:{
  {test1S x}/[1]
 };
run1[`test32;1]

test33:{
   async .as.scan[{async test1 x};1]
 };
test33S:{
  {test1S x}\[1]
 };
run1[`test33;1]

test34:{
   async .as.over[{async test1 x};(3;1)]
 };
test34S:{
  {test1S x}/[3;1]
 };
run1[`test34;1]

test35:{
   async .as.scan[{async test1 x};(3;1)]
 };
test35S:{
  {test1S x}\[3;1]
 };
run1[`test35;1]

test36:{
   async .as.over[{async test1 x};({x<10};1)]
 };
test36S:{
  {test1S x}/[{x<10};1]
 };
run1[`test36;1]

test37:{
   async .as.scan[{async test1 x};({x<10};1)]
 };
test37S:{
  {test1S x}\[{x<10};1]
 };
run1[`test37;1]

test38:{
   async .as.over[{async test1 x};({async test1 x; x<10};1)]
 };
test38S:{
  {test1S x}/[{x<10};1]
 };
run1[`test38;1]

test39:{
   async .as.over[{async v:test1 y; v+x};(1 2;`a`b!1 2)]
 };
test39S:{
  {test1S[y]+x}/[1 2;`a`b!1 2]
 };
run1[`test39;1]

test40:{
   async .as.scan[{async v:test1 y; v+x};(1 2;`a`b!1 2)]
 };
test40S:{
  {test1S[y]+x}\[1 2;`a`b!1 2]
 };
run1[`test40;1]

test41:{
   async .as.over[{async v:test1 y; v+x};(1 2;1 2)]
 };
test41S:{
  {test1S[y]+x}/[1 2;1 2]
 };
run1[`test41;1]

test42:{
   async .as.scan[{async v:test1 y; v+x};(1 2;1 2)]
 };
test42S:{
  {test1S[y]+x}\[1 2;1 2]
 };
run1[`test42;1]

test43:{
   async .as.over[{async v:test1 y; v+x};(1;2)]
 };
test43S:{
  {test1S[y]+x}/[1;2]
 };
run1[`test43;1]

test44:{
  f:{async v:test1 x; v+y}[;10];
  async r:f 1;
  :r;
 };
test44S:{
  r:{v:test1S x; v+y}[;10] 1;
  :r;
 };
run1[`test44;1]

test45:{
  f:{i:0; async .as.iRet 0; while[1; async .as.iRet i; i+:1]};
  f:.as.iCall[f;1]; / init
  while[1; f:.as.iNext[f;1]; if[5=last f; :last f]]; 
 };
test45S:{5};
run1[`test45;1];