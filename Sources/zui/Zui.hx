package zui;

// Immediate Mode UI Library
// https://github.com/armory3d/zui

import kha.input.Mouse;
import kha.input.Surface;
import kha.input.Keyboard;
import kha.input.KeyCode;
import kha.graphics2.Graphics;

@:structInit
typedef ZuiOptions = {
	font: kha.Font,
	?theme: zui.Themes.TTheme,
	?khaWindowId: Int,
	?scaleFactor: Float,
	?autoNotifyInput: Bool,
	?color_wheel: kha.Image
}

class Zui {
	public var isScrolling = false; // Use to limit other activities
	public var isTyping = false;
	public var enabled = true; // Current element state
	public var isStarted = false;
	public var isPushed = false;
	public var isHovered = false;
	public var isReleased = false;
	public var changed = false; // Global elements change check
	public var imageInvertY = false;
	public var scrollEnabled = true;
	public var alwaysRedraw = false; // Hurts performance
	public var highlightOnSelect = true; // Highlight text edit contents on selection
	public var tabSwitchEnabled = true; // Allow switching focus to the next element by pressing tab
	var highlightFullRow = false;
	public static var onBorderHover: Handle->Int->Void = null; // Mouse over window border, use for resizing
	public static var onTextHover: Void->Void = null; // Mouse over text input, use to set I-cursor
	public static var alwaysRedrawWindow = true; // Redraw cached window texture each frame or on changes only
	public static var keyRepeat = true; // Emulate key repeat for non-character keys
	public static var dynamicGlyphLoad = true; // Allow text input fields to push new glyphs into the font atlas
	#if (kha_android || kha_ios)
	public static var touchControls = true; // Pan with two fingers to scroll, hold finger for right click
	#else
	public static var touchControls = false;
	#end
	var touchHold = false;
	static var keyRepeatTime = 0.0;

	public var inputRegistered = false;
	public var inputEnabled = true;
	public var inputX: Float; // Input position
	public var inputY: Float;
	public var inputStartedX: Float;
	public var inputStartedY: Float;
	public var inputDX: Float; // Delta
	public var inputDY: Float;
	public var inputWheelDelta = 0;
	public var inputStarted: Bool; // Buttons
	public var inputStartedR: Bool;
	public var inputReleased: Bool;
	public var inputReleasedR: Bool;
	public var inputDown: Bool;
	public var inputDownR: Bool;
	public var isKeyPressed = false; // Keys
	public var isKeyDown = false;
	public var isShiftDown = false;
	public var isCtrlDown = false;
	public var isAltDown = false;
	public var isADown = false;
	public var isBackspaceDown = false;
	public var isDeleteDown = false;
	public var isEscapeDown = false;
	public var isReturnDown = false;
	public var isTabDown = false;
	public var key: Null<KeyCode> = null;
	public var char: String;
	static var textToPaste = "";
	static var textToCopy = "";
	static var isCut = false;
	static var isCopy = false;
	static var isPaste = false;
	static var copyReceiver: Zui = null;
	static var copyFrame = 0;
	var inputStartedTime = 0.0;

	var cursorX = 0; // Text input
	var highlightAnchor = 0;

	var ratios: Array<Float>; // Splitting rows
	var curRatio = -1;
	var xBeforeSplit: Float;
	var wBeforeSplit: Int;

	public var g: Graphics; // Drawing
	public var t: zui.Themes.TTheme;
	public var ops: ZuiOptions;
	var globalG: Graphics;
	var rtTextPipeline: kha.graphics4.PipelineState; // Rendering text into rendertargets

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
	var scrollAlign = 0.0;
	var imageScrollAlign = true;

	var _x: Float; // Cursor(stack) position
	var _y: Float;
	var _w: Int;
	var _h: Int;

	var _windowX = 0.0; // Window state
	var _windowY = 0.0;
	var _windowW: Float;
	var _windowH: Float;
	var currentWindow: Handle;
	var windowEnded = true;
	var scrollHandle: Handle = null; // Window or slider being scrolled
	var dragHandle: Handle = null; // Window being dragged
	var windowHeaderW = 0.0;
	var windowHeaderH = 0.0;
	var restoreX = -1.0;
	var restoreY = -1.0;

	var textSelectedHandle: Handle = null;
	var textSelected: String;
	var submitTextHandle: Handle = null;
	var textToSubmit = "";
	var tabPressed = false;
	var tabPressedHandle: Handle = null;
	var comboSelectedHandle: Handle = null;
	var comboSelectedWindow: Handle = null;
	var comboSelectedAlign: Align;
	var comboSelectedTexts: Array<String>;
	var comboItemCount: Int;
	var comboItemOffset: Int;
	var comboSelectedLabel: String;
	var comboSelectedX: Int;
	var comboSelectedY: Int;
	var comboSelectedW: Int;
	var submitComboHandle: Handle = null;
	var comboToSubmit = 0;
	var tooltipText = "";
	var tooltipImg: kha.Image = null;
	var tooltipImgMaxWidth: Null<Int> = null;
	var tooltipInvertY = false;
	var tooltipX = 0.0;
	var tooltipY = 0.0;
	var tooltipShown = false;
	var tooltipWait = false;
	var tooltipTime = 0.0;
	var tabNames: Array<String> = null; // Number of tab calls since window begin
	var tabColors: Array<Int> = null;
	var tabHandle: Handle = null;
	var tabScroll = 0.0;
	var tabVertical = false;
	var sticky = false;
	var scissor = false;

	var elementsBaked = false;
	var checkSelectImage: kha.Image = null;

	public function new(ops: ZuiOptions) {
		if (ops.theme == null) ops.theme = Themes.dark;
		t = ops.theme;
		if (ops.khaWindowId == null) ops.khaWindowId = 0;
		if (ops.scaleFactor == null) ops.scaleFactor = 1.0;
		if (ops.autoNotifyInput == null) ops.autoNotifyInput = true;
		this.ops = ops;
		setScale(ops.scaleFactor);
		if (ops.autoNotifyInput) registerInput();
		if (copyReceiver == null) {
			copyReceiver = this;
			kha.System.notifyOnCutCopyPaste(onCut, onCopy, onPaste);
			kha.System.notifyOnFrames(function(frames: Array<kha.Framebuffer>) {
				// Set isCopy to false on next frame
				if ((isCopy || isPaste) && ++copyFrame > 1) { isCopy = isCut = isPaste = false; copyFrame = 0; }
			});
		}
		var rtTextVS = kha.graphics4.Graphics2.createTextVertexStructure();
		rtTextPipeline = kha.graphics4.Graphics2.createTextPipeline(rtTextVS);
		rtTextPipeline.alphaBlendSource = BlendOne;
		rtTextPipeline.compile();
	}

