class Obj {
}

class Atom extends Obj {
	var value;
	withValue(value) => this.value = value;

	Atom.withValue(this.value);

	String toString() => 'Atom($value)';
}

class Nil extends Atom {
	Nil();
	String toString() => 'Nil()';
}


class ConsCell extends Obj {
	var l, r;

	withValues(l, r) {
		this.l = l;
		this.r = r;
	}

	ConsCell.withValues(this.l, this.r);

	String toString() => '($l . $r)';
}

main() {
	var c1, c2, c3;
	c1 = new ConsCell.withValues(new Atom.withValue(1), new Nil());
	c2 = new ConsCell.withValues(new Atom.withValue("二"), c1);
	c3 = new ConsCell.withValues(new Atom.withValue(3), c2);
	print(c3);
}
