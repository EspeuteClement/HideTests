package prefabs;


enum DiffResult {
	Skip;
	Set(value: Dynamic);
}
class Diff {

	public static function addToDiff(diff: DiffResult, key: String, value: Dynamic) : DiffResult{
		var v = switch(diff) {
			case Skip:
				var v = {};
				Reflect.setField(v, key, value);
				return Set(v);
			case Set(v):
				Reflect.setField(v, key, value);
				return diff;
		}
	}

	public static function deepCopy(v:Dynamic) : Dynamic {
		return haxe.Json.parse(haxe.Json.stringify(v));
	}

	public static function diffPrefab(original: Dynamic, modified: Dynamic) : DiffResult {
		if (original == null || modified == null) {
			if (original == modified)
				return Skip;
			return Set(deepCopy(modified));
		}

		if (original.type != modified.type)
			return Set(deepCopy(modified));

		var result = diffObj(original, modified, ["children"]); // we could skip "type" but because we are sure that the type are equals they will never be serialised

		var resultChildren = {};

		var originalChildren = original.children ?? [];
		var modifiedChildren = modified.children ?? [];

		var childrenMap : Map<String, {originals: Array<Dynamic>, modifieds: Array<Dynamic>}> = [];

		for (index => child in originalChildren) {
			hrt.tools.MapUtils.getOrPut(childrenMap, child.name ?? "", {originals: [], modifieds: []}).originals.push({index: index, child: child});
		}

		for (index => child in modifiedChildren) {
			hrt.tools.MapUtils.getOrPut(childrenMap, child.name ?? "", {originals: [], modifieds: []}).modifieds.push({index: index, child: child});
		}

		for (name => data in childrenMap) {
			for (index in 0...hxd.Math.imax(data.originals.length, data.modifieds.length)) {
				var originalChild = data.originals[index];
				var modifiedChild = data.modifieds[index];
				var key = name;
				if (index > 0)
					key += '@$index';

				var diff = diffPrefab(originalChild?.child, modifiedChild?.child);

				if (originalChild?.index != modifiedChild?.index) {
					if (modifiedChild?.index != null) {
						diff = addToDiff(diff, "@index", modifiedChild.index);
					}
				}

				switch(diff) {
					case Skip:
					case Set(value):
						Reflect.setField(resultChildren, key, value);
				}
			}
		}

		if (Reflect.fields(resultChildren).length > 0) {
			result = addToDiff(result, "children", resultChildren);
		}

		return result;
	}

