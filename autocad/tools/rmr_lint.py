#!/usr/bin/env python3
"""Static structural checker for the RooMNRooF AutoLISP source.

AutoCAD is not needed to run this. It performs the checks that catch the errors
which actually break a LISP load:

  1. string termination (including \\" escapes)
  2. parenthesis balance, unclosed lists and stray atoms
  3. defun name, argument-list and duplicated-local problems
  4. duplicate defun names
  5. setq of variables that are neither declared locals nor *globals*
  6. calls to functions that are never defined (typo detection)
  7. *RMR-* globals that are read but never set

Usage:  python3 rmr_lint.py path/to/RooMNRooF_Master.lsp
Exit code 0 = PASS, 1 = something needs review.
"""
import re
import sys
from collections import Counter, defaultdict

OPERATORS = set("""+ - * / = /= < > <= >= 1+ 1- . t nil""".split())

BUILTINS = set("""
abs acos alert and angle append apply ascii asin assoc atan atof atoi atoms-family boole
boundp caddr cadddr cadr
car cdddr cddr cdr chr close command command-s cond cons cos cosh cvunit defun
defun-q distof
distance end-list endcons entdel entget entmake entmakex entmod entnext entsel
entlast entupd
eof eq equal eval exit exp expt fillfloat findfile fix float foreach gc gensym
getangle getcfg getclose getcorner getdist getenv getfiled getint initget
getkword
getpoint getreal getstring geturl getvar handent help if itoa lambda last
layoutlist length list listp load load_dialog log log10 logand logior lognot
lsh mapcar max member menucmd min minusp mktemp namedobjdict nentsel nentselp
new_dialog not nth null numberp open or osnap polar prin1 princ print progn
prompt quit read read-line redraw regapp rem repeat reverse rtos set setenv
setfunhelp setq setvar sin sinh slide_image snvalid sqrt ssadd ssdel ssget
sslength ssmemb ssname ssnamex sssetfirst start_list startapp strcase strcat
strlen
subst substr tblnext tblobjname tblsearch term_dialog terpri textbox textpage
wcmatch
textscr trace trans type undo untrace vl-catch-all-apply
vl-catch-all-error-message vl-catch-all-error-p vl-cmdff vl-consp
vl-directory-files vl-every vl-exit-with-error vl-exit-with-value vl-file-copy
vl-file-delete vl-file-directory-p vl-file-length vl-file-rename vl-file-size
vl-filename-base vl-filename-directory vl-filename-extension
vl-filename-mktemp vl-get-resource vl-list-length vl-load-com vl-member-if
vl-member-if-not vl-mkdir vl-position vl-prin1-to-string vl-princ-to-string
vl-propagate vl-registry-delete vl-registry-descendents vl-registry-read
vl-registry-write vl-remove vl-remove-if vl-remove-if-not vl-some vl-sort
vl-sort-i vl-string-elt vl-string-left-trim vl-string-mismatch
vl-string-position vl-string-right-trim vl-string-search vl-string-subst
vl-string-translate vl-string-trim vl-symbol-name vl-symbol-value vl-symbolp
vlax-3d-point vlax-add-cmd vlax-create-object vlax-dump-object
vlax-ename->vla-object vlax-erased-p vlax-for vlax-get-acad-object
vlax-get-object vlax-get-or-create-object vlax-get-property
vlax-import-type-library vlax-invoke vlax-invoke-method vlax-make-safearray
vlax-make-variant vlax-method-applicable-p vlax-object-name vlax-put-property
vlax-release-object vlax-remove-cmd vlax-safearray-fill vlax-safearray-get-dim
vlax-safearray-get-element vlax-safearray-get-lower-bound
vlax-safearray-get-u-bound vlax-safearray-get-upper-bound
vlax-safearray-put-element vlax-safearray->list vlax-tmatrix
vlax-typeinfo-available-p vlax-variant-change-type vlax-variant-value
vlax-vla-object->ename vlax-write-enabled-p while write-char write-line zerop
""".split())

