var let = 'a';
JSLitmus.test('succ', function(){
  var let = 'a', alphabet = [];

  for (var i=0; i < 26; i++) {
      alphabet.push(let);
      let = _(let).succ();
  }

  return alphabet;
});
