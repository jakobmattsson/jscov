rm -rf $2
if [ `which jscoverage` ];
then
  jscoverage --js-version=1.8 --encoding=utf-8 $1 $2
else
  ./node-jscoverage/jscoverage --js-version=1.8 --encoding=utf-8 $1 $2
fi