NUM = re.compile(r"^[-+]?\d+(\.\d+)?([eE][-+]?\d+)?$")


def is_number(sym):
    return bool(NUM.match(sym))


def tokenize(src):
    """Return (tokens, errors). tokens are (kind, value, line)."""
    tokens = []
    errors = []
    i, line, n = 0, 1, len(src)
    while i < n:
        ch = src[i]
        if ch == "\n":
            line += 1
            i += 1
            continue
        if ch == '"':
            start_line = line
            i += 1
            buf = ['"']
            closed = False
            while i < n:
                c = src[i]
                if c == "\\" and i + 1 < n:
                    buf.append(c)
                    if src[i + 1] == "\n":
                        line += 1
                    buf.append(src[i + 1])
                    i += 2
                    continue
                if c == '"':
                    buf.append(c)
                    i += 1
                    closed = True
                    break
                if c == "\n":
                    break
                buf.append(c)
                i += 1
            if closed:
                tokens.append(("str", "".join(buf), start_line))
            else:
                errors.append("line %d: unterminated string" % start_line)
            continue
        if ch == ";":
            while i < n and src[i] != "\n":
                i += 1
            continue
        if ch in "()":
            tokens.append((ch, ch, line))
            i += 1
            continue
        if ch.isspace():
            i += 1
            continue
        start = i
        while i < n and not src[i].isspace() and src[i] not in '();"':
            i += 1
        tokens.append(("sym", src[start:i], line))
    return tokens, errors


class Form(object):
    __slots__ = ("line", "items")

    def __init__(self, line):
        self.line = line
        self.items = []


def parse(tokens):
    problems = []
    stack = []
    forms = []
    for kind, value, line in tokens:
        if kind == "(":
            stack.append(Form(line))
        elif kind == ")":
            if not stack:
                problems.append("line %d: unmatched ')'" % line)
                continue
            done = stack.pop()
            if stack:
                stack[-1].items.append(done)
            else:
                forms.append(done)
        else:
            if stack:
                stack[-1].items.append((kind, value, line))
            else:
                problems.append("line %d: atom '%s' outside any list" % (line, value))
    for f in stack:
        problems.append("line %d: unclosed '('" % f.line)
    return forms, problems


def head_of(form):
    if form.items and isinstance(form.items[0], tuple) and form.items[0][0] == "sym":
        return form.items[0][1], form.items[0][2]
    return None


def symbol_items(form):
    return [it for it in form.items if isinstance(it, tuple) and it[0] == "sym"]


def collect_arglists(form, out):
    """Remember defun/lambda parameter lists so they are not read as calls."""
    h = head_of(form)
    if h and h[0].lower() in ("defun", "defun-q", "lambda"):
        for it in form.items:
            if isinstance(it, Form):
                out.add(id(it))
                break
    for it in form.items:
        if isinstance(it, Form):
            collect_arglists(it, out)


def walk_forms(form):
    for it in form.items:
        if isinstance(it, Form):
            yield it
            for sub in walk_forms(it):
                yield sub


