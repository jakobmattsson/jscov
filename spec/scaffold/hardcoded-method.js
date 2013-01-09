
// are there more kinds of expressions like this that should be tested?
if (false) {
  f();
}

if (1) {
  f();
}

if (0) {
  f();
}


if (false) {
  f();
} else {
  g();
}

if (1) {
  f();
} else {
  g();
}

if (0) {
  f();
} else {
  g();
}





do {
  1
} while (2);


do {
  1
} while (0);

do {
  f();
} while (false);



for ( var i=0; 2; i++ ) {
  f();
}

for ( var i=0; 0; i++ ) {
  f();
}

for ( var i=0; false; i++ ) {
  f();
}



while (0) {
  f();
}

while (true) {
  f();
}

while (5) {
  f();
}


f = function() {
  return 5;
  after();
};
