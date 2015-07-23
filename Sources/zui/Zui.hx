package zui;

class Zui {

	// Theme values
	static inline var ELEMENT_H = 30; // Sizes
	static inline var ELEMENT_SEPARATOR_H = 1;
	static inline var ARROW_W = ELEMENT_H * 0.3;
	static inline var ARROW_H = ARROW_W;
	static inline var BUTTON_H = ELEMENT_H * 0.7;
	static inline var CHECK_W = ELEMENT_H * 0.5;
	static inline var CHECK_H = CHECK_W;
	static inline var CHECK_SELECT_W = ELEMENT_H * 0.3;
	static inline var CHECK_SELECT_H = CHECK_SELECT_W;
	static inline var RADIO_W = ELEMENT_H * 0.5;
	static inline var RADIO_H = RADIO_W;
	static inline var RADIO_SELECT_W = ELEMENT_H * 0.35;
	static inline var RADIO_SELECT_H = RADIO_SELECT_W;
	static inline var SCROLL_W = 13;
	static inline var SCROLL_BAR_W = 10;
	static inline var DEFAULT_TEXT_OFFSET_X = 5;

	static inline var WINDOW_BG_COL = 0xff323232; // Colors
	static inline var WINDOW_HEADER_COL = 0xff444a84;
	static inline var WINDOW_TEXT_COL = 0xffffffff;
	static inline var SCROLL_BG_COL = 0xff0c0c0c;
	static inline var SCROLL_COL = 0xff494949;
	static inline var NODE_BG_COL = 0xff585da4;
	static inline var NODE_TEXT_COL = 0xffffffff;
	static inline var BUTTON_BG_COL = 0xff4d526a;
	static inline var BUTTON_TEXT_COL = 0xffffffff;
	static inline var CHECK_COL = 0xff4d526a;
	static inline var CHECK_SELECT_COL = 0xffa3a8c0;
	static inline var RADIO_COL = 0xff4d526a;
	static inline var RADIO_SELECT_COL = 0xffa3a8c0;
	static inline var DEFAULT_TEXT_COL = 0xffffffff;
	static inline var DEFAULT_LABEL_COL = 0xffaaaaaa;
	static inline var ARROW_COL = 0xffffffff;

	public static inline var ALIGN_LEFT = 0;
	public static inline var ALIGN_CENTER = 1;
	public static inline var ALIGN_RIGHT = 2;

	static var firstInstance = true;
	static var inputX:Float; // Input position
	static var inputY:Float;
	static var inputDX:Float; // Delta
	static var inputDY:Float;
	static var inputStarted:Bool; // Buttons
	static var inputReleased:Bool;
	static var inputDown:Bool;

	static var isKeyDown = false; // Keys
	static var key:kha.Key;
	static var char:String;

	public static var scrolling:Bool = false;

	static var cursorX = 0; // Text input
	static var cursorY = 0;
	static var cursorPixelX = 0.0;

	var ratios:Array<Float>; // Splitting rows
	var curRatio:Int = -1;
	var xBeforeSplit:Float;
	var wBeforeSplit:Int;

	var g:kha.graphics2.Graphics;
	var font:kha.Font;
	var fontSmall:kha.Font;

	var fontOffsetY:Float; // Precalculated offsets
	var fontSmallOffsetY:Float;
	var arrowOffsetX:Float;
	var arrowOffsetY:Float;
	var titleOffsetX:Float;
	var buttonOffsetY:Float;
	var checkOffsetX:Float;
	var checkOffsetY:Float;
	var checkSelectOffsetX:Float;
	var checkSelectOffsetY:Float;
	var radioOffsetX:Float;
	var radioOffsetY:Float;
	var radioSelectOffsetX:Float;
	var radioSelectOffsetY:Float;

	var _x:Float; // Cursor(stack) position
	var _y:Float;
	var _w:Int;
	var _h:Int;

	var _windowX:Float;
	var _windowY:Float;
	var _windowW:Float;
	var _windowH:Float;
	var currentWindowId:Int;

	var windowExpanded:Array<Bool> = []; // Element states
	var windowScrollOffset:Array<Float> = [];
	var windowScrollEnabled:Array<Bool> = [];
	var nodeExpanded:Array<Bool> = [];
	var checkSelected:Array<Bool> = [];
	var radioSelected:Array<Int> = [];
	var textSelected:Int = -1;

