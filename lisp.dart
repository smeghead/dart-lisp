class Obj {
	Obj evaluate() {
		return this;
	}
	String toString() => 'obj';
}

class Atom extends Obj {
	var value;
	withValue(value) => this.value = value;

	Atom.withValue(this.value);

	String toString() => '$value';
}

class Nil extends Atom {
	Nil();
	String toString() => 'nil';
}

class ConsCell extends Obj {
	Obj l, r;

	withValues(l, r) {
		this.l = l;
		this.r = r;
	}

	ConsCell();
	ConsCell.withValues(this.l, this.r);

	Obj evaluate() {
		//print('ConsCell evaluate: ' + this.l);
		//print('ConsCell evaluate: LispFunction? ' + (this.l is LispFunction));
		//print('ConsCell evaluate: LispSpecialOperator? ' + (this.l is LispSpecialOperator));
		//FIXME 関数がConsの左にある場合には、いつも関数を実行してしまう。
		//      Listの始めが関数のときだけ関数を実行しようとするようにする必要がある。
		if (this.l is LispFunction || this.l is LispSpecialOperator) {
			var f = this.l;
			return f.evaluateFunction(this);
		} else {
			this.l = this.l.evaluate();
			this.r = this.r.evaluate();
			return this;
		}
	}

	String toString() => '($l . $r)';
}

class LispFunction extends Atom {
	String name;
	Function exec;

	bind(String name, Function exec) {
		this.name = name;
		this.exec = exec;
	}
	LispFunction.bind(this.name, this.exec);

	Obj evaluateFunction(ConsCell cons) {
		//eval argument.
		var args = cons.r.evaluate();
		cons.r = args;
		return this.exec(cons);
	}
	String toString() => '$name';
}

class LispSpecialOperator extends LispFunction {

	LispSpecialOperator.bind(name, exec) : super.bind(name, exec);

	Obj evaluateFunction(ConsCell cons) {
		return exec(cons);
	}
}

Map createBasicEnvironment(HashMap<String, Obj> env) {
	env['nil'] = new Nil();

	//functions
	env['car'] = new LispFunction.bind('car', (ConsCell cons) {
		return cons.r.l.l;
	});
	env['cdr'] = new LispFunction.bind('cdr', (ConsCell cons) {
		return cons.r.l.r;
	});
	env['cons'] = new LispFunction.bind('cons', (ConsCell cons) {
		return new ConsCell.withValues(cons.r.l, cons.r.r.l);
	});
	env['atom'] = new LispFunction.bind('atom', (ConsCell cons) {
		if (cons.r.l is Atom) {
			return cons.r.l;
		}
		return env['nil'];
	});
	env['eq'] = new LispFunction.bind('eq', (ConsCell cons) {
		if (cons.r.l.toString() == cons.r.r.l.toString()) {
			return cons.r.l;
		}
		return env['nil'];
	});

	//special operators
	env['quote'] = new LispSpecialOperator.bind('quote', (ConsCell cons) {
		return cons.r.l;
	});
	env['cond'] = new LispSpecialOperator.bind('cond', (ConsCell cons) {
		return lispCond(env, cons.r);
	});
	return env;
}

Obj lispCond(Map<String, Obj> env, ConsCell cons) {
	print('lispCond: start =====');
	print('lispCond: cons = ' + cons);
	print('lispCond: check = ' + cons.l.l.evaluate());
	if (cons.l.l.evaluate().toString() != 'nil') {
		return cons.r.l.evaluate();
	}
	print('lispCond: next');
	print('lispCond: cons.r = ' + cons.r);
	if (cons.r.toString() == 'nil') {
		return env['nil'];
	}
	return lispCond(env, cons.l);
}

class ResultObj {
	Obj o;
	int step = 0;
}

class Lisp {
	Map env;

	init(env) {
	}
	Lisp.init(this.env);

