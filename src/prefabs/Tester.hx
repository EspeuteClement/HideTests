package prefabs;

class TestDiffPrefabBase extends hrt.prefab.Prefab {
	@:s var floatValue : Float;
	@:s var intValue: Int;
	var dontDiffMe: Int;
	@:s var stringValue: String;

	public static function test() {
		var a = new TestDiffPrefabBase(null, null);
		var b = new TestDiffPrefabBase(null, null);

		b.floatValue = 1.0;
		b.intValue = 2;
		b.dontDiffMe = 3;
		b.stringValue = "Foo";

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectEqual(b.floatValue, diff.floatValue);
					Tester.expectEqual(b.intValue, diff.intValue);
					Tester.expectEqual(null, diff.dontDiffMe);
					Tester.expectEqual(b.stringValue, diff.stringValue);
			}
		}


		a.floatValue = 1.0;
		a.intValue = 10;
		a.dontDiffMe = 3;
		a.stringValue = "Bar";

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectNotEqual(b.floatValue, diff.floatValue);
					Tester.expectEqual(b.intValue, diff.intValue);
					Tester.expectEqual(null, diff.dontDiffMe);
					Tester.expectEqual(b.stringValue, diff.stringValue);
			}
		}

		b.stringValue = null;

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectNotEqual(b.floatValue, diff.floatValue);
					Tester.expectEqual(b.intValue, diff.intValue);
					Tester.expectEqual(null, diff.dontDiffMe);
					Tester.expectEqual(diff.stringValue, null);

					// make sure that the field in the object exists (because we want to know in the diffs when to remove a value)
					Assert.assert(Reflect.hasField(diff, "stringValue"));
			}
		}

	}
}

enum TestDiffEnum {
	Apple;
	Peach;
	Banana;
}

enum abstract TestDiffEnumAbstract(String) {
	var Red;
	var Green;
	var Blue;
}

enum abstract TestDiffEnumAbstract2(Int) {
	var Alice;
	var Bob;
	var Charles;
}

class TestDiffPrefabEnums extends hrt.prefab.Prefab {
	@:s var fruit: TestDiffEnum;
	@:s var color: TestDiffEnumAbstract;
	@:s var hacker: TestDiffEnumAbstract2;


	public static function test() {
		var a = new TestDiffPrefabEnums(null, null);
		var b = new TestDiffPrefabEnums(null, null);
		b.fruit = Peach;
		b.color = Green;
		b.hacker = Charles;

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectEqual(diff.fruit, "Peach");
					Tester.expectEqual(diff.color, "Green");
					Tester.expectEqual(diff.hacker, 2);
			}

		}

		a.fruit = Peach;
		a.color = Green;
		a.hacker = Charles;
		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip:
				case Set(diff): throw "there shoudl be no diff";
			}
		}

		a.fruit = Banana;
		a.color = Blue;
		a.hacker = Bob;
		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectEqual(diff.fruit, "Peach");
					Tester.expectEqual(diff.color, "Green");
					Tester.expectEqual(diff.hacker, 2);
			}
		}
	}
}

typedef TestStruct = {foo: Int, bar: Float};
class TestSubclass extends hrt.prefab.Prefab {
	@:s public var float: Float;
	@:s public var int: Int;
	@:s public var array: Array<Float>;

	//public function new() {};
}

class TestDiffTypedef extends hrt.prefab.Prefab {
	@:s var td : TestStruct;
	@:s var sub : TestSubclass;