	public function new(font:kha.Font, fontSmall:kha.Font) {
		this.font = font;
		this.fontSmall = fontSmall;
		var fontHeight = font.getHeight();
		var fontSmallHeight = fontSmall.getHeight();

		fontOffsetY = (ELEMENT_H - fontHeight) / 2; // Precalculate offsets
		fontSmallOffsetY = (ELEMENT_H - fontSmallHeight) / 2;
		arrowOffsetY = (ELEMENT_H - ARROW_H) / 2;
		arrowOffsetX = arrowOffsetY;
		titleOffsetX = arrowOffsetX * 2 + ARROW_W;
		buttonOffsetY = (ELEMENT_H - BUTTON_H) / 2;
		checkOffsetY = (ELEMENT_H - CHECK_H) / 2;
		checkOffsetX = checkOffsetY;
		checkSelectOffsetY = (CHECK_H - CHECK_SELECT_H) / 2;
		checkSelectOffsetX = checkSelectOffsetY;
		radioOffsetY = (ELEMENT_H - RADIO_H) / 2;
		radioOffsetX = radioOffsetY;
		radioSelectOffsetY = (RADIO_H - RADIO_SELECT_H) / 2;
		radioSelectOffsetX = radioSelectOffsetY;

		for (i in 0...10) { // Fixed amount of elements for now
			windowExpanded.push(true);
			windowScrollOffset.push(0);
			windowScrollEnabled.push(false);
		}
		for (i in 0...100) nodeExpanded.push(false);
		for (i in 0...100) checkSelected.push(false);
		for (i in 0...10) radioSelected.push(0);

		if (firstInstance) {
			firstInstance = false;
			kha.input.Mouse.get().notify(onMouseDown, onMouseUp, onMouseMove, null);
			//kha.input.Surface.get().notify(onMouseDown, onMouseUp, onMouseMove);
			kha.input.Keyboard.get().notify(onKeyDown, onKeyUp);
		}
	}

	public function begin(g:kha.graphics2.Graphics) {
		this.g = g;
		_x = 0; // Reset cursor
		_y = 0;
		_w = 0;
		_h = 0;
	}

	var lastMaxY:Float = 0;
	public function end() {
		// Reset input - only one char and one zui instance for now
		Zui.isKeyDown = false;
		Zui.inputStarted = false;
		Zui.inputReleased = false;
		Zui.inputDX = 0;
		Zui.inputDY = 0;
		lastMaxY = _y;
	}

	public function window(x:Int, y:Int, w:Int, h:Int, text:String, id:Int):Bool {
		currentWindowId = id;
		_windowX = x;
		_windowY = y;
		_windowW = w;
		_windowH = h;
		_x = x;
		_y = y + windowScrollOffset[id];
		_w = !windowScrollEnabled[id] ? w : w - SCROLL_W; // Exclude scrollbar if present
		_h = h;

		if (getPressed()) {
			windowExpanded[id] = !windowExpanded[id];
		}

		if (windowExpanded[id]) { // Bg
			g.color = WINDOW_BG_COL;
			g.fillRect(_x, _y - windowScrollOffset[id], _w, lastMaxY);
		}
		g.color = WINDOW_HEADER_COL; // Header
		g.fillRect(_x, _y, _w, ELEMENT_H);

		drawArrow(windowExpanded[id]); // Arrow

		g.color = WINDOW_TEXT_COL; // Title
		drawString(g, text, titleOffsetX, 0);

		endElement();

		return windowExpanded[id];
	}

	public function endWindow() {
		var id = currentWindowId;
		var fullHeight = _y - windowScrollOffset[id];
		if (fullHeight < _windowH) { // Disable scrollbar
			windowScrollEnabled[id] = false;
			windowScrollOffset[id] = 0;
		}
		else { // Draw window scrollbars if necessary
			windowScrollEnabled[id] = true;
			var amountToScroll = _windowH - fullHeight;
			var amountScrolled = windowScrollOffset[id];
			var ratio = amountScrolled / amountToScroll;
			var barH = _windowH - Math.abs(amountToScroll);
			if (barH < ELEMENT_H * 2) barH = ELEMENT_H;
			var barY = (_windowH - barH) * ratio;

			if (inputStarted && // Start scrolling
				getInputInRect(_windowX + _windowW - SCROLL_BAR_W, barY, SCROLL_BAR_W, barH)) {
				
				scrolling = true;
			}
			if (inputReleased) { // End scrolling
				scrolling = false;
			}
			if (scrolling) { // Scroll
				windowScrollOffset[id] -= inputDY;
				// Stay in bounds
				if (windowScrollOffset[id] > 0) windowScrollOffset[id] = 0;
				else if (fullHeight + windowScrollOffset[id] < _windowH) {
					windowScrollOffset[id] = _windowH - fullHeight;
				}
			}
			g.color = SCROLL_BG_COL; // Bg
			g.fillRect(_windowX + _windowW - SCROLL_W, _windowY, SCROLL_W, _windowH);
			g.color = SCROLL_COL; // Bar
			g.fillRect(_windowX + _windowW - SCROLL_BAR_W, barY, SCROLL_BAR_W, barH);
		}
	}

