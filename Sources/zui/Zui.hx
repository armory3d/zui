package zui;

class Zui {

	// Theme values
	public static inline var ELEMENT_H = 30; // Sizes
	public static inline var ARROW_W = ELEMENT_H * 0.5;
	public static inline var TITLE_OFFSET_X = ARROW_W * 1.3;
	// Colors

	var inputX:Float; // Input position
	var inputY:Float;
	var inputDX:Float; // Delta
	var inputDY:Float;
	var inputReleased:Bool; // Buttons

	var isKeyDown = false; // Keys
	var key:kha.Key;
	var char:String;

	var g:kha.graphics2.Graphics;
	var font:kha.Font;

	var _x:Float; // Cursor position
	var _y:Float;
	var _w:Int; // Window size
	var _h:Int;

	var cursorX = 0; // Text input
	var cursorY = 0;
	var cursorPixelX = 0.0;

	var windowExpanded:Array<Bool> = []; // Element states
	var nodeExpanded:Array<Bool> = [];
	var checkSelected:Array<Bool> = [];
	var radioSelected:Array<Int> = [];
	var textSelected:Int = -1;

	public function new(font:kha.Font) {
		this.font = font;

		// Fixed amount of elements for now
		for (i in 0...10) windowExpanded.push(true);
		for (i in 0...100) nodeExpanded.push(true);
		for (i in 0...100) checkSelected.push(false);
		for (i in 0...10) radioSelected.push(0); 
	}

	public function begin(g:kha.graphics2.Graphics) {
		this.g = g;
		_x = 0; // Reset cursor
		_y = 0;
		_w = 0;
		_h = 0;
	}

	public function end() {
		// Only one char at once for now
		isKeyDown = false;
	}

	public function setInput(inputX:Float, inputY:Float, inputReleased:Bool) {
		this.inputDX = inputX - this.inputX;
		this.inputDY = inputY - this.inputY;
		this.inputX = inputX;
		this.inputY = inputY;
		this.inputReleased = inputReleased;
	}

	public function setKeyInput(isKeyDown:Bool, key:kha.Key, char:String) {
		this.isKeyDown = isKeyDown;
		this.key = key;
		this.char = char;
	}

	public function window(x:Int, y:Int, w:Int, h:Int, text:String, id:Int):Bool {
		_x = x;
		_y = y;
		_w = w;
		_h = h;

		if (getPressed()) {
			windowExpanded[id] = !windowExpanded[id];
		}

		g.color = 0xff333333; // Bg
		windowExpanded[id] ? g.fillRect(_x, _y, _w, _h) : g.fillRect(_x, _y, _w, ELEMENT_H);

		drawArrow(windowExpanded[id]); // Arrow

		g.color = 0xffffffff; // Title
		g.font = font;
		g.drawString(text, _x + TITLE_OFFSET_X, _y);

		_y += ELEMENT_H;

		return windowExpanded[id];
	}

	public function node(text:String, id:Int):Bool {
		if (getPressed()) {
			nodeExpanded[id] = !nodeExpanded[id];
		}

		g.color = 0xff555555; // Bg
		g.fillRect(_x, _y, _w, ELEMENT_H);

		drawArrow(nodeExpanded[id]);

		g.color = 0xffffffff; // Title
		g.font = font;
		g.drawString(text, _x + TITLE_OFFSET_X, _y);

		_y += ELEMENT_H;

		return nodeExpanded[id];
	}

	public function text(text:String) {
		g.color = 0xffffffff;
		g.font = font;
		g.drawString(text, _x, _y);

		_y += ELEMENT_H;
	}

