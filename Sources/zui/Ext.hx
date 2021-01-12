package zui;

import zui.Zui;
import zui.Popup;
import kha.input.Keyboard;
import kha.input.KeyCode;

typedef ListOpts = {
	?addCb: String->Void,
	?removeCb: Int->Void,
	?getNameCb: Int->String,
	?setNameCb: Int->String->Void,
	?getLabelCb: Int->String,
	?itemDrawCb: Handle->Int->Void,
	?showRadio: Bool, // false
	?editable: Bool, // true
	?showAdd: Bool, // true
	?addLabel: String // 'Add'
}

@:access(zui.Zui)
class Ext {

	public static function floatInput(ui: Zui, handle: Handle, label = "", align: Align = Left, precision = 1000.0): Float {
		handle.text = Std.string(Math.round(handle.value * precision) / precision);
		var text = ui.textInput(handle, label, align);
		handle.value = Std.parseFloat(text);
		return handle.value;
	}

	public static function keyInput(ui: Zui, handle: Handle, label = "", align: Align = Left): Int {
		if (!ui.isVisible(ui.ELEMENT_H())) { ui.endElement(); return Std.int(handle.value); }

		var hover = ui.getHover();
		if (hover && Zui.onTextHover != null) Zui.onTextHover();
		ui.g.color = hover ? ui.t.ACCENT_HOVER_COL : ui.t.ACCENT_COL; // Text bg
		ui.drawRect(ui.g, ui.t.FILL_ACCENT_BG, ui._x + ui.buttonOffsetY, ui._y + ui.buttonOffsetY, ui._w - ui.buttonOffsetY * 2, ui.BUTTON_H());

		var startEdit = ui.getReleased() || ui.tabPressed;
		if (ui.textSelectedHandle != handle && startEdit) ui.startTextEdit(handle);
		if (ui.textSelectedHandle == handle) Ext.listenToKey(ui, handle);
		else handle.changed = false;

		if (label != "") {
			ui.g.color = ui.t.LABEL_COL; // Label
			var labelAlign = align == Align.Right ? Align.Left : Align.Right;
			var xOffset = labelAlign == Align.Left ? 7 : 0;
			ui.drawString(ui.g, label, xOffset, 0, labelAlign);
		}

		handle.text = Ext.keycodeToString(Std.int(handle.value));

		ui.g.color = ui.t.TEXT_COL; // Text
		ui.textSelectedHandle != handle ? ui.drawString(ui.g, handle.text, null, 0, align) : ui.drawString(ui.g, ui.textSelected, null, 0, align);

		ui.endElement();

		return Std.int(handle.value);
	}

	static function listenToKey(ui: Zui, handle: Handle) {
		if (ui.isKeyDown) {
			handle.value = ui.key;
			handle.changed = ui.changed = true;

			ui.textSelectedHandle = null;
			ui.isTyping = false;

			if (Keyboard.get() != null) Keyboard.get().hide();
		}
		else {
			ui.textSelected = "Press a key...";
		}
	}

	public static function list(ui: Zui, handle: Handle, ar: Array<Dynamic>, ?opts: ListOpts ): Int {
		var selected = 0;
		if (opts == null) opts = {};

		var addCb = opts.addCb != null ? opts.addCb : function(name: String) ar.push(name);
		var removeCb = opts.removeCb != null ? opts.removeCb : function(i: Int) ar.splice(i, 1);
		var getNameCb = opts.getNameCb != null ? opts.getNameCb : function(i: Int) return ar[i];
		var setNameCb = opts.setNameCb != null ? opts.setNameCb : function(i: Int, name: String) ar[i] = name;
		var getLabelCb = opts.getLabelCb != null ? opts.getLabelCb : function(i: Int) return "";
		var itemDrawCb = opts.itemDrawCb;
		var showRadio = opts.showRadio != null ? opts.showRadio : false;
		var editable = opts.editable != null ? opts.editable : true;
		var showAdd = opts.showAdd != null ? opts.showAdd : true;
		var addLabel = opts.addLabel != null ? opts.addLabel : "Add";

		var i = 0;
		while (i < ar.length) {
			if (showRadio) { // Prepend ratio button
				ui.row([0.12, 0.68, 0.2]);
				if (ui.radio(handle.nest(0), i, "")) {
					selected = i;
				}
			}
			else ui.row([0.8, 0.2]);

			var itemHandle = handle.nest(i);
			itemHandle.text = getNameCb(i);
			editable ? setNameCb(i, ui.textInput(itemHandle, getLabelCb(i))) : ui.text(getNameCb(i));
			if (ui.button("X")) removeCb(i);
			else i++;

			if (itemDrawCb != null) itemDrawCb(itemHandle.nest(i), i - 1);
		}
		if (showAdd && ui.button(addLabel)) addCb("untitled");

		return selected;
	}

