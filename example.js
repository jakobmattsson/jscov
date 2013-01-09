{ type: 'Program',
  body: 
   [ { type: 'FunctionDeclaration',
       id: 
        { type: 'Identifier',
          name: 'trailing_semicolon',
          loc: { start: { line: 1, column: 9 }, end: { line: 1, column: 27 } } },
       params: [],
       defaults: [],
       body: 
        { type: 'BlockStatement',
          body: 
           [ { type: 'ReturnStatement',
               argument: 
                { type: 'Literal',
                  value: 1,
                  loc: { start: { line: 2, column: 9 }, end: { line: 2, column: 10 } } },
               loc: { start: { line: 2, column: 2 }, end: { line: 3, column: 2 } } },
             { type: 'EmptyStatement',
               loc: { start: { line: 3, column: 2 }, end: { line: 3, column: 3 } } } ],
          loc: { start: { line: 1, column: 30 }, end: { line: 4, column: 1 } } },
       rest: null,
       generator: false,
       expression: false,
       loc: { start: { line: 1, column: 0 }, end: { line: 4, column: 1 } } },
     { type: 'ExpressionStatement',
       expression: 
        { type: 'FunctionExpression',
          id: 
           { type: 'Identifier',
             name: 'fExamineSyntacticCodeUnit',
             loc: 
              { start: { line: 14, column: 10 },
                end: { line: 14, column: 35 } } },
          params: 
           [ { type: 'Identifier',
               name: 'oSyntacticCodeUnit',
               loc: 
                { start: { line: 14, column: 36 },
                  end: { line: 14, column: 54 } } } ],
          defaults: [],
          body: 
           { type: 'BlockStatement',
             body: [],
             loc: 
              { start: { line: 14, column: 56 },
                end: { line: 16, column: 2 } } },
          rest: null,
          generator: false,
          expression: false,
          loc: { start: { line: 14, column: 1 }, end: { line: 16, column: 2 } } },
       loc: { start: { line: 7, column: 0 }, end: { line: 18, column: 0 } } } ],
  loc: { start: { line: 1, column: 0 }, end: { line: 18, column: 0 } } }
