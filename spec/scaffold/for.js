if (process.env.NODE_ENV !== 'production')
  for (key in require.cache)
    delete require.cache[key];

for (var i=0; i<10; i++ ) {
  a();
  b();
}

b = Math.random()

for (var i=0; i<10; i++ )
  c();

if (b)
  d();

if (b)
  e();
else
  f();

if (b > 1)
  g();
else if (b > 2)
  h();
else if (b > 3)
  i();
else
  j();

while (b) {
  g()
}

while (!b)
  g()



while (1+1) {
  f();
}



