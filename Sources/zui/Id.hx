package zui;

class Id {

	static var posId = 0;
	static var windowId = 0;
	static var nodeId = 0;
	static var textInputId = 0;
	static var radioId = 0;
	static var checkId = 0;

	public static function nextPos():Int { return posId++; }
	macro public static function pos() { return macro $v{nextPos()}; }

	public static function nextWindow():String { return (windowId++) + ""; }
	macro public static function window() { return macro $v{nextWindow()}; }

	public static function nextNode():String { return (nodeId++) + ""; }
	macro public static function node() { return macro $v{nextNode()}; }

    public static function nextTextInput():String { return (textInputId++) + ""; }
	macro public static function textInput() { return macro $v{nextTextInput()}; }

    public static function nextRadio():String { posId = 0; return (radioId++) + ""; }
	macro public static function radio() { return macro $v{nextRadio()}; }

	public static function nextCheck():String { return (checkId++) + ""; }
	macro public static function check() { return macro $v{nextCheck()}; }

	public static function nest(id:String, i:Int):String { return id + "_" + i; }
}
