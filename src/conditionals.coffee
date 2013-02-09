noop = "__noop__cc__"

process = ({ regexp, transform }) ->
  (line) ->
    x = line.match(regexp)
    return { line: line } if !x
    [padding, exp] = x.slice(1)
    line: padding + transform(exp)
    altered: true



langs =
  js:
    header: "var #{noop} = function() {};"
    processLine: process
      regexp: /^(\s*)\/\/\s*JSCOV:\s*(.*[^\s])(\s*)$/
      transform: (exp) -> "if (#{exp}) { #{noop}() } else { #{noop}() };"

  coffee:
    header: "#{noop} = (->)"
    processLine: process
      regexp: /^(\s*)#\s*JSCOV:\s*(.*[^\s])(\s*)$/
      transform: (exp) -> "if (#{exp}) then #{noop}() else #{noop}()"



exports.expand = (str, options={}) ->
  lang = options.lang ? 'js'
  result = str.split('\n').map(langs[lang].processLine)
  altered = result.some (x) -> x.altered

  if altered
    langs[lang].header + "\n" + result.map((x) -> x.line).join('\n')
  else
    str
