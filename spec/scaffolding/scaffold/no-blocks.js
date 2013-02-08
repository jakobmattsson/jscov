b = function () {
  if (1)
    return function () {
      if (2)
        return 3;
      else
        return 2;
    }();
  else
    return 1;

  if (0)
    return 'b';
  else
    return 'a';
}();
console.log(b)