	public function setScale(factor: Float) {
		ops.scaleFactor = factor;
		fontSize = FONT_SIZE();
		var fontHeight = ops.font.height(fontSize);
		fontOffsetY = (ELEMENT_H() - fontHeight) / 2; // Precalculate offsets
		arrowOffsetY = (ELEMENT_H() - ARROW_SIZE()) / 2;
		arrowOffsetX = arrowOffsetY;
		titleOffsetX = (arrowOffsetX * 2 + ARROW_SIZE()) / SCALE();
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
		}
		checkSelectImage = kha.Image.createRenderTarget(Std.int(CHECK_SELECT_SIZE()), Std.int(CHECK_SELECT_SIZE()), null, NoDepthAndStencil, 1, ops.khaWindowId);
		var g = checkSelectImage.g2;
		g.begin(true, 0x00000000);
		g.color = t.ACCENT_SELECT_COL;
		g.drawLine(0, 0, checkSelectImage.width, checkSelectImage.height, 2 * SCALE());
		g.drawLine(checkSelectImage.width, 0, 0, checkSelectImage.height, 2 * SCALE());
		g.end();
		elementsBaked = true;
	}

	public function remove() { // Clean up
		if (ops.autoNotifyInput) unregisterInput();
	}

	public function registerInput() {
		Mouse.get().notifyWindowed(ops.khaWindowId, onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
		Keyboard.get().notify(onKeyDown, onKeyUp, onKeyPress);
		#if (kha_android || kha_ios)
		if (Surface.get() != null) Surface.get().notify(onTouchDown, onTouchUp, onTouchMove);
		#end
		// Reset mouse delta on foreground
		kha.System.notifyOnApplicationState(function() { inputDX = inputDY = 0; }, null, null, null, null);
		inputRegistered = true;
	}

	public function unregisterInput() {
		Mouse.get().removeWindowed(ops.khaWindowId, onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
		Keyboard.get().remove(onKeyDown, onKeyUp, onKeyPress);
		#if (kha_android || kha_ios)
		if (Surface.get() != null) Surface.get().remove(onTouchDown, onTouchUp, onTouchMove);
		#end
		// kha.System.removeCutCopyPaste(onCut, onCopy, onPaste);
		endInput();
		inputX = inputY = 0;
		inputRegistered = false;
	}

	public function begin(g: Graphics) { // Begin UI drawing
		if (!elementsBaked) bakeElements();
		changed = false;
		globalG = g;
		_x = 0; // Reset cursor
		_y = 0;
		_w = 0;
		_h = 0;
	}

	public function end(last = true) { // End drawing
		if (!windowEnded) endWindow();
		drawCombo(); // Handle active combo
		drawTooltip();
		tabPressedHandle = null;
		if (last) endInput();
	}

	public function beginRegion(g: Graphics, x: Int, y: Int, w: Int) {
		if (!elementsBaked) { g.end(); bakeElements(); g.begin(false); }
		changed = false;
		globalG = g;
		this.g = g;
		currentWindow = null;
		tooltipText = "";
		tooltipImg = null;
		_windowX = 0;
		_windowY = 0;
		_windowW = w;
		_x = x;
		_y = y;
		_w = w;
	}

	public function endRegion(last = true) {
		drawTooltip();
		tabPressedHandle = null;
		if (last) endInput();
	}

	// Sticky region ignores window scrolling
	public function beginSticky() {
		sticky = true;
		_y -= currentWindow.scrollOffset;
	}

	public function endSticky() {
		sticky = false;
		scissor = true;
		g.scissor(0, Std.int(_y), Std.int(_windowW), Std.int(_windowH - _y));
		windowHeaderH += _y - windowHeaderH;
		_y += currentWindow.scrollOffset;
	}

	function endInput() {
		isKeyPressed = false;
		inputStarted = false;
		inputStartedR = false;
		inputReleased = false;
		inputReleasedR = false;
		inputDX = 0;
		inputDY = 0;
		inputWheelDelta = 0;
		textToPaste = "";
		if (keyRepeat && isKeyDown && kha.Scheduler.time() - keyRepeatTime > 0.05) {
			if (key == KeyCode.Backspace || key == KeyCode.Delete || key == KeyCode.Left || key == KeyCode.Right || key == KeyCode.Up || key == KeyCode.Down) {
				keyRepeatTime = kha.Scheduler.time();
				isKeyPressed = true;
			}
		}
		if (touchControls && inputDown && inputX == inputStartedX && inputY == inputStartedY && inputStartedTime > 0 && kha.Scheduler.time() - inputStartedTime > 0.5) {
			touchHold = true;
			inputStartedTime = 0;
		}
	}

	function inputChanged(): Bool {
		return inputDX != 0 || inputDY != 0 || inputWheelDelta != 0 || inputStarted || inputStartedR || inputReleased || inputReleasedR || inputDown || inputDownR || isKeyPressed;
	}

	public function windowDirty(handle: Handle, x: Int, y: Int, w: Int, h: Int): Bool {
		var wx = x + handle.dragX;
		var wy = y + handle.dragY;
		var inputChanged = getInputInRect(wx, wy, w, h) && inputChanged();
		return alwaysRedraw || isScrolling || isTyping || inputChanged;
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
		windowHeaderW = 0;
		windowHeaderH = 0;

		if (windowDirty(handle, x, y, w, h)) {
			handle.redraws = 2;
		}

		if (onBorderHover != null) {
			if (getInputInRect(_windowX - 4, _windowY, 8, _windowH)) {
				onBorderHover(handle, 0);
			}
			else if (getInputInRect(_windowX + _windowW - 4, _windowY, 8, _windowH)) {
				onBorderHover(handle, 1);
			}
			else if (getInputInRect(_windowX, _windowY - 4, _windowW, 8)) {
				onBorderHover(handle, 2);
			}
			else if (getInputInRect(_windowX, _windowY + _windowH - 4, _windowW, 8)) {
				onBorderHover(handle, 3);
			}
		}

		if (handle.redraws <= 0) {
			return false;
		}

		_x = 0;
		_y = handle.scrollOffset;
		if (handle.layout == Horizontal) w = Std.int(ELEMENT_W());
		_w = !handle.scrollEnabled ? w : w - SCROLL_W(); // Exclude scrollbar if present
		_h = h;
		tooltipText = "";
		tooltipImg = null;
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
			if (inputStarted && getInputInRect(_windowX, _windowY, _windowW, HEADER_DRAG_H())) {
				dragHandle = handle;
			}
			else if (inputReleased) {
				dragHandle = null;
			}
			if (handle == dragHandle) {
				handle.redraws = 2;
				handle.dragX += Std.int(inputDX);
				handle.dragY += Std.int(inputDY);
			}
			_y += HEADER_DRAG_H(); // Header offset
			windowHeaderH += HEADER_DRAG_H();
		}

		return true;
	}

	public function endWindow(bindGlobalG = true) {
		var handle = currentWindow;
		if (handle == null) return;
		if (handle.redraws > 0 || isScrolling || isTyping) {

			if (scissor) {
				scissor = false;
				g.disableScissor();
			}

			if (tabNames != null) drawTabs();

			if (handle.dragEnabled) { // Draggable header
				g.color = t.SEPARATOR_COL;
				g.fillRect(0, 0, _windowW, HEADER_DRAG_H());
			}

			var wh = _windowH - windowHeaderH; // Exclude header
			var fullHeight = _y - handle.scrollOffset - windowHeaderH;
			if (fullHeight < wh || handle.layout == Horizontal || !scrollEnabled) { // Disable scrollbar
				handle.scrollEnabled = false;
				handle.scrollOffset = 0;
			}
			else { // Draw window scrollbar if necessary
				handle.scrollEnabled = true;
				if (tabScroll < 0) { // Restore tab
					handle.scrollOffset = tabScroll;
					tabScroll = 0;
				}
				var wy = _windowY + windowHeaderH;
				var amountToScroll = fullHeight - wh;
				var amountScrolled = -handle.scrollOffset;
				var ratio = amountScrolled / amountToScroll;
				var barH = wh * Math.abs(wh / fullHeight);
				barH = Math.max(barH, ELEMENT_H());

				var totalScrollableArea = wh - barH;
				var e = amountToScroll / totalScrollableArea;
				var barY = totalScrollableArea * ratio + windowHeaderH;
				var barFocus = getInputInRect(_windowX + _windowW - SCROLL_W(), barY + _windowY, SCROLL_W(), barH);

				if (inputStarted && barFocus) { // Start scrolling
					scrollHandle = handle;
					isScrolling = true;
				}

				var scrollDelta: Float = inputWheelDelta;
				if (touchControls && inputDownR && inputDY != 0) {
					isScrolling = true;
					scrollDelta = -inputDY / 20;
				}
				if (handle == scrollHandle) { // Scroll
					scroll(inputDY * e, fullHeight);
				}
				else if (scrollDelta != 0 && comboSelectedHandle == null &&
						 getInputInRect(_windowX, wy, _windowW, wh)) { // Wheel
					scroll(scrollDelta * ELEMENT_H(), fullHeight);
				}

				// Stay in bounds
				if (handle.scrollOffset > 0) {
					handle.scrollOffset = 0;
				}
				else if (fullHeight + handle.scrollOffset < wh) {
					handle.scrollOffset = wh - fullHeight;
				}

				g.color = t.WINDOW_BG_COL; // Bg
				g.fillRect(_windowW - SCROLL_W(), wy, SCROLL_W(), wh);
				g.color = t.ACCENT_COL; // Bar
				var scrollbarFocus = getInputInRect(_windowX + _windowW - SCROLL_W(), wy, SCROLL_W(), wh);
				var barW = (scrollbarFocus || handle == scrollHandle) ? SCROLL_W() : SCROLL_W() / 3;
				g.fillRect(_windowW - barW - scrollAlign, barY, barW, barH);
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
		if (alwaysRedrawWindow || handle.redraws > -4) {
			if (bindGlobalG) globalG.begin(false);
			globalG.color = t.WINDOW_TINT_COL;
			globalG.drawImage(handle.texture, _windowX, _windowY);
			if (bindGlobalG) globalG.end();
			if (handle.redraws <= 0) handle.redraws--;
		}
	}

	function scroll(delta: Float, fullHeight: Float) {
		currentWindow.scrollOffset -= delta;
	}

	public function tab(handle: Handle, text: String, vertical = false, color: Int = -1): Bool {
		if (tabNames == null) { // First tab
			tabNames = [];
			tabColors = [];
			tabHandle = handle;
			tabVertical = vertical;
			_w -= tabVertical ? Std.int(ELEMENT_OFFSET() + ELEMENT_W() - 1 * SCALE()) : 0; // Shrink window area by width of vertical tabs
			vertical ?
				windowHeaderW += ELEMENT_W() :
				windowHeaderH += BUTTON_H() + buttonOffsetY + ELEMENT_OFFSET();
			restoreX = inputX; // Mouse in tab header, disable clicks for tab content
			restoreY = inputY;
			if (!vertical && getInputInRect(_windowX, _windowY, _windowW, windowHeaderH)) {
				inputX = inputY = -1;
			}
			vertical ? { _x += windowHeaderW + 6; _w -= 6; } : _y += windowHeaderH + 3;
		}
		tabNames.push(text);
		tabColors.push(color);
		return handle.position == tabNames.length - 1;
	}

	function drawTabs() {
		inputX = restoreX;
		inputY = restoreY;
		if (currentWindow == null) return;
		var tabX = 0.0;
		var tabY = 0.0;
		var tabH = Std.int(BUTTON_H() * 1.1);
		var origy = _y;
		_y = currentWindow.dragEnabled ? HEADER_DRAG_H() : 0;
		tabHandle.changed = false;

		if (isCtrlDown && isTabDown) { // Next tab
			tabHandle.position++;
			if (tabHandle.position >= tabNames.length) tabHandle.position = 0;
			isTabDown = false;
		}

		if (tabHandle.position >= tabNames.length) tabHandle.position = tabNames.length - 1;

		g.color = t.SEPARATOR_COL; // Tab background
		tabVertical ?
			g.fillRect(0, _y, ELEMENT_W(), _windowH) :
			g.fillRect(0, _y, _windowW, buttonOffsetY + tabH + 2);

		g.color = t.ACCENT_COL; // Underline tab buttons
		tabVertical ?
			g.fillRect(ELEMENT_W(), _y, 1, _windowH) :
			g.fillRect(buttonOffsetY, _y + buttonOffsetY + tabH + 2, _windowW - buttonOffsetY * 2, 1);

		var basey = tabVertical ? _y : _y + 2;

		for (i in 0...tabNames.length) {
			_x = tabX;
			_y = basey + tabY;
			_w = tabVertical ?
					Std.int(ELEMENT_W() - 1 * SCALE()) :
					Std.int(ops.font.width(fontSize, tabNames[i]) + buttonOffsetY * 2 + 18 * SCALE());
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
				tabHandle.changed = true;
			}
			var selected = tabHandle.position == i;

			g.color = (pushed || hover) ? t.BUTTON_HOVER_COL :
					  tabColors[i] != -1 ? tabColors[i] :
					  selected ? t.WINDOW_BG_COL :
					  t.SEPARATOR_COL;
			tabVertical ?
				tabY += tabH + 1 :
				tabX += _w + 1;
			drawRect(g, true, _x + buttonOffsetY, _y + buttonOffsetY, _w, tabH);
			g.color = selected ? t.BUTTON_TEXT_COL : t.LABEL_COL;
			drawString(g, tabNames[i], t.TEXT_OFFSET, 0, Align.Left);

			if (selected && !tabVertical) { // Hide underline for active tab
				g.color = t.WINDOW_BG_COL;
				g.fillRect(_x + buttonOffsetY + 1, _y + buttonOffsetY + tabH, _w - 1, 1);
			}
		}

		_x = 0; // Restore positions
		_y = origy;
		_w = Std.int(!currentWindow.scrollEnabled ? _windowW : _windowW - SCROLL_W());
	}

	public function panel(handle: Handle, text: String, isTree = false, filled = true, pack = true): Bool {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.selected; }
		if (getReleased()) {
			handle.selected = !handle.selected;
			handle.changed = changed = true;
		}

		if (filled) {
			g.color = t.PANEL_BG_COL;
			drawRect(g, true, _x, _y, _w, ELEMENT_H());
		}

		isTree ? drawTree(handle.selected) : drawArrow(handle.selected);

		g.color = t.LABEL_COL; // Title
		g.opacity = 1.0;
		drawString(g, text, titleOffsetX, 0);

		endElement();
		if (pack && !handle.selected) _y -= ELEMENT_OFFSET();

		return handle.selected;
	}

	public function image(image: kha.Image, tint = 0xffffffff, h: Null<Float> = null, sx = 0, sy = 0, sw = 0, sh = 0): State {
		var iw = (sw > 0 ? sw : image.width) * SCALE();
		var ih = (sh > 0 ? sh : image.height) * SCALE();
		var w = Math.min(iw, _w);
		var x = _x;
		var scroll = currentWindow != null ? currentWindow.scrollEnabled : false;
		var r = curRatio == -1 ? 1.0 : getRatio(ratios[curRatio], 1);
		if (imageScrollAlign) { // Account for scrollbar size
			w = Math.min(iw, _w - buttonOffsetY * 2);
			x += buttonOffsetY;
			if (!scroll) {
				w -= SCROLL_W() * r;
				x += SCROLL_W() * r / 2;
			}
		}
		else if (scroll) w += SCROLL_W() * r;

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
		var hover = getHover(h);
		if (curRatio == -1 && (started || down || released || hover)) {
			if (inputX < _windowX + _x || inputX > _windowX + _x + w) {
				started = down = released = hover = false;
			}
		}
		g.color = tint;
		if (!enabled) fadeColor();
		var h_float: Float = h; // TODO: hashlink fix
		if (sw > 0) { // Source rect specified
			imageInvertY ?
				g.drawScaledSubImage(image, sx, sy, sw, sh, x, _y + h_float, w, -h_float) :
				g.drawScaledSubImage(image, sx, sy, sw, sh, x, _y, w, h_float);
		}
		else {
			imageInvertY ?
				g.drawScaledImage(image, x, _y + h_float, w, -h_float) :
				g.drawScaledImage(image, x, _y, w, h_float);
		}

		endElement(h);
		return started ? State.Started : released ? State.Released : down ? State.Down : hover ? State.Hovered : State.Idle;
	}

	public function text(text: String, align = Align.Left, bg = 0x00000000): State {
		if (text.indexOf("\n") >= 0) { splitText(text, align, bg); return State.Idle; }
		var h = Math.max(ELEMENT_H(), ops.font.height(fontSize));
		if (!isVisible(h)) { endElement(h + ELEMENT_OFFSET()); return State.Idle; }
		var started = getStarted(h);
		var down = getPushed(h);
		var released = getReleased(h);
		var hover = getHover(h);
		if (bg != 0x0000000) {
			g.color = bg;
			g.fillRect(_x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());
		}
		g.color = t.TEXT_COL;
		drawString(g, text, TEXT_OFFSET(), 0, align);

		endElement(h + ELEMENT_OFFSET());
		return started ? State.Started : released ? State.Released : down ? State.Down : State.Idle;
	}

	inline function splitText(lines: String, align = Align.Left, bg = 0x00000000) {
		for (line in lines.split("\n")) text(line, align, bg);
	}

	function startTextEdit(handle: Handle) {
		isTyping = true;
		submitTextHandle = textSelectedHandle;
		textToSubmit = textSelected;
		textSelectedHandle = handle;
		textSelected = handle.text;
		cursorX = handle.text.length;
		if (tabPressed) {
			tabPressed = false;
			isKeyPressed = false; // Prevent text deselect after tab press
		}
		else if (!highlightOnSelect) { // Set cursor to click location
			var x = inputX - (_windowX + _x + TEXT_OFFSET());
			cursorX = 0;
			while (cursorX < textSelected.length && ops.font.width(fontSize, textSelected.substr(0, cursorX)) < x) {
				cursorX++;
			}
		}
		tabPressedHandle = handle;
		highlightAnchor = highlightOnSelect ? 0 : cursorX;
		if (Keyboard.get() != null) Keyboard.get().show();
	}

	function submitTextEdit() {
		submitTextHandle.text = textToSubmit;
		submitTextHandle.changed = changed = true;
		submitTextHandle = null;
		textToSubmit = "";
		textSelected = "";
	}

	function updateTextEdit(align = Align.Left, editable = true) {
		var text = textSelected;
		if (isKeyPressed) { // Process input
			if (key == KeyCode.Left) { // Move cursor
				if (cursorX > 0) cursorX--;
			}
			else if (key == KeyCode.Right) {
				if (cursorX < text.length) cursorX++;
			}
			else if (editable && key == KeyCode.Backspace) { // Remove char
				if (cursorX > 0 && highlightAnchor == cursorX) {
					text = text.substr(0, cursorX - 1) + text.substr(cursorX, text.length);
					cursorX--;
				}
				else if (highlightAnchor < cursorX) {
					text = text.substr(0, highlightAnchor) + text.substr(cursorX, text.length);
					cursorX = highlightAnchor;
				}
				else {
					text = text.substr(0, cursorX) + text.substr(highlightAnchor, text.length);
				}
			}
			else if (editable && key == KeyCode.Delete) {
				if (highlightAnchor == cursorX) {
					text = text.substr(0, cursorX) + text.substr(cursorX + 1);
				}
				else if (highlightAnchor < cursorX) {
					text = text.substr(0, highlightAnchor) + text.substr(cursorX, text.length);
					cursorX = highlightAnchor;
				}
				else {
					text = text.substr(0, cursorX) + text.substr(highlightAnchor, text.length);
				}
			}
			else if (key == KeyCode.Return) { // Deselect
				deselectText();
			}
			else if (key == KeyCode.Escape) { // Cancel
				textSelected = textSelectedHandle.text;
				deselectText();
			}
			else if (key == KeyCode.Tab && tabSwitchEnabled && !isCtrlDown) { // Next field
				tabPressed = true;
				deselectText();
				key = null;
			}
			else if (key == KeyCode.Home) {
				cursorX = 0;
			}
			else if (key == KeyCode.End) {
				cursorX = text.length;
			}
			else if (isCtrlDown && isADown) { // Select all
				cursorX = text.length;
				highlightAnchor = 0;
			}
			else if (editable && // Write
					 key != KeyCode.Shift &&
					 key != KeyCode.CapsLock &&
					 key != KeyCode.Control &&
					 key != KeyCode.Meta &&
					 key != KeyCode.Alt &&
					 key != KeyCode.Up &&
					 key != KeyCode.Down &&
					 char != null &&
					 char != "" &&
					 char.charCodeAt(0) >= 32) {
				text = text.substr(0, highlightAnchor) + char + text.substr(cursorX);
				cursorX = cursorX + 1 > text.length ? text.length : cursorX + 1;

				if (dynamicGlyphLoad && char.charCodeAt(0) > 126 && Graphics.fontGlyphs.indexOf(char.charCodeAt(0)) == -1) {
					Graphics.fontGlyphs.push(char.charCodeAt(0));
					Graphics.fontGlyphs = Graphics.fontGlyphs.copy(); // Trigger atlas update
				}
			}
			var selecting = isShiftDown && (key == KeyCode.Left || key == KeyCode.Right || key == KeyCode.Shift);
			if (!selecting && !isCtrlDown) highlightAnchor = cursorX;
		}

		if (textToPaste != "") { // Process cut copy paste
			text = text.substr(0, highlightAnchor) + textToPaste + text.substr(cursorX);
			cursorX += textToPaste.length;
			highlightAnchor = cursorX;
			textToPaste = "";
		}
		if (highlightAnchor == cursorX) textToCopy = text; // Copy
		else if (highlightAnchor < cursorX) textToCopy = text.substring(highlightAnchor, cursorX);
		else textToCopy = text.substring(cursorX, highlightAnchor);
		if (isCut) { // Cut
			if (highlightAnchor == cursorX) text = "";
			else if (highlightAnchor < cursorX) {
				text = text.substr(0, highlightAnchor) + text.substr(cursorX, text.length);
				cursorX = highlightAnchor;
			}
			else {
				text = text.substr(0, cursorX) + text.substr(highlightAnchor, text.length);
			}
		}

		var off = TEXT_OFFSET();
		var lineHeight = ELEMENT_H();
		var cursorHeight = lineHeight - buttonOffsetY * 3.0;
		// Draw highlight
		if (highlightAnchor != cursorX) {
			var istart = cursorX;
			var iend = highlightAnchor;
			if (highlightAnchor < cursorX) {
				istart = highlightAnchor;
				iend = cursorX;
			}
			var hlstr = text.substr(istart, iend - istart);
			var hlstrw = ops.font.width(fontSize, hlstr);
			var startoff = ops.font.width(fontSize, text.substr(0, istart));
			var hlStart = align == Align.Left ? _x + startoff + off : _x + _w - hlstrw - off;
			if (align == Align.Right) {
				hlStart -= ops.font.width(fontSize, text.substr(iend, text.length));
			}
			g.color = t.ACCENT_SELECT_COL;
			g.fillRect(hlStart, _y + buttonOffsetY * 1.5, hlstrw, cursorHeight);
		}

		// Flash cursor
		var time = kha.Scheduler.time();
		if (isKeyDown || time % (FLASH_SPEED() * 2.0) < FLASH_SPEED()) {
			var str = align == Align.Left ? text.substr(0, cursorX) : text.substring(cursorX, text.length);
			var strw = ops.font.width(fontSize, str);
			var cursorX = align == Align.Left ? _x + strw + off : _x + _w - strw - off;
			g.color = t.TEXT_COL; // Cursor
			g.fillRect(cursorX, _y + buttonOffsetY * 1.5, 1 * SCALE(), cursorHeight);
		}

		textSelected = text;
	}

	public function textInput(handle: Handle, label = "", align = Align.Left, editable = true): String {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.text; }

		var hover = getHover();
		if (hover && onTextHover != null) onTextHover();
		g.color = hover ? t.ACCENT_HOVER_COL : t.ACCENT_COL; // Text bg
		drawRect(g, t.FILL_ACCENT_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());

		var startEdit = getReleased() || tabPressed;
		if (textSelectedHandle != handle && startEdit) startTextEdit(handle);
		if (textSelectedHandle == handle) updateTextEdit(align, editable);
		if (submitTextHandle == handle) submitTextEdit();
		else handle.changed = false;

		if (label != "") {
			g.color = t.LABEL_COL; // Label
			var labelAlign = align == Align.Right ? Align.Left : Align.Right;
			var xOffset = labelAlign == Align.Left ? 7 : 0;
			drawString(g, label, xOffset, 0, labelAlign);
		}

		g.color = t.TEXT_COL; // Text
		textSelectedHandle != handle ? drawString(g, handle.text, null, 0, align) : drawString(g, textSelected, null, 0, align);

		endElement();
		return handle.text;
	}

	function deselectText() {
		if (textSelectedHandle == null) return;
		submitTextHandle = textSelectedHandle;
		textToSubmit = textSelected;
		textSelectedHandle = null;
		isTyping = false;
		if (currentWindow != null) currentWindow.redraws = 2;
		if (Keyboard.get() != null) Keyboard.get().hide();
		highlightAnchor = cursorX;
	}

	public function button(text: String, align = Align.Center, label = ""): Bool {
		if (!isVisible(ELEMENT_H())) { endElement(); return false; }
		var released = getReleased();
		var pushed = getPushed();
		var hover = getHover();
		if (released) changed = true;

		g.color = pushed ? t.BUTTON_PRESSED_COL :
				  hover ? t.BUTTON_HOVER_COL :
				  t.BUTTON_COL;

		drawRect(g, t.FILL_BUTTON_BG, _x + buttonOffsetY, _y + buttonOffsetY, _w - buttonOffsetY * 2, BUTTON_H());

		g.color = t.BUTTON_TEXT_COL;
		drawString(g, text, TEXT_OFFSET(), 0, align);
		if (label != "") {
			g.color = t.LABEL_COL;
			drawString(g, label, TEXT_OFFSET(), 0, align == Align.Right ? Align.Left : Align.Right);
		}

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
		drawString(g, text, titleOffsetX, 0, Align.Left);

		endElement();

		return handle.selected;
	}

	public function radio(handle: Handle, position: Int, text: String): Bool {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.position == position; }
		if (position == 0) handle.changed = false;
		if (getReleased()) {
			handle.position = position;
			handle.changed = changed = true;
		}

		var hover = getHover();
		drawRadio(handle.position == position, hover); // Radio

		g.color = t.TEXT_COL; // Text
		drawString(g, text, titleOffsetX, 0);

		endElement();

		return handle.position == position;
	}

	public function combo(handle: Handle, texts: Array<String>, label = "", showLabel = false, align = Align.Left, itemCount = -1 ): Int {
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
				comboSelectedY = Std.int(_y + _windowY + ELEMENT_H());
				comboSelectedW = Std.int(_w);
				comboItemCount = itemCount < 0 ? texts.length : itemCount;
				comboItemOffset = -1; // handle.position;
			}
		}
		if (handle == submitComboHandle) {
			handle.position = comboToSubmit;
			submitComboHandle = null;
			handle.changed = changed = true;
		}
		else handle.changed = false;

		if (inputWheelDelta != 0 && comboSelectedHandle != null) {
			comboItemOffset += inputWheelDelta > 0 ? 1 : -1;
			final maxOffset = comboSelectedTexts.length - comboItemCount;

			if (comboItemOffset > maxOffset) {
				comboItemOffset = maxOffset;
			}

			if (comboItemOffset < 0) {
				comboItemOffset = 0;
			}
		}

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

		if (showLabel && label != "") {
			if (align == Align.Left) _x -= 15;
			g.color = t.LABEL_COL;
			drawString(g, label, null, 0, align == Align.Left ? Align.Right : Align.Left);
			if (align == Align.Left) _x += 15;
		}

		if (align == Align.Right) _x -= 15;
		g.color = t.TEXT_COL; // Value
		if (handle.position < texts.length) {
			drawString(g, texts[handle.position], null, 0, align);
		}
		if (align == Align.Right) _x += 15;

		endElement();
		return handle.position;
	}

	public function slider(handle: Handle, text: String, from = 0.0, to = 1.0, filled = false, precision = 100.0, displayValue = true, align = Align.Right, textEdit = true): Float {
		if (!isVisible(ELEMENT_H())) { endElement(); return handle.value; }
		if (getStarted()) {
			scrollHandle = handle;
			isScrolling = true;
		}

		handle.changed = false;
		if (handle == scrollHandle) { // Scroll
			var range = to - from;
			var sliderX = _x + _windowX + buttonOffsetY;
			var sliderW = _w - buttonOffsetY * 2;
			var step = range / sliderW;
			var value = from + (inputX - sliderX) * step;
			handle.value = Math.round(value * precision) / precision;
			if (handle.value < from) handle.value = from; // Stay in bounds
			else if (handle.value > to) handle.value = to;
			handle.changed = changed = true;
		}

		var hover = getHover();
		drawSlider(handle.value, from, to, filled, hover); // Slider

		// Text edit
		var startEdit = (getReleased() || tabPressed) && textEdit;
		if (startEdit) { // Mouse did not move
			handle.text = handle.value + "";
			startTextEdit(handle);
			handle.changed = changed = true;
		}
		var lalign = align == Align.Left ? Align.Right : Align.Left;
		if (textSelectedHandle == handle) {
			updateTextEdit(lalign);
		}
		if (submitTextHandle == handle) {
			submitTextEdit();
			#if js
			handle.value = js.Lib.eval(handle.text);
			#else
			handle.value = Std.parseFloat(handle.text);
			#end
			handle.changed = changed = true;
		}

		g.color = t.LABEL_COL; // Text
		drawString(g, text, null, 0, align);

		if (displayValue) {
			g.color = t.TEXT_COL; // Value
			textSelectedHandle != handle ?
				drawString(g, (Math.round(handle.value * precision) / precision) + "", null, 0, lalign) :
				drawString(g, textSelected, null, 0, lalign);
		}

		endElement();
		return handle.value;
	}

	public function separator(h = 4, fill = true) {
		if (!isVisible(ELEMENT_H())) { _y += h * SCALE(); return; }
		if (fill) {
			g.color = t.SEPARATOR_COL;
			g.fillRect(_x, _y, _w, h * SCALE());
		}
		_y += h * SCALE();
	}

	public function tooltip(text: String) {
		tooltipText = text;
		tooltipY = _y + _windowY;
	}

	public function tooltipImage(image: kha.Image, maxWidth: Null<Int> = null) {
		tooltipImg = image;
		tooltipImgMaxWidth = maxWidth;
		tooltipInvertY = imageInvertY;
		tooltipY = _y + _windowY;
	}

	function drawArrow(selected: Bool) {
		var x = _x + arrowOffsetX;
		var y = _y + arrowOffsetY;
		g.color = t.TEXT_COL;
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
		var SIGN_W = 7 * SCALE();
		var x = _x + arrowOffsetX + 1;
		var y = _y + arrowOffsetY + 1;
		g.color = t.TEXT_COL;
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
			if (!enabled) fadeColor();
			var size = Std.int(CHECK_SELECT_SIZE());
			g.drawScaledImage(checkSelectImage, x + checkSelectOffsetX, y + checkSelectOffsetY, size, size);
		}
	}

	function drawRadio(selected: Bool, hover: Bool) {
		var x = _x + radioOffsetX;
		var y = _y + radioOffsetY;
		g.color = hover ? t.ACCENT_HOVER_COL : t.ACCENT_COL;
		drawRect(g, t.FILL_ACCENT_BG, x, y, CHECK_SIZE(), CHECK_SIZE()); // Bg

		if (selected) { // Check
			g.color = t.ACCENT_SELECT_COL;
			if (!enabled) fadeColor();
			g.fillRect(x + radioSelectOffsetX, y + radioSelectOffsetY, CHECK_SELECT_SIZE(), CHECK_SELECT_SIZE());
		}
	}

	function drawSlider(value: Float, from: Float, to: Float, filled: Bool, hover: Bool) {
		var x = _x + buttonOffsetY;
		var y = _y + buttonOffsetY;
		var w = _w - buttonOffsetY * 2;

		g.color = hover ? t.ACCENT_HOVER_COL : t.ACCENT_COL;
		drawRect(g, t.FILL_ACCENT_BG, x, y, w, BUTTON_H()); // Bg

		g.color = hover ? t.ACCENT_HOVER_COL : t.ACCENT_COL;
		var offset = (value - from) / (to - from);
		var barW = 8 * SCALE(); // Unfilled bar
		var sliderX = filled ? x : x + (w - barW) * offset;
		sliderX = Math.max(Math.min(sliderX, x + (w - barW)), x);
		var sliderW = filled ? w * offset : barW;
		sliderW = Math.max(Math.min(sliderW, w), 0);
		drawRect(g, true, sliderX, y, sliderW, BUTTON_H());
	}

	static inline function clampi(value: Int, min: Int, max: Int): Int {
		return value < min ? min : value > max ? max : value;
	}

	static var comboFirst = true;
	function drawCombo() {
		if (comboSelectedHandle == null) return;
		var _g = g;
		globalG.color = t.SEPARATOR_COL;
		var elementSize = Std.int(ELEMENT_H() + ELEMENT_OFFSET());
		final maxItemCount = Std.int(Math.min(comboSelectedTexts.length, comboItemCount));
		var comboH = (maxItemCount + 1) * elementSize;
		globalG.begin(false);
		var distTop = comboSelectedY - comboH - Std.int(ELEMENT_H());
		var distBottom = kha.System.windowHeight() - (comboSelectedY + comboH);
		var outOfScreen = distBottom < 0 && distBottom < distTop;
		var comboY = outOfScreen ? comboSelectedY - comboH - Std.int(ELEMENT_H()) : comboSelectedY;
		globalG.fillRect(comboSelectedX, comboY, comboSelectedW, comboH);
		beginRegion(globalG, comboSelectedX, comboY, comboSelectedW);

		// Move offset into visible range
		if (comboItemOffset == -1) {
			if (outOfScreen) {
				comboItemOffset = comboSelectedTexts.length - 1 - comboSelectedHandle.position;
			}
			else {
				comboItemOffset = comboSelectedHandle.position;
			}
			comboItemOffset = clampi(comboItemOffset, 0, comboSelectedTexts.length - maxItemCount);
		}

		if (outOfScreen) { // Unroll up
			g.color = t.LABEL_COL;
			drawString(g, comboSelectedLabel, null, 0, Align.Right);
			_y += elementSize;
			fill(0, 0, _w / SCALE(), 1 * SCALE(), t.ACCENT_SELECT_COL); // Separator
		}

		inputEnabled = true;
		var BUTTON_COL = t.BUTTON_COL;
		for (i in comboItemOffset...comboItemOffset + maxItemCount) {
			var j = outOfScreen ? comboSelectedTexts.length - 1 - i : i;
			t.BUTTON_COL = j == comboSelectedHandle.position ? t.ACCENT_SELECT_COL : t.SEPARATOR_COL;
			if (button(comboSelectedTexts[j], comboSelectedAlign)) {
				comboToSubmit = j;
				submitComboHandle = comboSelectedHandle;
				if (comboSelectedWindow != null) comboSelectedWindow.redraws = 2;
				break;
			}
		}
		t.BUTTON_COL = BUTTON_COL;

		if (!outOfScreen) { // Unroll down
			fill(0, 0, _w / SCALE(), 1 * SCALE(), t.ACCENT_SELECT_COL); // Separator
			g.color = t.LABEL_COL;
			drawString(g, comboSelectedLabel, null, 0, Align.Right);
		}

		final maxOffset = comboSelectedTexts.length - comboItemCount;
		if (maxOffset > 0) { // Scrollbar
			var barH = Math.max((comboItemCount / comboSelectedTexts.length) * ELEMENT_H() * 16, ELEMENT_H());
			var off = (comboH - barH - elementSize) * comboItemOffset / maxOffset;
			g.color = t.ACCENT_COL;
			g.fillRect((_x + _w) - SCROLL_W() / 3, comboY + off, SCROLL_W() / 3, barH);
		}

		if ((inputReleased || isEscapeDown) && !comboFirst) {
			comboSelectedHandle = null;
			comboFirst = true;
		}
		else comboFirst = false;
		inputEnabled = comboSelectedHandle == null;
		endRegion(false);
		globalG.end();
		g = _g; // Restore
	}

	function drawTooltip() {
		if (tooltipText != "" || tooltipImg != null) {
			if (inputChanged()) {
				tooltipShown = false;
				tooltipWait = inputDX == 0 && inputDY == 0; // Wait for movement before showing up again
			}
			if (!tooltipShown) {
				tooltipShown = true;
				tooltipX = inputX;
				tooltipTime = kha.Scheduler.time();
			}
			if (!tooltipWait && kha.Scheduler.time() - tooltipTime > TOOLTIP_DELAY()) {
				tooltipText != "" ? drawTooltipText() : drawTooltipImage();
			}
		}
		else tooltipShown = false;
	}

	function drawTooltipText() {
		globalG.color = t.TEXT_COL;
		var lines = tooltipText.split("\n");
		var tooltipW = 0.0;
		for (line in lines) {
			var lineTooltipW = ops.font.width(fontSize, line);
			if (lineTooltipW > tooltipW) tooltipW = lineTooltipW;
		}
		tooltipX = Math.min(tooltipX, kha.System.windowWidth() - tooltipW - 20);
		globalG.begin(false);
		globalG.fillRect(tooltipX, tooltipY, tooltipW + 20, ELEMENT_H() * lines.length * 0.6);
		globalG.font = ops.font;
		globalG.fontSize = fontSize;
		globalG.color = t.ACCENT_COL;
		for (i in 0...lines.length) {
			globalG.drawString(lines[i], tooltipX + 5, tooltipY + i * fontSize);
		}
		globalG.end();
	}

	function drawTooltipImage() {
		var w = tooltipImg.width;
		if (tooltipImgMaxWidth != null && w > tooltipImgMaxWidth) w = tooltipImgMaxWidth;
		var h = tooltipImg.height * (w / tooltipImg.width);
		tooltipX = Math.min(tooltipX, kha.System.windowWidth() - w - 20);
		tooltipY = Math.min(tooltipY, kha.System.windowHeight() - h - 20);
		globalG.color = 0xff000000;
		globalG.begin(false);
		globalG.fillRect(tooltipX, tooltipY, w, h);
		globalG.color = 0xffffffff;
		tooltipInvertY ?
			globalG.drawScaledImage(tooltipImg, tooltipX, tooltipY + h, w, -h) :
			globalG.drawScaledImage(tooltipImg, tooltipX, tooltipY, w, h);
		globalG.end();
	}

	function drawString(g: Graphics, text: String,
						xOffset: Null<Float> = null, yOffset: Float = 0, align = Align.Left) {
		var fullLength = text.length;
		while (text.length > 0 && ops.font.width(fontSize, text) > _w) {
			text = text.substr(0, text.length - 1);
		}
		if (text.length < fullLength) text += "..";

		if (xOffset == null) xOffset = t.TEXT_OFFSET;
		xOffset *= SCALE();
		g.font = ops.font;
		g.fontSize = fontSize;
		if (align == Align.Center) xOffset = _w / 2 - ops.font.width(fontSize, text) / 2;
		else if (align == Align.Right) xOffset = _w - ops.font.width(fontSize, text) - TEXT_OFFSET();

		if (!enabled) fadeColor();
		g.pipeline = rtTextPipeline;
		g.drawString(text, _x + xOffset, _y + fontOffsetY + yOffset);
		g.pipeline = null;
	}

	function endElement(elementSize: Null<Float> = null) {
		if (elementSize == null) elementSize = ELEMENT_H() + ELEMENT_OFFSET();
		if (currentWindow == null || currentWindow.layout == Vertical) {
			if (curRatio == -1 || (ratios != null && curRatio == ratios.length - 1)) { // New line
				_y += elementSize;

				if ((ratios != null && curRatio == ratios.length - 1)) { // Last row element
					curRatio = -1;
					ratios = null;
					_x = xBeforeSplit;
					_w = wBeforeSplit;
					highlightFullRow = false;
				}
			}
			else { // Row
				curRatio++;
				_x += _w; // More row elements to place
				_w = Std.int(getRatio(ratios[curRatio], wBeforeSplit));
			}
		}
		else { // Horizontal
			_x += _w + ELEMENT_OFFSET();
		}
	}

	/**
	 * Highlight all upcoming elements in the next row on a `mouse-over` event.
	 */
	public inline function highlightNextRow() {
		highlightFullRow = true;
	}

	inline function getRatio(ratio: Float, dyn: Float): Float {
		return ratio < 0 ? -ratio : ratio * dyn;
	}

	/**
	 * Draw the upcoming elements in the same row.
	 *
	 * Negative values will be treated as absolute, positive values as ratio to `window width`.
	 */
	public function row(ratios: Array<Float>) {
		this.ratios = ratios;
		curRatio = 0;
		xBeforeSplit = _x;
		wBeforeSplit = _w;
		_w = Std.int(getRatio(ratios[curRatio], _w));
	}

	public function indent(bothSides = true) {
		_x += TAB_W();
		_w -= TAB_W();

		if (bothSides) _w -= TAB_W();
	}

	public function unindent(bothSides = true) {
		_x -= TAB_W();
		_w += TAB_W();

		if (bothSides) _w += TAB_W();
	}

	function fadeColor() {
		g.color = kha.Color.fromFloats(g.color.R, g.color.G, g.color.B, 0.25);
	}

	public function fill(x: Float, y: Float, w: Float, h: Float, color: kha.Color) {
		g.color = color;
		if (!enabled) fadeColor();
		g.fillRect(_x + x * SCALE(), _y + y * SCALE() - 1, w * SCALE(), h * SCALE());
		g.color = 0xffffffff;
	}

	public function rect(x: Float, y: Float, w: Float, h: Float, color: kha.Color, strength = 1.0) {
		g.color = color;
		if (!enabled) fadeColor();
		g.drawRect(_x + x * SCALE(), _y + y * SCALE(), w * SCALE(), h * SCALE(), strength);
		g.color = 0xffffffff;
	}

	inline function drawRect(g: Graphics, fill: Bool, x: Float, y: Float, w: Float, h: Float, strength = 0.0) {
		if (strength == 0.0) strength = 1;
		if (!enabled) fadeColor();
		fill ? g.fillRect(x, y - 1, w, h + 1) : g.drawRect(x, y, w, h, strength);
	}

	function isVisible(elemH: Float): Bool {
		if (currentWindow == null) return true;
		return (_y + elemH > windowHeaderH && _y < currentWindow.texture.height);
	}

	function getReleased(elemH = -1.0): Bool { // Input selection
		isReleased = enabled && inputEnabled && inputReleased && getHover(elemH) && getInitialHover(elemH);
		return isReleased;
	}

	function getPushed(elemH = -1.0): Bool {
		isPushed = enabled && inputEnabled && inputDown && getHover(elemH) && getInitialHover(elemH);
		return isPushed;
	}

	function getStarted(elemH = -1.0): Bool {
		isStarted = enabled && inputEnabled && inputStarted && getHover(elemH);
		return isStarted;
	}

	function getInitialHover(elemH = -1.0): Bool {
		if (scissor && inputY < _windowY + windowHeaderH) return false;
		if (elemH == -1.0) elemH = ELEMENT_H();
		return enabled && inputEnabled &&
			inputStartedX >= _windowX + _x && inputStartedX < (_windowX + _x + _w) &&
			inputStartedY >= _windowY + _y && inputStartedY < (_windowY + _y + elemH);
	}

	function getHover(elemH = -1.0): Bool {
		if (scissor && inputY < _windowY + windowHeaderH) return false;
		if (elemH == -1.0) elemH = ELEMENT_H();
		isHovered = enabled && inputEnabled &&
			inputX >= _windowX + (highlightFullRow ? 0 : _x) && inputX < (_windowX + _x + (highlightFullRow ? _windowW : _w)) &&
			inputY >= _windowY + _y && inputY < (_windowY + _y + elemH);
		return isHovered;
	}

	function getInputInRect(x: Float, y: Float, w: Float, h: Float, scale = 1.0): Bool {
		return enabled && inputEnabled &&
			inputX >= x * scale && inputX < (x + w) * scale &&
			inputY >= y * scale && inputY < (y + h) * scale;
	}

	public function onMouseDown(button: Int, x: Int, y: Int) { // Input events
		button == 0 ? inputStarted = true : inputStartedR = true;
		button == 0 ? inputDown = true : inputDownR = true;
		inputStartedTime = kha.Scheduler.time();
		setInputPosition(x, y);
		inputStartedX = x;
		inputStartedY = y;
	}

	public function onMouseUp(button: Int, x: Int, y: Int) {
		if (isScrolling) { // Prevent action when scrolling is active
			isScrolling = false;
			scrollHandle = null;
			if (x == inputStartedX && y == inputStartedY) { // Mouse not moved
				button == 0 ? inputReleased = true : inputReleasedR = true;
			}
		}
		else {
			button == 0 ? inputReleased = true : inputReleasedR = true;
		}
		button == 0 ? inputDown = false : inputDownR = false;
		setInputPosition(x, y);
		deselectText();
		if (touchHold) {
			touchHold = false;
			inputReleased = false;
			inputReleasedR = true;
		}
	}

	public function onMouseMove(x: Int, y: Int, movementX: Int, movementY: Int) {
		#if (!kha_android && !kha_ios)
		setInputPosition(x, y);
		#end
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

	public function onKeyDown(code: KeyCode) {
		this.key = code;
		isKeyPressed = true;
		isKeyDown = true;
		keyRepeatTime = kha.Scheduler.time() + 0.4;
		switch code {
		case KeyCode.Shift: isShiftDown = true;
		case KeyCode.Control: isCtrlDown = true;
		#if kha_darwin
		case KeyCode.Meta: isCtrlDown = true;
		#end
		case KeyCode.Alt: isAltDown = true;
		case KeyCode.Backspace: isBackspaceDown = true;
		case KeyCode.Delete: isDeleteDown = true;
		case KeyCode.Escape: isEscapeDown = true;
		case KeyCode.Return: isReturnDown = true;
		case KeyCode.Tab: isTabDown = true;
		case KeyCode.A: isADown = true;
		case KeyCode.Space: char = " ";
		#if kha_android_rmb // Detect right mouse button on Android..
		case KeyCode.Back: if (!inputDownR) onMouseDown(1, Std.int(inputX), Std.int(inputY));
		#end
		default:
		}
	}

	public function onKeyUp(code: KeyCode) {
		isKeyDown = false;
		switch code {
		case KeyCode.Shift: isShiftDown = false;
		case KeyCode.Control: isCtrlDown = false;
		#if kha_darwin
		case KeyCode.Meta: isCtrlDown = false;
		#end
		case KeyCode.Alt: isAltDown = false;
		case KeyCode.Backspace: isBackspaceDown = false;
		case KeyCode.Delete: isDeleteDown = false;
		case KeyCode.Escape: isEscapeDown = false;
		case KeyCode.Return: isReturnDown = false;
		case KeyCode.Tab: isTabDown = false;
		case KeyCode.A: isADown = false;
		#if kha_android_rmb
		case KeyCode.Back: onMouseUp(1, Std.int(inputX), Std.int(inputY));
		#end
		default:
		}
	}

	public function onKeyPress(char: String) {
		this.char = char;
		isKeyPressed = true;
	}

	#if (kha_android || kha_ios)
	public function onTouchDown(index: Int, x: Int, y: Int) {
		// Reset movement delta on touch start
		if (index == 0) { inputDX = 0; inputDY = 0; inputX = x; inputY = y; }
		// Two fingers down - right mouse button
		if (index == 1) {
			onMouseUp(0, Std.int(inputX), Std.int(inputY));
			onMouseDown(1, Std.int(inputX), Std.int(inputY));
		}
	}

	public function onTouchUp(index: Int, x: Int, y: Int) {
		if (index == 1) { onMouseUp(1, Std.int(inputX), Std.int(inputY)); }
	}

	public function onTouchMove(index: Int, x: Int, y: Int) {
		if (index == 0) setInputPosition(x, y);
	}
	#end

	public function onCut(): String { isCut = true; return onCopy(); }
	public function onCopy(): String { isCopy = true; return textToCopy; }
	public function onPaste(s: String) { isPaste = true; textToPaste = s; }

	public inline function ELEMENT_W(): Float { return t.ELEMENT_W * SCALE(); }
	public inline function ELEMENT_H(): Float { return t.ELEMENT_H * SCALE(); }
	public inline function ELEMENT_OFFSET(): Float { return t.ELEMENT_OFFSET * SCALE(); }
	public inline function ARROW_SIZE(): Float { return t.ARROW_SIZE * SCALE(); }
	public inline function BUTTON_H(): Float { return t.BUTTON_H * SCALE(); }
	public inline function CHECK_SIZE(): Float { return t.CHECK_SIZE * SCALE(); }
	public inline function CHECK_SELECT_SIZE(): Float { return t.CHECK_SELECT_SIZE * SCALE(); }
	public inline function FONT_SIZE(): Int { return Std.int(t.FONT_SIZE * SCALE()); }
	public inline function SCROLL_W(): Int { return Std.int(t.SCROLL_W * SCALE()); }
	public inline function TEXT_OFFSET(): Float { return t.TEXT_OFFSET * SCALE(); }
	public inline function TAB_W(): Int { return Std.int(t.TAB_W * SCALE()); }
	public inline function HEADER_DRAG_H(): Int { return Std.int(15 * SCALE()); }
	public inline function SCALE(): Float { return ops.scaleFactor; }
	inline function FLASH_SPEED(): Float { return 0.5; }
	inline function TOOLTIP_DELAY(): Float { return 1.0; }

	public function resize(handle: Handle, w: Int, h: Int, khaWindowId = 0) {
		handle.redraws = 2;
		if (handle.texture != null) handle.texture.unload();
		if (w < 1) w = 1;
		if (h < 1) h = 1;
		handle.texture = kha.Image.createRenderTarget(w, h, kha.graphics4.TextureFormat.RGBA32, kha.graphics4.DepthStencilFormat.NoDepthAndStencil, 1, khaWindowId);
		handle.texture.g2.imageScaleQuality = kha.graphics2.ImageScaleQuality.High;
		// handle.texture.g2.mipmapScaleQuality = kha.graphics2.ImageScaleQuality.High;
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
	public var scrollOffset = 0.0;
	public var scrollEnabled = false;
	public var layout: Layout = 0;
	public var lastMaxX = 0.0;
	public var lastMaxY = 0.0;
	public var dragEnabled = false;
	public var dragX = 0;
	public var dragY = 0;
	public var changed = false;
	var children: Map<Int, Handle>;

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
		var c = children.get(i);
		if (c == null) {
			c = new Handle(ops);
			children.set(i, c);
		}
		return c;
	}

	public function unnest(i: Int) {
		if (children != null) {
			children.remove(i);
		}
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
	var Hovered = 4;
}
