package zui;

class Zui {
	public static inline var ELEMENT_H = 30; // Sizes
	static inline var ELEMENT_SEPARATOR_SIZE = 0;
	static inline var ARROW_W = ELEMENT_H * 0.3;
	static inline var ARROW_H = ARROW_W;
	static inline var BUTTON_H = ELEMENT_H * 0.7;
	static inline var CHECK_W = ELEMENT_H * 0.5;
	static inline var CHECK_H = CHECK_W;
	static inline var CHECK_SELECT_W = ELEMENT_H * 0.25;
	static inline var CHECK_SELECT_H = CHECK_SELECT_W;
	static inline var RADIO_W = ELEMENT_H * 0.5;
	static inline var RADIO_H = RADIO_W;
	static inline var RADIO_SELECT_W = ELEMENT_H * 0.35;
	static inline var RADIO_SELECT_H = RADIO_SELECT_W;
	static inline var SCROLL_W = 13;
	static inline var SCROLL_BAR_W = 10;
	static inline var DEFAULT_TEXT_OFFSET_X = 5;

	static inline var WINDOW_BG_COL = 0xff354346; // Colors
	static inline var SCROLL_BG_COL = 0xff0c0c0c;
	static inline var SCROLL_COL = 0xff494949;
	static inline var NODE_BG1_COL = 0xff2a3539;
	static inline var NODE_BG2_COL = 0xff222c2f;
	static inline var NODE_TEXT_COL = 0xffffffff;
	static inline var BUTTON_BG_COL = 0xff2b393c;
	static inline var BUTTON_TEXT_COL = 0xffffffff;
	static inline var TEXT_INPUT_BG_COL = 0xff2b393c;
	static inline var CHECK_COL = 0xff2b393c;
	static inline var CHECK_SELECT_COL = 0xff6bb278;
	static inline var RADIO_COL = 0xff2b393c;
	static inline var RADIO_SELECT_COL = 0xff6bb278;
	static inline var DEFAULT_TEXT_COL = 0xffffffff;
	static inline var DEFAULT_LABEL_COL = 0xffaaaaaa;
	static inline var ARROW_COL = 0xffffffff;

	public static inline var LAYOUT_VERTICAL = 0; // Window layout
	public static inline var LAYOUT_HORIZONTAL = 1;

	public static inline var ALIGN_LEFT = 0; // Text align
	public static inline var ALIGN_CENTER = 1;
	public static inline var ALIGN_RIGHT = 2;

	public static var isScrolling:Bool = false;

	static var firstInstance = true;

	static var inputX:Float; // Input position
	static var inputY:Float;
	static var inputDX:Float; // Delta
	static var inputDY:Float;
	static var inputWheelDelta:Int;
	static var inputStarted:Bool; // Buttons
	static var inputReleased:Bool;
	static var inputDown:Bool;

	static var isKeyDown = false; // Keys
	static var key:kha.Key;
	static var char:String;

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
	var curWindowState:WindowState;
	var windowEnded:Bool = true;

	var windowStates:Map<String, WindowState> = new Map(); // Element states
	var nodeStates:Map<String, NodeState> = new Map();
	var checkStates:Map<String, CheckState> = new Map();
	var radioStates:Map<String, RadioState> = new Map();
	var textSelectedId:String = "";
	var textSelectedCurrentText:String;
	var submitTextId:String;

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

		if (firstInstance) {
			firstInstance = false;
			prerenderElements();
			kha.input.Mouse.get().notify(onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
			//kha.input.Surface.get().notify(onMouseDown, onMouseUp, onMouseMove);
			kha.input.Keyboard.get().notify(onKeyDown, onKeyUp);
		}
	}

	static var checkSelectImage:kha.Image = null;
	function prerenderElements() {
		checkSelectImage = kha.Image.createRenderTarget(Std.int(CHECK_SELECT_W), Std.int(CHECK_SELECT_H));
		var g = checkSelectImage.g2;
		g.begin(true, 0x00000000);
		g.color = CHECK_SELECT_COL;
		g.fillRect(0, 0, CHECK_SELECT_W, CHECK_SELECT_H);
		//g.drawLine(0, CHECK_SELECT_H / 2, CHECK_SELECT_W / 2, CHECK_SELECT_H, 3);
		//g.drawLine(CHECK_SELECT_W / 2, CHECK_SELECT_H, CHECK_SELECT_W, 0, 3);
		g.end();
	}

