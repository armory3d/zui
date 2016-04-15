package zui;

class Id {

	static var posId = 0;
	static var windowId = 0;
	static var nodeId = 0;
	static var textInputId = 0;
	static var radioId = 0;
	static var checkId = 0;
	static var sliderId = 0;
	static var colorPickerId = 0;
	static var listId = 0;

	static function nextPos(): Int { return posId++; }
	macro public static function pos() { return macro $v{nextPos()}; }

	static function nextWindow(): String { return (windowId++) + ""; }
	macro public static function window() { return macro $v{nextWindow()}; }

	static function nextNode(): String { return (nodeId++) + ""; }
	macro public static function node() { return macro $v{nextNode()}; }

    static function nextTextInput(): String { return (textInputId++) + ""; }
	macro public static function textInput() { return macro $v{nextTextInput()}; }

    static function nextRadio(): String { posId = 0; return (radioId++) + ""; }
	macro public static function radio() { return macro $v{nextRadio()}; }

	static function nextCheck(): String { return (checkId++) + ""; }
	macro public static function check() { return macro $v{nextCheck()}; }
	
	static function nextSlider(): String { return (sliderId++) + ""; }
	macro public static function slider() { return macro $v{nextSlider()}; }
	
	static function nextColorPicker(): String { return (colorPickerId++) + ""; }
	macro public static function colorPicker() { return macro $v{nextColorPicker()}; }

	static function nextList(): String { return (listId++) + "l"; } // List postfix
	macro public static function list() { return macro $v{nextList()}; }

	public static function nest(id: String, i: Int): String { return id + "_" + i; }
}