	public function node(text:String, id:Int, fillBg = true):Bool {
		if (getPressed()) {
			nodeExpanded[id] = !nodeExpanded[id];
		}

		if (fillBg) { // Bg
			g.color = NODE_BG_COL;
			g.fillRect(_x, _y, _w, ELEMENT_H);
		}

		drawArrow(nodeExpanded[id]);

		g.color = NODE_TEXT_COL; // Title
		drawString(g, text, titleOffsetX, 0);

		endElement();

		return nodeExpanded[id];
	}

	public function text(text:String, align = ALIGN_LEFT) {
		g.color = DEFAULT_TEXT_COL;
		drawString(g, text, DEFAULT_TEXT_OFFSET_X, 0, align);

		endElement();
	}

	public function inputText(text:String, id:Int, label:String = ""):String {
		if (textSelected != id && getPressed()) { // Passive
			textSelected = id;
			cursorX = 0;
			cursorY = 0;
			cursorPixelX = DEFAULT_TEXT_OFFSET_X;
		}

		if (textSelected == id) { // Active
			if (isKeyDown) { // Process input
				if (key == kha.Key.LEFT) { // Move cursor
					if (cursorX > 0) {
						cursorX--;
						updateCursorPixelX(text, fontSmall);
					}
				}
				else if (key == kha.Key.RIGHT) {
					if (cursorX < text.length) {
						cursorX++;
						updateCursorPixelX(text, fontSmall);
					}
				}
				else if (key == kha.Key.BACKSPACE) { // Remove char
					if (cursorX > 0) {
						text = text.substr(0, cursorX - 1) + text.substr(cursorX);
						cursorX--;
						updateCursorPixelX(text, fontSmall);
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
						updateCursorPixelX(text, fontSmall);
					}
				}
			}

			g.color = DEFAULT_TEXT_COL; // Cursor
			var cursorHeight = ELEMENT_H * 0.9;
			var lineHeight = ELEMENT_H;
			g.fillRect(_x + cursorPixelX, _y + cursorY * lineHeight, 1, cursorHeight);
		}

		if (label != "") {
			g.color = DEFAULT_LABEL_COL;// Label
			drawStringSmall(g, label, 0, 0, ALIGN_RIGHT);
		}

		g.color = DEFAULT_TEXT_COL; // Text
		drawStringSmall(g, text);

		endElement();

		return text;
	}

	public function button(text:String):Bool {
		var pressed = getPressed();

		g.color = BUTTON_BG_COL;
		g.fillRect(_x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H);

		g.color = BUTTON_TEXT_COL;
		drawStringSmall(g, text, 0, 0, ALIGN_CENTER);

		endElement();

		return pressed;
	}

	public function check(text:String, id:Int):Bool {
		if (getPressed()) {
			checkSelected[id] = !checkSelected[id];
		}

		drawCheck(checkSelected[id]); // Check

		g.color = DEFAULT_TEXT_COL; // Text
		drawString(g, text, titleOffsetX, 0);

		endElement();

		return false;
	}

	public function radio(text:String, groupId:Int, id:Int):Bool {
		if (getPressed()) {
			radioSelected[groupId] = id;
		}

		drawRadio(radioSelected[groupId] == id); // Radio

		g.color = DEFAULT_TEXT_COL; // Text
		drawString(g, text, titleOffsetX, 0);

		endElement();

		return false;
	}

	function drawArrow(expanded:Bool) {
		var x = _x + arrowOffsetX;
		var y = _y + arrowOffsetY;
		g.color = ARROW_COL;
		if (expanded) {
			g.fillTriangle(x, y,
						   x + ARROW_W, y,
						   x + ARROW_W / 2, y + ARROW_H);
		}
		else {
			g.fillTriangle(x, y,
						   x, y + ARROW_H,
						   x + ARROW_W, y + ARROW_H / 2);
		}
	}

