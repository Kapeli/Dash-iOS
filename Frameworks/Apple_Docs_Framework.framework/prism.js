/* PrismJS 1.14.0
 https://prismjs.com/download.html#themes=prism&languages=markup+css+clike+javascript+c+cpp+json+markdown+objectivec */
var _self = (typeof window !== 'undefined')
? window   // if in browser
: (
   (typeof WorkerGlobalScope !== 'undefined' && self instanceof WorkerGlobalScope)
   ? self // if in worker
   : {}   // if in node js
   );

/**
 * Prism: Lightweight, robust, elegant syntax highlighting
 * MIT license http://www.opensource.org/licenses/mit-license.php/
 * @author Lea Verou http://lea.verou.me
 */

var Prism = (function(){
             
             // Private helper vars
             var lang = /\blang(?:uage)?-([\w-]+)\b/i;
             var uniqueId = 0;
             
             var _ = _self.Prism = {
             manual: _self.Prism && _self.Prism.manual,
             disableWorkerMessageHandler: _self.Prism && _self.Prism.disableWorkerMessageHandler,
             util: {
             encode: function (tokens) {
             if (tokens instanceof Token) {
             return new Token(tokens.type, _.util.encode(tokens.content), tokens.alias);
             } else if (_.util.type(tokens) === 'Array') {
             return tokens.map(_.util.encode);
             } else {
             return tokens.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/\u00a0/g, ' ');
             }
             },
             
             type: function (o) {
             return Object.prototype.toString.call(o).match(/\[object (\w+)\]/)[1];
             },
             
             objId: function (obj) {
             if (!obj['__id']) {
             Object.defineProperty(obj, '__id', { value: ++uniqueId });
             }
             return obj['__id'];
             },
             
             // Deep clone a language definition (e.g. to extend it)
             clone: function (o, visited) {
             var type = _.util.type(o);
             visited = visited || {};
             
             switch (type) {
             case 'Object':
             if (visited[_.util.objId(o)]) {
             return visited[_.util.objId(o)];
             }
             var clone = {};
             visited[_.util.objId(o)] = clone;
             
             for (var key in o) {
             if (o.hasOwnProperty(key)) {
             clone[key] = _.util.clone(o[key], visited);
             }
             }
             
             return clone;
             
             case 'Array':
             if (visited[_.util.objId(o)]) {
             return visited[_.util.objId(o)];
             }
             var clone = [];
             visited[_.util.objId(o)] = clone;
             
             o.forEach(function (v, i) {
                       clone[i] = _.util.clone(v, visited);
                       });
             
             return clone;
             }
             
             return o;
             }
             },
             
             languages: {
             extend: function (id, redef) {
             var lang = _.util.clone(_.languages[id]);
             
             for (var key in redef) {
             lang[key] = redef[key];
             }
             
             return lang;
             },
             
             /**
              * Insert a token before another token in a language literal
              * As this needs to recreate the object (we cannot actually insert before keys in object literals),
              * we cannot just provide an object, we need anobject and a key.
              * @param inside The key (or language id) of the parent
              * @param before The key to insert before. If not provided, the function appends instead.
              * @param insert Object with the key/value pairs to insert
              * @param root The object that contains `inside`. If equal to Prism.languages, it can be omitted.
              */
             insertBefore: function (inside, before, insert, root) {
             root = root || _.languages;
             var grammar = root[inside];
             
             if (arguments.length == 2) {
             insert = arguments[1];
             
             for (var newToken in insert) {
             if (insert.hasOwnProperty(newToken)) {
             grammar[newToken] = insert[newToken];
             }
             }
             
             return grammar;
             }
             
             var ret = {};
             
             for (var token in grammar) {
             
             if (grammar.hasOwnProperty(token)) {
             
             if (token == before) {
             
             for (var newToken in insert) {
             
             if (insert.hasOwnProperty(newToken)) {
             ret[newToken] = insert[newToken];
             }
             }
             }
             
             ret[token] = grammar[token];
             }
             }
             
             // Update references in other language definitions
             _.languages.DFS(_.languages, function(key, value) {
                             if (value === root[inside] && key != inside) {
                             this[key] = ret;
                             }
                             });
             
             return root[inside] = ret;
             },
             
             // Traverse a language definition with Depth First Search
             DFS: function(o, callback, type, visited) {
             visited = visited || {};
             for (var i in o) {
             if (o.hasOwnProperty(i)) {
             callback.call(o, i, o[i], type || i);
             
             if (_.util.type(o[i]) === 'Object' && !visited[_.util.objId(o[i])]) {
             visited[_.util.objId(o[i])] = true;
             _.languages.DFS(o[i], callback, null, visited);
             }
             else if (_.util.type(o[i]) === 'Array' && !visited[_.util.objId(o[i])]) {
             visited[_.util.objId(o[i])] = true;
             _.languages.DFS(o[i], callback, i, visited);
             }
             }
             }
             }
             },
             plugins: {},
             
             highlightAll: function(async, callback) {
             _.highlightAllUnder(document, async, callback);
             },
             
             highlightAllUnder: function(container, async, callback) {
             var env = {
             callback: callback,
             selector: 'code[class*="language-"], [class*="language-"] code, code[class*="lang-"], [class*="lang-"] code'
             };
             
             _.hooks.run("before-highlightall", env);
             
             var elements = env.elements || container.querySelectorAll(env.selector);
             
             for (var i=0, element; element = elements[i++];) {
             _.highlightElement(element, async === true, env.callback);
             }
             },
             
             highlightElement: function(element, async, callback) {
             // Find language
             var language, grammar, parent = element;
             
             while (parent && !lang.test(parent.className)) {
             parent = parent.parentNode;
             }
             
             if (parent) {
             language = (parent.className.match(lang) || [,''])[1].toLowerCase();
             grammar = _.languages[language];
             }
             
             // Set language on the element, if not present
             element.className = element.className.replace(lang, '').replace(/\s+/g, ' ') + ' language-' + language;
             
             if (element.parentNode) {
             // Set language on the parent, for styling
             parent = element.parentNode;
             
             if (/pre/i.test(parent.nodeName)) {
             parent.className = parent.className.replace(lang, '').replace(/\s+/g, ' ') + ' language-' + language;
             }
             }
             
             var code = element.textContent;
             
             var env = {
             element: element,
             language: language,
             grammar: grammar,
             code: code
             };
             
             _.hooks.run('before-sanity-check', env);
             
             if (!env.code || !env.grammar) {
             if (env.code) {
             _.hooks.run('before-highlight', env);
             env.element.textContent = env.code;
             _.hooks.run('after-highlight', env);
             }
             _.hooks.run('complete', env);
             return;
             }
             
             _.hooks.run('before-highlight', env);
             
             if (async && _self.Worker) {
             var worker = new Worker(_.filename);
             
             worker.onmessage = function(evt) {
             env.highlightedCode = evt.data;
             
             _.hooks.run('before-insert', env);
             
             env.element.innerHTML = env.highlightedCode;
             
             callback && callback.call(env.element);
             _.hooks.run('after-highlight', env);
             _.hooks.run('complete', env);
             };
             
             worker.postMessage(JSON.stringify({
                                               language: env.language,
                                               code: env.code,
                                               immediateClose: true
                                               }));
             }
             else {
             env.highlightedCode = _.highlight(env.code, env.grammar, env.language);
             
             _.hooks.run('before-insert', env);
             
             env.element.innerHTML = env.highlightedCode;
             
             callback && callback.call(element);
             
             _.hooks.run('after-highlight', env);
             _.hooks.run('complete', env);
             }
             },
             
             highlight: function (text, grammar, language) {
             var env = {
             code: text,
             grammar: grammar,
             language: language
             };
             _.hooks.run('before-tokenize', env);
             env.tokens = _.tokenize(env.code, env.grammar);
             _.hooks.run('after-tokenize', env);
             return Token.stringify(_.util.encode(env.tokens), env.language);
             },
             
             matchGrammar: function (text, strarr, grammar, index, startPos, oneshot, target) {
             var Token = _.Token;
             
             for (var token in grammar) {
             if(!grammar.hasOwnProperty(token) || !grammar[token]) {
             continue;
             }
             
             if (token == target) {
             return;
             }
             
             var patterns = grammar[token];
             patterns = (_.util.type(patterns) === "Array") ? patterns : [patterns];
             
             for (var j = 0; j < patterns.length; ++j) {
             var pattern = patterns[j],
             inside = pattern.inside,
             lookbehind = !!pattern.lookbehind,
             greedy = !!pattern.greedy,
             lookbehindLength = 0,
             alias = pattern.alias;
             
             if (greedy && !pattern.pattern.global) {
             // Without the global flag, lastIndex won't work
             var flags = pattern.pattern.toString().match(/[imuy]*$/)[0];
             pattern.pattern = RegExp(pattern.pattern.source, flags + "g");
             }
             
             pattern = pattern.pattern || pattern;
             
             // Don’t cache length as it changes during the loop
             for (var i = index, pos = startPos; i < strarr.length; pos += strarr[i].length, ++i) {
             
             var str = strarr[i];
             
             if (strarr.length > text.length) {
             // Something went terribly wrong, ABORT, ABORT!
             return;
             }
             
             if (str instanceof Token) {
             continue;
             }
             
             if (greedy && i != strarr.length - 1) {
             pattern.lastIndex = pos;
             var match = pattern.exec(text);
             if (!match) {
             break;
             }
             
             var from = match.index + (lookbehind ? match[1].length : 0),
             to = match.index + match[0].length,
             k = i,
             p = pos;
             
             for (var len = strarr.length; k < len && (p < to || (!strarr[k].type && !strarr[k - 1].greedy)); ++k) {
             p += strarr[k].length;
             // Move the index i to the element in strarr that is closest to from
             if (from >= p) {
             ++i;
             pos = p;
             }
             }
             
             // If strarr[i] is a Token, then the match starts inside another Token, which is invalid
             if (strarr[i] instanceof Token) {
             continue;
             }
             
             // Number of tokens to delete and replace with the new match
             delNum = k - i;
             str = text.slice(pos, p);
             match.index -= pos;
             } else {
             pattern.lastIndex = 0;
             
             var match = pattern.exec(str),
             delNum = 1;
             }
             
             if (!match) {
             if (oneshot) {
             break;
             }
             
             continue;
             }
             
             if(lookbehind) {
             lookbehindLength = match[1] ? match[1].length : 0;
             }
             
             var from = match.index + lookbehindLength,
             match = match[0].slice(lookbehindLength),
             to = from + match.length,
             before = str.slice(0, from),
             after = str.slice(to);
             
             var args = [i, delNum];
             
             if (before) {
             ++i;
             pos += before.length;
             args.push(before);
             }
             
             var wrapped = new Token(token, inside? _.tokenize(match, inside) : match, alias, match, greedy);
             
             args.push(wrapped);
             
             if (after) {
             args.push(after);
             }
             
             Array.prototype.splice.apply(strarr, args);
             
             if (delNum != 1)
             _.matchGrammar(text, strarr, grammar, i, pos, true, token);
             
             if (oneshot)
             break;
             }
             }
             }
             },
             
             tokenize: function(text, grammar, language) {
             var strarr = [text];
             
             var rest = grammar.rest;
             
             if (rest) {
             for (var token in rest) {
             grammar[token] = rest[token];
             }
             
             delete grammar.rest;
             }
             
             _.matchGrammar(text, strarr, grammar, 0, 0, false);
             
             return strarr;
             },
             
             hooks: {
             all: {},
             
             add: function (name, callback) {
             var hooks = _.hooks.all;
             
             hooks[name] = hooks[name] || [];
             
             hooks[name].push(callback);
             },
             
             run: function (name, env) {
             var callbacks = _.hooks.all[name];
             
             if (!callbacks || !callbacks.length) {
             return;
             }
             
             for (var i=0, callback; callback = callbacks[i++];) {
             callback(env);
             }
             }
             }
             };
             
             var Token = _.Token = function(type, content, alias, matchedStr, greedy) {
             this.type = type;
             this.content = content;
             this.alias = alias;
             // Copy of the full string this token was created from
             this.length = (matchedStr || "").length|0;
             this.greedy = !!greedy;
             };
             
             Token.stringify = function(o, language, parent) {
             if (typeof o == 'string') {
             return o;
             }
             
             if (_.util.type(o) === 'Array') {
             return o.map(function(element) {
                          return Token.stringify(element, language, o);
                          }).join('');
             }
             
             var env = {
             type: o.type,
             content: Token.stringify(o.content, language, parent),
             tag: 'span',
             classes: ['token', o.type],
             attributes: {},
             language: language,
             parent: parent
             };
             
             if (o.alias) {
             var aliases = _.util.type(o.alias) === 'Array' ? o.alias : [o.alias];
             Array.prototype.push.apply(env.classes, aliases);
             }
             
             _.hooks.run('wrap', env);
             
             var attributes = Object.keys(env.attributes).map(function(name) {
                                                              return name + '="' + (env.attributes[name] || '').replace(/"/g, '&quot;') + '"';
                                                                                                                        }).join(' ');
                                                              
                                                              return '<' + env.tag + ' class="' + env.classes.join(' ') + '"' + (attributes ? ' ' + attributes : '') + '>' + env.content + '</' + env.tag + '>';
                                                              
                                                              };
                                                              
                                                              if (!_self.document) {
                                                              if (!_self.addEventListener) {
                                                              // in Node.js
                                                              return _self.Prism;
                                                              }
                                                              
                                                              if (!_.disableWorkerMessageHandler) {
                                                              // In worker
                                                              _self.addEventListener('message', function (evt) {
                                                                                     var message = JSON.parse(evt.data),
                                                                                     lang = message.language,
                                                                                     code = message.code,
                                                                                     immediateClose = message.immediateClose;
                                                                                     
                                                                                     _self.postMessage(_.highlight(code, _.languages[lang], lang));
                                                                                     if (immediateClose) {
                                                                                     _self.close();
                                                                                     }
                                                                                     }, false);
                                                              }
                                                              
                                                              return _self.Prism;
                                                              }
                                                              
                                                              //Get current script and highlight
                                                              var script = document.currentScript || [].slice.call(document.getElementsByTagName("script")).pop();
                                                              
                                                              if (script) {
                                                              _.filename = script.src;
                                                              
                                                              if (!_.manual && !script.hasAttribute('data-manual')) {
                                                              if(document.readyState !== "loading") {
                                                              if (window.requestAnimationFrame) {
                                                              window.requestAnimationFrame(_.highlightAll);
                                                              } else {
                                                              window.setTimeout(_.highlightAll, 16);
                                                              }
                                                              }
                                                              else {
                                                              document.addEventListener('DOMContentLoaded', _.highlightAll);
                                                              }
                                                              }
                                                              }
                                                              
                                                              return _self.Prism;
                                                              
                                                              })();
             
             if (typeof module !== 'undefined' && module.exports) {
             module.exports = Prism;
             }
             
             // hack for components to work correctly in node.js
             if (typeof global !== 'undefined') {
             global.Prism = Prism;
             }
             ;
             Prism.languages.markup = {
             'syntax-comment': /<!--[\s\S]*?-->/,
             'prolog': /<\?[\s\S]+?\?>/,
             'doctype': /<!DOCTYPE[\s\S]+?>/i,
             'cdata': /<!\[CDATA\[[\s\S]*?]]>/i,
             'tag': {
             pattern: /<\/?(?!\d)[^\s>\/=$<%]+(?:\s+[^\s>\/=]+(?:=(?:("|')(?:\\[\s\S]|(?!\1)[^\\])*\1|[^\s'">=]+))?)*\s*\/?>/i,
                                               greedy: true,
                                               inside: {
                                               'tag': {
                                               pattern: /^<\/?[^\s>\/]+/i,
                                               inside: {
                                               'punctuation': /^<\/?/,
                                               'namespace': /^[^\s>\/:]+:/
                                               }
                                               },
                                               'attr-value': {
                                               pattern: /=(?:("|')(?:\\[\s\S]|(?!\1)[^\\])*\1|[^\s'">=]+)/i,
                                                           inside: {
                                                           'punctuation': [
                                                                           /^=/,
                                                                           {
                                                                           pattern: /(^|[^\\])["']/,
                                                                                               lookbehind: true
                                                                                               }
                                                                                               ]
                                                                           }
                                                                           },
                                                                           'punctuation': /\/?>/,
                                                                           'attr-name': {
                                                                           pattern: /[^\s>\/]+/,
                                                                           inside: {
                                                                           'namespace': /^[^\s>\/:]+:/
                                                                           }
                                                                           }
                                                                           
                                                                           }
                                                                           },
                                                                           'entity': /&#?[\da-z]{1,8};/i
                                                                           };
                                                                           
                                                                           Prism.languages.markup['tag'].inside['attr-value'].inside['entity'] =
                                                                           Prism.languages.markup['entity'];
                                                                           
                                                                           // Plugin to make entity title show the real entity, idea by Roman Komarov
                                                                           Prism.hooks.add('wrap', function(env) {
                                                                                           
                                                                                           if (env.type === 'entity') {
                                                                                           env.attributes['title'] = env.content.replace(/&amp;/, '&');
                                                                                           }
                                                                                           });
                                                                           
                                                                           Prism.languages.xml = Prism.languages.markup;
                                                                           Prism.languages.html = Prism.languages.markup;
                                                                           Prism.languages.mathml = Prism.languages.markup;
                                                                           Prism.languages.svg = Prism.languages.markup;
                                                                           
                                                                           Prism.languages.css = {
                                                                           'syntax-comment': /\/\*[\s\S]*?\*\//,
                                                                           'atrule': {
                                                                           pattern: /@[\w-]+?.*?(?:;|(?=\s*\{))/i,
                                                                           inside: {
                                                                           'rule': /@[\w-]+/
                                                                           // See rest below
                                                                           }
                                                                           },
                                                                           'url': /url\((?:(["'])(?:\\(?:\r\n|[\s\S])|(?!\1)[^\\\r\n])*\1|.*?)\)/i,
                                                                                             'syntax-keyword': /[^{}\s][^{};]*?(?=\s*\{)/,
                                                                                             'syntax-string': {
                                                                                             pattern: /("|')(?:\\(?:\r\n|[\s\S])|(?!\1)[^\\\r\n])*\1/,
                                                                                                        greedy: true
                                                                                                        },
                                                                                                        'property': /[-_a-z\xA0-\uFFFF][-\w\xA0-\uFFFF]*(?=\s*:)/i,
                                                                                                        'important': /\B!important\b/i,
                                                                                                        'function': /[-a-z0-9]+(?=\()/i,
                                                                                                                                };
                                                                                                                                
                                                                                                                                Prism.languages.css['atrule'].inside.rest = Prism.languages.css;
                                                                                                                                
                                                                                                                                if (Prism.languages.markup) {
                                                                                                                                Prism.languages.insertBefore('markup', 'tag', {
                                                                                                                                                             'style': {
                                                                                                                                                             pattern: /(<style[\s\S]*?>)[\s\S]*?(?=<\/style>)/i,
                                                                                                                                                             lookbehind: true,
                                                                                                                                                             inside: Prism.languages.css,
                                                                                                                                                             alias: 'language-css',
                                                                                                                                                             greedy: true
                                                                                                                                                             }
                                                                                                                                                             });
                                                                                                                                
                                                                                                                                Prism.languages.insertBefore('inside', 'attr-value', {
                                                                                                                                                             'style-attr': {
                                                                                                                                                             pattern: /\s*style=("|')(?:\\[\s\S]|(?!\1)[^\\])*\1/i,
                                                                                                                                                                                 inside: {
                                                                                                                                                                                 'attr-name': {
                                                                                                                                                                                 pattern: /^\s*style/i,
                                                                                                                                                                                 inside: Prism.languages.markup.tag.inside
                                                                                                                                                                                 },
                                                                                                                                                                                 'punctuation': /^\s*=\s*['"]|['"]\s*$/,
                                                                                                                                                                                                          'attr-value': {
                                                                                                                                                                                                          pattern: /.+/i,
                                                                                                                                                                                                          inside: Prism.languages.css
                                                                                                                                                                                                          }
                                                                                                                                                                                                          },
                                                                                                                                                                                                          alias: 'language-css'
                                                                                                                                                                                                          }
                                                                                                                                                                                                          }, Prism.languages.markup.tag);
                                                                                                                                                                                                          };
                                                                                                                                                                                                          Prism.languages.clike = {
                                                                                                                                                                                                          'syntax-placeholder': {
                                                                                                                                                                                                          pattern: /<#[^#]*#>/,
                                                                                                                                                                                                          greedy: true
                                                                                                                                                                                                          },
                                                                                                                                                                                                          'syntax-comment': [
                                                                                                                                                                                                                             {
                                                                                                                                                                                                                             pattern: /(^|[^\\])\/\*[\s\S]*?(?:\*\/|$)/,
                                                                                                                                                                                                                             lookbehind: true
                                                                                                                                                                                                                             },
                                                                                                                                                                                                                             {
                                                                                                                                                                                                                             pattern: /(^|[^\\:])\/\/.*/,
                                                                                                                                                                                                                             lookbehind: true,
                                                                                                                                                                                                                             greedy: true
                                                                                                                                                                                                                             }
                                                                                                                                                                                                                             ],
                                                                                                                                                                                                          'syntax-string': {
                                                                                                                                                                                                          pattern: /[@]?(["'])(?:\\(?:\r\n|[\s\S])|(?!\1)[^\\\r\n])*\1/,
                                                                                                                                                                                                                          greedy: true
                                                                                                                                                                                                                          },
                                                                                                                                                                                                                          'syntax-keyword': /\b(?:if|else|while|do|for|return|in|instanceof|function|new|try|throw|catch|finally|null|break|continue|true|false)\b/,
                                                                                                                                                                                                                          'function': /[a-z0-9_]+(?=\()/i,
                                                                                                                                                                                                                                                  'syntax-number': /\b0x[\da-f]+\b|(?:\b\d+\.?\d*|\B\.\d+)(?:e[+-]?\d+)?/i,
                                                                                                                                                                                                                                                  //    'operator': /--?|\+\+?|!=?=?|<=?|>=?|==?=?|&&?|\|\|?|\?|\*|\/|~|\^|%/,
                                                                                                                                                                                                                                                  };
                                                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                  Prism.languages.javascript = Prism.languages.extend('clike', {
                                                                                                                                                                                                                                                                                                      'syntax-keyword': /\b(?:as|async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally|for|from|function|get|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|set|static|super|switch|this|throw|try|typeof|var|void|while|with|yield)\b/,
                                                                                                                                                                                                                                                                                                      'syntax-number': /\b(?:0[xX][\dA-Fa-f]+|0[bB][01]+|0[oO][0-7]+|NaN|Infinity)\b|(?:\b\d+\.?\d*|\B\.\d+)(?:[Ee][+-]?\d+)?/,
                                                                                                                                                                                                                                                                                                      // Allow for all non-ASCII characters (See http://stackoverflow.com/a/2008444)
                                                                                                                                                                                                                                                                                                      'function': /[_$a-z\xA0-\uFFFF][$\w\xA0-\uFFFF]*(?=\s*\()/i,
                                                                                                                                                                                                                                                                                                                                                       });
                                                                                                                                                                                                                                                                                                      
                                                                                                                                                                                                                                                                                                      Prism.languages.insertBefore('javascript', 'keyword', {
                                                                                                                                                                                                                                                                                                                                   'syntax-string': {
                                                                                                                                                                                                                                                                                                                                   pattern: /((?:^|[^$\w\xA0-\uFFFF."'\])\s])\s*)\/(\[[^\]\r\n]+]|\\.|[^/\\\[\r\n])+\/[gimyu]{0,5}(?=\s*($|[\r\n,.;})\]]))/,
                                                                                                                                                                                                                                                                                                                                                    lookbehind: true,
                                                                                                                                                                                                                                                                                                                                                    greedy: true
                                                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                                                                                                    // This must be declared before keyword because we use "function" inside the look-forward
                                                                                                                                                                                                                                                                                                                                                    'function-variable': {
                                                                                                                                                                                                                                                                                                                                                    pattern: /[_$a-z\xA0-\uFFFF][$\w\xA0-\uFFFF]*(?=\s*=\s*(?:function\b|(?:\([^()]*\)|[_$a-z\xA0-\uFFFF][$\w\xA0-\uFFFF]*)\s*=>))/i,
                                                                                                                                                                                                                                                                                                                                                    alias: 'function'
                                                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                                                                                                    });
                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                    Prism.languages.insertBefore('javascript', 'syntax-string', {
                                                                                                                                                                                                                                                                                                                                                                                 'syntax-string': {
                                                                                                                                                                                                                                                                                                                                                                                 pattern: /`(?:\\[\s\S]|\${[^}]+}|[^\\`])*`/,
                                                                                                                                                                                                                                                                                                                                                                                 greedy: true,
                                                                                                                                                                                                                                                                                                                                                                                 inside: {
                                                                                                                                                                                                                                                                                                                                                                                 'interpolation': {
                                                                                                                                                                                                                                                                                                                                                                                 pattern: /\${[^}]+}/,
                                                                                                                                                                                                                                                                                                                                                                                 inside: {
                                                                                                                                                                                                                                                                                                                                                                                 'interpolation-punctuation': {
                                                                                                                                                                                                                                                                                                                                                                                 pattern: /^\${|}$/,
                                                                                                                                                                                                                                                                                                                                                                                 alias: 'punctuation'
                                                                                                                                                                                                                                                                                                                                                                                 },
                                                                                                                                                                                                                                                                                                                                                                                 rest: null // See below
                                                                                                                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                                                                                                                 },
                                                                                                                                                                                                                                                                                                                                                                                 'syntax-string': /[\s\S]+/
                                                                                                                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                                                                                                                 });
                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                    if (Prism.languages.markup) {
                                                                                                                                                                                                                                                                                                                                                    Prism.languages.insertBefore('markup', 'tag', {
                                                                                                                                                                                                                                                                                                                                                                                 'script': {
                                                                                                                                                                                                                                                                                                                                                                                 pattern: /(<script[\s\S]*?>)[\s\S]*?(?=<\/script>)/i,
                                                                                                                                                                                                                                                                                                                                                                                 lookbehind: true,
                                                                                                                                                                                                                                                                                                                                                                                 inside: Prism.languages.javascript,
                                                                                                                                                                                                                                                                                                                                                                                 alias: 'language-javascript',
                                                                                                                                                                                                                                                                                                                                                                                 greedy: true
                                                                                                                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                                                                                                                 });
                                                                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                    Prism.languages.js = Prism.languages.javascript;
                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                    Prism.languages.cfamily = Prism.languages.extend('clike', {
                                                                                                                                                                                                                                                                                                                                                                                                     'syntax-keyword': /\b(?:_Alignas|_Alignof|_Atomic|_Bool|_Complex|_Generic|_Imaginary|_Noreturn|_Static_assert|_Thread_local|asm|typeof|inline|auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|int|long|register|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|__FILE__|__LINE__|__DATE__|__TIME__|__TIMESTAMP__|__func__|EOF|NULL|SEEK_CUR|SEEK_END|SEEK_SET|stdin|stdout|stderr|alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|class|compl|const|constexpr|const_cast|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|float|for|friend|goto|if|inline|int|int8_t|int16_t|int32_t|int64_t|uint8_t|uint16_t|uint32_t|uint64_t|long|mutable|namespace|new|noexcept|nullptr|operator|private|protected|public|register|reinterpret_cast|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|union|unsigned|using|virtual|void|volatile|wchar_t|while|true|false|id|asm|typeof|inline|auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|int|long|register|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|in|self|super)\b|(?:@interface|@end|@implementation|@protocol|@class|@public|@protected|@private|@property|@try|@catch|@finally|@throw|@synthesize|@dynamic|@selector)\b/,
                                                                                                                                                                                                                                                                                                                                                                                                     'syntax-number': /(?:\b0x[\da-f]+|(?:\b\d+\.?\d*|\B\.\d+)(?:e[+-]?\d+)?)[ful]*/i,
                                                                                                                                                                                                                                                                                                                                                                                                     });
                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                    Prism.languages.insertBefore('swift', 'syntax-keyword', {
                                                                                                                                                                                                                                                                                                                                                                                 'syntax-build-config-keyword': {
                                                                                                                                                                                                                                                                                                                                                                                 // allow for multiline macro definitions
                                                                                                                                                                                                                                                                                                                                                                                 // spaces after the # character compile fine with gcc
                                                                                                                                                                                                                                                                                                                                                                                 pattern: /(^\s*)#\s*[a-z]+(?:[^\r\n\\]|\\(?:\r\n|[\s\S]))*/im,
                                                                                                                                                                                                                                                                                                                                                                                 lookbehind: true,
                                                                                                                                                                                                                                                                                                                                                                                 alias: 'property',
                                                                                                                                                                                                                                                                                                                                                                                 inside: {
                                                                                                                                                                                                                                                                                                                                                                                 // highlight the path of the include statement as a string
                                                                                                                                                                                                                                                                                                                                                                                 'syntax-string': {
                                                                                                                                                                                                                                                                                                                                                                                 pattern: /(#\s*include\s*)(?:<.+?>|("|')(?:\\?.)+?\2)/,
                                                                                                                                                                                                                                                                                                                                                                                                                     lookbehind: true
                                                                                                                                                                                                                                                                                                                                                                                                                     }
                                                                                                                                                                                                                                                                                                                                                                                                                     }
                                                                                                                                                                                                                                                                                                                                                                                                                     }
                                                                                                                                                                                                                                                                                                                                                                                                                     });
                                                                                                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                                                                                                                                            Prism.languages.json = {
                                                                                                                                                                                                                                                                                                                                                                                                            'syntax-string': {
                                                                                                                                                                                                                                                                                                                                                                                                            pattern: /"(?:\\.|[^\\"\r\n])*"(?!\s*:)/,
                                                                                                                                                                                                                                                                                                                                                                                 greedy: true
                                                                                                                                                                                                                                                                                                                                                                                 },
                                                                                                                                                                                                                                                                                                                                                                                 'syntax-number': /\b0x[\dA-Fa-f]+\b|(?:\b\d+\.?\d*|\B\.\d+)(?:[Ee][+-]?\d+)?/,
                                                                                                                                                                                                                                                                                                                                                                                 'syntax-keyword': /\b(?:true|false|null)\b/i,
                                                                                                                                                                                                                                                                                                                                                                                 };
                                                                                                                                                                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                                                                                                                                                 Prism.languages.jsonp = Prism.languages.json;
                                                                                                                                                                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                                                                                                                                                 Prism.languages.markdown = Prism.languages.extend('markup', {});
                                                                                                                                                                                                                                                                                                                                                                                 Prism.languages.insertBefore('markdown', 'prolog', {
                                                                                                                                                                                                                                                                                                                                                                                                              'blockquote': {
                                                                                                                                                                                                                                                                                                                                                                                                              // > ...
                                                                                                                                                                                                                                                                                                                                                                                                              pattern: /^>(?:[\t ]*>)*/m,
                                                                                                                                                                                                                                                                                                                                                                                                              alias: 'punctuation'
                                                                                                                                                                                                                                                                                                                                                                                                              },
                                                                                                                                                                                                                                                                                                                                                                                                              'code': [
                                                                                                                                                                                                                                                                                                                                                                                                                       {
                                                                                                                                                                                                                                                                                                                                                                                                                       // Prefixed by 4 spaces or 1 tab
                                                                                                                                                                                                                                                                                                                                                                                                                       pattern: /^(?: {4}|\t).+/m,
                                                                                                                                                                                                                                                                                                                                                                                                                       alias: 'keyword'
                                                                                                                                                                                                                                                                                                                                                                                                                       },
                                                                                                                                                                                                                                                                                                                                                                                                                       {
                                                                                                                                                                                                                                                                                                                                                                                                                       // `code`
                                                                                                                                                                                                                                                                                                                                                                                                                       // ``code``
                                                                                                                                                                                                                                                                                                                                                                                                                       pattern: /``.+?``|`[^`\n]+`/,
                                                                                                                                                                                                                                                                                                                                                                                                                       alias: 'keyword'
                                                                                                                                                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                                                                                                                                                       ],
                                                                                                                                                                                                                                                                                                                                                                                                              'title': [
                                                                                                                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                                                                        // title 1
                                                                                                                                                                                                                                                                                                                                                                                                                        // =======
                                                                                                                                                                                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                                                                                                                                                                        // title 2
                                                                                                                                                                                                                                                                                                                                                                                                                        // -------
                                                                                                                                                                                                                                                                                                                                                                                                                        pattern: /\w+.*(?:\r?\n|\r)(?:==+|--+)/,
                                                                                                                                                                                                                                                                                                                                                                                                                        alias: 'important',
                                                                                                                                                                                                                                                                                                                                                                                                                        inside: {
                                                                                                                                                                                                                                                                                                                                                                                                                        punctuation: /==+$|--+$/
                                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                                        },
                                                                                                                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                                                                        // # title 1
                                                                                                                                                                                                                                                                                                                                                                                                                        // ###### title 6
                                                                                                                                                                                                                                                                                                                                                                                                                        pattern: /(^\s*)#+.+/m,
                                                                                                                                                                                                                                                                                                                                                                                                                        lookbehind: true,
                                                                                                                                                                                                                                                                                                                                                                                                                        alias: 'important',
                                                                                                                                                                                                                                                                                                                                                                                                                        inside: {
                                                                                                                                                                                                                                                                                                                                                                                                                        punctuation: /^#+|#+$/
                                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                                                                                                                        ],
                                                                                                                                                                                                                                                                                                                                                                                                              'hr': {
                                                                                                                                                                                                                                                                                                                                                                                                              // ***
                                                                                                                                                                                                                                                                                                                                                                                                              // ---
                                                                                                                                                                                                                                                                                                                                                                                                              // * * *
                                                                                                                                                                                                                                                                                                                                                                                                              // -----------
                                                                                                                                                                                                                                                                                                                                                                                                              pattern: /(^\s*)([*-])(?:[\t ]*\2){2,}(?=\s*$)/m,
                                                                                                                                                                                                                                                                                                                                                                                                              lookbehind: true,
                                                                                                                                                                                                                                                                                                                                                                                                              alias: 'punctuation'
                                                                                                                                                                                                                                                                                                                                                                                                              },
                                                                                                                                                                                                                                                                                                                                                                                                              'list': {
                                                                                                                                                                                                                                                                                                                                                                                                              // * item
                                                                                                                                                                                                                                                                                                                                                                                                              // + item
                                                                                                                                                                                                                                                                                                                                                                                                              // - item
                                                                                                                                                                                                                                                                                                                                                                                                              // 1. item
                                                                                                                                                                                                                                                                                                                                                                                                              pattern: /(^\s*)(?:[*+-]|\d+\.)(?=[\t ].)/m,
                                                                                                                                                                                                                                                                                                                                                                                                              lookbehind: true,
                                                                                                                                                                                                                                                                                                                                                                                                              alias: 'punctuation'
                                                                                                                                                                                                                                                                                                                                                                                                              },
                                                                                                                                                                                                                                                                                                                                                                                                              'url-reference': {
                                                                                                                                                                                                                                                                                                                                                                                                              // [id]: http://example.com "Optional title"
                                                                                                                                                                                                                                                                                                                                                                                                              // [id]: http://example.com 'Optional title'
                                                                                                                                                                                                                                                                                                                                                                                                              // [id]: http://example.com (Optional title)
                                                                                                                                                                                                                                                                                                                                                                                                              // [id]: <http://example.com> "Optional title"
                                                                                                                                                                                                                                                                                                                                                                                                              pattern: /!?\[[^\]]+\]:[\t ]+(?:\S+|<(?:\\.|[^>\\])+>)(?:[\t ]+(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\((?:\\.|[^)\\])*\)))?/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     inside: {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     'variable': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     pattern: /^(!?\[)[^\]]+/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 lookbehind: true
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 },
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 'syntax-string': /(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\((?:\\.|[^)\\])*\))$/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 'punctuation': /^[\[\]!:]|[<>]/
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 },
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 alias: 'url'
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 },
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 'bold': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 // **strong**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 // __strong__
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 // Allow only one line break
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 pattern: /(^|[^\\])(\*\*|__)(?:(?:\r?\n|\r)(?!\r?\n|\r)|.)+?\2/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 lookbehind: true,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 inside: {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 'punctuation': /^\*\*|^__|\*\*$|__$/
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 },
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 'italic': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 // *em*
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 // _em_
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 // Allow only one line break
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 pattern: /(^|[^\\])([*_])(?:(?:\r?\n|\r)(?!\r?\n|\r)|.)+?\2/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 lookbehind: true,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 inside: {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 'punctuation': /^[*_]|[*_]$/
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 },
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 'url': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 // [example](http://example.com "Optional title")
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 // [example] [id]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 pattern: /!?\[[^\]]+\](?:\([^\s)]+(?:[\t ]+"(?:\\.|[^"\\])*")?\)| ?\[[^\]\n]*\])/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            inside: {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            'variable': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            pattern: /(!?\[)[^\]]+(?=\]$)/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       lookbehind: true
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       },
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'syntax-string': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       pattern: /"(?:\\.|[^"\\])*"(?=\)$)/
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            });
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Prism.languages.markdown['bold'].inside['url'] = Prism.languages.markdown['url'];
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Prism.languages.markdown['italic'].inside['url'] = Prism.languages.markdown['url'];
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Prism.languages.markdown['bold'].inside['italic'] = Prism.languages.markdown['italic'];
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Prism.languages.markdown['italic'].inside['bold'] = Prism.languages.markdown['bold'];
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        // issues: nested multiline comments
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Prism.languages.swift = Prism.languages.extend('clike', {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'syntax-string': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       pattern: /("|""")(\\(?:\((?:[^()]|\([^)]+\))+\)|\r\n|[\s\S])|(?!\1)[^\\])*\1/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       greedy: true,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       inside: {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'interpolation': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       pattern: /\\\((?:[^()]|\([^)]+\))+\)/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       inside: {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       delimiter: {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       pattern: /\\(\([^)]*\))/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       alias: 'syntax-code-text',
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       inside: {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'left-paren': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       pattern: /\(/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   alias: 'syntax-string'
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   },
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   'right-paren': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   pattern: /\)$/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       alias: 'syntax-string'
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       },
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       // See rest below
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       // See rest below
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       },
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'syntax-keyword': /\b(?:as|associativity|break|case|catch|class|continue|convenience|default|defer|deinit|didSet|do|dynamic(?:Type)?|else|enum|extension|fallthrough|final|for|func|get|guard|if|import|in|infix|init|inout|internal|is|lazy|left|let|mutating|new|none|nonmutating|operator|optional|override|postfix|precedence|prefix|private|Protocol|public|repeat|required|rethrows|return|right|safe|self|Self|set|static|struct|subscript|super|switch|throws?|try|Type|typealias|unowned|unsafe|var|weak|where|while|willSet|__(?:COLUMN__|FILE__|FUNCTION__|LINE__)|#(?:file|line|column|function|available|selector|keyPath))\b/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'syntax-number': /\b(?:[\d_]+(?:\.[\de_]+)?|0x[a-f0-9_]+(?:\.[a-f0-9p_]+)?|0b[01_]+|0o[0-7_]+)\b/i,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       });
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Prism.languages.insertBefore('swift', 'syntax-keyword', {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     'syntax-build-config-keyword': /#(?:if|elseif|else|endif)/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     'syntax-build-config-id': /\b(?:os|arch|swift|canImport|error|warning|targetEnvironment|macOS|macOSApplicationExtension|iOS|iOSApplicationExtension|watchOS|tvOS|simulator|linux|i386|x86_64|arm|arm64)\b/i
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     });
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Prism.languages.insertBefore('swift', 'function', {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     'atrule': {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     pattern: /@\b(?:IB(?:Outlet|Designable|Action|Inspectable)|class_protocol|exported|noreturn|NS(?:Copying|Managed)|objc|UIApplicationMain|auto_closure|escaping|rethrows|available)\b/,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     alias: 'syntax-keyword'
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     });
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Prism.languages.swift['syntax-string'].inside['interpolation'].inside.rest = Prism.languages.swift;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        Prism.languages.swift['syntax-string'].inside['interpolation'].inside.delimiter.inside.rest = Prism.languages.swift;