	List<Obj> readSexp(source) {
		//lexical analysis.
		var lexList = new List<String>();
		String buf = '';
		for (var i = 0; i < source.length; i++) {
			var c = source[i];
			switch (c) {
				case '(':
					lexList.add(c);
					break;
				case ')':
					if (buf != '') {
						lexList.add(buf);
						buf = '';
					}
					lexList.add(c);
					break;
				case ' ':
				case '\t':
				case '\n':
					if (buf != '') {
						lexList.add(buf);
						buf = '';
					}
					break;
				case '.':
					lexList.add('.');
					break;
				default:
					buf += c;
					break;
			}
		}
		if (buf != '') {
			lexList.add(buf);
		}

		//build syntax tree.
		var syntaxTree = buildSexp(lexList, null);
		var ret = new List<Obj>();
		ret.add(syntaxTree.o);
		return ret;
	}

	Obj evalSexp(Obj o) {
		return o.evaluate();
	}

	String stringSexp(o) {
		//print('Lisp print');
		return o.toString();
	}
	
	ResultObj buildSexp(List<String> list, ResultObj nesting) {
		//debug
		var x = ' ';
		for (var e in list) {
			x += e + ' ';
		}
		print('buildSexp: ' + x);

		ResultObj ret = new ResultObj();
		switch (list[0]) {
			case '(':
				int i = 1;
				//先頭が(ならConsCellを返す
				ret.o = new ConsCell();
				ResultObj left = buildSexp(new List<String>.fromList(list, 1, list.length), null);
				i += left.step;
				ret.o.l = left.o;
				if (list[i] == '.') { //次の要素をチェックする
					//ConsCell
					i += 1;
					ResultObj right = buildSexp(new List<String>.fromList(list, i, list.length), null);
					i += right.step;
					ret.o.r = right.o;
					if (list[i] != ')') {
						//not cons cell. error.
						throw new Exception('syntax error. excepted ) appear ' + list[i]);
					}
					ret.step = i + 1;
				} else {
					//i += 1;
					//List
					ret.o.r = env['nil'];
					print('buildSexp: ret.o [' + ret.o + ']');
					ResultObj right = buildSexp(new List<String>.fromList(list, i, list.length), ret);
					print('buildSexp: ret.o [' + ret.o + ']\tright.o[' + right.o + ']');
					if (ret.o != right.o) {
						ret.o.r = new ConsCell.withValues(right.o, env['nil']);
					}
					ret.step += right.step;
				}
				break;
			case ')':
				if (nesting != null) {
					nesting.step += 1;
					return nesting;
				}
			case '.':
				break;
			default:
				var elm = list[0];
				if (nesting == null) {
					//先頭が(以外ならAtomを返す
					if (elm == 'nil') {
						ret.o = env['nil'];
					} else if (this.env.containsKey(elm)) {
						ret.o = env[elm];
					} else {
						ret.o = new Atom.withValue(elm);
					}
					ret.step = 1;
				} else {
					//Listの継続の場合は、リスト要素の追加
					ConsCell last = lastCons(nesting.o);
					last.r = new ConsCell();
					last.r.l = new Atom.withValue(elm);
					last.r.r = env['nil'];
					return buildSexp(new List<String>.fromList(list, 1, list.length), nesting);
				}
				break;
		}
		return ret;
	}
}


ConsCell lastCons(ConsCell cons) {
	if (cons.r.toString() == 'nil') {
		return cons;
	}
	return lastCons(cons.r);
}

