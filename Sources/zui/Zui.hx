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
	?autoNotifyInput: Bool,
	?color_wheel: kha.Image
}

class Zui {
	public var isScrolling = false; // Use to limit other activities
	public var isTyping = false;
	public var isStarted = false; // Current element state
	public var isPushed = false;
	public var isHovered = false;
	public var isReleased = false;
	public var changed = false; // Global elements change check
	public var alwaysRedraw = false; // Hurts performance
	public var imageInvertY = false;

	public var inputRegistered = false;
	public var inputEnabled = true;
	var inputX: Float; // Input position
	var inputY: Float;
	var inputInitialX: Float;
	var inputInitialY: Float;
	var inputDX: Float; // Delta
	var inputDY: Float;
	var inputWheelDelta = 0;
	var inputStarted: Bool; // Buttons
	var inputReleased: Bool;
	var inputDown: Bool;
	var inputDownR: Bool;
	var isKeyDown = false; // Keys
	var key: Null<kha.input.KeyCode> = null;
	var char: String;

	var cursorX = 0; // Text input
	var cursorY = 0;
	var highlightStart = 0;
	var highlightEnd = 0;

	var ratios: Array<Float>; // Splitting rows
	var curRatio = -1;
	var xBeforeSplit: Float;
	var wBeforeSplit: Int;

	var globalG: kha.graphics2.Graphics; // Drawing
	public var g: kha.graphics2.Graphics;

	var t:zui.Themes.TTheme;
	var SCALE: Float;
	var ops: ZuiOptions;
	var fontSize: Int;

	var fontOffsetY: Float; // Precalculated offsets
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
	var scrollAlign: Float = 0.0;
	var imageScrollAlign = true;

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
	public var scrollEnabled = true;
	var windowHeader = 0.0;

	var textSelectedHandle: Handle = null;
	var textSelectedCurrentText: String;
	var submitTextHandle: Handle = null;
	var textToSubmit = "";
	var tabPressed = false;
	var tabPressedHandle: Handle = null;
	var comboSelectedHandle: Handle = null;
	var comboSelectedWindow: Handle = null;
	var comboSelectedAlign: Align;
	var comboSelectedTexts: Array<String>;
	var comboSelectedLabel: String;
	var comboSelectedX: Int;
	var comboSelectedY: Int;
	var comboSelectedW: Int;
	var submitComboHandle: Handle = null;
	var comboToSubmit = 0;
	var tooltipText = "";
	var tooltipX = 0.0;
	var tooltipY = 0.0;
	var tooltipShown = false;
	var tooltipTime = 0.0;
	var tabNames: Array<String> = null; // Number of tab calls since window begin
	var tabHandle: Handle = null;
	var tabScroll = 0.0;

	var elementsBaked = false;
	var checkSelectImage: kha.Image = null;

	public function new(ops: ZuiOptions) {
		if (ops.theme == null) ops.theme = Themes.dark;
		t = ops.theme;
		if (ops.khaWindowId == null) ops.khaWindowId = 0;
		if (ops.scaleFactor == null) ops.scaleFactor = 1.0;
		if (ops.scaleTexture == null) ops.scaleTexture = 1.0;
		if (ops.autoNotifyInput == null) ops.autoNotifyInput = true;
		this.ops = ops;
		setScale(ops.scaleFactor);
		if (ops.autoNotifyInput) registerInput();
	}

	public function setScale(factor: Float) {
		ops.scaleFactor = factor;
		SCALE = ops.scaleFactor * ops.scaleTexture;
		fontSize = Std.int(t.FONT_SIZE * ops.scaleFactor);
		var fontHeight = ops.font.height(fontSize);
		fontOffsetY = (ELEMENT_H() - fontHeight) / 2; // Precalculate offsets
		arrowOffsetY = (ELEMENT_H() - ARROW_SIZE()) / 2;
		arrowOffsetX = arrowOffsetY;
		titleOffsetX = (arrowOffsetX * 2 + ARROW_SIZE()) / SCALE;
		buttonOffsetY = (ELEMENT_H() - BUTTON_H()) / 2;
		checkOffsetY = (ELEMENT_H() - CHECK_SIZE()) / 2;
		checkOffsetX = checkOffsetY;
		checkSelectOffsetY = (CHECK_SIZE() - CHECK_SELECT_SIZE()) / 2;
		checkSelectOffsetX = checkSelectOffsetY;
		radioOffsetY = (ELEMENT_H() - CHECK_SIZE()) / 2;
		radioOffsetX = radioOffsetY;
		radioSelectOffsetY = (CHECK_SIZE() - CHECK_SELECT_SIZE()) / 2;
		radioSelectOffsetX = radioSelectOffsetY;
		elementsBaked = false;
	}
	