	public static function test() {
		var a = new TestDiffTypedef(null, null);
		var b = new TestDiffTypedef(null, null);
		b.td = {foo: 42, bar: 99.0};
		b.sub = new TestSubclass(null, null);
		b.sub.float = 42.0;
		b.sub.int = 99;
		b.sub.array = [1,2,3];

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectEqual(diff.td.foo, 42);
					Tester.expectEqual(diff.td.bar, 99.0);
					Tester.expectNotEqual(a.td, diff.td); // check deep copy succeeded
					Tester.expectNotEqual(b.td, diff.td); // check deep copy succeeded

					Tester.expectEqual(diff.sub.float, 42.0);
					Tester.expectEqual(diff.sub.int, 99);
					Tester.expectEqual(diff.sub.array[0], 1);
					Tester.expectEqual(diff.sub.array[1], 2);
					Tester.expectEqual(diff.sub.array[2], 3);
					Tester.expectNotEqual(a.sub, diff.sub); // check deep copy succeeded
					Tester.expectNotEqual(b.sub, diff.sub); // check deep copy succeeded
			}
		}

		a.td = {foo: 41, bar: 99.0};

		a.sub = new TestSubclass(null, null);
		a.sub.float = 42.0;
		a.sub.int = 99;
		a.sub.array = [1,2,3];

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectEqual(diff.td.foo, 42);
					Assert.assert(!Reflect.hasField(diff.td, "bar"));
					Tester.expectNotEqual(a.td, diff.td); // check deep copy succeeded
					Tester.expectNotEqual(b.td, diff.td); // check deep copy succeeded

					Assert.assert(!Reflect.hasField(diff, "sub"));
			}
		}

		a.sub.float = 41.0;
		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectEqual(diff.sub.float, 42.0);
					Assert.assert(!Reflect.hasField(diff.sub, "int"));
					Assert.assert(!Reflect.hasField(diff.sub, "array"));
			}
		}
	}
}

class TestDiffArray extends hrt.prefab.Prefab {
	@:s var ofFloats : Array<Float>;
	@:s var ofInts : Array<Int>;
	@:s var ofStructs : Array<TestStruct>;
	@:s var ofDynamics : Array<Dynamic>;
	@:s var ofSubs : Array<TestSubclass>;

