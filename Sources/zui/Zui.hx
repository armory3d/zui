package zui;

// Immediate Mode UI for Haxe Kha
// https://github.com/luboslenco/zui

class Zui {
	static inline var _ELEMENT_W = 100; // For horizontal layout
	static inline var _ELEMENT_H = 30; // For vertical layout
	static inline var _ELEMENT_SEPARATOR_SIZE = 0;
	static inline var _ARROW_W = _ELEMENT_H * 0.3;
	static inline var _ARROW_H = _ARROW_W;
	static inline var _BUTTON_H = _ELEMENT_H * 0.7;
	static inline var _CHECK_W = _ELEMENT_H * 0.5;
	static inline var _CHECK_H = _CHECK_W;
	static inline var _CHECK_SELECT_W = _ELEMENT_H * 0.3;
	static inline var _CHECK_SELECT_H = _CHECK_SELECT_W;
	static inline var _RADIO_W = _ELEMENT_H * 0.5;
	static inline var _RADIO_H = _RADIO_W;
	static inline var _RADIO_SELECT_W = _ELEMENT_H * 0.3;
	static inline var _RADIO_SELECT_H = _RADIO_SELECT_W;
	static inline var _SCROLL_W = 12;
	static inline var _SCROLL_BAR_W = 12;
	static inline var _DEFAULT_TEXT_OFFSET_X = 8;
	static inline var _TAB_W = 12;
	static inline var _LINE_STRENGTH = 2;
	static var SCALE:Float;

	static inline var WINDOW_BG_COL = 0xff000000; // Colors
	static inline var WINDOW_TINT_COL = 0xddffffff;
	static inline var SCROLL_BG_COL = 0xff101010;
	static inline var SCROLL_COL = 0xff494949;
	static inline var NODE_BG1_COL = 0xff000000;
	static inline var NODE_BG2_COL = 0xff000000;
	static inline var NODE_TEXT_COL = 0xff737270;
	static inline var NODE_TEXT_COL_HOVER = NODE_TEXT_COL;
	static inline var BUTTON_BG_COL = 0xff557ab7;
	static inline var BUTTON_TEXT_COL = 0xffcac9c7;
	static inline var BUTTON_BG_COL_HOVER = 0xff668ecf;
	static inline var BUTTON_BG_COL_PRESSED = 0xffcda90b;
	static inline var TEXT_INPUT_BG_COL = 0xff343436;
	static inline var TEXT_INPUT_BG_COL_HOVER = 0xff444446;
	static inline var TEXT_CURSOR_COL = DEFAULT_TEXT_COL;
	static inline var TEXT_CURSOR_FLASH_SPEED = 0.5;
	static inline var CHECK_COL = 0xff343436;
	static inline var CHECK_COL_HOVER = 0xff444446;
	static inline var CHECK_SELECT_COL = 0xffd6d6d6;
	static inline var RADIO_COL = 0xff343436;
	static inline var RADIO_COL_HOVER = 0xff444446;
	static inline var RADIO_SELECT_COL = 0xffd6d6d6;
	static inline var DEFAULT_TEXT_COL = 0xffcac9c7;
	static inline var DEFAULT_TEXT_COL_HOVER = DEFAULT_TEXT_COL;
	static inline var DEFAULT_LABEL_COL = 0xffaaaaaa;
	static inline var ARROW_COL = 0xffcac9c7;
	static inline var ARROW_COL_HOVER = ARROW_COL;
	static inline var SEPARATOR_COL = 0xff22211f;
	static inline var FILL_TEXT_INPUT_BG = false;
	static inline var FILL_BUTTON_BG = true;
	static inline var FILL_CHECK_BG = false;
	static inline var FILL_RADIO_BG = false;

	public static inline var LAYOUT_VERTICAL = 0; // Window layout
	public static inline var LAYOUT_HORIZONTAL = 1;

