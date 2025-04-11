package prefabs;


enum DiffResult {
	Skip;
	Set(value: Dynamic);
}
class Diff {

	public static function diffObj(original: Dynamic, modified: Dynamic) : DiffResult {
		var result = {};
		var removedFields : Array<String> = [];

		if (original == null || modified == null) {
			if (original == modified)
				return Skip;
			return Set(modified);
		}

		// Mark fields as removed
		for (originalField in Reflect.fields(original)) {
			if (originalField == "children")
				continue;

			if (!Reflect.hasField(modified, originalField)) {
				removedFields.push(originalField);
				continue;
			}
		}

		for (modifiedField in Reflect.fields(modified)) {
			if (modifiedField == "children")
				continue;

			var originalValue = Reflect.getProperty(original, modifiedField);
			var modifiedValue = Reflect.getProperty(modified, modifiedField);

			switch(diffValue(originalValue, modifiedValue)) {
				case Skip:
				case Set(v):
					Reflect.setField(result, modifiedField, v);
			}
		}

		if (removedFields.length > 0) {
			Reflect.setField(result, "@removed", removedFields);
		}

		if (Reflect.fields(result).length == 0)
			return Skip;
		return Set(result);
	}

	static function diffArr(original: Array<Dynamic>, modified: Dynamic) : DiffResult {
		if (original.length != modified.length) {
			return Set(modified);
		}

		for (index in 0...original.length) {
			var originalValue = original[index];
			var modifiedValue = modified[index];

			switch(diffValue(originalValue, modifiedValue)) {
				case Set(_):
					// return the whole modified object when any field is different than the original
					return Set(modified);
				case Skip:
			}
		}
		return Skip;
	}

	static function diffValue(originalValue: Dynamic, modifiedValue: Dynamic) : DiffResult {
		var originalType = Type.typeof(originalValue);
		var modifiedType = Type.typeof(modifiedValue);

		if (!originalType.equals(modifiedType)) {
			return Set(modifiedValue);
		}

		switch (modifiedType) {
			case TNull:
				// The only way we get here is if both types are null, so by definition they are both null and so there is no diff
				return Skip;
			case TInt | TFloat | TBool:
				if (originalValue == modifiedValue) {
					return Skip;
				}
			case TObject:
				return diffObj(originalValue, modifiedValue);
			case TClass(subClass): {
				switch (subClass) {
					case String:
						if (originalValue == modifiedValue) {
							return Skip;
						}
					case Array:
						return diffArr(originalValue, modifiedValue);
					default:
						throw "Can't diff class " + subClass;
				}
			}
			default:
				throw "Unhandled type " + modifiedType;
		}
		return Set(modifiedValue);
	}

	public static function apply(orignal: Dynamic, diff: Dynamic) : Dynamic {
		return null;
	}

	public static function test() {
		{
			Tester.testDiff(Diff.diffObj(null, null), Skip);
			Tester.testDiff(Diff.diffObj(null, {}), Set({}));
			Tester.testDiff(Diff.diffObj({}, null), Set(null));
			Tester.testDiff(Diff.diffObj({a: 1}, {a: 1}), Skip);
			Tester.testDiff(Diff.diffObj({a: 1, b: 1.0, c: [1,2,3], d: "string", e: {a: 1}}, {}), Set({"@removed": ["a", "b", "c", "d", "e"]}));
			Tester.testDiff(Diff.diffObj({}, {a: 1, b: 1.0, c: [1,2,3], d: "string", e: {a: 1}}), Set({a: 1, b: 1.0, c: [1,2,3], d: "string", e: {a: 1}}));

			// Diff arrays
			Tester.testDiff(Diff.diffObj({a: []}, {a: []}), Skip);

			Tester.testDiff(Diff.diffObj({a: [1]}, {a: []}), Set({a: []}));
			Tester.testDiff(Diff.diffObj({a: []}, {a: [1]}), Set({a: [1]}));
			Tester.testDiff(Diff.diffObj({a: [1,2]}, {a: [1]}), Set({a: [1]}));
			Tester.testDiff(Diff.diffObj({a: null}, {a: [1]}), Set({a: [1]}));
			Tester.testDiff(Diff.diffObj({a: []}, {a: null}), Set({a: null}));
			Tester.testDiff(Diff.diffObj({a: []}, {}), Set({"@removed": ["a"]}));

		}


		var a = {
			a: 1,
			b: 2,
			c: [1, 2, 3],
			d: {
				a: 1,
				b: 2,
				c: [1,2,3],
			}
		}

		var b = {
			a: 1,
			b: 3,
			c: [1,2,3],
		}

		switch(Diff.diffObj(a,b)) {
			case Skip: throw "Should not skip";
			case Set(v):
				Tester.expectEqual(Reflect.hasField(v, "a"), false);
				Tester.expectEqual(v.b, 3);
				Tester.expectEqual(Reflect.hasField(v, "c"), false);
				Tester.expectEqual(Reflect.hasField(v, "@removed"), true);
				Tester.expectEqual((Reflect.getProperty(v, "@removed"):Array<Dynamic>).contains("d"), true);
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

	public static function expectEqualDyn(a: Dynamic, b: Dynamic) {
		expectEqual(haxe.Json.stringify(a), haxe.Json.stringify(b));
	}

	public static function testDiff(a: DiffResult, b: DiffResult) {
		switch (a) {
			case Skip:
				switch (b) {
					case Skip: return;
					case Set(v): throw 'Skip were set $v was expected';
				}
			case Set(v):
				switch(b) {
					case Skip: throw 'Value $v where Skip was expected';
					case Set(w):
						expectEqualDyn(v,w);
						return;
				}
		}
	}

	// public static function expectEqualDeep(a: Dynamic, b: Dynamic) {
	// 	var isEqual = hrt.prefab.Macros.isEqual(a, b);
	// 	Assert.assert(isEqual);
	// }

	// public static function expectNotEqualDeep(a: Dynamic, b: Dynamic) {
	// 	var isEqual = hrt.prefab.Macros.isEqual(a, b);
	// 	Assert.assert(!isEqual);
	// }


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
			Diff.test,
			// TestSubclass.test,
			// TestCloneDynamic.test,
			// TestSerArray.test,
			// TestDiffPrefabBase.test,
			// TestDiffPrefabEnums.test,
			// TestDiffTypedef.test,
			// TestDiffArray.test,
			// TestDiffDynamic.test,
			// TestCopyAllToDynamic.test,
			TestLocatePrefab.test,
			// TestDiffChildren.test,
		];

		var runs = 0;
		var success = 0;
		for (test in tests) {
			try {
				runs ++;
				test();
				success ++;
			} catch(e) {
				textResult += '=========================================================================\n=========================================================================\nTest $runs failed: \n$e\n\n${haxe.CallStack.toString(haxe.CallStack.exceptionStack(true))}\n\n';
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