	public static function test() {
		var a = new TestDiffArray(null, null);
		var b = new TestDiffArray(null, null);

		b.ofFloats = [1.0,2.0,3.0];
		b.ofInts = [1,2,3];
		b.ofStructs = [{foo: 1, bar: 1.0},{foo: 2, bar: 2.0},{foo: 3, bar: 3.0}];
		b.ofDynamics = [{foo: 1, bar: 1.0},{buzz: 2, boar: 2.0},{foo: 3, bar: 3.0}];
		b.ofSubs = [new TestSubclass(null, null), new TestSubclass(null, null)];
		b.ofSubs[0].float = 1.0;
		b.ofSubs[0].int = 2;

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectNotEqual(diff.ofFloats, null);
					Tester.expectNotEqual(diff.ofInts, null);
					Tester.expectNotEqual(diff.ofStructs, null);
					Tester.expectNotEqual(diff.ofDynamics, null);

					// the arrays refs must not be equal
					Tester.expectNotEqual(diff.ofFloats, b.ofFloats);
					Tester.expectNotEqual(diff.ofInts, b.ofInts);
					Tester.expectNotEqual(diff.ofStructs, b.ofStructs);
					Tester.expectNotEqual(diff.ofDynamics, b.ofDynamics);

					Tester.expectEqual(b.ofFloats.length, diff.ofFloats.length);
					Tester.expectEqual(b.ofFloats[0], diff.ofFloats[0]);
					Tester.expectEqual(b.ofFloats[1], diff.ofFloats[1]);
					Tester.expectEqual(b.ofFloats[2], diff.ofFloats[2]);

					Tester.expectEqual(b.ofInts.length, diff.ofInts.length);
					Tester.expectEqual(b.ofInts[0], diff.ofInts[0]);
					Tester.expectEqual(b.ofInts[1], diff.ofInts[1]);
					Tester.expectEqual(b.ofInts[2], diff.ofInts[2]);

					Tester.expectEqual(b.ofStructs.length, diff.ofStructs.length);
					Tester.expectEqual(b.ofStructs[0].foo, diff.ofStructs[0].foo);
					Tester.expectEqual(b.ofStructs[1].bar, diff.ofStructs[1].bar);
					Tester.expectEqual(b.ofStructs[2].foo, diff.ofStructs[2].foo);

					Tester.expectEqual(b.ofDynamics.length, diff.ofDynamics.length);
					Tester.expectEqual(b.ofDynamics[0].foo, diff.ofDynamics[0].foo);
					Tester.expectEqual(b.ofDynamics[1].boar, diff.ofDynamics[1].boar);
					Tester.expectEqual(b.ofDynamics[2].foo, diff.ofDynamics[2].foo);

					Tester.expectEqual(b.ofSubs.length, diff.ofSubs.length);
					Tester.expectEqual(b.ofSubs[0].float, diff.ofSubs[0].float);
					Tester.expectEqual(b.ofSubs[0].int, diff.ofSubs[0].int);
			}
		}

		/// Test similar arrays being ignored in diffs

		a.ofFloats = [1.0,2.0,3.0];
		a.ofInts = [1,2,3];
		a.ofStructs = [{foo: 1, bar: 1.0},{foo: 2, bar: 2.0},{foo: 3, bar: 3.0}];

		a.ofSubs = [new TestSubclass(null, null), new TestSubclass(null, null)];
		a.ofSubs[0].float = 1.0;
		a.ofSubs[0].int = 2;

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Assert.assert(!Reflect.hasField(diff,"ofFloats"));
					Assert.assert(!Reflect.hasField(diff,"ofInts"));
					Assert.assert(!Reflect.hasField(diff,"ofStructs"));
					Assert.assert(!Reflect.hasField(diff,"ofSubs"));
			}
		}

		/// Tests that having one value off copies the whole array in the diff

		a.ofFloats[1] = 99;
		a.ofInts[2] = 99;
		a.ofStructs.push({foo: 3, bar: 3.0});
		a.ofSubs[0].int = 1;

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectNotEqual(diff.ofFloats, null);
					Tester.expectNotEqual(diff.ofInts, null);
					Tester.expectNotEqual(diff.ofStructs, null);

					// the arrays refs must not be equal
					Tester.expectNotEqual(diff.ofFloats, b.ofFloats);
					Tester.expectNotEqual(diff.ofInts, b.ofInts);
					Tester.expectNotEqual(diff.ofStructs, b.ofStructs);

					Tester.expectEqual(b.ofFloats.length, diff.ofFloats.length);
					Tester.expectEqual(b.ofFloats[0], diff.ofFloats[0]);
					Tester.expectEqual(b.ofFloats[1], diff.ofFloats[1]);
					Tester.expectEqual(b.ofFloats[2], diff.ofFloats[2]);

					Tester.expectEqual(b.ofInts.length, diff.ofInts.length);
					Tester.expectEqual(b.ofInts[0], diff.ofInts[0]);
					Tester.expectEqual(b.ofInts[1], diff.ofInts[1]);
					Tester.expectEqual(b.ofInts[2], diff.ofInts[2]);

					Tester.expectEqual(b.ofStructs.length, diff.ofStructs.length);
					Tester.expectEqual(b.ofStructs[0].foo, diff.ofStructs[0].foo);
					Tester.expectEqual(b.ofStructs[1].bar, diff.ofStructs[1].bar);
					Tester.expectEqual(b.ofStructs[2].foo, diff.ofStructs[2].foo);

					Tester.expectEqual(b.ofSubs.length, diff.ofSubs.length);
					Tester.expectEqual(b.ofSubs[0].float, diff.ofSubs[0].float);
					Tester.expectEqual(b.ofSubs[0].int, diff.ofSubs[0].int);
			}
		}
	}
}

class TestDiffDynamic extends hrt.prefab.Prefab {
	@:s var dyn : Dynamic;

	public static function test() {
		var a = new TestDiffDynamic(null, null);
		var b = new TestDiffDynamic(null, null);

		b.dyn = {
			foo: 1.0,
			bar: 2.0,
		};

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectNotEqual(diff.dyn, null);
					Tester.expectNotEqual(diff.dyn, b.dyn);

					Tester.expectEqual(diff.dyn.foo, 1.0);
					Tester.expectEqual(diff.dyn.bar, 2.0);
			}
		}

		a.dyn = {
			foo: 1.0,
			bar: 2.0,
		};

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip:
				case Set(diff): throw "diff but there should be no diff";
			}
		}

		a.dyn.buzz = 3.0;

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectNotEqual(diff.dyn, null);
					Tester.expectNotEqual(diff.dyn, b.dyn);

					Assert.assert(!Reflect.hasField(diff.dyn, "foo"));
					Assert.assert(!Reflect.hasField(diff.dyn, "bar"));
					Assert.assert(Reflect.hasField(diff.dyn, "buzz"));
					Tester.expectEqual(diff.dyn.buzz, null);
			}
		}

		a.dyn.bar = 3.0;

		{
			var diff = a.diff(b, {});
			switch(diff) {
				case Skip: throw "no diff";
				case Set(diff):
					Tester.expectNotEqual(diff.dyn, null);
					Tester.expectNotEqual(diff.dyn, b.dyn);

					Assert.assert(!Reflect.hasField(diff.dyn, "foo"));
					Tester.expectEqual(diff.dyn.bar, b.dyn.bar);
					Assert.assert(Reflect.hasField(diff.dyn, "buzz"));
					Tester.expectEqual(diff.dyn.buzz, null);
			}
		}
	}
}

