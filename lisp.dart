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
		//print('Lisp read');

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
		//for (var e in lexList) {
			//print('list:' + e);
		//}

		//build syntax tree.
		ResultObj syntaxTree = buildSexp(lexList);
		var ret = new List<Obj>();
		ret.add(syntaxTree.o);
		return ret;

//		ConsCell currentCons;
//		for (var e in lexList) {
//			switch (e) {
//				case '(':
//					currentCons = new ConsCell();
//					break;
//				case ')':
//					break;
//				case '.':
//					break;
//				default:
//					if (currentCons.l == nil) {
//						currentCons.l = new A
//					break;
//			}
//		}


//		RegExp exp = const RegExp(@"(\w+)");
//
//		Iterable<Match> matches = exp.allMatches(source);
//		for (Match m in matches) {
//			String match = m.group(0);
//			print(match);
//		};

//		return new Atom.withValue(source);
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
			ret.step = i;
			break;
		case ')':
		case '.':
			break;
		default:
			//先頭が(以外ならAtomを返す
			ret.o = new Atom.withValue(list[0]);
			ret.step = 1;
			break;
	}
	return ret;
}

//List<Obj> buildSyntaxTree(List<String> list, int index, ConsCell currentCons, List<Obj> tree) {
//	print('buildSyntaxTree(' + list + ', ' + index + ', ' + currentCons + ', ' + tree + ')');
//	if (list.length < index - 1) return tree;
//
//	print('buildSyntaxTree: ' + index + ' ' + list[index]);
//	switch (list[index]) {
//		case '(':
//			var cons = new ConsCell();
//			tree.add(cons);
//			return buildSyntaxTree(list, index + 1, cons, tree);
//			break;
//		case ')':
//			break;
//		case '.':
//			return buildSyntaxTree(list, index + 1, currentCons, tree);
//			break;
//		default:
//			if (currentCons == null) {
//				tree.add(new Atom.withValue(list[index]));
//			} else if (currentCons.l == null) {
//				List<Obj> rets = buildSyntaxTree(list, index + 1, currentCons, tree);
//			print('set l' + rets[0]);
//				currentCons.l = rets[0];
//			} else {
//			print('set r');
//				List<Obj> rets = buildSyntaxTree(list, index + 1, currentCons, tree);
//				currentCons.r = rets[0];
//			}
//			break;
//	}
//	print('buildSyntaxTree: last');
//	return tree;
//}

main() {
	var list = new List<String>();
	list.add('a');
	list.add('b');
	list.add('c');
	print(new List<String>.fromList(list, 1, 2));
	Lisp l = new Lisp.init(new HashMap<String, Obj>());

	List<Obj> lispObjects = l.readSexp('1');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1));
		print(l.stringSexp(e1) == '1');
	}

	lispObjects = l.readSexp('a');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1));
		print(l.stringSexp(e1) == 'a');
	}

	lispObjects = l.readSexp('(age . sage)');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print('a');
		print(e1.l);
		print(e1.r);
		print(l.stringSexp(e1));
		print(l.stringSexp(e1) == '(age . sage)');
	}

	lispObjects = l.readSexp('(a . b)');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1));
		print(l.stringSexp(e1) == '(a . b)');
	}

	lispObjects = l.readSexp('(a . (b . c))');
	for (Obj e in lispObjects) {
		Obj e1 = l.evalSexp(e);
		print(l.stringSexp(e1));
		print(l.stringSexp(e1) == '(a . (b . c))');
	}

//	Obj c1, c2, c3;
//	c1 = new ConsCell.withValues(new Atom.withValue(1), new Nil());
//	c2 = new ConsCell.withValues(new Atom.withValue("二"), c1);
//	c3 = new ConsCell.withValues(new Atom.withValue(3), c2);
//	print(c3);


	print('main end');

}
