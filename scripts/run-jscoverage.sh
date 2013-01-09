rm -rf $2
if [ `which jscoverage` ];
then
  jscoverage --encoding=utf-8 $1 $2
else
  ./node-jscoverage/jscoverage --encoding=utf-8 $1 $2
fi