@:build(hrt.prefab.Macros.buildSerializable())
class TestCopyAllToDynamic {
	@:s public var float: Float = 42.0;
	@:s public var int : Int;
	@:s public var dyn : Dynamic;
	@:s public var str : TestStruct;
	@:s public var sub : TestSubclass;

	public function new() {

	}

	static public function test() {
		var a = new TestCopyAllToDynamic();
		a.int = 16;

		{
			var copy = a.copyAllToDynamic({});

			Tester.expectEqual(copy.float, 42.0);
			Tester.expectEqual(copy.int, 16);

			Assert.assert(Reflect.hasField(copy, "dyn"));
			Tester.expectEqual(copy.dyn, null);

			Assert.assert(Reflect.hasField(copy, "str"));
			Tester.expectEqual(copy.str, null);

			Assert.assert(Reflect.hasField(copy, "sub"));
			Tester.expectEqual(copy.sub, null);
		}

		a.dyn = {foo: "Toto", bar: true};
		a.str = {foo: 42, bar: 99.0};
		a.sub = new TestSubclass(null, null);
		a.sub.float = 42.0;
		a.sub.int = 99;
		a.sub.array = [1,2,3];

		{
			var copy = a.copyAllToDynamic({});

			Tester.expectEqual(copy.float, 42.0);
			Tester.expectEqual(copy.int, 16);

			Assert.assert(Reflect.hasField(copy, "dyn"));
			Tester.expectNotEqual(copy.dyn, null);
			Tester.expectEqual(copy.dyn.foo, a.dyn.foo);
			Tester.expectEqual(copy.dyn.bar, a.dyn.bar);

			Tester.expectEqualDeep(copy.str, a.str);

			Tester.expectNotEqual(copy.sub, null);
			Tester.expectEqual(copy.sub.float, a.sub.float);
			Tester.expectEqual(copy.sub.int, a.sub.int);
			Tester.expectEqualDeep(copy.sub.array, a.sub.array);
		}
	}
}

class TestDiffChildren {

