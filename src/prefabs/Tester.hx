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

			Tester.expectEqual(b.floatValue, diff.floatValue);
			Tester.expectEqual(b.intValue, diff.intValue);
			Tester.expectEqual(null, diff.dontDiffMe);
			Tester.expectEqual(b.stringValue, diff.stringValue);
		}


		a.floatValue = 1.0;
		a.intValue = 10;
		a.dontDiffMe = 3;
		a.stringValue = "Bar";

		{
			var diff = a.diff(b, {});

			Tester.expectNotEqual(b.floatValue, diff.floatValue);
			Tester.expectEqual(b.intValue, diff.intValue);
			Tester.expectEqual(null, diff.dontDiffMe);
			Tester.expectEqual(b.stringValue, diff.stringValue);
		}

		b.stringValue = null;

		{
			var diff = a.diff(b, {});

			Tester.expectNotEqual(b.floatValue, diff.floatValue);
			Tester.expectEqual(b.intValue, diff.intValue);
			Tester.expectEqual(null, diff.dontDiffMe);
			Tester.expectEqual(diff.stringValue, null);

			// make sure that the field in the object exists (because we want to know in the diffs when to remove a value)
			Assert.assert(Reflect.hasField(diff, "stringValue"));
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
			Tester.expectEqual(diff.fruit, "Peach");
			Tester.expectEqual(diff.color, "Green");
			Tester.expectEqual(diff.hacker, 2);
		}

		a.fruit = Peach;
		a.color = Green;
		a.hacker = Charles;
		{
			var diff = a.diff(b, {});
			Tester.expectEqual(diff.fruit, null);
			Tester.expectEqual(diff.color, null);
			Tester.expectEqual(diff.hacker, null);
		}

		a.fruit = Banana;
		a.color = Blue;
		a.hacker = Bob;
		{
			var diff = a.diff(b, {});
			Tester.expectEqual(diff.fruit, "Peach");
			Tester.expectEqual(diff.color, "Green");
			Tester.expectEqual(diff.hacker, 2);
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

		a.td = {foo: 41, bar: 99.0};

		a.sub = new TestSubclass(null, null);
		a.sub.float = 42.0;
		a.sub.int = 99;
		a.sub.array = [1,2,3];

		{
			var diff = a.diff(b, {});
			Tester.expectEqual(diff.td.foo, 42);
			Tester.expectEqual(diff.td.bar, 99.0); // the 99 value should be present in the copied struct (because object are fully cloned in diffs)
			Tester.expectNotEqual(a.td, diff.td); // check deep copy succeeded
			Tester.expectNotEqual(b.td, diff.td); // check deep copy succeeded

			Assert.assert(!Reflect.hasField(diff, "sub"));
		}

		a.sub.float = 41.0;
		{
			var diff = a.diff(b, {});

			Tester.expectEqual(diff.sub.float, 42.0);
			Tester.expectEqual(diff.sub.int, 99);
			Tester.expectEqual(diff.sub.array[0], 1);
			Tester.expectEqual(diff.sub.array[1], 2);
			Tester.expectEqual(diff.sub.array[2], 3);

			Tester.expectNotEqual(a.sub, diff.sub); // check deep copy succeeded
			Tester.expectNotEqual(b.sub, diff.sub); // check deep copy succeeded
		}
	}
}

class TestDiffArray extends hrt.prefab.Prefab {
	@:s var ofFloats : Array<Float>;
	@:s var ofInts : Array<Int>;
	@:s var ofStructs : Array<TestStruct>;
	@:s var ofDynamics : Array<Dynamic>;

	public static function test() {
		var a = new TestDiffArray(null, null);
		var b = new TestDiffArray(null, null);

		b.ofFloats = [1.0,2.0,3.0];
		b.ofInts = [1,2,3];
		b.ofStructs = [{foo: 1, bar: 1.0},{foo: 2, bar: 2.0},{foo: 3, bar: 3.0}];
		b.ofDynamics = [{foo: 1, bar: 1.0},{buzz: 2, boar: 2.0},{foo: 3, bar: 3.0}];

		{
			var diff = a.diff(b, {});
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
		}

		/// Test similar arrays being ignored in diffs

		a.ofFloats = [1.0,2.0,3.0];
		a.ofInts = [1,2,3];
		a.ofStructs = [{foo: 1, bar: 1.0},{foo: 2, bar: 2.0},{foo: 3, bar: 3.0}];

		{
			var diff = a.diff(b, {});
			Tester.expectEqual(diff.ofFloats, null);
			Tester.expectEqual(diff.ofInts, null);
			Tester.expectEqual(diff.ofStructs, null);
		}

		/// Tests that having one value off copies the whole array in the diff

		a.ofFloats[1] = 99;
		a.ofInts[2] = 99;
		a.ofStructs.push({foo: 3, bar: 3.0});

		{
			var diff = a.diff(b, {});
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

			Tester.expectNotEqual(diff.dyn, null);
			Tester.expectNotEqual(diff.dyn, b.dyn);

			Tester.expectEqual(diff.dyn.foo, 1.0);
			Tester.expectEqual(diff.dyn.bar, 2.0);
		}

		a.dyn = {
			foo: 1.0,
			bar: 2.0,
		};

		{
			var diff = a.diff(b, {});

			Tester.expectEqual(diff.dyn, null);
		}

		a.dyn.buzz = 3.0;

		{
			var diff = a.diff(b, {});

			Tester.expectNotEqual(diff.dyn, null);
			Tester.expectNotEqual(diff.dyn, b.dyn);

			Tester.expectEqual(diff.dyn.foo, 1.0);
			Tester.expectEqual(diff.dyn.bar, 2.0);
			Assert.assert(!Reflect.hasField(diff.dyn, "buzz"));
		}
	}
}

@:build(hrt.prefab.Macros.buildSerializable())
class TestCopyAllToDynamic {
	@:s public var float: Float = 42.0;
	@:s public var int : Int;
	@:s public var dyn : Dynamic;
	@:s public var td : TestDiffTypedef;

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

			Assert.assert(Reflect.hasField(copy, "td"));
			Tester.expectEqual(copy.td, null);
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
