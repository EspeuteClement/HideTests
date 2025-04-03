import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ExprTools;

using Lambda;

class Macros {

	#if macro
	public static function gatherTests() {
		final buildFields = Context.getBuildFields();

		final names : Array<String> = [];

		for (field in buildFields) {
			switch(field.kind) {
				case FFun(func):
					if (field.meta.find(meta -> meta.name == ":test") != null) {
						names.push(field.name);
					}
			}
		}

		return buildFields;
	}
	#end
}