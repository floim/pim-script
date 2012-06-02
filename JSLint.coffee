fs = require 'fs'
vm = require 'vm'
util = require 'util'
parser = require("uglify-js").parser
uglify = require("uglify-js").uglify
ctx = vm.createContext()
vm.runInContext fs.readFileSync(__dirname + "/jslint.js"), ctx
JSLINT = ctx.JSLINT

try
  if process.argv.length < 3
    throw new Error "No file specified"
  filename = process.argv[2]
  script = fs.readFileSync filename, 'utf8'
catch e
  console.log "File could not be read"
  process.exit 1

details = null
re = /\/\*\!(?:FLO|P)IM_PLUGIN([\s\S]+)\*\//
script = script.replace re, (header) ->
  matches = header.match re
  if matches
    try
      details = JSON.parse matches[1]
  return ""
unless details?
  console.error "There are no details!"
  process.exit 1

details.id = 2
details.revision = 1

# Alias dependencies.
accessList = details.access ? []
accessList.unshift "app"
accessList.unshift "plugin"
for access in accessList
  script = "  var #{access} = lib.#{access}();\n#{script}"

walk = (ast) ->
  if Array.isArray(ast) and ast.length > 0
    type = ast[0]
    if type is 'toplevel'
      for ast2, i in ast[1]
        ast[1][i] = walk ast2
    else if type is 'var'
      #skip
    else if type is 'new'
      #skip
      ast[1] = walk ast[1]
      for ast2,i in ast[2]
        ast[2][i] = walk ast[2][i]
      if ast[2].length is 0
        ast[2].push ['name','null']
    else if type is 'num'
      #skip
    else if type is 'regexp'
      #skip
    else if type is 'unary-prefix'
      ast[2] = walk ast[2]
    else if type is 'name'
      #skip
    else if type is 'sub'
      ast[1] = walk ast[1]
      base = ast[1]
      property = walk ast[2]
      if property[0] isnt 'num'
        ast = [
          'call'
          [
            'dot',
            ['name', 'ADSAFE'],
            'get'
          ]
          [
            base
            property
          ]
        ]
    else if type is 'return'
      ast[1] = walk ast[1]
    else if type is 'binary'
      operation = ast[1]
      ast[2] = walk ast[2]
      ast[3] = walk ast[3]
    else if type is 'call'
      funcName = ast[1]
      if ast[1][0] is 'dot'
        ast[1][1] = walk ast[1][1]
      else
        ast[1] = walk ast[1]
      params = ast[2]
      for ast2, i in ast[2]
        ast[2][i] = walk ast2
      if funcName[0] is 'name'
        if funcName[1] is 'parseInt'
          if params.length is 1
            ast[2].push ['num', 10]
        else if funcName[1] is 'setTimeout'
          ast[1] = [
            'dot'
            ['name', 'ADSAFE']
            'later'
          ]
    else if type is 'if'
      condition = ast[1]
      ast[1] = walk ast[1]
      ast[2] = walk ast[2]
      ast[3] = walk ast[3]
    else if type is 'while'
      #skip
      ast[2] = walk ast[2]
      if ast[1][0] is 'assign'
        # Rewrite this as a for loop
        if ast[2][0] isnt 'block'
          ast[2] = [
            'block'
            [
              ast[2]
            ]
          ]
        ast[2][1].unshift [
          'if'
          [
            'unary-prefix'
            '!'
            ast[1][2]
          ]
          [
            'block'
            [
              [
                'break'
                null
              ]
            ]
          ]
          undefined
        ]
        ast[2][1].unshift [
          'stat'
          ast[1]
        ]
        ast = [
          'for'
          null
          null
          null
          ast[2]
        ]
    else if type is 'block'
      for ast2, i in ast[1]
        ast[1][i] = walk ast2
    else if type is 'function'
      #skip ('function', name, arguments, ast)
      for ast2, i in ast[3]
        ast[3][i] = walk ast2
    else if type is 'stat'
      ast[1] = walk ast[1]
    else if type is 'assign'
      if ast[2][0] is 'dot'
        # Base:
        base = walk ast[2][1]
        # property:
        property = ast[2][2]
        # value
        value = walk ast[3]
        ast = [
          'call'
          [
            'dot',
            ['name', 'ADSAFE'],
            'set'
          ]
          [
            base
            ['string', property]
            value
          ]
        ]
      else
        ast[2] = walk ast[2]
        ast[3] = walk ast[3]
    else if type is 'dot'
      # Base:
      base = walk ast[1]
      # property:
      property = ast[2]
      ast = [
        'call'
        [
          'dot',
          ['name', 'ADSAFE'],
          'get'
        ]
        [
          base
          ['string', property]
        ]
      ]
    else if type is 'string'
      a = ast[1].indexOf("</")
      if a > -1
        ast = [
          'binary'
          '+'
          [
            'string'
            ast[1].substr(0,a+1)
          ]
          walk [
            'string'
            ast[1].substr(a+1)
          ]
        ]
    else
      console.error "Unknown type: '#{type}'"
      console.log util.inspect ast, false, null, true
  return ast
ast = parser.parse script
console.log util.inspect ast, false, null, true
walk ast, 0
ast = uglify.ast_mangle ast, {
  mangle: true
  toplevel: true
  defines: {'this':['name', "null"]}
}
#ast = uglify.ast_squeeze ast
script = uglify.gen_code ast, beautify: true, indent_start:4, indent_level:2, quote_keys: true
console.log script

script = script.replace /(\n|^)\/\/.*(\n|$)/g, "$2"
num2alphabet = (num) ->
  chars = "ABCDEFGHIJ".split("")
  num = parseInt num
  if isNaN(num) or !isFinite(num)
    throw new Error "Invalid number"
  num = ""+num
  out = ""
  for i in [0...num.length]
    out += chars[parseInt num.charAt(i)]
  return out
id = details.id
adsafeId = "ZZZ#{num2alphabet id}_"
head = "<div id=\"#{adsafeId}\"><script>\n"
foot = "</script>\n</div>"
script = "#{head}  ADSAFE.go(\"#{adsafeId}\", function (dom, lib) {\n    \"use strict\";\n#{script}\n  });#{foot}"
ok = JSLINT script, {
  adsafe: true, fragment: true, predef: [], browser: true, safe: true, bitwise: true, continue: true, eqeq: true, es5: true, evil: false, forin: true, newcap: true, nomen: true, plusplus: true, regexp: true, undef: true, unparam: true, sloppy: true, stupid: true, sub: true, vars: true, white: true, css: true
}, {
  plugin: false
}
unless ok
  console.error "FAIL"
  result = JSLINT.data()
  console.log util.inspect result, false, 3, true
else
  script = script.substr(head.length, script.length - (head.length+foot.length))
  script = "new ADSAFE_APP(#{id}, \"#{adsafeId}\", #{JSON.stringify(details)}, function(ADSAFE){\n#{script}\n});"
  fs.writeFileSync "#{filename}.adsafe.js", script
  console.log script
