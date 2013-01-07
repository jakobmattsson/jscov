function trailing_semicolon() {
  return 1
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


// Semicomon trailing after variable declaration
var dirname = require._core[filename]
    ? ''
    : require.modules.path().dirname(filename)
;
