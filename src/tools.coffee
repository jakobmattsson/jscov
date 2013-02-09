



exports.replaceProperties = (obj, newProps) ->
  props = Object.getOwnPropertyNames(obj)
  props.forEach (prop) -> delete obj[prop]

  Object.getOwnPropertyNames(newProps).forEach (prop) ->
    obj[prop] = newProps[prop]



exports.strToNumericEntity = (str) ->
  symbols = [0...str.length].map (i) ->
    charCode = str.charCodeAt(i)
    if charCode < 128
      str[i]
    else
      '&#' + charCode + ';'
  symbols.join('')
