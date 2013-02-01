// Binary (strings, numbers, booleans)

a = "foo" + "bar" + "baz" + "boz";

b = 1 || 2 && 10 << 2 >> 1 + 1 - 2 % 3 * 4 / 5 ^ 6 | 7 & 8 >>> 9
c = 11 == 11
d = 11 != 11
e = 11 === 11
f = 11 !== 11
g = 11 > 11
h = 11 < 11
i = 11 <= 11
j = 11 >= 11
k = 11 in []
l = 11 instanceof Number
m = 10 - 100;

b = false || true && false << true >> true + true - false % true * false / true ^ false | true & false >>> true
c = false == true
d = false != true
e = false === true
f = false !== true
g = false > true
h = false < true
i = false <= true
j = false >= true
k = false in []
l = false instanceof Number
m = false - true


// Unary (strings, numbers, booleans)

a = !"hej"
a = ~"hej"
a = -"hej"
a = void "hej"

a = !1
a = ~1
a = -1
a = void 0



a = !false
a = ~false
a = -false
a = void false



// Ternary (strings, numbers, booleans)

a = "hello" ? g() : f
a = 1 ? (a+b) : f()
a = true ? 67 : 92

a = "" ? g() : f
a = 0 ? (a+b) : f()
a = false ? 67 : 92


// Comma (strings, numbers, booleans)

a = "1", "2", "3"
a = 1, 2, 3
a = true, false