	public static function diffObj(original: Dynamic, modified: Dynamic, skipFields: Array<String> = null) : DiffResult {
		skipFields ??= [];
		var result = {};
		var removedFields : Array<String> = [];

		if (original == null || modified == null) {
			if (original == modified)
				return Skip;
			return Set(deepCopy(modified));
		}

		// Mark fields as removed
		for (originalField in Reflect.fields(original)) {
			if (skipFields.contains(originalField))
				continue;

			if (!Reflect.hasField(modified, originalField)) {
				removedFields.push(originalField);
				continue;
			}
		}

		for (modifiedField in Reflect.fields(modified)) {
			if (skipFields.contains(modifiedField))
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

	public static function diffArr(original: Array<Dynamic>, modified: Dynamic) : DiffResult {
		if (original.length != modified.length) {
			return Set(deepCopy(modified));
		}

		for (index in 0...original.length) {
			var originalValue = original[index];
			var modifiedValue = modified[index];

			switch(diffValue(originalValue, modifiedValue)) {
				case Set(_):
					// return the whole modified object when any field is different than the original
					return Set(deepCopy(modified));
				case Skip:
			}
		}
		return Skip;
	}

	public static function diffValue(originalValue: Dynamic, modifiedValue: Dynamic) : DiffResult {
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

	/**
		Modifies `target` dynamic so `apply(a, diff(a, b)) == b`
	**/
	public static function apply(target: Dynamic, diff: Dynamic) {
		if (diff == null)
			return null;

		if (target == null)
			target = {};

		if (diff.type != null && diff.type != target.type) {
			return diff;
		}

		for (field in Reflect.fields(diff)) {
			if (field == "children")
			{
				var targetChildren = Reflect.field(target, "children") ?? [];
				var diffChildren = Reflect.field(diff, "children");

				var finalChildren = [];

				for (index => child in targetChildren) {
					finalChildren[index] = child;
				}

				for (fields in Reflect.fields(diffChildren)) {
					var diffChild = Reflect.field(diffChildren, fields);
					var name = fields;
					var split = name.split("@");
					var nthChild = 0;
					if (split.length == 2) {
						name = split[0];
						nthChild = Std.parseInt(split[1]);
					}

					var targetChild = null;
					var finalIndex = 0;
					for (index => child in targetChildren) {
						if (name == child.name) {
							if (nthChild == 0) {
								targetChild = child;
								finalIndex = index;
								break;
							} else {
								nthChild --;
							}
						}
					}

					// Remove child if null
					if (diffChild == null) {
						finalChildren.splice(finalIndex, 1);
						continue;
					}

					var modifiedChild = apply(targetChild, diffChild);
					finalIndex = Reflect.field(diffChild, "@index") ?? finalIndex;

					finalChildren[finalIndex] = modifiedChild;
				}

				Reflect.setField(target, "children", finalChildren);
				continue;
			}

			if (field == "@removed") {
				var removed = Reflect.field(diff, "@removed");
				for (field in (removed:Array<String>)) {
					Reflect.deleteField(target, field);
				}
				continue;
			}

			if (field.charAt(0) == "@") {
				continue;
			}

			var targetValue = Reflect.getProperty(target, field);
			var diffValue = Reflect.getProperty(diff, field);

			var targetType = Type.typeof(targetValue);
			var diffType = Type.typeof(diffValue);

			switch (targetType) {
				case TNull | TInt | TFloat | TBool | TClass(Array) | TClass(String):
					Reflect.setField(target, field, diffValue);
				case TObject:
					apply(targetValue, diffValue);
				default:
					throw "unhandeld type " + targetType;
			}
		}
		return target;
	}

	public static function testApply() {
		{
			var base = {};
			var diff = {a: 1, b: 2};

			apply(base, diff);
			Tester.expectEqualDyn(base, {a: 1, b: 2});
		}

		{
			var base = {c: 3};
			var diff = {a: 1, b: 2};

			apply(base, diff);
			Tester.expectEqualDyn(base, {c:3, a: 1, b: 2});
		}


	}

	public static function test() {
		{
			Tester.testDiff(null, null, Skip);
			Tester.testDiff(null, {}, Set({}));
			Tester.testDiff({}, null, Set(null));
			Tester.testDiff({a: 1}, {a: 1}, Skip);
			Tester.testDiff({a: 1, b: 1.0, c: [1,2,3], d: "string", e: {a: 1}}, {}, Set({"@removed": ["a", "b", "c", "d", "e"]}));
			Tester.testDiff({}, {a: 1, b: 1.0, c: [1,2,3], d: "string", e: {a: 1}}, Set({a: 1, b: 1.0, c: [1,2,3], d: "string", e: {a: 1}}));

			// Diff arrays
			Tester.testDiff({a: []}, {a: []}, Skip);

			Tester.testDiff({a: [1]}, {a: []}, Set({a: []}));
			Tester.testDiff({a: []}, {a: [1]}, Set({a: [1]}));
			Tester.testDiff({a: [1,2]}, {a: [1]}, Set({a: [1]}));
			Tester.testDiff({a: null}, {a: [1]}, Set({a: [1]}));
			Tester.testDiff({a: []}, {a: null}, Set({a: null}));
			Tester.testDiff({a: []}, {}, Set({"@removed": ["a"]}));

		}

		// {
		// 	Tester.testDiff(Skip, "a", 1, Set({a: 1}));
		// 	Tester.testDiff(Set({b: 2}), "a", 1, Set({b: 2, a: 1}));
		// }

		{

			// test that diffprefab debhaves as diffObj when index and children are missing
			Tester.testDiff(null, null, Skip);
			Tester.testDiff(null, {}, Set({}));
			Tester.testDiff({}, null, Set(null));
			Tester.testDiff({a: 1}, {a: 1}, Skip);
			Tester.testDiff({a: 1, b: 1.0, c: [1,2,3], d: "string", e: {a: 1}}, {}, Set({"@removed": ["a", "b", "c", "d", "e"]}));
			Tester.testDiff({}, {a: 1, b: 1.0, c: [1,2,3], d: "string", e: {a: 1}}, Set({a: 1, b: 1.0, c: [1,2,3], d: "string", e: {a: 1}}));

			// Full diff if the type is different
			Tester.testDiff({type: "foo", a:1}, {type: "bar", a:1}, Set({type: "bar", a:1}), true);

			// partial diff if type are the same
			Tester.testDiff({type: "foo", a:1, b:2}, {type: "foo", a:1, b:3}, Set({b: 3}), true);

			Tester.testDiff(
				{
					a: 1,
					children: [
						{name: "a",a: 1}
					]
				},
				//////////////////////////////////
				{
					a: 1,
					children: [
						{name: "a",a: 2}
					]
				}
			,
			Set({
				children: {"a": {a: 2}}
			}), true);

			Tester.testDiff(
				{
					a: 1,
					children: [
						{name: "a",a: 1},
						{name: "a",a: 2}
					]
				},
				//////////////////////////////////
				{
					a: 1,
					children: [
						{name: "a",a: 2},
						{name: "a",a: 3}
					]
				}
			,
			Set({
				children: {"a": {a: 2}, "a@1": {a: 3}}
			}), true);

			Tester.testDiff(
				{
					a: 1,
					children: [
						{name: "a",a: 1},
						{name: "a",a: 2}
					]
				},
				//////////////////////////////////
				{
					a: 1,
					children: [
						{name: "a",a: 2},
					]
				}
			,
			Set({
				children: {"a": {a: 2}, "a@1": null}
			}), true);

			Tester.testDiff(
				{
					a: 1,
					children: [
						{name: "a",a: 1},
						{name: "b",a: 1},
						{name: "c",a:1 }
					]
				},
				//////////////////////////////////
				{
					a: 1,
					children: [
						{name: "b",a: 1},
						{name: "c",a:1 },
						{name: "a",a: 2}
					]
				}
			,
			Set({
				children: {"a": {a: 2, "@index": 2}, "b": {"@index": 0}, "c": {"@index": 1}}
			}), true);

			Tester.testDiff(
				{
					a: 1,
					children: [
						{name: "a",a: 1},
					]
				},
				//////////////////////////////////
				{
					a: 1,
					children: [
						{name: "a",a: 2},
						{name: "a",a: 2}
					]
				}
			,
			Set({
				children: {"a": {a: 2}, "a@1": {"name": "a", a: 2, "@index":1}}
			}), true);

			Tester.testDiff(
				{
					a: 1,
					children: [
						{name: "a",a: 1},
						{name: "a", type: "foo", a:1},
						{name: "a", type: "foo", a:1},
					]
				},
				//////////////////////////////////
				{
					a: 1,
					children: [
						{name: "a",a: 2},
						{name: "a",a: 2, type: "bar"}
					]
				}
			,
			Set({
				children: {"a": {a: 2}, "a@1": {"name": "a", a: 2, type:"bar"}, "a@2": null},
			}), true);

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
		// redundancy with eqlDeep and diffValue != skip to make sure we dont miss any case
		if (!eqlDeep(a, b) || @:privateAccess Diff.diffValue(a,b) != Skip) {
			throw haxe.Json.stringify(a) + "\n!=\n" + haxe.Json.stringify(b);
		}
	}

	public static function eqlDeep(a: Dynamic, b: Dynamic) : Bool {
		var aType = Type.typeof(a);
		var bType = Type.typeof(b);
		if (!aType.equals(bType))
			return false;

		switch (aType) {
			case TClass(Array):
				if (a.length != b.length)
					return false;
				for (index in 0...a.length) {
					if (!eqlDeep(a[index], b[index]))
						return false;
				}
				return true;
			case TObject:
				var aFields = Reflect.fields(a);
				var bFields = Reflect.fields(b);
				if (aFields.length != bFields.length)
					return false;
				for (field in aFields) {
					if (!eqlDeep(Reflect.field(a, field), Reflect.field(b, field)))
						return false;
				}
				return true;
			case TClass(String) | TInt | TFloat | TEnum(_) | TNull:
				return a == b;
			default:
				throw "Unhandled type for eqlDeep " + aType;
				return false;
		}
	}

	public static function testDiff(orig: Dynamic, modif: Dynamic, expected: DiffResult, prefabMode: Bool = false) {
		var origClone = haxe.Json.parse(haxe.Json.stringify(orig));
		var modifClone = haxe.Json.parse(haxe.Json.stringify(modif));
		var a = @:privateAccess prefabMode ? Diff.diffPrefab(orig, modif) : Diff.diffValue(orig, modif);
		var b = expected;

		// Diff shouldn't modify values
		expectEqualDyn(orig, origClone);
		expectEqualDyn(modif, modifClone);

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
						var copy = Reflect.copy(orig);
						copy = Diff.apply(copy, w);
						expectEqualDyn(copy, modif);
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
			Diff.testApply,
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
