package zui;

// Immediate Mode UI Library
// https://github.com/armory3d/zui

@:structInit
typedef ZuiOptions = {
	font: kha.Font,
	?theme: zui.Themes.TTheme,
	?khaWindowId: Int,
	?scaleFactor: Float,
	?scaleTexture: Float,
	?autoNotifyInput: Bool
}

@:allow(zui.Nodes)
class Zui {
	static var t:zui.Themes.TTheme;
	static var SCALE: Float;

	public static var isScrolling = false; // Use to limit other activities
	public static var isTyping = false;

	static var firstInstance = true;
	static var elementsBaked = false;

	var inputX: Float; // Input position
	var inputY: Float;
	var inputInitialX: Float;
	var inputInitialY: Float;
	var inputDX: Float; // Delta
	var inputDY: Float;
	var inputWheelDelta: Int;
	var inputStarted: Bool; // Buttons
	var inputReleased: Bool;
	var inputDown: Bool;
	var isKeyDown = false; // Keys
	var key: kha.Key;
	var char: String;

	var cursorX = 0; // Text input
	var cursorY = 0;
	var cursorPixelX = 0.0;

	var ratios: Array<Float>; // Splitting rows
	var curRatio = -1;
	var xBeforeSplit: Float;
	var wBeforeSplit: Int;

	var globalG: kha.graphics2.Graphics; // Drawing
	var g: kha.graphics2.Graphics;

	var ops: ZuiOptions;
	var fontSize: Int;
	var fontSmallSize: Int;

	var fontOffsetY: Float; // Precalculated offsets
	var fontSmallOffsetY: Float;
	var arrowOffsetX: Float;
	var arrowOffsetY: Float;
	var titleOffsetX: Float;
	var buttonOffsetY: Float;
	var checkOffsetX: Float;
	var checkOffsetY: Float;
	var checkSelectOffsetX: Float;
	var checkSelectOffsetY: Float;
	var radioOffsetX: Float;
	var radioOffsetY: Float;
	var radioSelectOffsetX: Float;
	var radioSelectOffsetY: Float;
	var scrollAlign: Float;

	var _x: Float; // Cursor(stack) position
	var _y: Float;
	var _w: Int;
	var _h: Int;

	var _windowX: Float; // Window state
	var _windowY: Float;
	var _windowW: Float;
	var _windowH: Float;
	var currentWindow: Handle;
	var windowEnded = true;
	var scrollingHandle: Handle = null; // Window or slider being scrolled

	var textSelectedHandle: Handle = null;
	var textSelectedCurrentText: String;
	var submitTextHandle: Handle = null;
	var textToSubmit = "";