	public static function panelList(ui: Zui, handle: Handle, ar: Array<Dynamic>,
									 addCb: String->Void = null,
									 removeCb: Int->Void = null,
									 getNameCb: Int->String = null,
									 setNameCb: Int->String->Void = null,
									 itemDrawCb: Handle->Int->Void = null,
									 editable = true,
									 showAdd = true,
									 addLabel: String = "Add") {

		if (addCb == null) addCb = function(name: String) { ar.push(name); };
		if (removeCb == null) removeCb = function(i: Int) { ar.splice(i, 1); };
		if (getNameCb == null) getNameCb = function(i: Int) { return ar[i]; };
		if (setNameCb == null) setNameCb = function(i: Int, name: String) { ar[i] = name; };

		var i = 0;
		while (i < ar.length) {
			ui.row([0.12, 0.68, 0.2]);
			var expanded = ui.panel(handle.nest(i), "");

			var itemHandle = handle.nest(i);
			editable ? setNameCb(i, ui.textInput(itemHandle, getNameCb(i))) : ui.text(getNameCb(i));
			if (ui.button("X")) removeCb(i);
			else i++;

			if (itemDrawCb != null && expanded) itemDrawCb(itemHandle.nest(i), i - 1);
		}
		if (showAdd && ui.button(addLabel)) {
			addCb("untitled");
		}
	}

	public static function colorField(ui: Zui, handle:Handle, alpha = false): Int {
		ui.g.color = handle.color;

		ui.drawRect(ui.g, true, ui._x + 2, ui._y + ui.buttonOffsetY, ui._w - 4, ui.BUTTON_H());
		ui.g.color = ui.getHover() ? ui.t.ACCENT_HOVER_COL : ui.t.ACCENT_COL;
		ui.drawRect(ui.g, false, ui._x + 2, ui._y + ui.buttonOffsetY, ui._w - 4, ui.BUTTON_H(), 1.0);

		if (ui.getStarted()) {
			Popup.showCustom(
				new Zui(ui.ops),
				function(ui:Zui) {
					colorWheel(ui, handle, alpha);
				},
				Std.int(ui.inputX), Std.int(ui.inputY), 200, 500);
		}

		ui.endElement();
		return handle.color;
	}

	public static function colorPicker(ui: Zui, handle: Handle, alpha = false): Int {
		var r = ui.slider(handle.nest(0, {value: handle.color.R}), "R", 0, 1, true);
		var g = ui.slider(handle.nest(1, {value: handle.color.G}), "G", 0, 1, true);
		var b = ui.slider(handle.nest(2, {value: handle.color.B}), "B", 0, 1, true);
		var a = handle.color.A;
		if (alpha) a = ui.slider(handle.nest(3, {value: a}), "A", 0, 1, true);
		var col = kha.Color.fromFloats(r, g, b, a);
		ui.text("", Right, col);
		return col;
	}

	static function initPath(handle: Handle, systemId: String) {
		handle.text = systemId == "Windows" ? "C:\\Users" : "/";
		// %HOMEDRIVE% + %HomePath%
		// ~
	}