main() {
	Lisp l = new Lisp.init(new HashMap<String, Obj>());
	l.env = createBasicEnvironment(l.env);

	List<Obj> lispObjects;

	lispObjects = l.readSexp('1');
	for (Obj e in lispObjects) {
		print(l.stringSexp(e) == '1');
	}

	lispObjects = l.readSexp('a');
	for (Obj e in lispObjects) {
		print(l.stringSexp(e) == 'a');
	}

	lispObjects = l.readSexp('(age . sage)');
	for (Obj e in lispObjects) {
		print(l.stringSexp(e) == '(age . sage)');
	}

	lispObjects = l.readSexp('(age\t . \nsage)');
	for (Obj e in lispObjects) {
		print(l.stringSexp(e) == '(age . sage)');
	}

	lispObjects = l.readSexp('(a . (b . nil))');
	for (Obj e in lispObjects) {
		print(l.stringSexp(e) == '(a . (b . nil))');
	}

	lispObjects = l.readSexp('((a . b) . c)');
	for (Obj e in lispObjects) {
		print(l.stringSexp(e) == '((a . b) . c)');
	}

	lispObjects = l.readSexp('(a b)');
	for (Obj e in lispObjects) {
		print(l.stringSexp(e) == '(a . (b . nil))');
	}

	lispObjects = l.readSexp('(a (b c))');
	for (Obj e in lispObjects) {
		print(l.stringSexp(e));
		print(l.stringSexp(e) == '(a . ((b . (c . nil)) . nil))');
	}

	lispObjects = l.readSexp('(a b c)');
	for (Obj e in lispObjects) {
		print(l.stringSexp(e) == '(a . (b . (c . nil)))');
	}

//	lispObjects = l.readSexp('(car (quote (b c))');
//	for (Obj e in lispObjects) {
////		print(l.stringSexp(e));
////		print(l.stringSexp(e) == '(car . ((quote . ((b . (c . nil)) . nil)) . nil))');
//		Obj e1 = l.evalSexp(e);
//		print(l.stringSexp(e1));
//		print(l.stringSexp(e1) == 'b');
//	}
//
//	lispObjects = l.readSexp('(cdr (quote (b c))');
//	for (Obj e in lispObjects) {
//		Obj e1 = l.evalSexp(e);
//		print(l.stringSexp(e1));
//		print(l.stringSexp(e1) == '(c . nil)');
//	}
//
//	lispObjects = l.readSexp('(car (cdr (quote (b c)))');
//	for (Obj e in lispObjects) {
//		Obj e1 = l.evalSexp(e);
//		print(l.stringSexp(e1));
//		print(l.stringSexp(e1) == 'c');
//	}
//
//	lispObjects = l.readSexp('(cons b c))');
//	for (Obj e in lispObjects) {
//		print(e);
//		Obj e1 = l.evalSexp(e);
//		print(l.stringSexp(e1));
//		print(l.stringSexp(e1) == '(b . c)');
//	}
//
//	lispObjects = l.readSexp('(atom b))');
//	for (Obj e in lispObjects) {
//		print(e);
//		Obj e1 = l.evalSexp(e);
//		print(l.stringSexp(e1));
//		print(l.stringSexp(e1) == 'b');
//	}
//
//	lispObjects = l.readSexp('(atom (quote (a . b)))');
//	for (Obj e in lispObjects) {
//		print(e);
//		Obj e1 = l.evalSexp(e);
//		print(l.stringSexp(e1));
//		print(l.stringSexp(e1) == 'nil');
//	}
//
//	lispObjects = l.readSexp('(eq 1 1)');
//	for (Obj e in lispObjects) {
//		print(e);
//		Obj e1 = l.evalSexp(e);
//		print(l.stringSexp(e1));
//		print(l.stringSexp(e1) == '1');
//	}
//
//	lispObjects = l.readSexp('(eq 1 2)');
//	for (Obj e in lispObjects) {
//		print(e);
//		Obj e1 = l.evalSexp(e);
//		print(l.stringSexp(e1));
//		print(l.stringSexp(e1) == 'nil');
//	}
//
//	lispObjects = l.readSexp('(cond (nil 0) (t 1))');
//	for (Obj e in lispObjects) {
//		print('expected: ' + '(cond . ((nil . (0 . nil)) . ((t . (1 . nil)) . nil)))');
//		print('actual  : ' + l.stringSexp(e));
//		print(l.stringSexp(e) == '(cond . ((nil . (0 . nil)) . ((t . (1 . nil)) . nil)))');
//
//		Obj e1 = l.evalSexp(e);
//		print(l.stringSexp(e1));
//		print(l.stringSexp(e1) == '1');
//	}


	print('main end');
}
