package zui;

class Zui {

	// Theme values
	public static inline var ELEMENT_H = 30;
	public static inline var ARROW_W = ELEMENT_H * 0.5;
	public static inline var TITLE_OFFSET_X = ARROW_W * 1.3;

	var inputX:Float; // Input position
	var inputY:Float;
	var inputDX:Float; // Delta
	var inputDY:Float; // Delta
	var inputReleased:Bool; // Buttons

	var g:kha.graphics2.Graphics;
	var font:kha.Font;

	var _x:Float; // Cursor position
	var _y:Float;
	var _w:Int; // Window size
	var _h:Int;

	var windowExpanded:Array<Bool> = []; // Element states
	var nodeExpanded:Array<Bool> = [];

	public function new(font:kha.Font) {
		this.font = font;

		// Preset amount of elements for now
		for (i in 0...10) windowExpanded.push(true);
		for (i in 0...100) nodeExpanded.push(true);
	}

	public function begin(g:kha.graphics2.Graphics) {
		this.g = g;
		_x = 0; // Reset cursor
		_y = 0;
		_w = 0;
		_h = 0;
	}

	public function setInput(inputX:Float, inputY:Float, inputReleased:Bool) {
		this.inputDX = inputX - this.inputX;
		this.inputDY = inputY - this.inputY;
		this.inputX = inputX;
		this.inputY = inputY;
		this.inputReleased = inputReleased;
	}

	public function window(x:Int, y:Int, w:Int, h:Int, text:String, id:Int):Bool {
		_x = x;
		_y = y;
		_w = w;
		_h = h;

		if (inputReleased &&
        	inputX >= _x && inputX < (_x + _w) &&
        	inputY >= _y && inputY < (_y + ELEMENT_H)) {

			windowExpanded[id] = !windowExpanded[id];
		}

		g.color = 0xff333333; // Bg
		//windowExpanded[id] ? g.fillRect(_x, _y, _w, _h) : g.fillRect(_x, _y, _w, ELEMENT_H);
		g.fillRect(_x, _y, _w, ELEMENT_H);

		drawArrow(windowExpanded[id]); // Arrow

		g.color = 0xffffffff; // Title
		g.font = font;
		g.drawString(text, _x + TITLE_OFFSET_X, _y);

		_y += ELEMENT_H;

		return windowExpanded[id];
	}

	public function node(text:String, id:Int):Bool {
		if (inputReleased &&
        	inputX >= _x && inputX < (_x + _w) &&
        	inputY >= _y && inputY < (_y + ELEMENT_H)) {

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

	public function inputText(text:String):String {
		return "";
	}

	public function button(text:String):Bool {
		var pressed = inputReleased &&
        	inputX >= _x && inputX < (_x + _w) &&
        	inputY >= _y && inputY < (_y + ELEMENT_H);

		g.color = 0xff777777;
		g.fillRect(_x, _y, _w, ELEMENT_H);

		g.color = 0xffffffff;
		g.font = font;
		g.drawString(text, _x, _y);

		_y += ELEMENT_H;

		return pressed;
	}

	public function check(text:String):Bool {

	}

	public function radio(text:String):Bool {

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
}