	public static function test() {
		var a = new hrt.prefab.Prefab(null, null);
		var b = new hrt.prefab.Prefab(null, null);

		var aChild = new hrt.prefab.Prefab(a, null);
		aChild.name = "child";
		aChild.props = {foo: 1};

		var aChildChild = new hrt.prefab.Prefab(aChild, null);
		aChildChild.name = "subchild";
		aChildChild.props = {foo: 2, bar: 3};


		var bChild = new hrt.prefab.Prefab(b, null);
		bChild.name = "child";
		bChild.props = {foo: 1};

		var bChildChild = new hrt.prefab.Prefab(bChild, null);
		bChildChild.name = "subchild";
		bChildChild.props = {foo: 2, bar: 3};

		// Test there is no diff when the prefabs are identical
		{
			switch(a.diff(b, {})) {
				case Skip:
				case Set(_): throw "there should be no diff";
			};
		}

		// Test that a difference in the child causes the diff of the child to be serialised
		bChild.props = {foo: 2};
		{
			switch(a.diff(b, {})) {
				case Skip: throw "no skip";
				case Set(diff): {
					Assert.assert(Reflect.hasField(diff, "children"));
					Assert.assert(Reflect.hasField(diff.children, "child"));
					Assert.assert(Reflect.hasField(diff.children.child, "props"));

					Assert.assert(Reflect.fields(diff.children.child).length == 1);
					Tester.expectEqual(diff.children.child.props.foo, 2);
				}
			}
		}

		// test 2 deep diff
		(bChildChild.props:Dynamic).bar = 4;

		{
			switch(a.diff(b, {})) {
				case Skip: throw "no skip";
				case Set(diff): {
					Assert.assert(Reflect.hasField(diff, "children"));
					Assert.assert(Reflect.hasField(diff.children, "child"));
					Assert.assert(Reflect.hasField(diff.children.child, "props"));

					Assert.assert(Reflect.hasField(diff.children.child, "children"));
					Assert.assert(Reflect.hasField(diff.children.child.children, "subchild"));
					Assert.assert(Reflect.hasField(diff.children.child.children.subchild, "props"));

					Assert.assert(Reflect.fields(diff.children.child).length == 2); // props and children

					Tester.expectEqual(diff.children.child.props.foo, 2);

					Assert.assert(Reflect.fields(diff.children.child.children.subchild).length == 1); // only props
					Tester.expectEqual(diff.children.child.children.subchild.props.bar, 4);

				}
			}
		}

		// Check deep hierarchy without intermediary struct
		bChild.props = {foo: 1};

		{
			switch(a.diff(b, {})) {
				case Skip: throw "no skip";
				case Set(diff): {
					Assert.assert(Reflect.hasField(diff, "children"));
					Assert.assert(Reflect.hasField(diff.children, "child"));

					Assert.assert(Reflect.hasField(diff.children.child, "children"));
					Assert.assert(Reflect.hasField(diff.children.child.children, "subchild"));
					Assert.assert(Reflect.hasField(diff.children.child.children.subchild, "props"));

					Assert.assert(Reflect.fields(diff.children.child).length == 1); // only children

					Assert.assert(Reflect.fields(diff.children.child.children.subchild).length == 1); // only props
					Tester.expectEqual(diff.children.child.children.subchild.props.bar, 4);

				}
			}
		}

		// Test that if the child is removed from A, the full object is serialized in the diff
		aChild.parent = null;
		{
			switch(a.diff(b, {})) {
				case Skip: throw "no skip";
				case Set(diff): {
					Assert.assert(Reflect.hasField(diff, "children"));
					Assert.assert(Reflect.hasField(diff.children, "child"));
					Assert.assert(Reflect.hasField(diff.children.child, "props"));
					Tester.expectEqual(diff.children.child.type, "prefab");
					Tester.expectEqual(diff.children.child.props.foo, 1);

					Assert.assert(Reflect.hasField(diff.children.child, "children"));
					// Because the child is serialized using the prefab serialization, the children is an array
					Tester.expectNotEqual(diff.children.child.children[0], null);
					Assert.assert(Reflect.hasField(diff.children.child.children[0], "props"));

					Tester.expectEqual(diff.children.child.children[0].name, "subchild");
					Tester.expectEqual(diff.children.child.children[0].type, "prefab");
					Tester.expectEqual(diff.children.child.children[0].props.bar, 4);
				}
			}
		}
		// reset aChild parent
		aChild.parent = a;

		// Test that if the child is removed from the comparaison, a null is set in the children chain to
		// indicate that the prefab has been removed
		bChild.parent = null;

		{
			switch(a.diff(b, {})) {
				case Skip: throw "no skip";
				case Set(diff): {
					Assert.assert(Reflect.hasField(diff, "children"));
					Assert.assert(Reflect.hasField(diff.children, "child"));
					Tester.expectEqual(diff.children.child, null);


				}
			}
		}

		var bChildObj = new hrt.prefab.Object3D(b, null);
		bChildObj.name = "child";

		{
			switch(a.diff(b, {})) {
				case Skip: throw "no skip";
				case Set(diff): {
					Assert.assert(Reflect.hasField(diff, "children"));
					Assert.assert(Reflect.hasField(diff.children, "child"));
					Tester.expectEqual(diff.children.child.type, "object");
					Tester.expectEqual(diff.children.child.name, "child");
				}
			}
		}
	}
}

