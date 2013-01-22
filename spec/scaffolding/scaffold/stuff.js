// regexp
reg = /\\$[0-9]^/


// floats
a = 0.000001
b = 0.00000000000001
c = 1.000001
d = 1.00000000000001
e = 1/3
f = 0.123456789123456789123456789
g = 0.12345678912345678123
h = 0.1234567891234567849
i = 0.1234567891234567850


// Computed NaN-literals
var x = 0 / 0;



// property lookup
x["y"].f();
x["with"].f();
x["6"].f();
x["06"].f();
x["0xAB"].f();
x["6x"].f();
x["+++y"].f();


while (true) { }
while ("hej") { }
while (123) { }


n = 1e+400
m = Number.POSITIVE_INFINITY

p =  1 /  0
q = -1 /  0
r =  1 / -0
s = -1 / -0



// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS”

str = "HOLDER “AS IS”"

str = "åäö"

myvaråäö = 1
x['$variable'] = 1


x.myvaråäö.f();
x['myvaråäö'].f();








function trailing_semicolon() {
  return 1
  ;
}


function fake_trailing_semicolon() {
  return 1;
  ;
}



;(
  // Comment between
  function() {}
);


;(
  // Comment between
  f()+g()
);


;(
  // Comment between
  function a() {
}(1));


// Semicolon trailing after variable declaration
var dirname = 10
;

// Fake semicolon trailing after variable declaration
var dirname = 11;
;


var apa = 1,
  x = 2;


var apa = 1,
  x = 2;
;






1+2
;

f()
;