	public static var dataPath = "";
	static var lastPath = "";
	public static function fileBrowser(ui: Zui, handle: Handle, foldersOnly = false): String {
		var sep = "/";

		#if kha_krom

		var cmd = "ls ";
		var systemId = kha.System.systemId;
		if (systemId == "Windows") {
			cmd = "dir /b ";
			if (foldersOnly) cmd += "/ad ";
			sep = "\\";
			handle.text = StringTools.replace(handle.text, "\\\\", "\\");
			handle.text = StringTools.replace(handle.text, "\r", "");
		}
		if (handle.text == "") initPath(handle, systemId);

		var save = Krom.getFilesLocation() + sep + dataPath + "dir.txt";
		if (handle.text != lastPath) Krom.sysCommand(cmd + '"' + handle.text + '"' + " > " + '"' + save + '"');
		lastPath = handle.text;
		var str = haxe.io.Bytes.ofData(Krom.loadBlob(save)).toString();
		var files = str.split("\n");

		#elseif kha_kore

		if (handle.text == "") initPath(handle, kha.System.systemId);
		var files = sys.FileSystem.isDirectory(handle.text) ? sys.FileSystem.readDirectory(handle.text) : [];

		#elseif kha_webgl

		var files: Array<String> = [];

		var userAgent = untyped navigator.userAgent.toLowerCase();
		if (userAgent.indexOf(" electron/") > -1) {
			if (handle.text == "") {
				var pp = untyped window.process.platform;
				var systemId = pp == "win32" ? "Windows" : (pp == "darwin" ? "OSX" : "Linux");
				initPath(handle, systemId);
			}
			try {
				files = untyped require("fs").readdirSync(handle.text);
			}
			catch (e: Dynamic) {
				// Non-directory item selected
			}
		}

		#else

		var files: Array<String> = [];

		#end

		// Up directory
		var i1 = handle.text.indexOf("/");
		var i2 = handle.text.indexOf("\\");
		var nested =
			(i1 > -1 && handle.text.length - 1 > i1) ||
			(i2 > -1 && handle.text.length - 1 > i2);
		handle.changed = false;
		if (nested && ui.button("..", Align.Left)) {
			handle.changed = ui.changed = true;
			handle.text = handle.text.substring(0, handle.text.lastIndexOf(sep));
			// Drive root
			if (handle.text.length == 2 && handle.text.charAt(1) == ":") handle.text += sep;
		}

		// Directory contents
		for (f in files) {
			if (f == "" || f.charAt(0) == ".") continue; // Skip hidden
			if (ui.button(f, Align.Left)) {
				handle.changed = ui.changed = true;
				if (handle.text.charAt(handle.text.length - 1) != sep) handle.text += sep;
				handle.text += f;
			}
		}

		return handle.text;
	}

	public static function inlineRadio(ui: Zui, handle: Handle, texts: Array<String>, align: Align = Center): Int {
		if (!ui.isVisible(ui.ELEMENT_H())) { ui.endElement(); return handle.position; }
		var step = ui._w / texts.length;
		var hovered = -1;
		if (ui.getHover()) {
			var ix = Std.int(ui.inputX - ui._x - ui._windowX);
			for (i in 0...texts.length) if (ix < i * step + step) { hovered = i; break; }
		}
		if (ui.getReleased()) {
			handle.position = hovered;
			handle.changed = ui.changed = true;
		}
		else handle.changed = false;

		for (i in 0...texts.length) {
			if (handle.position == i) {
				ui.g.color = ui.t.ACCENT_HOVER_COL;
				if (!ui.enabled) ui.fadeColor();
				ui.g.fillRect(ui._x + step * i, ui._y + ui.buttonOffsetY, step, ui.BUTTON_H());
			}
			else if (hovered == i) {
				ui.g.color = ui.t.ACCENT_COL;
				if (!ui.enabled) ui.fadeColor();
				ui.g.drawRect(ui._x + step * i, ui._y + ui.buttonOffsetY, step, ui.BUTTON_H());
			}
			ui.g.color = ui.t.TEXT_COL; // Text
			ui.drawString(ui.g, texts[i], ui.TEXT_OFFSET() + (step * i) / ui.SCALE(), 0, Align.Left);
		}
		ui.endElement();
		return handle.position;
	}