	public function remove() {
		kha.input.Mouse.get().remove(onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
		kha.input.Keyboard.get().remove(onKeyDown, onKeyUp);
	}

	public function begin(g:kha.graphics2.Graphics) {
		this.g = g;
		_x = 0; // Reset cursor
		_y = 0;
		_w = 0;
		_h = 0;
	}

	public function end() {
		if (!windowEnded) { endWindow(); }

		Zui.isKeyDown = false; // Reset input - only one char and one zui instance for now
		Zui.inputStarted = false;
		Zui.inputReleased = false;
		Zui.inputDX = 0;
		Zui.inputDY = 0;
		Zui.inputWheelDelta = 0;
	}

	public function window(id:String, x:Int, y:Int, w:Int, h:Int, layout = LAYOUT_VERTICAL) {
		var state = windowStates.get(id);
		if (state == null) { state = new WindowState(layout); windowStates.set(id, state); }

		if (!windowEnded) { endWindow(); }
		windowEnded = false;
		
		curWindowState = state;
		_windowX = x;
		_windowY = y;
		_windowW = w;
		_windowH = h;
		_x = x;
		_y = y + state.scrollOffset;
		_w = !state.scrollEnabled ? w : w - SCROLL_W; // Exclude scrollbar if present
		_h = h;

		g.color = WINDOW_BG_COL;
		g.fillRect(_x, _y - state.scrollOffset, state.lastMaxX, state.lastMaxY);
	}

	function endWindow() {
		var state = curWindowState;
		var fullHeight = _y - state.scrollOffset;
		if (fullHeight < _windowH || state.layout == LAYOUT_HORIZONTAL) { // Disable scrollbar
			state.scrollEnabled = false;
			state.scrollOffset = 0;
		}
		else { // Draw window scrollbar if necessary
			state.scrollEnabled = true;
			var amountToScroll = _windowH - fullHeight;
			var amountScrolled = state.scrollOffset;
			var ratio = amountScrolled / amountToScroll;
			var barH = _windowH - Math.abs(amountToScroll);
			if (barH < ELEMENT_H * 2) barH = ELEMENT_H;
			var barY = (_windowH - barH) * ratio;

			if ((inputStarted) && // Start scrolling
				getInputInRect(_windowX + _windowW - SCROLL_BAR_W, barY, SCROLL_BAR_W, barH)) {
				
				state.scrolling = true;
				isScrolling = true;
			}
			if (state.scrolling) { // Scroll
				var delta = inputWheelDelta != 0 ? inputWheelDelta : inputDY;
				scroll(inputDY, fullHeight);
			}
			g.color = SCROLL_BG_COL; // Bg
			g.fillRect(_windowX + _windowW - SCROLL_W, _windowY, SCROLL_W, _windowH);
			g.color = SCROLL_COL; // Bar
			g.fillRect(_windowX + _windowW - SCROLL_BAR_W, barY, SCROLL_BAR_W, barH);
		}
		state.lastMaxX = _x;
		state.lastMaxY = _y;
		if (state.layout == LAYOUT_HORIZONTAL) state.lastMaxY += ELEMENT_H;
		windowEnded = true;
	}

	function scroll(delta:Float, fullHeight:Float) {
		var state = curWindowState;
		state.scrollOffset -= delta;
		// Stay in bounds
		if (state.scrollOffset > 0) state.scrollOffset = 0;
		else if (fullHeight + state.scrollOffset < _windowH) {
			state.scrollOffset = _windowH - fullHeight;
		}
	}

	public function node(id:String, text:String, accent = 1, expanded = false):Bool {
		var state = nodeStates.get(id);
		if (state == null) { state = new NodeState(expanded); nodeStates.set(id, state); }

		if (getPressed()) {
			state.expanded = !state.expanded;
		}

		if (accent > 0) { // Bg
			g.color = accent == 1 ? NODE_BG1_COL : NODE_BG2_COL;
			g.fillRect(_x, _y, _w, ELEMENT_H);
		}

		drawArrow(state.expanded);

		g.color = NODE_TEXT_COL; // Title
		accent > 0 ? drawString(g, text, titleOffsetX, 0) : drawStringSmall(g, text, titleOffsetX, 0);

		endElement();

		return state.expanded;
	}

	public function text(text:String, align = ALIGN_LEFT) {
		g.color = DEFAULT_TEXT_COL;
		drawStringSmall(g, text, DEFAULT_TEXT_OFFSET_X, 0, align);

		endElement();
	}

	public function textInput(id:String, text:String, label:String = ""):String {
		if (submitTextId == id) { // Submit edited text
			text = textSelectedCurrentText;
			submitTextId = "";
			textSelectedCurrentText = "";
		}

		g.color = TEXT_INPUT_BG_COL; // Text bg
		g.fillRect(_x, _y + fontOffsetY, _w, BUTTON_H);

		if (textSelectedId != id && getPressed()) { // Passive
			textSelectedId = id;
			textSelectedCurrentText = text;
			cursorX = 0;
			cursorY = 0;
			cursorPixelX = DEFAULT_TEXT_OFFSET_X;
		}

		if (textSelectedId == id) { // Active
			var text = textSelectedCurrentText;
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
					deselectText(); // One-line text for now
				}
				else if (key == kha.Key.CHAR) {
					if (char.charCodeAt(0) == 13) { // ENTER
						deselectText(); // One-line text for now
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
			textSelectedCurrentText = text;
		}

		if (label != "") {
			g.color = DEFAULT_LABEL_COL;// Label
			drawStringSmall(g, label, 0, 0, ALIGN_RIGHT);
		}

		g.color = DEFAULT_TEXT_COL; // Text
		textSelectedId != id ? drawStringSmall(g, text) : drawStringSmall(g, textSelectedCurrentText);

		endElement();

		return text;
	}

	function deselectText() {
		submitTextId = textSelectedId;
		textSelectedId = "";
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

	public function check(id:String, text:String, initState:Bool = false):Bool {
		var state = checkStates.get(id);
		if (state == null) { state = new CheckState(initState); checkStates.set(id, state); }

		if (getPressed()) {
			state.selected = !state.selected;
		}

		drawCheck(state.selected); // Check

		g.color = DEFAULT_TEXT_COL; // Text
		drawStringSmall(g, text, titleOffsetX, 0);

		endElement();

		return state.selected;
	}

	public function radio(groupId:String, pos:Int, text:String, initState:Int = 0):Bool {
		var state = radioStates.get(groupId);
		if (state == null) {
			state = new RadioState(initState); radioStates.set(groupId, state);
		}

		if (getPressed()) {
			state.selected = pos;
		}

		drawRadio(state.selected == pos); // Radio

		g.color = DEFAULT_TEXT_COL; // Text
		drawStringSmall(g, text, titleOffsetX, 0);

		endElement();

		return state.selected == pos;
	}

	public function setRadioSelection(groupId:String, pos:Int) {
		var state = radioStates.get(groupId);
		if (state != null) state.selected = pos;
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
			//g.color = CHECK_SELECT_COL;
			//g.fillRect(x + checkSelectOffsetX, y + checkSelectOffsetY, CHECK_SELECT_W, CHECK_SELECT_H);
			g.color = kha.Color.White;
			g.drawImage(checkSelectImage, x + checkSelectOffsetX, y + checkSelectOffsetY);
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
		if (curWindowState.layout == LAYOUT_VERTICAL) {
			if (curRatio == -1 || (ratios != null && curRatio == ratios.length - 1)) { // New line
				_y += ELEMENT_H + ELEMENT_SEPARATOR_SIZE;
				
				if ((ratios != null && curRatio == ratios.length - 1)) { // Last row element
					curRatio = -1;
					ratios = null;
					_x = xBeforeSplit;
					_w = wBeforeSplit;
				}
			}
			else { // Row
				curRatio++;
				_x += _w; // More row elements to place
				_w = Std.int(wBeforeSplit * ratios[curRatio]);
			}
		}
		else { // HORIZONTAL
			_x += _w + ELEMENT_SEPARATOR_SIZE;
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
    	if (isScrolling) {
    		isScrolling = false;
    		for (s in windowStates) s.scrolling = false;
    	}
    	else { // To prevent action when scrolling is active
    		Zui.inputReleased = true;
    	}
    	Zui.inputDown = false;
    	setInputPosition(x, y);
    	deselectText();
    }

    function onMouseMove(x:Int, y:Int) {
    	setInputPosition(x, y);
    }

    function onMouseWheel(delta:Int) {
    	Zui.inputWheelDelta = delta;
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

class WindowState {
	public var scrolling:Bool = false;
	public var scrollOffset:Float = 0;
	public var scrollEnabled:Bool = false;
	public var layout:Int;
	public var lastMaxX:Float = 0;
	public var lastMaxY:Float = 0;
	public function new(layout:Int) { this.layout = layout; }
}

class NodeState {
	public var expanded:Bool;
	public function new(expanded:Bool) { this.expanded = expanded; }
}

class CheckState {
	public var selected:Bool = false;
	public function new(selected:Bool) { this.selected = selected; }
}

class RadioState {
	public var selected:Int = 0;
	public function new(selected:Int) { this.selected = selected; }
}