	function drawCheck(selected:Bool) {
		var x = _x + checkOffsetX;
		var y = _y + checkOffsetY;
		g.color = CHECK_COL;
		g.fillRect(x, y, CHECK_W, CHECK_H); // Bg

		if (selected) { // Check
			g.color = CHECK_SELECT_COL;
			g.fillRect(x + checkSelectOffsetX, y + checkSelectOffsetY, CHECK_SELECT_W, CHECK_SELECT_H);
		}
	}

	function drawRadio(selected:Bool) {
		var x = _x + radioOffsetX;
		var y = _y + radioOffsetY;
		g.color = RADIO_COL;
		g.fillRect(x, y, RADIO_W, RADIO_H); // Bg

		if (selected) { // Check
			g.color = RADIO_SELECT_COL;
			var xx = x + radioSelectOffsetX;
			var yy = y + radioSelectOffsetY;
			g.fillTriangle(xx, yy, xx, yy + RADIO_SELECT_H, xx + RADIO_SELECT_W, yy + RADIO_SELECT_H / 2);
		}
	}

	function drawString(g:kha.graphics2.Graphics, text:String,
						xOffset:Float = DEFAULT_TEXT_OFFSET_X, yOffset:Float = 0,
						align = ALIGN_LEFT) {
		g.font = font;
		if (align == ALIGN_CENTER) xOffset = _w / 2 - font.stringWidth(text) / 2;
		else if (align == ALIGN_RIGHT) xOffset = _w - font.stringWidth(text) - DEFAULT_TEXT_OFFSET_X;

		g.drawString(text, _x + xOffset, _y + fontOffsetY + yOffset);
	}

	function drawStringSmall(g:kha.graphics2.Graphics, text:String,
							 xOffset:Float = DEFAULT_TEXT_OFFSET_X, yOffset:Float = 0,
							 align = ALIGN_LEFT) {
		g.font = fontSmall;
		if (align == ALIGN_CENTER) xOffset = _w / 2 - fontSmall.stringWidth(text) / 2;
		else if (align == ALIGN_RIGHT) xOffset = _w - fontSmall.stringWidth(text) - DEFAULT_TEXT_OFFSET_X;

		g.drawString(text, _x + xOffset, _y + fontSmallOffsetY + yOffset);
	}

	function endElement() {
		if (curRatio == -1 || (ratios != null && curRatio == ratios.length - 1)) { // New line
			_y += ELEMENT_H + ELEMENT_SEPARATOR_H;
			
			if ((ratios != null && curRatio == ratios.length - 1)) { // Last row element
				curRatio = -1;
				ratios = null;
				_x = xBeforeSplit;
				_w = wBeforeSplit;
			}
		}
		else { // Row
			curRatio++;
			_x += _w ; // More row elements to place
			_w = Std.int(wBeforeSplit * ratios[curRatio]);
		}
	}

	public function row(ratios:Array<Float>) {
		this.ratios = ratios;
		curRatio = 0;
		xBeforeSplit = _x;
		wBeforeSplit = _w;
		_w = Std.int(_w * ratios[curRatio]);
	}

	function getPressed():Bool { // Input selection
		return inputReleased &&
        	inputX >= _x && inputX < (_x + _w) &&
        	inputY >= _y && inputY < (_y + ELEMENT_H);
	}

	function getInputInRect(x:Float, y:Float, w:Float, h:Float):Bool {
		return
			inputX >= x && inputX < x + w &&
			inputY >= y && inputY < y + h;
	}

	function updateCursorPixelX(text:String, font:kha.Font) { // Set cursor to current char
		var str = text.substr(0, cursorX);
		cursorPixelX = font.stringWidth(str) + DEFAULT_TEXT_OFFSET_X;
	}

    function onMouseDown(button:Int, x:Int, y:Int) { // Input events
    	Zui.inputStarted = true;
    	Zui.inputDown = true;
    	setInputPosition(x, y);
    }

    function onMouseUp(button:Int, x:Int, y:Int) {
    	Zui.inputReleased = true;
    	Zui.inputDown = false;
    	setInputPosition(x, y);
    }

    function onMouseMove(x:Int, y:Int) {
    	setInputPosition(x, y);
    }

    function setInputPosition(inputX:Int, inputY:Int) {
		Zui.inputDX = inputX - Zui.inputX;
		Zui.inputDY = inputY - Zui.inputY;
		Zui.inputX = inputX;
		Zui.inputY = inputY;
	}

	function onKeyDown(key:kha.Key, char:String) {
        Zui.isKeyDown = true;
        Zui.key = key;
        Zui.char = char;
    }

    function onKeyUp(key:kha.Key, char:String) {
    }
}