	static var wheelSelectedHande: Handle = null;
	public static function colorWheel(ui: Zui, handle: Handle, alpha = false, w: Null<Float> = null, colorPreview = true): kha.Color {
		if (w == null) w = ui._w;
		rgbToHsv(handle.color.R, handle.color.G, handle.color.B, ar);
		var chue = ar[0];
		var csat = ar[1];
		var cval = ar[2];
		var calpha = handle.color.A;
		// Wheel
		var px = ui._x;
		var py = ui._y;
		var scroll = ui.currentWindow != null ? ui.currentWindow.scrollEnabled : false;
		if (!scroll) { w -= ui.SCROLL_W(); px += ui.SCROLL_W() / 2; }
		ui.image(ui.ops.color_wheel, kha.Color.fromFloats(cval, cval, cval));
		// Picker
		var ph = ui._y - py;
		var ox = px + w / 2;
		var oy = py + ph / 2;
		var cw = w * 0.7;
		var cwh = cw / 2;
		var cx = ox;
		var cy = oy + csat * cwh; // Sat is distance from center
		// Rotate around origin by hue
		var theta = chue * (Math.PI * 2.0);
		var cx2 = Math.cos(theta) * (cx - ox) - Math.sin(theta) * (cy - oy) + ox;
		var cy2 = Math.sin(theta) * (cx - ox) + Math.cos(theta) * (cy - oy) + oy;
		cx = cx2;
		cy = cy2;

		ui.g.color = 0xff000000;
		ui.g.fillRect(cx - 3 * ui.SCALE(), cy - 3 * ui.SCALE(), 6 * ui.SCALE(), 6 * ui.SCALE());
		ui.g.color = 0xffffffff;
		ui.g.fillRect(cx - 2 * ui.SCALE(), cy - 2 * ui.SCALE(), 4 * ui.SCALE(), 4 * ui.SCALE());

		if (alpha) {
			var alphaHandle = handle.nest(1, {value: Math.round(calpha * 100) / 100});
			calpha = ui.slider(alphaHandle, "Alpha", 0.0, 1.0, true);
			if (alphaHandle.changed) handle.changed = ui.changed = true;
		}
		// Mouse picking
		var gx = ox + ui._windowX;
		var gy = oy + ui._windowY;
		if (ui.inputStarted && ui.getInputInRect(gx - cwh, gy - cwh, cw, cw)) wheelSelectedHande = handle;
		if (ui.inputReleased) wheelSelectedHande = null;
		if (ui.inputDown && wheelSelectedHande == handle) {
			csat = Math.min(dist(gx, gy, ui.inputX, ui.inputY), cwh) / cwh;
			var angle = Math.atan2(ui.inputX - gx, ui.inputY - gy);
			if (angle < 0) angle = Math.PI + (Math.PI - Math.abs(angle));
			angle = Math.PI * 2 - angle;
			chue = angle / (Math.PI * 2);
			handle.changed = ui.changed = true;
		}
		// Save as rgb
		hsvToRgb(chue, csat, cval, ar);
		handle.color = kha.Color.fromFloats(ar[0], ar[1], ar[2], calpha);

		if (colorPreview) ui.text("", Right, handle.color);

		var pos = Ext.inlineRadio(ui, Id.handle(), ["RGB", "HSV", "Hex"]);
		var h0 = handle.nest(0).nest(0);
		var h1 = handle.nest(0).nest(1);
		var h2 = handle.nest(0).nest(2);
		if (pos == 0) {
			h0.value = handle.color.R;

			handle.color.R = ui.slider(h0, "R", 0, 1, true);
			h1.value = handle.color.G;

			handle.color.G = ui.slider(h1, "G", 0, 1, true);
			h2.value = handle.color.B;
			handle.color.B = ui.slider(h2, "B", 0, 1, true);
		}
		else if (pos == 1) {
			rgbToHsv(handle.color.R, handle.color.G, handle.color.B, ar);
			h0.value = ar[0];
			h1.value = ar[1];
			h2.value = ar[2];
			var chue = ui.slider(h0, "H", 0, 1, true);
			var csat = ui.slider(h1, "S", 0, 1, true);
			var cval = ui.slider(h2, "V", 0, 1, true);
			hsvToRgb(chue, csat, cval, ar);
			handle.color = kha.Color.fromFloats(ar[0], ar[1], ar[2]);
		}
		else if (pos == 2) {
			#if js
			handle.text = untyped (handle.color >>> 0).toString(16);
			handle.color = untyped parseInt(ui.textInput(handle, "#"), 16);
			#end
		}
		if (h0.changed || h1.changed || h2.changed) handle.changed = ui.changed = true;
		return handle.color;
	}