	public static inline var ALIGN_LEFT = 0; // Text align
	public static inline var ALIGN_CENTER = 1;
	public static inline var ALIGN_RIGHT = 2;

	public static var isScrolling = false; // Use to limit other activities
	public static var isTyping = false;

	public static var autoNotifyMouseEvents = true;
	static var firstInstance = true;

	var inputX:Float; // Input position
	var inputY:Float;
	
	var inputInitialX:Float;
	var inputInitialY:Float;

	var inputDX:Float; // Delta
	var inputDY:Float;
	var inputWheelDelta:Int;
	var inputStarted:Bool; // Buttons
	var inputReleased:Bool;
	var inputDown:Bool;

	var isKeyDown = false; // Keys
	var key:kha.Key;
	var char:String;

	var cursorX = 0; // Text input
	var cursorY = 0;
	var cursorPixelX = 0.0;

	var ratios:Array<Float>; // Splitting rows
	var curRatio:Int = -1;
	var xBeforeSplit:Float;
	var wBeforeSplit:Int;

	var globalG:kha.graphics2.Graphics; // Drawing
	var g:kha.graphics2.Graphics;
	var font:kha.Font;
	var fontSize:Int;
	var fontSmallSize:Int;

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
	var scrollAlign:Float;

	var _x:Float; // Cursor(stack) position
	var _y:Float;
	var _w:Int;
	var _h:Int;

	var _windowX:Float; // Window state
	var _windowY:Float;
	var _windowW:Float;
	var _windowH:Float;
	var curWindowState:WindowState;
	var windowEnded = true;

	var windowStates:Map<String, WindowState> = new Map(); // Element states
	var nodeStates:Map<String, NodeState> = new Map();
	var checkStates:Map<String, CheckState> = new Map();
	var radioStates:Map<String, RadioState> = new Map();
	var sliderStates:Map<String, SliderState> = new Map();
	// var colorPickerStates:Map<String, ColorPickerState> = new Map();
	var textSelectedId:String = "";
	var textSelectedCurrentText:String;
	var submitTextId:String;
	var textToSubmit:String = "";
	var khaWindowId = 0;
	var scaleFactor:Float;