	function bakeElements() {
		if (checkSelectImage != null) {
			checkSelectImage.unload();
			checkSelectImage = null;
		}
		checkSelectImage = kha.Image.createRenderTarget(Std.int(CHECK_SELECT_SIZE()), Std.int(CHECK_SELECT_SIZE()), null, NoDepthAndStencil, 1, ops.khaWindowId);
		var g = checkSelectImage.g2;
		g.begin(true, 0x00000000);
		g.color = t.ACCENT_SELECT_COL;
		g.drawLine(0, 0, checkSelectImage.width, checkSelectImage.height, 2 * SCALE);//LINE_STRENGTH());
		g.drawLine(checkSelectImage.width, 0, 0, checkSelectImage.height, 2 * SCALE);//LINE_STRENGTH());
		g.end();
		elementsBaked = true;
	}

	public function remove() { // Clean up
		if (ops.autoNotifyInput) unregisterInput();
	}

	public function registerInput() {
		kha.input.Mouse.get().notifyWindowed(ops.khaWindowId, onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
		kha.input.Keyboard.get().notify(onKeyDown, onKeyUp, onKeyPress);
		inputRegistered = true;
	}

	public function unregisterInput() {
		kha.input.Mouse.get().removeWindowed(ops.khaWindowId, onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
		kha.input.Keyboard.get().remove(onKeyDown, onKeyUp, onKeyPress);
		endInput();
		inputX = inputY = 0;
		inputRegistered = false;
	}

	public function begin(g: kha.graphics2.Graphics) { // Begin UI drawing
		if (!elementsBaked) bakeElements();
		globalG = g;
		_x = 0; // Reset cursor
		_y = 0;
		_w = 0;
		_h = 0;
	}

	public function end(last = true) { // End drawing
		if (!windowEnded) endWindow();
		if (comboSelectedHandle != null) drawCombo(); // Handle active combo
		if (last) endInput();
		if (tabPressedHandle != null) {
			setHighlight(0, tabPressedHandle.text.length);
			tabPressedHandle = null;
		}
	}

	function endInput() {
		isKeyDown = false; // Reset input - only one char for now
		inputStarted = false;
		inputReleased = false;
		inputDX = 0;
		inputDY = 0;
		inputWheelDelta = 0;
	}

	public function beginLayout(g: kha.graphics2.Graphics, x: Int, y: Int, w: Int) {
		if (!elementsBaked) bakeElements();
		currentWindow = null;
		this.g = g;
		_windowX = 0;
		_windowY = 0;
		_windowW = w;
		_x = x;
		_y = y;
		_w = w;
	}

	public function endLayout(last = true) {
		if (last) endInput();
	}

	function inputChanged(): Bool {
		return inputDX != 0 || inputDY != 0 || inputWheelDelta != 0 || inputStarted || inputReleased || inputDown || inputDownR || isKeyDown;
	}

	// Returns true if redraw is needed
	public function window(handle: Handle, x: Int, y: Int, w: Int, h: Int, drag = false): Bool {
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
		windowHeader = 0;

		var inputChanged = getInputInRect(_windowX, _windowY, _windowW, _windowH) && inputChanged();
		if (alwaysRedraw || isScrolling || isTyping || inputChanged) {
			handle.redraws = 2; // Redraw
		}

		if (handle.redraws == 0) {
			return false;
		}

		_x = 0;
		_y = handle.scrollOffset;
		if (handle.layout == Horizontal) w = Std.int(ELEMENT_W());
		_w = !handle.scrollEnabled ? w : w - SCROLL_W(); // Exclude scrollbar if present
		_h = h;
		tooltipText = "";
		tabNames = null;

		if (t.FILL_WINDOW_BG) {
			g.begin(true, t.WINDOW_BG_COL);
		}
		else {
			g.begin(true, 0x00000000);
			g.color = t.WINDOW_BG_COL;
			g.fillRect(_x, _y - handle.scrollOffset, handle.lastMaxX, handle.lastMaxY);
		}

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
			windowHeader += 15;
		}

		return true;
	}

	public function endWindow() {
		var handle = currentWindow;
		if (handle.redraws > 0 || isScrolling || isTyping) {

			if (tabNames != null) drawTabs();

			if (handle.dragEnabled) { // Draggable header
				g.color = t.SEPARATOR_COL;
				g.fillRect(0, 0, _windowW, 15);
			}

			var fullHeight = _y - handle.scrollOffset;
			if (fullHeight < _windowH || handle.layout == Horizontal || !scrollEnabled) { // Disable scrollbar
				handle.scrollEnabled = false;
				handle.scrollOffset = 0;
			}
			else { // Draw window scrollbar if necessary
				handle.scrollEnabled = true;
				if (tabScroll < 0) { // Restore tab
					handle.scrollOffset = tabScroll;
					tabScroll = 0;
				}
				var amountToScroll = fullHeight - _windowH;
				var amountScrolled = -handle.scrollOffset;
				var ratio = amountScrolled / amountToScroll;
				var barH = _windowH * Math.abs(_windowH / fullHeight);
				barH = Math.max(barH, ELEMENT_H());
				
				var totalScrollableArea = _windowH - barH;
				var e = amountToScroll / totalScrollableArea;
				var barY = totalScrollableArea * ratio;

				if ((inputStarted) && // Start scrolling
					 getInputInRect(_windowX + _windowW - SCROLL_W(), barY + _windowY, SCROLL_W(), barH)) {
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
				
				g.color = t.WINDOW_BG_COL; // Bg
				g.fillRect(_windowW - SCROLL_W(), _windowY, SCROLL_W(), _windowH);
				g.color = t.ACCENT_COL; // Bar
				g.fillRect(_windowW - SCROLL_W() - scrollAlign, barY, SCROLL_W(), barH);
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
		
		if (tooltipText != "") {
			if (!tooltipShown) { 
				tooltipShown = true;
				tooltipX = inputX;
				tooltipTime = kha.Scheduler.time();
			}
			if (kha.Scheduler.time() - tooltipTime > t.TOOLTIP_DELAY) drawTooltip();
		}
		else tooltipShown = false;
		
		globalG.end();
	}

	function scroll(delta: Float, fullHeight: Float) {
		currentWindow.scrollOffset -= delta;
	}

	var restoreX = -1.0;
	var restoreY = -1.0;
	public function tab(handle: Handle, text: String): Bool {
		if (tabNames == null) { // First tab
			tabNames = [];
			tabHandle = handle;
			windowHeader += buttonOffsetY + BUTTON_H();
			restoreX = inputX; // Mouse in tab header, disable clicks for tab content
			restoreY = inputY;
			if (getInputInRect(_windowX, _windowY, _windowW, windowHeader)) { 
				inputX = inputY = -1;
			}
		}
		tabNames.push(text);
		var selected = handle.position == tabNames.length - 1;
		if (selected) endElement();
		return selected;
	}

	function drawTabs() {
		inputX = restoreX;
		inputY = restoreY;
		if (currentWindow == null) return;
		var tabX = 0.0;
		var origy = _y;
		_y = currentWindow.dragEnabled ? 15 : 0;

		g.color = t.WINDOW_BG_COL; // Underline tab buttons
		g.fillRect(0, _y, _windowW, buttonOffsetY + BUTTON_H());
		g.color = t.ACCENT_COL;
		g.fillRect(buttonOffsetY, _y + buttonOffsetY + BUTTON_H(), _windowW - buttonOffsetY * 2, LINE_STRENGTH());
		
		for (i in 0...tabNames.length) {
			_x = tabX;
			_w = Std.int(ops.font.width(fontSize, tabNames[i]) + buttonOffsetY * 2 + 14 * SCALE);
			var released = getReleased();
			var pushed = getPushed();
			var hover = getHover();
			if (released) {
				var h = tabHandle.nest(tabHandle.position); // Restore tab scroll
				h.scrollOffset = currentWindow.scrollOffset;
				h = tabHandle.nest(i);
				tabScroll = h.scrollOffset;
				tabHandle.position = i; // Set new tab
				currentWindow.redraws = 3;
			}
			var selected = tabHandle.position == i;

			g.color = pushed ? t.ACCENT_HOVER_COL : //
					  hover ? t.ACCENT_HOVER_COL : //
					  t.ACCENT_COL; //
			tabX += _w + 5;
			drawRect(g, !selected, _x + buttonOffsetY, _y + buttonOffsetY, _w, BUTTON_H());
			g.color = t.BUTTON_TEXT_COL;
			drawString(g, tabNames[i], TEXT_OFFSET(), 0, Align.Left);

			if (selected) { // Hide underline for active tab
				g.color = t.WINDOW_BG_COL;
				g.fillRect(_x + buttonOffsetY + 1, _y + buttonOffsetY + BUTTON_H(), _w - 1, LINE_STRENGTH());
			}
		}

		_x = 0; // Restore positions
		_y = origy;
		_w = Std.int(!currentWindow.scrollEnabled ? _windowW : _windowW - SCROLL_W());
	}

	public function panel(handle: Handle, text: String, accent = 0, isTree = false): Bool {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.selected; }
		if (getReleased()) handle.selected = !handle.selected;
		var hover = getHover();

		if (accent > 0) { // Bg
			g.color = t.PANEL_BG_COL;
			g.fillRect(_x, _y, _w, ELEMENT_H());
		}

		isTree ? drawTree(handle.selected) : drawArrow(handle.selected);

		g.color = t.PANEL_TEXT_COL; // Title
		g.opacity = 1.0;
		drawString(g, text, titleOffsetX, 0);

		endElement();

		return handle.selected;
	}
	
	public function image(image: kha.Image, tint = 0xffffffff, h: Null<Float> = null): State {
		var iw = image.width * SCALE;
		var ih = image.height * SCALE;
		var w = Math.min(iw, _w);
		var x = _x;
		if (imageScrollAlign) {
			w = Math.min(iw, _w - buttonOffsetY * 2);
			x += buttonOffsetY;
			var scroll = currentWindow != null ? currentWindow.scrollEnabled : false;
			if (!scroll) { 
				var r = curRatio == -1 ? 1.0 : ratios[curRatio];
				w -= SCROLL_W() * r;
				x += SCROLL_W() * r / 2;
			}
		}

		// Image size
		var ratio = h == null ?
			w / iw :
			h / ih;
		h == null ?
			h = ih * ratio :
			w = iw * ratio;

		if (!isVisible(h)) {
			endElement(h);
			return State.Idle;
		}
		var started = getStarted(h);
		var down = getPushed(h);
		var released = getReleased(h);
		g.color = tint;
		var h_float:Float = h; // TODO: hashlink fix
		imageInvertY ? g.drawScaledImage(image, x, _y + h_float, w, -h_float) : g.drawScaledImage(image, x, _y, w, h_float);
		
		endElement(h);
		return started ? State.Started : released ? State.Released : down ? State.Down : State.Idle;
	}

	public function text(text: String, align:Align = Left, bg = 0x00000000) {
		if (!isVisible(ELEMENT_H())) { endElement(); return; }
		getReleased();
		if (bg != 0x0000000) {
			g.color = bg;
			g.fillRect(_x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());
		}
		g.color = t.TEXT_COL;
		drawString(g, text, TEXT_OFFSET(), 0, align);

		endElement();
	}

	public function floatInput(handle: Handle, label = "", align:Align = Left): Float {
		var text = textInput(handle, label, align, true);
		return Std.parseFloat(text);
	}

	function startTextEdit(handle: Handle) {
		isTyping = true;
		submitTextHandle = textSelectedHandle;
		textToSubmit = textSelectedCurrentText;
		textSelectedHandle = handle;
		textSelectedCurrentText = handle.text;
		tabPressed = false;
		tabPressedHandle = handle;
		cursorX = handle.text.length;
		cursorY = 0;
		setHighlight(0, cursorX); // Highlight all text when first selected
		if (kha.input.Keyboard.get() != null) {
			kha.input.Keyboard.get().show();
		}
	}

	function submitTextEdit() {
		submitTextHandle.text = textToSubmit;
		submitTextHandle.changed = changed = true;
		submitTextHandle = null;
		textToSubmit = "";
		textSelectedCurrentText = "";
	}

	function updateTextEdit(align:Align = Left, asFloat: Bool) {
		var text = textSelectedCurrentText;
		if (isKeyDown) { // Process input
			if (key == kha.input.KeyCode.Left) { // Move cursor
				if (cursorX > 0) cursorX--;
			}
			else if (key == kha.input.KeyCode.Right) {
				if (cursorX < text.length) cursorX++;
			}
			else if (key == kha.input.KeyCode.Backspace) { // Remove char
				if (cursorX > 0) {
					if (highlightStart != highlightEnd) {
						text = text.substr(0, highlightStart) + text.substr(highlightEnd, text.length);
					}
					else {
						text = text.substr(0, cursorX - 1) + text.substr(cursorX, text.length);
					}
					cursorX--;
				}
			}
			else if (key == kha.input.KeyCode.Delete) {
				text = text.substr(0, highlightStart) + text.substr(highlightEnd + 1);
			}
			else if (key == kha.input.KeyCode.Return) { // Deselect
				deselectText(); // One-line text for now
			}
			else if (key == kha.input.KeyCode.Tab) { // Next field
				tabPressed = true;
				deselectText();
				key = null;
			}
			else if (key == kha.input.KeyCode.Home) {
				cursorX = 0;
			}
			else if (key == kha.input.KeyCode.End) {
				cursorX = text.length;
			}
			else if (key != kha.input.KeyCode.Shift && key != kha.input.KeyCode.CapsLock) {
				if (char != null && char != "") {
					if (char.charCodeAt(0) >= 32 && char.charCodeAt(0) != 127) { // 127=DEL
						text = text.substr(0, highlightStart) + char + text.substr(highlightEnd);
						cursorX++;
					}
				}
			}
			setHighlight(cursorX, cursorX); //TODO: Implement shift modifier key
		}

		var off = TEXT_OFFSET();
		var lineHeight = ELEMENT_H();
		var cursorHeight = lineHeight - buttonOffsetY * 3.0;
		//Draw highlight
		if (highlightStart != highlightEnd) {
			var hlstr = align == Left ? text.substr(highlightStart, highlightEnd) : text.substring(highlightEnd, highlightStart);
			var hlstrw = g.font.width(g.fontSize, hlstr);
			var hlStart = align == Left ? _x + highlightStart + off : _x + _w - hlstrw - off;
			g.fillRect(hlStart, _y + cursorY * lineHeight + buttonOffsetY * 1.5, hlstrw * SCALE, cursorHeight);
		}

		// Flash cursor
		var time = kha.Scheduler.time();
		if (time % (t.FLASH_SPEED * 2.0) < t.FLASH_SPEED) {
			g.color = t.TEXT_COL; // Cursor
			var str = align == Left ? text.substr(0, cursorX) : text.substring(cursorX, text.length);
			var strw = g.font.width(g.fontSize, str);
			var cursorX = align == Left ? _x + strw + off : _x + _w - strw - off;
			g.fillRect(cursorX, _y + cursorY * lineHeight + buttonOffsetY * 1.5, 1 * SCALE, cursorHeight);
		}
		
		if (asFloat) text = formatFloatString(text);
		textSelectedCurrentText = text;
	}

	public function textInput(handle: Handle, label = "", align:Align = Left, asFloat = false): String {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.text; }

		var hover = getHover();
		g.color = hover ? t.ACCENT_HOVER_COL : t.ACCENT_COL; // Text bg
		drawRect(g, t.FILL_ACCENT_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());

		var startEdit = getReleased() || tabPressed;
		if (textSelectedHandle != handle && startEdit) startTextEdit(handle);
		if (textSelectedHandle == handle) updateTextEdit(align, asFloat);
		if (submitTextHandle == handle) submitTextEdit();
		else handle.changed = false;

		if (label != "") {
			g.color = t.LABEL_COL; // Label
			var labelAlign = align == Right ? Left : Right;
			var xOffset = labelAlign == Left ? 7 : 0;
			drawString(g, label, xOffset, 0, labelAlign);
		}

		g.color = t.TEXT_COL; // Text
		textSelectedHandle != handle ? drawString(g, handle.text, null, 0, align) : drawString(g, textSelectedCurrentText, null, 0, align);

		endElement();

		return handle.text;
	}

	inline function setHighlight(start:Int, end:Int) {
		highlightStart = start < end ? start : end;
		highlightEnd = start < end ? end : start;
	}

	inline function formatFloatString(text:String): String {
		var f = Std.parseFloat(text);
		if (f != f) f = 0; //NaN
		var f_text = Std.string(f);

		if (Std.parseInt(text) == f) f_text += ".0";
		if (text.charAt(0) == "-") {
			if (f_text.charAt(0) != "-") f_text = "-" + f_text; //keep - for -0.0
			if (text.charAt(1) == "-") { //change -- to -
				f_text = text.substring(1, text.length);
				cursorX--;
			}
		}
		return f_text;
	}

	function deselectText() {
		submitTextHandle = textSelectedHandle;
		textToSubmit = textSelectedCurrentText;
		textSelectedHandle = null;
		isTyping = false;
		if (currentWindow != null) currentWindow.redraws = 2;

		if (kha.input.Keyboard.get() != null) {
			kha.input.Keyboard.get().hide();
		}
		setHighlight(0, 0);
	}

	public function button(text: String, align:Align = Center): Bool {
		if (!isVisible(ELEMENT_H())) { endElement(); return false; }
		var released = getReleased();
		var pushed = getPushed();
		var hover = getHover();

		g.color = pushed ? t.BUTTON_PRESSED_COL :
				  hover ? t.BUTTON_HOVER_COL :
				  t.BUTTON_COL;

		drawRect(g, t.FILL_BUTTON_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());

		g.color = t.BUTTON_TEXT_COL;
		drawString(g, text, TEXT_OFFSET(), 0, align);

		endElement();

		return released;
	}

	public function check(handle: Handle, text: String): Bool {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.selected; }
		if (getReleased()) {
			handle.selected = !handle.selected;
			handle.changed = changed = true;
		}
		else handle.changed = false;

		var hover = getHover();
		drawCheck(handle.selected, hover); // Check

		g.color = t.TEXT_COL; // Text
		drawString(g, text, titleOffsetX, 0, Left);

		endElement();

		return handle.selected;
	}

	public function radio(handle: Handle, position: Int, text: String): Bool {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.position == position; }
		if (getReleased()) {
			handle.position = position;
			handle.changed = changed = true;
		}
		else handle.changed = false;

		var hover = getHover();
		drawRadio(handle.position == position, hover); // Radio

		g.color = t.TEXT_COL; // Text
		drawString(g, text, titleOffsetX, 0);

		endElement();

		return handle.position == position;
	}