	public static function textArea(ui: Zui, handle: Handle, align = Align.Left, editable = true): String {
		handle.text = StringTools.replace(handle.text, "\t", "    ");
		var lines = handle.text.split("\n");
		var selected = ui.textSelectedHandle == handle; // Text being edited
		var cursorStartX = ui.cursorX;
		var keyPressed = selected && ui.isKeyPressed;
		ui.highlightOnSelect = false;
		ui.tabSwitchEnabled = false;
		ui.g.color = ui.t.SEPARATOR_COL;
		ui.drawRect(ui.g, true, ui._x + ui.buttonOffsetY, ui._y + ui.buttonOffsetY, ui._w - ui.buttonOffsetY * 2, lines.length * ui.ELEMENT_H() - ui.buttonOffsetY * 2);

		for (i in 0...lines.length) { // Draw lines
			if ((!selected && ui.getHover()) || (selected && i == handle.position)) {
				handle.position = i; // Set active line
				handle.text = lines[i];
				ui.textInput(handle, "", align, editable);
				if (keyPressed && ui.key != KeyCode.Return) { // Edit text
					lines[i] = ui.textSelected;
				}
			}
			else {
				ui.text(lines[i], align);
			}
			ui._y -= ui.ELEMENT_OFFSET();
		}
		ui._y += ui.ELEMENT_OFFSET();

		if (keyPressed) {
			// Move cursor vertically
			if (ui.key == KeyCode.Down && handle.position < lines.length - 1) { handle.position++; }
			if (ui.key == KeyCode.Up && handle.position > 0) { handle.position--; }
			// New line
			if (editable && ui.key == KeyCode.Return) {
				handle.position++;
				lines.insert(handle.position, lines[handle.position - 1].substr(ui.cursorX));
				lines[handle.position - 1] = lines[handle.position - 1].substr(0, ui.cursorX);
				ui.startTextEdit(handle);
				ui.cursorX = ui.highlightAnchor = 0;
			}
			// Delete line
			if (editable && ui.key == KeyCode.Backspace && cursorStartX == 0 && handle.position > 0) {
				handle.position--;
				ui.cursorX = ui.highlightAnchor = lines[handle.position].length;
				lines[handle.position] += lines[handle.position + 1];
				lines.splice(handle.position + 1, 1);
			}
			ui.textSelected = lines[handle.position];
		}

		ui.highlightOnSelect = true;
		ui.tabSwitchEnabled = true;
		handle.text = lines.join("\n");
		return handle.text;
	}

	static var _ELEMENT_OFFSET = 0;
	static var _BUTTON_COL = 0;
	public static function beginMenu(ui: Zui) {
		_ELEMENT_OFFSET = ui.t.ELEMENT_OFFSET;
		_BUTTON_COL = ui.t.BUTTON_COL;
		ui.t.ELEMENT_OFFSET = 0;
		ui.t.BUTTON_COL = ui.t.SEPARATOR_COL;
		ui.g.color = ui.t.SEPARATOR_COL;
		ui.g.fillRect(0, 0, ui._windowW, MENUBAR_H(ui));
	}