def main(path):
    src = open(path, encoding="utf-8").read()
    tokens, tok_errors = tokenize(src)
    forms, problems = parse(tokens)

    defined = {}
    arglists = set()
    calls = Counter()
    call_lines = defaultdict(list)
    globals_set = Counter()
    globals_used = Counter()
    defun_issues = []
    setq_issues = []

    def record_call(name, line, declared):
        clean = name.lstrip("'")
        low = clean.lower()
        if is_number(clean) or low in OPERATORS:
            return
        if low in declared:
            return
        if low.startswith(("vla-", "vlax-", "acet-", "vl-")):
            return
        calls[clean] += 1
        call_lines[clean].append(line)

    def handle_defun(form):
        items = form.items
        if len(items) < 2 or not isinstance(items[1], tuple):
            defun_issues.append("line %d: defun without a name" % form.line)
            return
        name = items[1][1]
        if name in defined:
            defun_issues.append("line %d: duplicate defun '%s' (first at line %d)"
                                % (form.line, name, defined[name]))
        defined[name] = form.line
        argform = None
        for it in items[2:]:
            if isinstance(it, Form):
                argform = it
                break
        if argform is None:
            defun_issues.append("line %d: defun '%s' has no argument list" % (form.line, name))
            return
        args = [s[1] for s in symbol_items(argform)]
        if "/" in args:
            cut = args.index("/")
            required, locals_ = args[:cut], args[cut + 1:]
        else:
            required, locals_ = args, []
        dupes = sorted(k for k, v in Counter(a.lower() for a in required + locals_).items() if v > 1)
        if dupes:
            defun_issues.append("line %d: defun '%s' duplicated names: %s" % (form.line, name, dupes))
        declared = set(a.lower() for a in required + locals_)
        for sub in walk_forms(form):
            if id(sub) in arglists:
                continue
            h = head_of(sub)
            if not h:
                continue
            sym, sline = h
            if sym.lower() in ("setq", "set"):
                names = symbol_items(sub)[1:]
                i = 0
                while i < len(names):
                    var = names[i][1]
                    if var.startswith("*") and var.endswith("*"):
                        globals_set[var] += 1
                    elif var.lower() not in declared:
                        setq_issues.append("line %d: '%s' sets undeclared '%s'" % (names[i][2], name, var))
                    i += 2
            else:
                record_call(sym, sline, declared)

    for form in forms:
        collect_arglists(form, arglists)
        h = head_of(form)
        if h and h[0].lower() == "defun":
            handle_defun(form)
        elif h and h[0].lower() == "setq":
            names = symbol_items(form)[1:]
            i = 0
            while i < len(names):
                if names[i][1].startswith("*"):
                    globals_set[names[i][1]] += 1
                i += 2
        else:
            for sub in walk_forms(form):
                if id(sub) in arglists:
                    continue
                hh = head_of(sub)
                if hh:
                    record_call(hh[0], hh[1], set())

    for kind, value, line in tokens:
        if kind == "sym" and value.startswith("*") and value.endswith("*") and len(value) > 2:
            globals_used[value] += 1

    unknown = []
    for name, count in calls.items():
        low = name.lower()
        if low in BUILTINS:
            continue
        if any(k.lower() == low for k in defined):
            continue
        unknown.append((name, count, call_lines[name][:4]))

    quoted = []
    for kind, value, line in tokens:
        if kind == "sym" and value.startswith("'"):
            ref = value.lstrip("'")
            if (":" in ref or ref.lower().startswith("rmr")) and not any(k.lower() == ref.lower() for k in defined):
                quoted.append((ref, line))

    unset = sorted(g for g in globals_used if g not in globals_set)
    commands = sorted(k for k in defined if k.lower().startswith("c:"))

    print("file             : %s" % path)
    print("bytes / lines    : %d / %d" % (len(src), src.count("\n") + 1))
    print("tokens / forms   : %d / %d" % (len(tokens), len(forms)))
    print("defuns / commands: %d / %d" % (len(defined), len(commands)))
    print("tokenizer errors : %d" % len(tok_errors))
    for e in tok_errors:
        print("    " + e)
    print("parse problems   : %d" % len(problems))
    for e in problems:
        print("    " + e)
    print("defun issues     : %d" % len(defun_issues))
    for e in defun_issues:
        print("    " + e)
    print("setq issues      : %d" % len(setq_issues))
    for e in setq_issues:
        print("    " + e)
    print("unknown calls    : %d" % len(unknown))
    for name, count, lines in sorted(unknown):
        print("    %s x%d first lines %s" % (name, count, lines))
    print("bad quoted refs  : %d" % len(quoted))
    for ref, line in sorted(set(quoted)):
        print("    '%s' at line %d is never defined" % (ref, line))
    print("unset globals    : %s" % (unset or "none"))
    print("commands (%d):" % len(commands))
    for c in commands:
        print("    " + c)

    ok = not (tok_errors or problems or defun_issues or setq_issues or unknown or unset or quoted)
    print("RESULT: %s" % ("PASS" if ok else "REVIEW"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
