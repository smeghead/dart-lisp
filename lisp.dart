class Obj {
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

	String toString() => '($l . $r)';
}

class Lisp {
	Map env;

	init(env) {
		this.env = env;
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
		ResultObj syntaxTree = buildSexp(lexList);
		var ret = new List<Obj>();
		ret.add(syntaxTree.o);
		return ret;
	}

	Obj evalSexp(Obj o) {
		//print('Lisp eval');
		return o;
	}

	String stringSexp(o) {
		//print('Lisp print');
		return o.toString();
	}
}

class ResultObj {
	Obj o;
	int step = 0;
}

ResultObj buildSexp(List<String> list) {
	ResultObj ret = new ResultObj();
	switch (list[0]) {
		case '(':
			int i = 1;
			//先頭が(ならConsCellを返す
			ret.o = new ConsCell();
			ResultObj left = buildSexp(new List<String>.fromList(list, 1, list.length - 2));
			i += left.step;
			ret.o.l = left.o;
			if (list[i] != '.') {
				//not cons cell. error.
				throw new Exception('syntax error. excepted . appear ' + list[i]);
			}
			i += 1;
			ResultObj right = buildSexp(new List<String>.fromList(list, i, list.length - 1));
			i += right.step;
			ret.o.r = right.o;
			if (list[i] != ')') {
				//not cons cell. error.
				throw new Exception('syntax error. excepted ) appear ' + list[i]);
			}
			ret.step = i + 1;
			break;
		case ')':
		case '.':
			break;
		default:
			//先頭が(以外ならAtomを返す
			if (list[0] == 'nil') {
				ret.o = new Nil();
			} else {
				ret.o = new Atom.withValue(list[0]);
			}
			ret.step = 1;
			break;
	}
	return ret;
}

main() {
	Lisp l = new Lisp.init(new HashMap<String, Obj>());

	List<Obj> lispObjects = l.readSexp('1');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1) == '1');
	}

	lispObjects = l.readSexp('a');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1) == 'a');
	}

	lispObjects = l.readSexp('(age . sage)');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1) == '(age . sage)');
	}

	lispObjects = l.readSexp('(age\t . \nsage)');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1) == '(age . sage)');
	}

	lispObjects = l.readSexp('(a . (b . nil))');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1) == '(a . (b . nil))');
	}

	lispObjects = l.readSexp('((a . b) . c)');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1) == '((a . b) . c)');
	}

	print('main end');

}