	public function inputText(text:String, id:Int):String {
		if (textSelected != id && getPressed()) { // Passive
			textSelected = id;
			cursorX = 0;
			cursorY = 0;
			cursorPixelX = 0;
		}

		if (textSelected == id) { // Active
			if (isKeyDown) { // Process input
				if (key == kha.Key.LEFT) { // Move cursor
					if (cursorX > 0) {
						cursorX--;
						updateCursorPixelX(text);
					}
				}
				else if (key == kha.Key.RIGHT) {
					if (cursorX < text.length) {
						cursorX++;
						updateCursorPixelX(text);
					}
				}
				else if (key == kha.Key.BACKSPACE) { // Remove char
					if (cursorX > 0) {
						text = text.substr(0, cursorX - 1) + text.substr(cursorX);
						cursorX--;
						updateCursorPixelX(text);
					}
				}
				else if (key == kha.Key.ENTER) { // Deselect
					textSelected = -1; // One-line text for now
				}
				else if (key == kha.Key.CHAR) {
					if (char.charCodeAt(0) == 13) { // ENTER
						textSelected = -1; // One-line text for now
					}
					else {
						text = text.substr(0, cursorX) + char + text.substr(cursorX);
						cursorX++;
						updateCursorPixelX(text);
					}
				}
			}

			g.color = 0xffffffff; // Cursor
			var cursorHeight = ELEMENT_H * 0.9;
			var lineHeight = ELEMENT_H;
			g.fillRect(_x + cursorPixelX, _y + cursorY * lineHeight, 1, cursorHeight);
		}

		g.color = 0xffffffff;
		g.font = font;
		g.drawString(text, _x, _y);

		_y += ELEMENT_H;

		return text;
	}

	public function button(text:String):Bool {
		var pressed = getPressed();

		g.color = 0xff777777;
		g.fillRect(_x, _y, _w, ELEMENT_H);

		g.color = 0xffffffff;
		g.font = font;
		g.drawString(text, _x, _y);

		_y += ELEMENT_H;

		return pressed;
	}

	public function check(text:String, id:Int):Bool {
		if (getPressed()) {
			checkSelected[id] = !checkSelected[id];
		}

		drawCheck(checkSelected[id]); // Check

		g.color = 0xffffffff; // Text
		g.font = font;
		g.drawString(text, _x + TITLE_OFFSET_X, _y);

		_y += ELEMENT_H;

		return false;
	}

	public function radio(text:String, groupId:Int, id:Int):Bool {
		if (getPressed()) {
			radioSelected[groupId] = id;
		}

		drawRadio(radioSelected[groupId] == id); // Radio

		g.color = 0xffffffff; // Text
		g.font = font;
		g.drawString(text, _x + TITLE_OFFSET_X, _y);

		_y += ELEMENT_H;

		return false;
	}

	function drawArrow(expanded:Bool) {
		g.color = 0xffffffff;
		if (expanded) {
			g.fillTriangle(_x, _y,
						   _x + ARROW_W, _y,
						   _x + ARROW_W / 2, _y + ARROW_W);
		}
		else {
			g.fillTriangle(_x, _y,
						   _x, _y + ARROW_W,
						   _x + ARROW_W, _y + ARROW_W / 2);
		}
	}

	function drawCheck(selected:Bool) {
		g.color = 0xff555555;
		g.fillRect(_x, _y, ARROW_W, ARROW_W); // Bg

		if (selected) { // Check
			g.color = 0xff777777;
			g.fillRect(_x, _y, ARROW_W * 0.8, ARROW_W * 0.8);
		}
	}

	function drawRadio(selected:Bool) {
		g.color = 0xff555555;
		g.fillRect(_x, _y, ARROW_W, ARROW_W); // Bg

		if (selected) { // Check
			g.color = 0xff777777;
			g.fillRect(_x, _y, ARROW_W * 0.6, ARROW_W * 0.6);
		}
	}

	function getPressed():Bool {
		return inputReleased &&
        	inputX >= _x && inputX < (_x + _w) &&
        	inputY >= _y && inputY < (_y + ELEMENT_H);
	}

	function updateCursorPixelX(text:String) { // Set cursor to current char
		var str = text.substr(0, cursorX);
		cursorPixelX = font.stringWidth(str);
	}

	function capCursor(text:String) { // Make sure cursor stays in bounds
		if (cursorX > text.length) {
			cursorX = text.length;
			updateCursorPixelX(text);
		}
	}
}
