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