class TestLocatePrefab {
	static public function test() {
		var root = new hrt.prefab.Prefab(null, null);

		var a = new hrt.prefab.Prefab(root, null);
		a.name = "a";

		var b = new hrt.prefab.Prefab(root, null);
		b.name = "b";

		var ba = new hrt.prefab.Prefab(b, null);
		ba.name = "a";

		var c = new hrt.prefab.Prefab(root, null);
		c.name = "c";

		var ca = new hrt.prefab.Prefab(c, null);
		ca.name = "a";

		var caa = new hrt.prefab.Prefab(ca, null);
		caa.name = "a";

		var many = new hrt.prefab.Prefab(root, null);
		many.name = "many";

		var many1 = new hrt.prefab.Prefab(root, null);
		many1.name = "many";

		var many2 = new hrt.prefab.Prefab(root, null);
		many2.name = "many";

		var many2a = new hrt.prefab.Prefab(many2, null);
		many2a.name = "a";

		Tester.expectEqual(root.locatePrefab("a"), a);
		Tester.expectEqual(root.locatePrefab("b"), b);
		Tester.expectEqual(root.locatePrefab("c"), c);
		Tester.expectEqual(root.locatePrefab("b.a"), ba);
		Tester.expectEqual(root.locatePrefab("c.a"), ca);
		Tester.expectEqual(root.locatePrefab("c.a.a"), caa);

		Tester.expectEqual(root.locatePrefab("many"), many);
		Tester.expectEqual(root.locatePrefab("many-1"), many1);
		Tester.expectEqual(root.locatePrefab("many-2"), many2);
		Tester.expectEqual(root.locatePrefab("many-2.a"), many2a);

		Tester.expectEqual(caa.getUniqueName(), "a");
		Tester.expectEqual(caa.getAbsPath(true), "c.a.a");

		Tester.expectEqual(many.getUniqueName(), "many");
		Tester.expectEqual(many1.getUniqueName(), "many-1");
		Tester.expectEqual(many2.getUniqueName(), "many-2");

		Tester.expectEqual(many2a.getUniqueName(), "a");
		Tester.expectEqual(many2a.getAbsPath(true), "many-2.a");
		Tester.expectEqual(many2a.getAbsPath(false), "many.a");

		for (p in root.flatten()) {
			if (p == root) continue;
			Tester.expectEqual(root.locatePrefab(p.getAbsPath(true)), p);
		}

	}
}

class Tester extends hrt.prefab.Prefab {

	public static function expectEqual(a: Dynamic, b: Dynamic) {
		Assert.assert(a == b);
	}

	public static function expectNotEqual(a: Dynamic, b: Dynamic) {
		Assert.assert(a != b);
	}

	public static function expectEqualDeep(a: Dynamic, b: Dynamic) {
		var isEqual = hrt.prefab.Macros.isEqual(a, b);
		Assert.assert(isEqual);
	}


	#if editor
	override function getHideProps():Null<hide.prefab.HideProps> {
		return {
			icon: "cogs",
			name: "Tester",
		};
	}

	var codeResult : hide.Element;

	function runEditorTests() {
		var textResult = "";

		var tests = [
			TestDiffPrefabBase.test,
			TestDiffPrefabEnums.test,
			TestDiffTypedef.test,
			TestDiffArray.test,
			TestDiffDynamic.test,
			TestCopyAllToDynamic.test,
			TestLocatePrefab.test,
			TestDiffChildren.test,
		];

		var runs = 0;
		var success = 0;
		for (test in tests) {
			try {
				runs ++;
				test();
				success ++;
			} catch(e) {
				textResult += 'Test $runs failed: \n$e\n\n${haxe.CallStack.toString(haxe.CallStack.exceptionStack(true))}\n\n';
			}
		}


		textResult += '\n\nTests finished : [$success/$runs]';
		codeResult.text(textResult);
	}

	override function edit(editContext:hide.prefab.EditContext) {
		var e = new hide.Element('
		<div>
		<fancy-button>
			<span class="label">Run all tests</span>
		</fancy-button>
		<br/>
		<pre class="results"></pre>
		</div>
		'
		);

		codeResult = e.find(".results");
		codeResult.text("aaa");

		e.find("fancy-button").on("click", (_) -> runEditorTests());

		editContext.properties.add(e);
	}
	static var _ = hrt.prefab.Prefab.register("tester", Tester);
	#end
}