	public static function endMenu(ui: Zui) {
		ui.t.ELEMENT_OFFSET = _ELEMENT_OFFSET;
		ui.t.BUTTON_COL = _BUTTON_COL;
	}

	public static function menuButton(ui: Zui, text: String): Bool {
		ui._w = Std.int(ui.ops.font.width(ui.fontSize, text) + 25 * ui.SCALE());
		return ui.button(text);
	}

	public static inline function MENUBAR_H(ui: Zui): Float {
		return ui.BUTTON_H() * 1.1 + 2 + ui.buttonOffsetY;
	}

	/**
	Keycodes can be found here: http://api.kha.tech/kha/input/KeyCode.html
	**/
	static function keycodeToString(keycode: Int): String {
		switch (keycode) {
			case -1: return "None";
			case KeyCode.Unknown: return "Unknown";
			case KeyCode.Back: return "Back";
			case KeyCode.Cancel: return "Cancel";
			case KeyCode.Help: return "Help";
			case KeyCode.Backspace: return "Backspace";
			case KeyCode.Tab: return "Tab";
			case KeyCode.Clear: return "Clear";
			case KeyCode.Return: return "Return";
			case KeyCode.Shift: return "Shift";
			case KeyCode.Control: return "Ctrl";
			case KeyCode.Alt: return "Alt";
			case KeyCode.Pause: return "Pause";
			case KeyCode.CapsLock: return "CapsLock";
			case KeyCode.Kana: return "Kana";
			// case KeyCode.Hangul: return "Hangul"; // Hangul == Kana
			case KeyCode.Eisu: return "Eisu";
			case KeyCode.Junja: return "Junja";
			case KeyCode.Final: return "Final";
			case KeyCode.Hanja: return "Hanja";
			// case KeyCode.Kanji: return "Kanji"; // Kanji == Hanja
			case KeyCode.Escape: return "Esc";
			case KeyCode.Convert: return "Convert";
			case KeyCode.NonConvert: return "NonConvert";
			case KeyCode.Accept: return "Accept";
			case KeyCode.ModeChange: return "ModeChange";
			case KeyCode.Space: return "Space";
			case KeyCode.PageUp: return "PageUp";
			case KeyCode.PageDown: return "PageDown";
			case KeyCode.End: return "End";
			case KeyCode.Home: return "Home";
			case KeyCode.Left: return "Left";
			case KeyCode.Up: return "Up";
			case KeyCode.Right: return "Right";
			case KeyCode.Down: return "Down";
			case KeyCode.Select: return "Select";
			case KeyCode.Print: return "Print";
			case KeyCode.Execute: return "Execute";
			case KeyCode.PrintScreen: return "PrintScreen";
			case KeyCode.Insert: return "Insert";
			case KeyCode.Delete: return "Delete";
			case KeyCode.Colon: return "Colon";
			case KeyCode.Semicolon: return "Semicolon";
			case KeyCode.LessThan: return "LessThan";
			case KeyCode.Equals: return "Equals";
			case KeyCode.GreaterThan: return "GreaterThan";
			case KeyCode.QuestionMark: return "QuestionMark";
			case KeyCode.At: return "At";
			case KeyCode.Win: return "Win";
			case KeyCode.ContextMenu: return "ContextMenu";
			case KeyCode.Sleep: return "Sleep";
			case KeyCode.Numpad0: return "Numpad0";
			case KeyCode.Numpad1: return "Numpad1";
			case KeyCode.Numpad2: return "Numpad2";
			case KeyCode.Numpad3: return "Numpad3";
			case KeyCode.Numpad4: return "Numpad4";
			case KeyCode.Numpad5: return "Numpad5";
			case KeyCode.Numpad6: return "Numpad6";
			case KeyCode.Numpad7: return "Numpad7";
			case KeyCode.Numpad8: return "Numpad8";
			case KeyCode.Numpad9: return "Numpad9";
			case KeyCode.Multiply: return "Multiply";
			case KeyCode.Add: return "Add";
			case KeyCode.Separator: return "Separator";
			case KeyCode.Subtract: return "Subtract";
			case KeyCode.Decimal: return "Decimal";
			case KeyCode.Divide: return "Divide";
			case KeyCode.F1: return "F1";
			case KeyCode.F2: return "F2";
			case KeyCode.F3: return "F3";
			case KeyCode.F4: return "F4";
			case KeyCode.F5: return "F5";
			case KeyCode.F6: return "F6";
			case KeyCode.F7: return "F7";
			case KeyCode.F8: return "F8";
			case KeyCode.F9: return "F9";
			case KeyCode.F10: return "F10";
			case KeyCode.F11: return "F11";
			case KeyCode.F12: return "F12";
			case KeyCode.F13: return "F13";
			case KeyCode.F14: return "F14";
			case KeyCode.F15: return "F15";
			case KeyCode.F16: return "F16";
			case KeyCode.F17: return "F17";
			case KeyCode.F18: return "F18";
			case KeyCode.F19: return "F19";
			case KeyCode.F20: return "F20";
			case KeyCode.F21: return "F21";
			case KeyCode.F22: return "F22";
			case KeyCode.F23: return "F23";
			case KeyCode.F24: return "F24";
			case KeyCode.NumLock: return "NumLock";
			case KeyCode.ScrollLock: return "ScrollLock";
			case KeyCode.WinOemFjJisho: return "WinOemFjJisho";
			case KeyCode.WinOemFjMasshou: return "WinOemFjMasshou";
			case KeyCode.WinOemFjTouroku: return "WinOemFjTouroku";
			case KeyCode.WinOemFjLoya: return "WinOemFjLoya";
			case KeyCode.WinOemFjRoya: return "WinOemFjRoya";
			case KeyCode.Circumflex: return "Circumflex";
			case KeyCode.Exclamation: return "Exclamation";
			case KeyCode.DoubleQuote: return "DoubleQuote";
			case KeyCode.Hash: return "Hash";
			case KeyCode.Dollar: return "Dollar";
			case KeyCode.Percent: return "Percent";
			case KeyCode.Ampersand: return "Ampersand";
			case KeyCode.Underscore: return "Underscore";
			case KeyCode.OpenParen: return "OpenParen";
			case KeyCode.CloseParen: return "CloseParen";
			case KeyCode.Asterisk: return "Asterisk";
			case KeyCode.Plus: return "Plus";
			case KeyCode.Pipe: return "Pipe";
			case KeyCode.HyphenMinus: return "HyphenMinus";
			case KeyCode.OpenCurlyBracket: return "OpenCurlyBracket";
			case KeyCode.CloseCurlyBracket: return "CloseCurlyBracket";
			case KeyCode.Tilde: return "Tilde";
			case KeyCode.VolumeMute: return "VolumeMute";
			case KeyCode.VolumeDown: return "VolumeDown";
			case KeyCode.VolumeUp: return "VolumeUp";
			case KeyCode.Comma: return "Comma";
			case KeyCode.Period: return "Period";
			case KeyCode.Slash: return "Slash";
			case KeyCode.BackQuote: return "BackQuote";
			case KeyCode.OpenBracket: return "OpenBracket";
			case KeyCode.BackSlash: return "BackSlash";
			case KeyCode.CloseBracket: return "CloseBracket";
			case KeyCode.Quote: return "Quote";
			case KeyCode.Meta: return "Meta";
			case KeyCode.AltGr: return "AltGr";
			case KeyCode.WinIcoHelp: return "WinIcoHelp";
			case KeyCode.WinIco00: return "WinIco00";
			case KeyCode.WinIcoClear: return "WinIcoClear";
			case KeyCode.WinOemReset: return "WinOemReset";
			case KeyCode.WinOemJump: return "WinOemJump";
			case KeyCode.WinOemPA1: return "WinOemPA1";
			case KeyCode.WinOemPA2: return "WinOemPA2";
			case KeyCode.WinOemPA3: return "WinOemPA3";
			case KeyCode.WinOemWSCTRL: return "WinOemWSCTRL";
			case KeyCode.WinOemCUSEL: return "WinOemCUSEL";
			case KeyCode.WinOemATTN: return "WinOemATTN";
			case KeyCode.WinOemFinish: return "WinOemFinish";
			case KeyCode.WinOemCopy: return "WinOemCopy";
			case KeyCode.WinOemAuto: return "WinOemAuto";
			case KeyCode.WinOemENLW: return "WinOemENLW";
			case KeyCode.WinOemBackTab: return "WinOemBackTab";
			case KeyCode.ATTN: return "ATTN";
			case KeyCode.CRSEL: return "CRSEL";
			case KeyCode.EXSEL: return "EXSEL";
			case KeyCode.EREOF: return "EREOF";
			case KeyCode.Play: return "Play";
			case KeyCode.Zoom: return "Zoom";
			case KeyCode.PA1: return "PA1";
			case KeyCode.WinOemClear: return "WinOemClear";
		}
		return String.fromCharCode(keycode);
	}

