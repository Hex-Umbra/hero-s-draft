/* Hero's Draft — Formation : coloration syntaxique, quiz, navigation */
(function () {
  'use strict';

  /* ------------------------------------------------------------------ */
  /* 1. Coloration syntaxique (Dart / JSON / YAML / texte)               */
  /* ------------------------------------------------------------------ */

  var DART_KEYWORDS = ('abstract as assert async await break case catch class const continue covariant ' +
    'default deferred do dynamic else enum export extends extension external factory false final finally ' +
    'for get hide if implements import in interface is late library mixin new null on operator part ' +
    'required rethrow return sealed set show static super switch sync this throw true try typedef var ' +
    'void when while with yield').split(' ');

  var DART_TYPES = ('int double num bool String List Map Set Iterable Future Stream Object Function ' +
    'Widget StatelessWidget StatefulWidget State BuildContext Color Vector2 Component PositionComponent ' +
    'SpriteComponent FlameGame Notifier NotifierProvider Provider FutureProvider Ref WidgetRef Random ' +
    'Duration Curves Colors Icons Offset Size Rect Canvas Paint TextStyle Random').split(' ');

  function escapeHtml(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  // Tokenise en protégeant chaînes et commentaires d'abord.
  function highlight(code, lang) {
    var out = '';
    var i = 0;
    var n = code.length;

    function isWordChar(c) { return /[A-Za-z0-9_$]/.test(c); }

    while (i < n) {
      var c = code[i];

      // commentaire ligne
      if (c === '/' && code[i + 1] === '/') {
        var j = code.indexOf('\n', i); if (j === -1) j = n;
        out += '<span class="tok-com">' + escapeHtml(code.slice(i, j)) + '</span>';
        i = j; continue;
      }
      // commentaire bloc
      if (c === '/' && code[i + 1] === '*') {
        var k = code.indexOf('*/', i + 2); k = (k === -1) ? n : k + 2;
        out += '<span class="tok-com">' + escapeHtml(code.slice(i, k)) + '</span>';
        i = k; continue;
      }
      // commentaire YAML / shell
      if (c === '#' && (lang === 'yaml' || lang === 'bash' || lang === 'shell')) {
        var y = code.indexOf('\n', i); if (y === -1) y = n;
        out += '<span class="tok-com">' + escapeHtml(code.slice(i, y)) + '</span>';
        i = y; continue;
      }
      // chaînes
      if (c === '"' || c === "'" || c === '`') {
        var q = c, s = i + 1, esc = false;
        while (s < n) {
          if (code[s] === '\\' && !esc) { esc = true; s++; continue; }
          if (code[s] === q && !esc) { s++; break; }
          if (code[s] === '\n' && q !== '`') { break; }
          esc = false; s++;
        }
        out += '<span class="tok-str">' + escapeHtml(code.slice(i, s)) + '</span>';
        i = s; continue;
      }
      // annotation Dart
      if (c === '@' && isWordChar(code[i + 1] || '')) {
        var a = i + 1; while (a < n && isWordChar(code[a])) a++;
        out += '<span class="tok-ann">' + escapeHtml(code.slice(i, a)) + '</span>';
        i = a; continue;
      }
      // nombres
      if (/[0-9]/.test(c) && !isWordChar(code[i - 1] || '')) {
        var d = i; while (d < n && /[0-9a-fA-FxX._]/.test(code[d])) d++;
        out += '<span class="tok-num">' + escapeHtml(code.slice(i, d)) + '</span>';
        i = d; continue;
      }
      // mots
      if (isWordChar(c)) {
        var w = i; while (w < n && isWordChar(code[w])) w++;
        var word = code.slice(i, w);
        var after = code.slice(w).match(/^\s*\(/);
        var cls = null;
        if (DART_KEYWORDS.indexOf(word) !== -1) cls = 'tok-kw';
        else if (DART_TYPES.indexOf(word) !== -1) cls = 'tok-typ';
        else if (/^[A-Z][A-Za-z0-9_]*$/.test(word)) cls = 'tok-typ';
        else if (after) cls = 'tok-fn';
        out += cls ? '<span class="' + cls + '">' + escapeHtml(word) + '</span>' : escapeHtml(word);
        i = w; continue;
      }
      out += escapeHtml(c); i++;
    }
    return out;
  }

  function highlightJson(code) {
    var out = code
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    out = out.replace(/("(?:\\.|[^"\\])*")(\s*:)/g, '<span class="tok-key">$1</span>$2');
    out = out.replace(/:(\s*)("(?:\\.|[^"\\])*")/g, ':$1<span class="tok-str">$2</span>');
    out = out.replace(/\b(true|false|null)\b/g, '<span class="tok-kw">$1</span>');
    out = out.replace(/(:\s*)(-?\d+(?:\.\d+)?)/g, '$1<span class="tok-num">$2</span>');
    return out;
  }

  function runHighlight() {
    var blocks = document.querySelectorAll('.code pre code, .code pre');
    Array.prototype.forEach.call(document.querySelectorAll('.code'), function (box) {
      var pre = box.querySelector('pre');
      if (!pre || pre.dataset.hl === '1') return;
      var lang = (box.getAttribute('data-lang') || 'dart').toLowerCase();
      var src = pre.textContent;
      if (lang === 'json') pre.innerHTML = highlightJson(src);
      else if (lang === 'text' || lang === 'txt' || lang === 'log') pre.innerHTML = escapeHtml(src);
      else pre.innerHTML = highlight(src, lang);
      pre.dataset.hl = '1';
    });
  }

  /* ------------------------------------------------------------------ */
  /* 2. Quiz interactif                                                  */
  /* ------------------------------------------------------------------ */
  function initQuiz() {
    Array.prototype.forEach.call(document.querySelectorAll('.quiz .q'), function (q) {
      var answer = parseInt(q.getAttribute('data-answer'), 10);
      var opts = q.querySelector('.q-opts');
      var exp = q.querySelector('.q-exp');
      if (!opts) return;
      Array.prototype.forEach.call(opts.children, function (li, idx) {
        li.addEventListener('click', function () {
          if (opts.classList.contains('locked')) return;
          opts.classList.add('locked');
          Array.prototype.forEach.call(opts.children, function (o, j) {
            if (j === answer) o.classList.add('correct');
            else if (j === idx) o.classList.add('incorrect');
          });
          if (exp) exp.classList.add('show');
        });
      });
    });
  }

  /* ------------------------------------------------------------------ */
  /* 3. Menu mobile + lien actif                                         */
  /* ------------------------------------------------------------------ */
  function initNav() {
    var btn = document.querySelector('.menu-btn');
    var side = document.querySelector('.sidebar');
    if (btn && side) {
      btn.addEventListener('click', function () { side.classList.toggle('open'); });
      document.addEventListener('click', function (e) {
        if (window.innerWidth > 980) return;
        if (side.contains(e.target) || btn.contains(e.target)) return;
        side.classList.remove('open');
      });
    }
    var active = document.querySelector('.nav a.active');
    if (active && side) {
      var t = active.offsetTop - side.clientHeight / 2;
      if (t > 0) side.scrollTop = t;
    }
  }

  /* ------------------------------------------------------------------ */
  /* 4. Navigation clavier (← →)                                         */
  /* ------------------------------------------------------------------ */
  function initKeys() {
    document.addEventListener('keydown', function (e) {
      if (e.target && /input|textarea|select/i.test(e.target.tagName)) return;
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      var prev = document.querySelector('.pager a.prev');
      var next = document.querySelector('.pager a.next');
      if (e.key === 'ArrowLeft' && prev) window.location.href = prev.getAttribute('href');
      if (e.key === 'ArrowRight' && next) window.location.href = next.getAttribute('href');
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    runHighlight();
    initQuiz();
    initNav();
    initKeys();
  });
})();