	public function new(font:kha.Font, fontSize = 17, fontSmallSize = 16, khaWindowId = 0, scaleFactor = 1.0) {
		this.font = font;
		this.fontSize = Std.int(fontSize * scaleFactor);
		this.fontSmallSize = Std.int(fontSmallSize * scaleFactor);
		var fontHeight = font.height(this.fontSize);
		var fontSmallHeight = font.height(this.fontSmallSize);
		this.khaWindowId = khaWindowId;
		SCALE = this.scaleFactor = scaleFactor;

		fontOffsetY = (ELEMENT_H() - fontHeight) / 2; // Precalculate offsets
		fontSmallOffsetY = (ELEMENT_H() - fontSmallHeight) / 2;
		arrowOffsetY = (ELEMENT_H() - ARROW_H()) / 2;
		arrowOffsetX = arrowOffsetY;
		titleOffsetX = (arrowOffsetX * 2 + ARROW_W()) / SCALE;
		buttonOffsetY = (ELEMENT_H() - BUTTON_H()) / 2;
		checkOffsetY = (ELEMENT_H() - CHECK_H()) / 2;
		checkOffsetX = checkOffsetY;
		checkSelectOffsetY = (CHECK_H() - CHECK_SELECT_H()) / 2;
		checkSelectOffsetX = checkSelectOffsetY;
		radioOffsetY = (ELEMENT_H() - RADIO_H()) / 2;
		radioOffsetX = radioOffsetY;
		radioSelectOffsetY = (RADIO_H() - RADIO_SELECT_H()) / 2;
		radioSelectOffsetX = radioSelectOffsetY;
		scrollAlign = 0;//(SCROLL_W() - SCROLL_BAR_W()) / 2;

		if (autoNotifyMouseEvents){
			kha.input.Mouse.get().notifyWindowed(khaWindowId, onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
		}
		
		if (firstInstance) {
			firstInstance = false;
			prerenderElements();
			kha.input.Keyboard.get().notify(onKeyDown, onKeyUp);
		}
	}

	static var checkSelectImage:kha.Image = null;
	function prerenderElements() { // Not yet used
		checkSelectImage = kha.Image.createRenderTarget(Std.int(CHECK_SELECT_W()), Std.int(CHECK_SELECT_H()), null, NoDepthAndStencil, 1, khaWindowId);
		var g = checkSelectImage.g2;
		g.begin(true, 0x00000000);
		g.color = CHECK_SELECT_COL;
		g.drawLine(0, 0, CHECK_SELECT_W(), CHECK_SELECT_H(), LINE_STRENGTH());
		g.drawLine(CHECK_SELECT_W(), 0, 0, CHECK_SELECT_H(), LINE_STRENGTH());
		g.end();
	}

	public function remove() { // Clean up
		kha.input.Mouse.get().removeWindowed(khaWindowId, onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
		kha.input.Keyboard.get().remove(onKeyDown, onKeyUp);
	}

	public function begin(g:kha.graphics2.Graphics) { // Begin UI drawing
		SCALE = scaleFactor;
		globalG = g;
		_x = 0; // Reset cursor
		_y = 0;
		_w = 0;
		_h = 0;
	}

	public function end() { // End drawing
		if (!windowEnded) { endWindow(); }

		isKeyDown = false; // Reset input - only one char for now
		inputStarted = false;
		inputReleased = false;
		inputDX = 0;
		inputDY = 0;
		inputWheelDelta = 0;
	}

	// Returns true if redraw is needed
	public function window(id:String, x:Int, y:Int, w:Int, h:Int, layout = LAYOUT_VERTICAL):Bool {
		layout == LAYOUT_VERTICAL ? w = Std.int(w * scaleFactor) : h = Std.int(h * scaleFactor);
		
		var state = windowStates.get(id);
		if (state == null) {
			state = new WindowState(layout, w, h, khaWindowId); windowStates.set(id, state);
		}

		if (!windowEnded) { endWindow(); } // End previous window if necessary
		windowEnded = false;

		g = state.texture.g2; // Set g

		if (getInputInRect(x, y, w, h)) { // Redraw
			state.redraws = 2;
		}

		curWindowState = state;
		_windowX = x;
		_windowY = y;
		_windowW = w;
		_windowH = h;
		_x = 0;//x;
		_y = state.scrollOffset;//y + state.scrollOffset;
		if (layout == LAYOUT_HORIZONTAL) w = Std.int(ELEMENT_W());
		_w = !state.scrollEnabled ? w : w - SCROLL_W(); // Exclude scrollbar if present
		_h = h;

		if (state.redraws == 0 && !isScrolling && !isTyping) return false;

		g.begin(true, 0x00000000);
		g.color = WINDOW_BG_COL;
		g.fillRect(_x, _y - state.scrollOffset, state.lastMaxX, state.lastMaxY);

		return true;
	}

	public function redrawWindow(id:String) {
		var state = windowStates.get(id);
		if (state != null) state.redraws = 1;
	}

	function endWindow() {
		var state = curWindowState;
		if (state.redraws > 0 || isScrolling || isTyping) {
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
				if (barH < ELEMENT_H() * 2) barH = ELEMENT_H();
				var barY = (_windowH - barH) * ratio;

				if ((inputStarted) && // Start scrolling
					getInputInRect(_windowX + _windowW - SCROLL_BAR_W(), barY, SCROLL_BAR_W(), barH)) {

					state.scrolling = true;
					isScrolling = true;
				}
				if (state.scrolling) { // Scroll
					scroll(inputDY / SCALE, fullHeight);
				}
				else if (inputWheelDelta != 0) { // Wheel
					scroll(-inputWheelDelta * 3, fullHeight);
				}
				g.color = SCROLL_BG_COL; // Bg
				g.fillRect(_windowW - SCROLL_W(), _windowY, SCROLL_W(), _windowH);
				g.color = SCROLL_COL; // Bar
				g.fillRect(_windowW - SCROLL_BAR_W() - scrollAlign, barY, SCROLL_BAR_W(), barH);
			}

			state.lastMaxX = _x;
			state.lastMaxY = _y;
			if (state.layout == LAYOUT_VERTICAL) state.lastMaxX += _windowW;
			else state.lastMaxY += _windowH;
			state.redraws--;

			g.end();
		}

		windowEnded = true;

		// Draw window texture
		globalG.begin(false);
		globalG.color = WINDOW_TINT_COL;
		globalG.drawImage(state.texture, _windowX, _windowY);
		globalG.end();
	}

	function scroll(delta:Float, fullHeight:Float) {
		var state = curWindowState;
		state.scrollOffset -= delta * SCALE;
		// Stay in bounds
		if (state.scrollOffset > 0) state.scrollOffset = 0;
		else if (fullHeight + state.scrollOffset < _windowH) {
			state.scrollOffset = _windowH - fullHeight;
		}
	}

	public function node(id:String, text:String, accent = 0, expanded = false):Bool {
		var state = nodeStates.get(id);
		if (state == null) { state = new NodeState(expanded); nodeStates.set(id, state); }

		if (getReleased()) {
			state.expanded = !state.expanded;
		}

		var hover = getHover();

		if (accent > 0) { // Bg
			g.color = accent == 1 ? NODE_BG1_COL : NODE_BG2_COL;
			g.fillRect(_x, _y, _w, ELEMENT_H());
		}

		drawArrow(state.expanded, hover);

		g.color = hover ? NODE_TEXT_COL_HOVER : NODE_TEXT_COL; // Title
		g.opacity = 1.0;
		accent > 0 ? drawString(g, text, titleOffsetX, 0) : drawStringSmall(g, text, titleOffsetX, 0);

		endElement();

		return state.expanded;
	}
	
	public function image(image:kha.Image) {
		var w = _w - buttonOffsetY * 2;
		var ratio = w / image.width;
		var h = image.height * ratio;
		g.drawScaledImage(image, _x + buttonOffsetY, _y, w, h);
		_y += h;
		endElement(false);
	}

	public function text(text:String, align = ALIGN_LEFT, bg:Int = 0x00000000) {
		if (bg != 0x0000000) {
			g.color = bg;
			g.fillRect(_x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());
		}
		g.color = DEFAULT_TEXT_COL;
		drawStringSmall(g, text, DEFAULT_TEXT_OFFSET_X(), 0, align);

		endElement();
	}

	public function textInput(id:String, text:String, label:String = ""):String {
		if (submitTextId == id) { // Submit edited text
			//text = textSelectedCurrentText;
			text = textToSubmit;
			textToSubmit = "";
			submitTextId = "";
			textSelectedCurrentText = "";
		}

		var hover = getHover();
		g.color = hover ? TEXT_INPUT_BG_COL_HOVER : TEXT_INPUT_BG_COL; // Text bg
		drawRect(g, FILL_TEXT_INPUT_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H(), 2);

		if (textSelectedId != id && getReleased()) { // Passive
			isTyping = true;
			submitTextId = textSelectedId;
			textToSubmit = textSelectedCurrentText;
			textSelectedId = id;
			textSelectedCurrentText = text;
			cursorX = text.length;
			cursorY = 0;
			updateCursorPixelX(text, font, fontSmallSize);

			if (kha.input.Keyboard.get() != null) {
				kha.input.Keyboard.get().show();
			}
		}

		if (textSelectedId == id) { // Active
			var text = textSelectedCurrentText;
			if (isKeyDown) { // Process input
				if (key == kha.Key.LEFT) { // Move cursor
					if (cursorX > 0) {
						cursorX--;
						updateCursorPixelX(text, font, fontSmallSize);
					}
				}
				else if (key == kha.Key.RIGHT) {
					if (cursorX < text.length) {
						cursorX++;
						updateCursorPixelX(text, font, fontSmallSize);
					}
				}
				else if (key == kha.Key.BACKSPACE) { // Remove char
					if (cursorX > 0) {
						text = text.substr(0, cursorX - 1) + text.substr(cursorX);
						cursorX--;
						updateCursorPixelX(text, font, fontSmallSize);
					}
				}
				else if (key == kha.Key.ENTER) { // Deselect
					deselectText(); // One-line text for now
				}
				else if (key == kha.Key.CHAR) {
					text = text.substr(0, cursorX) + char + text.substr(cursorX);
					cursorX++;
					updateCursorPixelX(text, font, fontSmallSize);
				}
			}

			var time = kha.System.time;
			//Flash cursor
			if(time % (TEXT_CURSOR_FLASH_SPEED * 2.0) < TEXT_CURSOR_FLASH_SPEED){
				g.color = TEXT_CURSOR_COL; // Cursor
				var cursorHeight = ELEMENT_H() - buttonOffsetY * 3.0;
				var lineHeight = ELEMENT_H();
				g.fillRect(_x + cursorPixelX, _y + cursorY * lineHeight + buttonOffsetY * 1.5, 1 * SCALE, cursorHeight);
			}
			
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
		textToSubmit = textSelectedCurrentText;
		textSelectedId = "";
		isTyping = false;
		for (w in windowStates) w.redraws = 2;

		if (kha.input.Keyboard.get() != null) {
			kha.input.Keyboard.get().hide();
		}
	}

	public function button(text:String):Bool {
		var wasPressed = getReleased();
		var pushed = getPushed();
		var hover = getHover();

		g.color = pushed ? BUTTON_BG_COL_PRESSED :
				  hover ? BUTTON_BG_COL_HOVER :
				  BUTTON_BG_COL;

		drawRect(g, FILL_BUTTON_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());

		g.color = BUTTON_TEXT_COL;
		drawStringSmall(g, text, 0, 0, ALIGN_CENTER);

		endElement();

		return wasPressed;
	}

	public function check(id:String, text:String, initState:Bool = false):Bool {
		var state = checkStates.get(id);
		if (state == null) { state = new CheckState(initState); checkStates.set(id, state); }

		if (getReleased()) {
			state.selected = !state.selected;
		}

		var hover = getHover();
		drawCheck(state.selected, hover); // Check

		g.color = hover ? DEFAULT_TEXT_COL_HOVER : DEFAULT_TEXT_COL; // Text
		drawStringSmall(g, text, titleOffsetX, 0);

		endElement();

		return state.selected;
	}

	public function radio(groupId:String, pos:Int, text:String, initState:Int = 0):Bool {
		var state = radioStates.get(groupId);
		if (state == null) {
			state = new RadioState(initState); radioStates.set(groupId, state);
		}

		if (getReleased()) {
			state.selected = pos;
		}

		var hover = getHover();
		drawRadio(state.selected == pos, hover); // Radio

		g.color = hover ? DEFAULT_TEXT_COL_HOVER : DEFAULT_TEXT_COL; // Text
		drawStringSmall(g, text, titleOffsetX, 0);

		endElement();

		return state.selected == pos;
	}

	public function setRadioSelection(groupId:String, pos:Int) {
		var state = radioStates.get(groupId);
		if (state != null) state.selected = pos;
	}
	
	public function slider(id:String, text:String, from:Float, to:Float, filled:Bool = false, precision = 100, initValue:Float = 0):Float {
		var state = sliderStates.get(id);
		if (state == null) { state = new SliderState(initValue); sliderStates.set(id, state); }

		if (getStarted()) {
			state.scrolling = true;
			isScrolling = true;
		}
		if (state.scrolling) { // Scroll
			var range = to - from;
			var sliderX = _x + _windowX + buttonOffsetY;
			var sliderW = _w - buttonOffsetY * 2;
			var step = range / sliderW;
			var value = (inputX - sliderX) * step;
			state.value = Std.int(value * precision) / precision;
			if (state.value < from) state.value = from; // Stay in bounds
			else if (state.value > to) state.value = to;
		}
		
		var hover = getHover();
		drawSlider(state.value, from, to, filled, hover); // Slider

		g.color = DEFAULT_LABEL_COL;// Text
		drawStringSmall(g, text, 0, 0, ALIGN_RIGHT);

		g.color = DEFAULT_TEXT_COL; // Value
		drawStringSmall(g, state.value + "");

		endElement();
		return state.value;
	}
	
	// public function colorPicker(id:String, initColor:Int = 0xffffffff):Int {
	// 	var state = colorPickerStates.get(id);
	// 	if (state == null) { state = new ColorPickerState(initColor); colorPickerStates.set(id, state); }

	// 	var w = _w - buttonOffsetY * 2;
	// 	g.drawScaledImage(checkSelectImage, _x + buttonOffsetY, _y, w, w);

	// 	_y += w;
	// 	endElement(false);
	// 	return state.value;
	// }
	
	public function separator() {
		g.color = SEPARATOR_COL;
		g.fillRect(_x, _y, _w - DEFAULT_TEXT_OFFSET_X(), LINE_STRENGTH());
		_y += 2;
	}

	function drawArrow(expanded:Bool, hover:Bool) {
		var x = _x + arrowOffsetX;
		var y = _y + arrowOffsetY;
		g.color = hover ? ARROW_COL_HOVER : ARROW_COL;
		if (expanded) {
			g.fillTriangle(x, y,
						   x + ARROW_W(), y,
						   x + ARROW_W() / 2, y + ARROW_H());
		}
		else {
			g.fillTriangle(x, y,
						   x, y + ARROW_H(),
						   x + ARROW_W(), y + ARROW_H() / 2);
		}
	}

	function drawCheck(selected:Bool, hover:Bool) {
		var x = _x + checkOffsetX;
		var y = _y + checkOffsetY;

		g.color = hover ? CHECK_COL_HOVER : CHECK_COL;
		drawRect(g, FILL_CHECK_BG, x, y, CHECK_W(), CHECK_H(), 2); // Bg

		if (selected) { // Check
			//g.color = CHECK_SELECT_COL;
			//g.fillRect(x + checkSelectOffsetX, y + checkSelectOffsetY, CHECK_SELECT_W(), CHECK_SELECT_H());
			g.color = kha.Color.White;
			g.drawImage(checkSelectImage, x + checkSelectOffsetX, y + checkSelectOffsetY);
		}
	}

	function drawRadio(selected:Bool, hover:Bool) {
		var x = _x + radioOffsetX;
		var y = _y + radioOffsetY;
		g.color = hover ? RADIO_COL_HOVER : RADIO_COL;
		drawRect(g, FILL_RADIO_BG, x, y, RADIO_W(), RADIO_H()); // Bg

		if (selected) { // Check
			g.color = RADIO_SELECT_COL;
			g.fillRect(x + radioSelectOffsetX, y + radioSelectOffsetY, RADIO_SELECT_W(), RADIO_SELECT_H());
		}
	}
	
	function drawSlider(value:Float, from:Float, to:Float, filled:Bool, hover:Bool) {
		var x = _x + buttonOffsetY;
		var y = _y + buttonOffsetY;
		var w = _w - buttonOffsetY * 2;

		g.color = hover ? CHECK_COL_HOVER : CHECK_COL;
		drawRect(g, FILL_CHECK_BG, x, y, w, BUTTON_H(), 2); // Bg
		
		var offset = ((to - from) / to) * (value / (to - from));
		var barW = 8 * SCALE; // Unfilled bar
		var sliderX = filled ? x : x + (w - barW) * offset;
		var sliderW = filled ? w * offset : barW; 
		g.fillRect(sliderX, y, sliderW, BUTTON_H());
	}

	function drawString(g:kha.graphics2.Graphics, text:String,
						xOffset:Float = _DEFAULT_TEXT_OFFSET_X, yOffset:Float = 0,
						align = ALIGN_LEFT) {
		xOffset *= SCALE;
		g.font = font;
		g.fontSize = fontSize;
		if (align == ALIGN_CENTER) xOffset = _w / 2 - font.width(fontSize, text) / 2;
		else if (align == ALIGN_RIGHT) xOffset = _w - font.width(fontSize, text) - DEFAULT_TEXT_OFFSET_X();

		g.drawString(text, _x + xOffset, _y + fontOffsetY + yOffset);
	}

	function drawStringSmall(g:kha.graphics2.Graphics, text:String,
							 xOffset:Float = _DEFAULT_TEXT_OFFSET_X, yOffset:Float = 0,
							 align = ALIGN_LEFT) {
		xOffset *= SCALE;
		g.font = font;
		g.fontSize = fontSmallSize;
		if (align == ALIGN_CENTER) xOffset = _w / 2 - font.width(fontSmallSize, text) / 2;
		else if (align == ALIGN_RIGHT) xOffset = _w - font.width(fontSmallSize, text) - DEFAULT_TEXT_OFFSET_X();

		g.drawString(text, _x + xOffset, _y + fontSmallOffsetY + yOffset);
	}

	function endElement(nextLine = true) {
		if (curWindowState.layout == LAYOUT_VERTICAL) {
			if (curRatio == -1 || (ratios != null && curRatio == ratios.length - 1)) { // New line
				if (nextLine) _y += ELEMENT_H() + ELEMENT_SEPARATOR_SIZE();

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
			_x += _w + ELEMENT_SEPARATOR_SIZE();
		}
	}

	public function row(ratios:Array<Float>) {
		this.ratios = ratios;
		curRatio = 0;
		xBeforeSplit = _x;
		wBeforeSplit = _w;
		_w = Std.int(_w * ratios[curRatio]);
	}
	
	public function indent() {
		_x += TAB_W();
		_w -= TAB_W();
	}
	public function unindent() {
		_x -= TAB_W();
		_w += TAB_W();
	}
	
	inline function drawRect(g:kha.graphics2.Graphics, fill: Bool, x: Float, y: Float, w: Float, h: Float, strength: Float = 1.0) {
		fill ? g.fillRect(x, y, w, h) : g.drawRect(x, y, w, h, LINE_STRENGTH());
	}

	function getReleased():Bool { // Input selection
		return inputReleased && getHover() && getInitialHover();
	}

	function getPushed():Bool {
		return inputDown && getHover() && getInitialHover();
	}
	
	function getStarted():Bool {
		return inputStarted && getHover();
	}

	function getInitialHover():Bool {
		return
			inputInitialX >= _windowX + _x && inputInitialX < (_windowX + _x + _w) &&
        	inputInitialY >= _windowY + _y && inputInitialY < (_windowY + _y + ELEMENT_H());
	}

	function getHover():Bool {
		return
			inputX >= _windowX + _x && inputX < (_windowX + _x + _w) &&
        	inputY >= _windowY + _y && inputY < (_windowY + _y + ELEMENT_H());
	}

	function getInputInRect(x:Float, y:Float, w:Float, h:Float):Bool {
		return
			inputX >= x && inputX < x + w &&
			inputY >= y && inputY < y + h;
	}

	function updateCursorPixelX(text:String, font:kha.Font, fontSize:Int) { // Set cursor to current char
		var str = text.substr(0, cursorX);
		cursorPixelX = font.width(fontSize, str) + DEFAULT_TEXT_OFFSET_X();
	}

    public function onMouseDown(button:Int, x:Int, y:Int) { // Input events
    	inputStarted = true;
    	inputDown = true;
		
    	setInitialInputPosition(x, y);
    }

    public function onMouseUp(button:Int, x:Int, y:Int) {
    	if (isScrolling) {
    		isScrolling = false;
    		for (s in windowStates) s.scrolling = false;
    		for (s in sliderStates) s.scrolling = false;
    	}
    	else { // To prevent action when scrolling is active
    		inputReleased = true;
    	}
    	inputDown = false;
    	setInputPosition(x, y);
    	deselectText();
    }

    public function onMouseMove(x:Int, y:Int, movementX:Int, movementY:Int) {
    	setInputPosition(x, y);
    }

    public function onMouseWheel(delta:Int) {
    	inputWheelDelta = delta;
    }
	
	function setInitialInputPosition(inputX:Int, inputY:Int) {
		setInputPosition(inputX, inputY);
		
		this.inputInitialX = inputX;
		this.inputInitialY = inputY;
	}

    function setInputPosition(inputX:Int, inputY:Int) {
		inputDX += inputX - this.inputX;
		inputDY += inputY - this.inputY;
		this.inputX = inputX;
		this.inputY = inputY;
	}

	function onKeyDown(key:kha.Key, char:String) {
        isKeyDown = true;
        this.key = key;
        this.char = char;
    }

    function onKeyUp(key:kha.Key, char:String) {
    }
	
	static inline function ELEMENT_W() { return _ELEMENT_W * SCALE; }
	static inline function ELEMENT_H() { return _ELEMENT_H * SCALE; }
	static inline function ELEMENT_SEPARATOR_SIZE() { return _ELEMENT_SEPARATOR_SIZE * SCALE; }
	static inline function ARROW_W() { return _ARROW_W * SCALE; }
	static inline function ARROW_H() { return _ARROW_H * SCALE; }
	static inline function BUTTON_H() { return _BUTTON_H * SCALE; }
	static inline function CHECK_W() { return _CHECK_W * SCALE; }
	static inline function CHECK_H() { return _CHECK_H * SCALE; }
	static inline function CHECK_SELECT_W() { return _CHECK_SELECT_W * SCALE; }
	static inline function CHECK_SELECT_H() { return _CHECK_SELECT_H * SCALE; }
	static inline function RADIO_W() { return _RADIO_W * SCALE; }
	static inline function RADIO_H() { return _RADIO_H * SCALE; }
	static inline function RADIO_SELECT_W() { return _RADIO_SELECT_W * SCALE; }
	static inline function RADIO_SELECT_H() { return _RADIO_SELECT_H * SCALE; }
	static inline function SCROLL_W() { return Std.int(_SCROLL_W * SCALE); }
	static inline function SCROLL_BAR_W() { return _SCROLL_BAR_W * SCALE; }
	static inline function DEFAULT_TEXT_OFFSET_X() { return _DEFAULT_TEXT_OFFSET_X * SCALE; }
	static inline function TAB_W() { return Std.int(_TAB_W * SCALE); }
	static inline function LINE_STRENGTH() { return _LINE_STRENGTH * SCALE; }
}

class WindowState { // Cached states
	public var texture:kha.Image;
	public var redraws = 2;
	public var scrolling:Bool = false;
	public var scrollOffset:Float = 0;
	public var scrollEnabled:Bool = false;
	public var layout:Int;
	public var lastMaxX:Float = 0;
	public var lastMaxY:Float = 0;
	public function new(layout:Int, w:Int, h:Int, windowId:Int) { this.layout = layout; texture = kha.Image.createRenderTarget(w, h, kha.graphics4.TextureFormat.RGBA32, kha.graphics4.DepthStencilFormat.NoDepthAndStencil, 1, windowId); }
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
class SliderState {
	public var value:Float = 0;
	public var scrolling:Bool = false;
	public function new(value:Float) { this.value = value; }
}
// class ColorPickerState {
// 	public var value:Int = 0;
// 	public function new(value:Int) { this.value = value; }
// }