	public function new(ops: ZuiOptions) {
		if (ops.theme == null) ops.theme = Themes.dark;
		t = ops.theme;
		if (ops.khaWindowId == null) ops.khaWindowId = 0;
		if (ops.scaleFactor == null) ops.scaleFactor = 1.0;
		if (ops.scaleTexture == null) ops.scaleTexture = 1.0;
		if (ops.autoNotifyInput == null) ops.autoNotifyInput = true;
		this.ops = ops;
		setScaleFactor(ops.scaleFactor);

		if (ops.autoNotifyInput && firstInstance) {
			kha.input.Mouse.get().notifyWindowed(ops.khaWindowId, onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
			kha.input.Keyboard.get().notify(onKeyDown, onKeyUp);
		}
		firstInstance = false;
	}
	
	public function setScaleFactor(scaleFactor: Float) {
		SCALE = ops.scaleFactor = scaleFactor * ops.scaleTexture;
		fontSize = Std.int(t._FONT_SIZE * ops.scaleFactor);
		fontSmallSize = Std.int(t._FONT_SMALL_SIZE * ops.scaleFactor);
		var fontHeight = ops.font.height(fontSize);
		var fontSmallHeight = ops.font.height(fontSmallSize);

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
		scrollAlign = 0;
	}

	static var checkSelectImage: kha.Image = null;
	function bakeElements() {
		elementsBaked = true;
		checkSelectImage = kha.Image.createRenderTarget(Std.int(CHECK_SELECT_W()), Std.int(CHECK_SELECT_H()), null, NoDepthAndStencil, 1, ops.khaWindowId);
		var g = checkSelectImage.g2;
		g.begin(true, 0x00000000);
		g.color = t.CHECK_SELECT_COL;
		g.drawLine(0, 0, CHECK_SELECT_W(), CHECK_SELECT_H(), LINE_STRENGTH());
		g.drawLine(CHECK_SELECT_W(), 0, 0, CHECK_SELECT_H(), LINE_STRENGTH());
		g.end();
	}

	public function remove() { // Clean up
		if (ops.autoNotifyInput) {
			kha.input.Mouse.get().removeWindowed(ops.khaWindowId, onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
			kha.input.Keyboard.get().remove(onKeyDown, onKeyUp);
		}
	}

	public function begin(g: kha.graphics2.Graphics) { // Begin UI drawing
		if (!elementsBaked) bakeElements();
		SCALE = ops.scaleFactor;
		globalG = g;
		_x = 0; // Reset cursor
		_y = 0;
		_w = 0;
		_h = 0;
	}

	public function end() { // End drawing
		if (!windowEnded) endWindow();
		isKeyDown = false; // Reset input - only one char for now
		inputStarted = false;
		inputReleased = false;
		inputDX = 0;
		inputDY = 0;
		inputWheelDelta = 0;
	}

	// Returns true if redraw is needed
	public function window(handle: Handle, x: Int, y: Int, w: Int, h: Int, drag = false): Bool {
		w = Std.int(w);// * ops.scaleFactor);
		h = Std.int(h);// * ops.scaleFactor);

		if (handle.texture == null || w != handle.texture.width || h != handle.texture.height) {
			resize(handle, w, h, ops.khaWindowId);
		}

		if (!windowEnded) endWindow(); // End previous window if necessary
		windowEnded = false;

		g = handle.texture.g2; // Set g
		currentWindow = handle;
		_windowX = x + handle.dragX;
		_windowY = y + handle.dragY;
		_windowW = w;
		_windowH = h;

		if (getInputInRect(_windowX, _windowY, _windowW, _windowH)) handle.redraws = 2; // Redraw

		_x = 0;
		_y = handle.scrollOffset;
		if (handle.layout == Horizontal) w = Std.int(ELEMENT_W());
		_w = !handle.scrollEnabled ? w : w - SCROLL_W(); // Exclude scrollbar if present
		_h = h;

		if (handle.redraws == 0 && !isScrolling && !isTyping) return false;

		g.begin(true, 0x00000000);
		g.color = t.WINDOW_BG_COL;
		g.fillRect(_x, _y - handle.scrollOffset, handle.lastMaxX, handle.lastMaxY);

		handle.dragEnabled = drag;
		if (drag) {
			if (inputStarted && getInputInRect(_windowX, _windowY, _windowW, 15)) {
				handle.dragging = true;
			}
			else if (inputReleased) {
				handle.dragging = false;
			}
			if (handle.dragging) {
				handle.redraws = 2;
				handle.dragX += Std.int(inputDX);
				handle.dragY += Std.int(inputDY);
			}
			_y += 15; // Header offset 
		}

		return true;
	}

	function endWindow() {
		var handle = currentWindow;
		if (handle.redraws > 0 || isScrolling || isTyping) {

			if (handle.dragEnabled) { // Draggable header
				g.color = t.SEPARATOR_COL;
				g.fillRect(0, 0, _windowW, 15);
			}

			var fullHeight = _y - handle.scrollOffset;
			if (fullHeight < _windowH || handle.layout == Horizontal) { // Disable scrollbar
				handle.scrollEnabled = false;
				handle.scrollOffset = 0;
			}
			else { // Draw window scrollbar if necessary
				handle.scrollEnabled = true;
				var amountToScroll = fullHeight - _windowH;
				var amountScrolled = -handle.scrollOffset;
				var ratio = amountScrolled / amountToScroll;
				var barH = _windowH * Math.abs(_windowH / fullHeight);
				barH = Math.max(barH, ELEMENT_H());
				
				var totalScrollableArea = _windowH - barH;
				var e = amountToScroll / totalScrollableArea;
				var barY = totalScrollableArea * ratio;

				if ((inputStarted) && // Start scrolling
					getInputInRect(_windowX + _windowW - SCROLL_BAR_W(), barY + _windowY, SCROLL_BAR_W(), barH)) {

					handle.scrolling = true;
					scrollingHandle = handle;
					isScrolling = true;
				}
				
				if (handle.scrolling) { // Scroll
					scroll(inputDY * e, fullHeight);
				}
				else if (inputWheelDelta != 0) { // Wheel
					scroll(inputWheelDelta * ELEMENT_H(), fullHeight);
				}
				
				//Stay in bounds
				if (handle.scrollOffset > 0) {
					handle.scrollOffset = 0;
				}
				else if (fullHeight + handle.scrollOffset < _windowH) {
					handle.scrollOffset = _windowH - fullHeight;
				}
				
				g.color = t.SCROLL_BG_COL; // Bg
				g.fillRect(_windowW - SCROLL_W(), _windowY, SCROLL_W(), _windowH);
				g.color = t.SCROLL_COL; // Bar
				g.fillRect(_windowW - SCROLL_BAR_W() - scrollAlign, barY, SCROLL_BAR_W(), barH);
			}

			handle.lastMaxX = _x;
			handle.lastMaxY = _y;
			if (handle.layout == Vertical) handle.lastMaxX += _windowW;
			else handle.lastMaxY += _windowH;
			handle.redraws--;

			g.end();
		}

		windowEnded = true;

		// Draw window texture
		globalG.begin(false);
		globalG.color = t.WINDOW_TINT_COL;
		// if (scaleTexture != 1.0) globalG.imageScaleQuality = kha.graphics2.ImageScaleQuality.High;
		globalG.drawScaledImage(handle.texture, _windowX, _windowY, handle.texture.width / ops.scaleTexture, handle.texture.height / ops.scaleTexture);
		globalG.end();
	}

	function scroll(delta: Float, fullHeight: Float) {
		currentWindow.scrollOffset -= delta;
	}

	public function panel(handle: Handle, text: String, accent = 0): Bool {
		if (getReleased()) handle.selected = !handle.selected;
		var hover = getHover();

		if (accent > 0) { // Bg
			g.color = accent == 1 ? t.PANEL_BG1_COL : t.PANEL_BG2_COL;
			g.fillRect(_x, _y, _w, ELEMENT_H());
		}

		drawArrow(handle.selected, hover);

		g.color = hover ? t.PANEL_TEXT_COL_HOVER : t.PANEL_TEXT_COL; // Title
		g.opacity = 1.0;
		accent > 0 ? drawString(g, text, titleOffsetX, 0) : drawStringSmall(g, text, titleOffsetX, 0);

		endElement();

		return handle.selected;
	}
	
	public function image(image: kha.Image) {
		var w = _w - buttonOffsetY * 2;
		var ratio = w / image.width;
		var h = image.height * ratio;
		g.color = t.WINDOW_TINT_COL;
		g.drawScaledImage(image, _x + buttonOffsetY, _y, w, h);
		_y += h;
		endElement(false);
	}

	public function text(text: String, align:Align = Left, bg = 0x00000000) {
		if (bg != 0x0000000) {
			g.color = bg;
			g.fillRect(_x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());
		}
		g.color = t.TEXT_COL;
		drawStringSmall(g, text, DEFAULT_TEXT_OFFSET_X(), 0, align);

		endElement();
	}

	public function textInput(handle: Handle, label = ""): String {
		if (submitTextHandle == handle) { // Submit edited text
			handle.text = textToSubmit;
			textToSubmit = "";
			submitTextHandle = null;
			textSelectedCurrentText = "";
		}

		var hover = getHover();
		g.color = hover ? t.TEXT_INPUT_BG_COL_HOVER : t.TEXT_INPUT_BG_COL; // Text bg
		drawRect(g, t.FILL_TEXT_INPUT_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H(), 2);

		if (textSelectedHandle != handle && getReleased()) { // Passive
			isTyping = true;
			submitTextHandle = textSelectedHandle;
			textToSubmit = textSelectedCurrentText;
			textSelectedHandle = handle;
			textSelectedCurrentText = handle.text;
			cursorX = handle.text.length;
			cursorY = 0;
			updateCursorPixelX(handle.text, ops.font, fontSmallSize);

			if (kha.input.Keyboard.get() != null) {
				kha.input.Keyboard.get().show();
			}
		}

		if (textSelectedHandle == handle) { // Active
			var text = textSelectedCurrentText;
			if (isKeyDown) { // Process input
				if (key == kha.Key.LEFT) { // Move cursor
					if (cursorX > 0) {
						cursorX--;
						updateCursorPixelX(text, ops.font, fontSmallSize);
					}
				}
				else if (key == kha.Key.RIGHT) {
					if (cursorX < text.length) {
						cursorX++;
						updateCursorPixelX(text, ops.font, fontSmallSize);
					}
				}
				else if (key == kha.Key.BACKSPACE) { // Remove char
					if (cursorX > 0) {
						text = text.substr(0, cursorX - 1) + text.substr(cursorX);
						cursorX--;
						updateCursorPixelX(text, ops.font, fontSmallSize);
					}
				}
				else if (key == kha.Key.ENTER) { // Deselect
					deselectText(); // One-line text for now
				}
				else if (key == kha.Key.CHAR) {
					text = text.substr(0, cursorX) + char + text.substr(cursorX);
					cursorX++;
					updateCursorPixelX(text, ops.font, fontSmallSize);
				}
			}

			// Flash cursor
			var time = kha.Scheduler.time();
			if (time % (t.TEXT_CURSOR_FLASH_SPEED * 2.0) < t.TEXT_CURSOR_FLASH_SPEED) {
				g.color = t.TEXT_CURSOR_COL; // Cursor
				var cursorHeight = ELEMENT_H() - buttonOffsetY * 3.0;
				var lineHeight = ELEMENT_H();
				g.fillRect(_x + cursorPixelX, _y + cursorY * lineHeight + buttonOffsetY * 1.5, 1 * SCALE, cursorHeight);
			}
			
			textSelectedCurrentText = text;
		}

		if (label != "") {
			g.color = t.DEFAULT_LABEL_COL; // Label
			drawStringSmall(g, label, 0, 0, Right);
		}

		g.color = t.TEXT_COL; // Text
		textSelectedHandle != handle ? drawStringSmall(g, handle.text) : drawStringSmall(g, textSelectedCurrentText);

		endElement();

		return handle.text;
	}

	function deselectText() {
		submitTextHandle = textSelectedHandle;
		textToSubmit = textSelectedCurrentText;
		textSelectedHandle = null;
		isTyping = false;
		currentWindow.redraws = 2;

		if (kha.input.Keyboard.get() != null) {
			kha.input.Keyboard.get().hide();
		}
	}

	public function button(text: String): Bool {
		var wasPressed = getReleased();
		var pushed = getPushed();
		var hover = getHover();

		g.color = pushed ? t.BUTTON_BG_COL_PRESSED :
				  hover ? t.BUTTON_BG_COL_HOVER :
				  t.BUTTON_BG_COL;

		drawRect(g, t.FILL_BUTTON_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());

		g.color = t.BUTTON_TEXT_COL;
		drawStringSmall(g, text, 0, 0, Center);

		endElement();

		return wasPressed;
	}

	public function check(handle: Handle, text: String): Bool {
		if (getReleased()) handle.selected = !handle.selected;

		var hover = getHover();
		drawCheck(handle.selected, hover); // Check

		g.color = hover ? t.TEXT_COL_HOVER : t.TEXT_COL; // Text
		drawStringSmall(g, text, titleOffsetX, 0, Left);

		endElement();

		return handle.selected;
	}

	public function radio(handle: Handle, position: Int, text: String): Bool {
		if (getReleased()) handle.position = position;

		var hover = getHover();
		drawRadio(handle.position == position, hover); // Radio

		g.color = hover ? t.TEXT_COL_HOVER : t.TEXT_COL; // Text
		drawStringSmall(g, text, titleOffsetX, 0);

		endElement();

		return handle.position == position;
	}

	public function inlineRadio(handle: Handle, texts: Array<String>): Int {
		if (getReleased()) {
			if (++handle.position >= texts.length) handle.position = 0;
		}

		var hover = getHover();
		drawInlineRadio(texts[handle.position], hover); // Radio

		endElement();
		return handle.position;
	}

	public function slider(handle: Handle, text: String, from = 0.0, to = 1.0, filled = false, precision = 100, displayValue = true): Float {
		if (getStarted()) {
			handle.scrolling = true;
			scrollingHandle = handle;
			isScrolling = true;
		}
		if (handle.scrolling) { // Scroll
			var range = to - from;
			var sliderX = _x + _windowX + buttonOffsetY;
			var sliderW = _w - buttonOffsetY * 2;
			var step = range / sliderW;
			var value = from + (inputX - sliderX) * step;
			handle.value = Std.int(value * precision) / precision;
			if (handle.value < from) handle.value = from; // Stay in bounds
			else if (handle.value > to) handle.value = to;
		}
		
		var hover = getHover();
		drawSlider(handle.value, from, to, filled, hover); // Slider

		g.color = t.DEFAULT_LABEL_COL;// Text
		drawStringSmall(g, text, 0, 0, Right);

		if (displayValue) {
			g.color = t.TEXT_COL; // Value
			drawStringSmall(g, handle.value + "");
		}

		endElement();
		return handle.value;
	}

	public function separator() {
		g.color = t.SEPARATOR_COL;
		g.fillRect(_x, _y, _w - DEFAULT_TEXT_OFFSET_X(), LINE_STRENGTH());
		_y += 2;
	}

	function drawArrow(selected: Bool, hover: Bool) {
		var x = _x + arrowOffsetX;
		var y = _y + arrowOffsetY;
		g.color = hover ? t.ARROW_COL_HOVER : t.ARROW_COL;
		if (selected) {
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

	function drawCheck(selected: Bool, hover: Bool) {
		var x = _x + checkOffsetX;
		var y = _y + checkOffsetY;

		g.color = hover ? t.CHECK_COL_HOVER : t.CHECK_COL;
		drawRect(g, t.FILL_CHECK_BG, x, y, CHECK_W(), CHECK_H(), 2); // Bg

		if (selected) { // Check
			//g.color = t.CHECK_SELECT_COL;
			//g.fillRect(x + checkSelectOffsetX, y + checkSelectOffsetY, CHECK_SELECT_W(), CHECK_SELECT_H());
			g.color = kha.Color.White;
			g.drawImage(checkSelectImage, x + checkSelectOffsetX, y + checkSelectOffsetY);
		}
	}

	function drawRadio(selected: Bool, hover: Bool) {
		var x = _x + radioOffsetX;
		var y = _y + radioOffsetY;
		g.color = hover ? t.RADIO_COL_HOVER : t.RADIO_COL;
		drawRect(g, t.FILL_RADIO_BG, x, y, RADIO_W(), RADIO_H()); // Bg

		if (selected) { // Check
			g.color = t.RADIO_SELECT_COL;
			g.fillRect(x + radioSelectOffsetX, y + radioSelectOffsetY, RADIO_SELECT_W(), RADIO_SELECT_H());
		}
	}

	function drawInlineRadio(text: String, hover: Bool) {
		if (hover) { // Bg
			g.color = t.RADIO_COL_HOVER;
			g.fillRect(_x + 5, _y + 5, _w - 10, ELEMENT_H() - 10);
		}
		var x = _x + arrowOffsetX; // Arrows
		var y = _y + arrowOffsetY;
		g.color = hover ? t.ARROW_COL_HOVER : t.ARROW_COL;
		g.fillTriangle(x, y, x, y + ARROW_H(), x - ARROW_W() / 2, y + ARROW_H() / 2);
		var x = _x + _w - arrowOffsetX - 5;
		g.fillTriangle(x, y, x, y + ARROW_H(), x + ARROW_W() / 2, y + ARROW_H() / 2);

		g.color = hover ? t.TEXT_COL_HOVER : t.TEXT_COL; // Text
		drawStringSmall(g, text, titleOffsetX, 0, Align.Center);
	}
	
	function drawSlider(value: Float, from: Float, to: Float, filled: Bool, hover: Bool) {
		var x = _x + buttonOffsetY;
		var y = _y + buttonOffsetY;
		var w = _w - buttonOffsetY * 2;

		g.color = hover ? t.CHECK_COL_HOVER : t.CHECK_COL;
		drawRect(g, t.FILL_SLIDER_BG, x, y, w, BUTTON_H(), 2); // Bg
		
		g.color = hover ? t.SLIDER_COL_HOVER : t.SLIDER_COL;
		var offset = (value - from) / (to - from);
		var barW = 8 * SCALE; // Unfilled bar
		var sliderX = filled ? x : x + (w - barW) * offset;
		var sliderW = filled ? w * offset : barW; 
		g.fillRect(sliderX, y, sliderW, BUTTON_H());
	}

	function drawString(g: kha.graphics2.Graphics, text: String,
						xOffset: Null<Float> = null, yOffset: Float = 0,
						align:Align = Left) {
		if (xOffset == null) xOffset = t._DEFAULT_TEXT_OFFSET_X;
		xOffset *= SCALE;
		g.font = ops.font;
		g.fontSize = fontSize;
		if (align == Center) xOffset = _w / 2 - ops.font.width(fontSize, text) / 2;
		else if (align == Right) xOffset = _w - ops.font.width(fontSize, text) - DEFAULT_TEXT_OFFSET_X();

		g.drawString(text, _x + xOffset, _y + fontOffsetY + yOffset);
	}

	function drawStringSmall(g: kha.graphics2.Graphics, text: String,
							 xOffset: Null<Float> = null, yOffset: Float = 0,
							 align:Align = Left) {
		if (xOffset == null) xOffset = t._DEFAULT_TEXT_OFFSET_X;
		xOffset *= SCALE;
		g.font = ops.font;
		g.fontSize = fontSmallSize;
		if (align == Center) xOffset = _w / 2 - ops.font.width(fontSmallSize, text) / 2;
		else if (align == Right) xOffset = _w - ops.font.width(fontSmallSize, text) - DEFAULT_TEXT_OFFSET_X();

		g.drawString(text, _x + xOffset, _y + fontSmallOffsetY + yOffset);
	}

	function endElement(nextLine = true) {
		if (currentWindow.layout == Vertical) {
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

	public function row(ratios: Array<Float>) {
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
	
	inline function drawRect(g: kha.graphics2.Graphics, fill: Bool, x: Float, y: Float, w: Float, h: Float, strength = 1.0) {
		fill ? g.fillRect(x, y, w, h) : g.drawRect(x, y, w, h, LINE_STRENGTH());
	}

	function getReleased(): Bool { // Input selection
		return inputReleased && getHover() && getInitialHover();
	}

	function getPushed(): Bool {
		return inputDown && getHover() && getInitialHover();
	}
	
	function getStarted(): Bool {
		return inputStarted && getHover();
	}

	function getInitialHover(): Bool {
		return
			inputInitialX >= _windowX + _x && inputInitialX < (_windowX + _x + _w) &&
        	inputInitialY >= _windowY + _y && inputInitialY < (_windowY + _y + ELEMENT_H());
	}

	function getHover(): Bool {
		return
			inputX >= _windowX + _x && inputX < (_windowX + _x + _w) &&
        	inputY >= _windowY + _y && inputY < (_windowY + _y + ELEMENT_H());
	}

	function getInputInRect(x: Float, y: Float, w: Float, h: Float): Bool {
		return
			inputX >= x && inputX < x + w &&
			inputY >= y && inputY < y + h;
	}

	function updateCursorPixelX(text: String, font: kha.Font, fontSize: Int) { // Set cursor to current char
		var str = text.substr(0, cursorX);
		cursorPixelX = ops.font.width(fontSize, str) + DEFAULT_TEXT_OFFSET_X();
	}

    public function onMouseDown(button: Int, x: Int, y: Int) { // Input events
    	inputStarted = true;
    	inputDown = true;
    	setInitialInputPosition(Std.int(x * ops.scaleTexture), Std.int(y * ops.scaleTexture));
    }

    public function onMouseUp(button: Int, x: Int, y: Int) {
    	if (isScrolling) {
    		isScrolling = false;
    		if (scrollingHandle != null) scrollingHandle.scrolling = false;
    	}
    	else { // To prevent action when scrolling is active
    		inputReleased = true;
    	}
    	inputDown = false;
    	setInputPosition(Std.int(x * ops.scaleTexture), Std.int(y * ops.scaleTexture));
    	deselectText();
    }

    public function onMouseMove(x: Int, y: Int, movementX: Int, movementY: Int) {
    	setInputPosition(Std.int(x * ops.scaleTexture), Std.int(y * ops.scaleTexture));
    }

    public function onMouseWheel(delta: Int) {
    	inputWheelDelta = delta;
    }
	
	function setInitialInputPosition(inputX: Int, inputY: Int) {
		setInputPosition(inputX, inputY);
		this.inputInitialX = inputX;
		this.inputInitialY = inputY;
	}

    function setInputPosition(inputX: Int, inputY: Int) {
		inputDX += inputX - this.inputX;
		inputDY += inputY - this.inputY;
		this.inputX = inputX;
		this.inputY = inputY;
	}

	function onKeyDown(key: kha.Key, char: String) {
        isKeyDown = true;
        this.key = key;
        this.char = char;
    }

    function onKeyUp(key: kha.Key, char: String) {
    }
	
	static inline function ELEMENT_W() { return t._ELEMENT_W * SCALE; }
	static inline function ELEMENT_H() { return t._ELEMENT_H * SCALE; }
	static inline function ELEMENT_SEPARATOR_SIZE() { return t._ELEMENT_SEPARATOR_SIZE * SCALE; }
	static inline function ARROW_W() { return t._ARROW_W * SCALE; }
	static inline function ARROW_H() { return t._ARROW_H * SCALE; }
	static inline function BUTTON_H() { return t._BUTTON_H * SCALE; }
	static inline function CHECK_W() { return t._CHECK_W * SCALE; }
	static inline function CHECK_H() { return t._CHECK_H * SCALE; }
	static inline function CHECK_SELECT_W() { return t._CHECK_SELECT_W * SCALE; }
	static inline function CHECK_SELECT_H() { return t._CHECK_SELECT_H * SCALE; }
	static inline function RADIO_W() { return t._RADIO_W * SCALE; }
	static inline function RADIO_H() { return t._RADIO_H * SCALE; }
	static inline function RADIO_SELECT_W() { return t._RADIO_SELECT_W * SCALE; }
	static inline function RADIO_SELECT_H() { return t._RADIO_SELECT_H * SCALE; }
	static inline function SCROLL_W() { return Std.int(t._SCROLL_W * SCALE); }
	static inline function SCROLL_BAR_W() { return t._SCROLL_BAR_W * SCALE; }
	static inline function DEFAULT_TEXT_OFFSET_X() { return t._DEFAULT_TEXT_OFFSET_X * SCALE; }
	static inline function TAB_W() { return Std.int(t._TAB_W * SCALE); }
	static inline function LINE_STRENGTH() { return t._LINE_STRENGTH * SCALE; }

	public function resize(handle:Handle, w: Int, h: Int, khaWindowId = 0) {
		handle.redraws = 2;
		if (handle.texture != null) handle.texture.unload();
		handle.texture = kha.Image.createRenderTarget(w, h, kha.graphics4.TextureFormat.RGBA32, kha.graphics4.DepthStencilFormat.NoDepthAndStencil, 1, khaWindowId);
	}
}

typedef HandleOptions = {
	?selected: Bool,
	?position: Int,
	?value: Float,
	?text: String,
	?color: kha.Color,
	?layout: Layout
}

class Handle {
	public var selected = false;
	public var position = 0;
	public var color = kha.Color.White;
	public var value = 0.0;
	public var text = "";
	public var texture: kha.Image = null;
	public var redraws = 2;
	public var scrolling = false;
	public var scrollOffset = 0.0;
	public var scrollEnabled = false;
	public var layout: Layout = 0;
	public var lastMaxX = 0.0;
	public var lastMaxY = 0.0;
	public var dragging = false;
	public var dragEnabled = false;
	public var dragX = 0;
	public var dragY = 0;
	var children: Array<Handle>;

	public function new(ops: HandleOptions = null) {
		if (ops != null) {
			if (ops.selected != null) selected = ops.selected;
			if (ops.position != null) position = ops.position;
			if (ops.value != null) value = ops.value;
			if (ops.text != null) text = ops.text;
			if (ops.color != null) color = ops.color;
			if (ops.layout != null) layout = ops.layout;
		}
	}

	public function nest(i: Int, ops: HandleOptions = null): Handle {
		if (children == null) children = [];
		while (children.length <= i) children.push(new Handle(ops));
		return children[i];
	}

	public static var global = new Handle();
}

@:enum abstract Layout(Int) from Int {
	var Vertical = 0;
	var Horizontal = 1;
}

@:enum abstract Align(Int) from Int {
	var Left = 0;
	var Center = 1;
	var Right = 2;
}
