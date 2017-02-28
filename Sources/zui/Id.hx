package zui;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class Id {

	static var i = 0;
	macro public static function pos() { return macro $v{i++}; }

	public static macro function handle(ops: Expr = null) {
		var code = 'zui.Zui.Handle.global.nest(zui.Id.pos(),' + ExprTools.toString(ops) + ')';
	    return Context.parse(code, Context.currentPos());
	}
}