	static inline function dist(x1: Float, y1: Float, x2: Float, y2: Float): Float {
		var vx = x1 - x2;
		var vy = y1 - y2;
		return Math.sqrt(vx * vx + vy * vy);
	}
	static inline function fract(f: Float): Float { return f - Std.int(f); }
	static inline function mix(x: Float, y: Float, a: Float): Float { return x * (1.0 - a) + y * a; }
	static inline function clamp(x: Float, minVal: Float, maxVal: Float): Float { return Math.min(Math.max(x, minVal), maxVal); }
	static inline function step(edge: Float, x: Float): Float { return x < edge ? 0.0 : 1.0; }
	static inline var kx = 1.0;
	static inline var ky = 2.0 / 3.0;
	static inline var kz = 1.0 / 3.0;
	static inline var kw = 3.0;
	static var ar = [0.0, 0.0, 0.0];
	static function hsvToRgb(cR: Float, cG: Float, cB: Float, out: Array<Float>) {
		var px = Math.abs(fract(cR + kx) * 6.0 - kw);
		var py = Math.abs(fract(cR + ky) * 6.0 - kw);
		var pz = Math.abs(fract(cR + kz) * 6.0 - kw);
		out[0] = cB * mix(kx, clamp(px - kx, 0.0, 1.0), cG);
		out[1] = cB * mix(kx, clamp(py - kx, 0.0, 1.0), cG);
		out[2] = cB * mix(kx, clamp(pz - kx, 0.0, 1.0), cG);
	}
	static inline var Kx = 0.0;
	static inline var Ky = -1.0 / 3.0;
	static inline var Kz = 2.0 / 3.0;
	static inline var Kw = -1.0;
	static inline var e = 1.0e-10;
	static function rgbToHsv(cR: Float, cG: Float, cB: Float, out: Array<Float>) {
		var px = mix(cB, cG, step(cB, cG));
		var py = mix(cG, cB, step(cB, cG));
		var pz = mix(Kw, Kx, step(cB, cG));
		var pw = mix(Kz, Ky, step(cB, cG));
		var qx = mix(px, cR, step(px, cR));
		var qy = mix(py, py, step(px, cR));
		var qz = mix(pw, pz, step(px, cR));
		var qw = mix(cR, px, step(px, cR));
		var d = qx - Math.min(qw, qy);
		out[0] = Math.abs(qz + (qw - qy) / (6.0 * d + e));
		out[1] = d / (qx + e);
		out[2] = qx;
	}
}