	public function inlineRadio(handle: Handle, texts: Array<String>): Int {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.position; }
		if (getReleased()) {
			if (++handle.position >= texts.length) handle.position = 0;
			handle.changed = changed = true;
		}
		else handle.changed = false;

		var hover = getHover();
		drawInlineRadio(texts[handle.position], hover); // Radio

		endElement();
		return handle.position;
	}

	public function combo(handle: Handle, texts: Array<String>, label = "", showLabel = false, align: Align = Left): Int {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.position; }
		if (getReleased()) {
			if (comboSelectedHandle == null) {
				inputEnabled = false;
				comboSelectedHandle = handle;
				comboSelectedWindow = currentWindow;
				comboSelectedAlign = align;
				comboSelectedTexts = texts;
				comboSelectedLabel = label;
				comboSelectedX = Std.int(_x + _windowX);
				comboSelectedY = Std.int(_y + _windowY + ELEMENT_H() + ELEMENT_OFFSET());
				comboSelectedW = Std.int(_w);
			}
		}
		if (handle == submitComboHandle) {
			handle.position = comboToSubmit;
			submitComboHandle = null;
			handle.changed = changed = true;
		}
		else handle.changed = false;

		var hover = getHover();
		if (hover) { // Bg
			g.color = t.ACCENT_HOVER_COL;
			drawRect(g, t.FILL_ACCENT_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());
		}
		else {
			g.color = t.ACCENT_COL;
			drawRect(g, t.FILL_ACCENT_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());
		}

		var x = _x + _w - arrowOffsetX - 8;
		var y = _y + arrowOffsetY + 3;
		g.fillTriangle(x, y, x + ARROW_SIZE(), y, x + ARROW_SIZE() / 2, y + ARROW_SIZE() / 2);

		g.color = t.TEXT_COL; // Value

		if (showLabel && label != "") {
			if (align == Left) _x -= 15;
			drawString(g, label, null, 0, align == Left ? Right : Left);
			if (align == Left) _x += 15;
		}
		
		if (align == Right) _x -= 15;
		drawString(g, texts[handle.position], null, 0, align);
		if (align == Right) _x += 15;

		endElement();
		return handle.position;
	}

	public function slider(handle: Handle, text: String, from = 0.0, to = 1.0, filled = false, precision = 100, displayValue = true, align: Align = Right): Float {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.value; }
		if (getStarted()) {
			handle.scrolling = true;
			scrollingHandle = handle;
			isScrolling = true;
		}
		
		handle.changed = false;
		if (handle.scrolling) { // Scroll
			var range = to - from;
			var sliderX = _x + _windowX + buttonOffsetY;
			var sliderW = _w - buttonOffsetY * 2;
			var step = range / sliderW;
			var value = from + (inputX - sliderX) * step;
			handle.value = Std.int(value * precision) / precision;
			if (handle.value < from) handle.value = from; // Stay in bounds
			else if (handle.value > to) handle.value = to;
			handle.changed = changed = true;
		}

		var hover = getHover();
		drawSlider(handle.value, from, to, filled, hover); // Slider

		// Text edit
		var startEdit = getReleased() || tabPressed;
		if (startEdit) { // Mouse did not move
			handle.text = handle.value + "";
			startTextEdit(handle);
		}
		var lalign = align == Left ? Right : Left;
		if (textSelectedHandle == handle) {
			updateTextEdit(lalign, false);
		}
		if (submitTextHandle == handle) {
			submitTextEdit();
			handle.value = Std.parseFloat(handle.text);
		}
		
		g.color = t.LABEL_COL;// Text
		drawString(g, text, null, 0, align);

		if (displayValue) {
			g.color = t.TEXT_COL; // Value
			textSelectedHandle != handle ? 
				drawString(g, handle.value + "", null, 0, lalign) :
				drawString(g, textSelectedCurrentText, null, 0, lalign);
		}

		endElement();
		return handle.value;
	}

	public function separator() {
		if (!isVisible(ELEMENT_H())) { _y += 2; return; }
		g.color = t.SEPARATOR_COL;
		g.fillRect(_x, _y, _w - TEXT_OFFSET(), LINE_STRENGTH());
		_y += 2;
	}

	public function tooltip(text: String) {
		tooltipText = text;
		tooltipY = _y + _windowY;
	}

	function drawArrow(selected: Bool) {
		var x = _x + arrowOffsetX;
		var y = _y + arrowOffsetY;
		g.color = t.ARROW_COL;
		if (selected) {
			g.fillTriangle(x, y,
						   x + ARROW_SIZE(), y,
						   x + ARROW_SIZE() / 2, y + ARROW_SIZE());
		}
		else {
			g.fillTriangle(x, y,
						   x, y + ARROW_SIZE(),
						   x + ARROW_SIZE(), y + ARROW_SIZE() / 2);
		}
	}

	function drawTree(selected: Bool) {
		var SIGN_W = 7;
		var x = _x + arrowOffsetX + 1;
		var y = _y + arrowOffsetY + 1;
		g.color = t.ARROW_COL;
		if (selected) {
			g.fillRect(x, y + SIGN_W / 2 - 1, SIGN_W, SIGN_W / 8);
		}
		else {
			g.fillRect(x, y + SIGN_W / 2 - 1, SIGN_W, SIGN_W / 8);
			g.fillRect(x + SIGN_W / 2 - 1, y, SIGN_W / 8, SIGN_W);
		}
	}

	function drawCheck(selected: Bool, hover: Bool) {
		var x = _x + checkOffsetX;
		var y = _y + checkOffsetY;

		g.color = hover ? t.ACCENT_HOVER_COL : t.ACCENT_COL;
		drawRect(g, t.FILL_ACCENT_BG, x, y, CHECK_SIZE(), CHECK_SIZE()); // Bg

		if (selected) { // Check
			g.color = kha.Color.White;
			g.drawImage(checkSelectImage, x + checkSelectOffsetX, y + checkSelectOffsetY);
		}
	}

	function drawRadio(selected: Bool, hover: Bool) {
		var x = _x + radioOffsetX;
		var y = _y + radioOffsetY;
		g.color = hover ? t.ACCENT_HOVER_COL : t.ACCENT_COL;
		drawRect(g, t.FILL_ACCENT_BG, x, y, CHECK_SIZE(), CHECK_SIZE()); // Bg

		if (selected) { // Check
			g.color = t.ACCENT_SELECT_COL;
			g.fillRect(x + radioSelectOffsetX, y + radioSelectOffsetY, CHECK_SELECT_SIZE(), CHECK_SELECT_SIZE());
		}
	}

	function drawInlineRadio(text: String, hover: Bool) {
		if (hover) { // Bg
			g.color = t.ACCENT_HOVER_COL;
			g.fillRect(_x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());
		}
		else {
			g.color = t.ACCENT_COL;
			g.drawRect(_x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());
		}
		g.color = t.TEXT_COL; // Text
		drawString(g, text, titleOffsetX, 0, Align.Center);
	}
	
	function drawSlider(value: Float, from: Float, to: Float, filled: Bool, hover: Bool) {
		var x = _x + buttonOffsetY;
		var y = _y + buttonOffsetY;
		var w = _w - buttonOffsetY * 2;

		g.color = hover ? t.ACCENT_HOVER_COL : t.ACCENT_COL;
		drawRect(g, t.FILL_ACCENT_BG, x, y, w, BUTTON_H()); // Bg
		
		g.color = hover ? t.ACCENT_HOVER_COL : t.ACCENT_COL;
		var offset = (value - from) / (to - from);
		var barW = 8 * SCALE; // Unfilled bar
		var sliderX = filled ? x : x + (w - barW) * offset;
		var sliderW = filled ? w * offset : barW; 
		sliderW = Math.min(sliderW, w);
		g.fillRect(sliderX, y, sliderW, BUTTON_H());
	}

	static var comboFirst = true;
	function drawCombo() {
		var _g = g;
		globalG.color = 0xff222222;
		var elementSize = ELEMENT_H() + ELEMENT_OFFSET();
		globalG.begin(false);
		globalG.fillRect(comboSelectedX, comboSelectedY, comboSelectedW, (comboSelectedTexts.length + 1) * elementSize);
		beginLayout(globalG, comboSelectedX, comboSelectedY, comboSelectedW);
		inputEnabled = true;
		for (i in 0...comboSelectedTexts.length) {
			if (button(comboSelectedTexts[i], comboSelectedAlign)) {
				comboToSubmit = i;
				submitComboHandle = comboSelectedHandle;
				if (comboSelectedWindow != null) comboSelectedWindow.redraws = 2;
				break;
			}
		}
		text(comboSelectedLabel);
		if (inputReleased && !comboFirst) {
			comboSelectedHandle = null;
			comboFirst = true;
		}
		else comboFirst = false;
		inputEnabled = comboSelectedHandle == null;
		endLayout(false);
		globalG.end();
		g = _g; // Restore
	}

	function drawTooltip() {
		globalG.color = t.TEXT_COL;
		var lines = tooltipText.split("\n");
		var tooltipW:Float = 0;
		for (line in lines) {
			var lineTooltipW = ops.font.width(fontSize, line);
			if (lineTooltipW > tooltipW) tooltipW = lineTooltipW;
		}
		tooltipX = Math.min(tooltipX, kha.System.windowWidth() - tooltipW - 20);
		globalG.fillRect(tooltipX, tooltipY, tooltipW + 20, ELEMENT_H() * lines.length * 0.6);
		globalG.font = ops.font;
		globalG.fontSize = fontSize;
		globalG.color = t.ACCENT_COL;
		for (i in 0...lines.length) {
			globalG.drawString(lines[i], tooltipX + 5, tooltipY + i * fontSize);
		}
	}

	function drawString(g: kha.graphics2.Graphics, text: String,
						xOffset: Null<Float> = null, yOffset: Float = 0,
						align:Align = Left) {
		var maxChars = Std.int(_w / Std.int(fontSize / 2)); // Guess width for now
		if (text.length > maxChars) text = text.substring(0, maxChars) + "..";
		
		if (xOffset == null) xOffset = t.TEXT_OFFSET;
		xOffset *= SCALE;
		g.font = ops.font;
		g.fontSize = fontSize;
		if (align == Center) xOffset = _w / 2 - ops.font.width(fontSize, text) / 2;
		else if (align == Right) xOffset = _w - ops.font.width(fontSize, text) - TEXT_OFFSET();

		g.drawString(text, _x + xOffset, _y + fontOffsetY + yOffset);
	}

	function endElement(elementSize:Null<Float> = null) {
		if (currentWindow == null) { _y += ELEMENT_H() + ELEMENT_OFFSET(); return; }
		if (currentWindow.layout == Vertical) {
			if (curRatio == -1 || (ratios != null && curRatio == ratios.length - 1)) { // New line
				if (elementSize == null) elementSize = ELEMENT_H() + ELEMENT_OFFSET();
				_y += elementSize;

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
			_x += _w + ELEMENT_OFFSET();
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
	
	public function fill(x: Float, y: Float, w: Float, h: Float, color: kha.Color) {
		g.color = color;
		g.fillRect(_x + x * SCALE, _y + y * SCALE, w * SCALE, h * SCALE);
		g.color = 0xffffffff;
	}

	inline function drawRect(g: kha.graphics2.Graphics, fill: Bool, x: Float, y: Float, w: Float, h: Float, strength = 0.0) {
		if (strength == 0.0) strength = LINE_STRENGTH();
		fill ? g.fillRect(x, y, w, h) : g.drawRect(x, y, w, h, strength);
	}

	function isVisible(elemH: Float): Bool {
		if (currentWindow == null) return true;
		// Assume vertical layout for now
		return (_y + elemH > 0 && _y < currentWindow.texture.height);
	}

	function getReleased(elemH = -1.0): Bool { // Input selection
		isReleased = inputEnabled && inputReleased && getHover(elemH) && getInitialHover(elemH);
		return isReleased;
	}

	function getPushed(elemH = -1.0): Bool {
		isPushed = inputEnabled && inputDown && getHover(elemH) && getInitialHover(elemH);
		return isPushed;
	}
	
	function getStarted(elemH = -1.0): Bool {
		isStarted = inputEnabled && inputStarted && getHover(elemH);
		return isStarted;
	}

	function getInitialHover(elemH = -1.0): Bool {
		if (elemH == -1.0) elemH = ELEMENT_H();
		return inputEnabled &&
			inputInitialX >= _windowX + _x && inputInitialX < (_windowX + _x + _w) &&
			inputInitialY >= _windowY + _y && inputInitialY < (_windowY + _y + elemH);
	}

	function getHover(elemH = -1.0): Bool {
		if (elemH == -1.0) elemH = ELEMENT_H();
		isHovered = inputEnabled &&
			inputX >= _windowX + _x && inputX < (_windowX + _x + _w) &&
			inputY >= _windowY + _y && inputY < (_windowY + _y + elemH);
		return isHovered;
	}

	function getInputInRect(x: Float, y: Float, w: Float, h: Float, scale = 1.0): Bool {
		return inputEnabled &&
			inputX >= x * scale && inputX < (x + w) * scale &&
			inputY >= y * scale && inputY < (y + h) * scale;
	}

	public function onMouseDown(button: Int, x: Int, y: Int) { // Input events
		inputStarted = true;
		button == 0 ? inputDown = true : inputDownR = true;
		var sx = Std.int(x * ops.scaleTexture);
		var sy = Std.int(y * ops.scaleTexture);
		setInputPosition(sx, sy);
		inputInitialX = sx;
		inputInitialY = sy;
	}

	public function onMouseUp(button: Int, x: Int, y: Int) {
		if (isScrolling) {
			isScrolling = false;
			if (scrollingHandle != null) scrollingHandle.scrolling = false;
			if (x == inputInitialX && y == inputInitialY) inputReleased = true; // Mouse not moved
		}
		else { // To prevent action when scrolling is active
			inputReleased = true;
		}
		button == 0 ? inputDown = false : inputDownR = false;
		setInputPosition(Std.int(x * ops.scaleTexture), Std.int(y * ops.scaleTexture));
		deselectText();
	}

	public function onMouseMove(x: Int, y: Int, movementX: Int, movementY: Int) {
		setInputPosition(Std.int(x * ops.scaleTexture), Std.int(y * ops.scaleTexture));
	}

	public function onMouseWheel(delta: Int) {
		inputWheelDelta = delta;
	}

	function setInputPosition(x: Int, y: Int) {
		inputDX += x - inputX;
		inputDY += y - inputY;
		inputX = x;
		inputY = y;
	}

	public function onKeyDown(code: kha.input.KeyCode) {
		isKeyDown = true;
		this.key = code;
		if (code == kha.input.KeyCode.Space) this.char = " ";
	}

	public function onKeyUp(code: kha.input.KeyCode) {}

	public function onKeyPress(char: String) {
		isKeyDown = true;
		this.char = char;
	}
	
	inline function ELEMENT_W() { return t.ELEMENT_W * SCALE; }
	inline function ELEMENT_H() { return t.ELEMENT_H * SCALE; }
	inline function ELEMENT_OFFSET() { return t.ELEMENT_OFFSET * SCALE; }
	inline function ARROW_SIZE() { return t.ARROW_SIZE * SCALE; }
	inline function BUTTON_H() { return t.BUTTON_H * SCALE; }
	inline function CHECK_SIZE() { return t.CHECK_SIZE * SCALE; }
	inline function CHECK_SELECT_SIZE() { return t.CHECK_SELECT_SIZE * SCALE; }
	inline function SCROLL_W() { return Std.int(t.SCROLL_W * SCALE); }
	inline function TEXT_OFFSET() { return t.TEXT_OFFSET; }
	inline function TAB_W() { return Std.int(t.TAB_W * SCALE); }
	inline function LINE_STRENGTH() { return t.LINE_STRENGTH * SCALE; }

	public function resize(handle:Handle, w: Int, h: Int, khaWindowId = 0) {
		handle.redraws = 2;
		if (handle.texture != null) handle.texture.unload();
		handle.texture = kha.Image.createRenderTarget(w, h, kha.graphics4.TextureFormat.RGBA32, kha.graphics4.DepthStencilFormat.NoDepthAndStencil, 1, khaWindowId);
		handle.texture.g2.imageScaleQuality = kha.graphics2.ImageScaleQuality.High;
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
	public var changed = false;
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
		while (children.length <= i) children.push(null);
		if (children[i] == null) children[i] = new Handle(ops);
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

@:enum abstract State(Int) from Int {
	var Idle = 0;
	var Started = 1;
	var Down = 2;
	var Released = 3;
}
