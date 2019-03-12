package zui;

import zui.Zui;

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
	public static function floatInput(ui: Zui, handle: Handle, label = "", align:Align = Left): Float {
		handle.text = Std.string(handle.value);
		var text = ui.textInput(handle, label, align);
		handle.value = Std.parseFloat(text);
		return handle.value;
	}

	public static function list(ui: Zui, handle: Handle, ar: Array<Dynamic>, ?opts: ListOpts ): Int {
		var selected = 0;
		if (opts == null) opts = {};

		var addCb = opts.addCb != null ? opts.addCb : function(name: String) ar.push(name);
		var removeCb = opts.removeCb != null ? opts.removeCb : function(i: Int) ar.splice(i, 1);
		var getNameCb = opts.getNameCb != null ? opts.getNameCb : function(i: Int) return ar[i];
		var setNameCb = opts.setNameCb != null ? opts.setNameCb : function(i: Int, name: String) ar[i] = name;
		var getLabelCb = opts.getLabelCb != null ? opts.getLabelCb : function(i: Int) return '';
		var itemDrawCb = opts.itemDrawCb;
		var showRadio = opts.showRadio != null ? opts.showRadio : false;
		var editable = opts.editable != null ? opts.editable : true;
		var showAdd = opts.showAdd != null ? opts.showAdd : true;
		var addLabel = opts.addLabel != null ? opts.addLabel : 'Add';

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
									 addLabel: String = 'Add' ) {

		if (addCb == null) addCb = function(name: String) { ar.push(name); };
		if (removeCb == null) removeCb = function(i: Int) { ar.splice(i, 1); };
		if (getNameCb == null) getNameCb = function(i: Int) { return ar[i]; };
		if (setNameCb == null) setNameCb = function(i: Int, name:String) { ar[i] = name; };

		var i = 0;
		while (i < ar.length) {
			ui.row([0.12, 0.68, 0.2]);
			var expanded = ui.panel(handle.nest(i), "", 0);

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
		if (handle.text != lastPath) Krom.sysCommand(cmd + '"' + handle.text + '"' + ' > ' + '"' + save + '"');
		lastPath = handle.text;
		var str = haxe.io.Bytes.ofData(Krom.loadBlob(save)).toString();
		var files = str.split("\n");

		#elseif kha_kore

		if (handle.text == "") initPath(handle, kha.System.systemId);
		var files = sys.FileSystem.isDirectory(handle.text) ? sys.FileSystem.readDirectory(handle.text) : [];

		#elseif kha_webgl

		var files:Array<String> = [];

		var userAgent = untyped navigator.userAgent.toLowerCase();
		if (userAgent.indexOf(' electron/') > -1) {
			if (handle.text == "") {
				var pp = untyped window.process.platform;
				var systemId = pp == "win32" ? "Windows" : (pp == "darwin" ? "OSX" : "Linux");
				initPath(handle, systemId);
			}
			try {
				files = untyped require('fs').readdirSync(handle.text);
			}
			catch(e:Dynamic) {
				// Non-directory item selected
			}
		}

		#else

		var files:Array<String> = [];

		#end

		// Up directory
		var i1 = handle.text.indexOf("/");
		var i2 = handle.text.indexOf("\\");
		var nested =
			(i1 > -1 && handle.text.length - 1 > i1) ||
			(i2 > -1 && handle.text.length - 1 > i2);
		if (nested && ui.button("..", Align.Left)) {
			handle.text = handle.text.substring(0, handle.text.lastIndexOf(sep));
			// Drive root
			if (handle.text.length == 2 && handle.text.charAt(1) == ":") handle.text += sep;
		}

		// Directory contents
		for (f in files) {
			if (f == "" || f.charAt(0) == ".") continue; // Skip hidden
			if (ui.button(f, Align.Left)) {
				if (handle.text.charAt(handle.text.length - 1) != sep) handle.text += sep;
				handle.text += f;
			}
		}

		return handle.text;
	}

	static var wheelSelectedHande: Handle = null;
	public static function colorWheel(ui: Zui, handle: Handle, alpha = false, w: Null<Float> = null, rowAlign = false): kha.Color {
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
		ui.g.fillRect(cx - 3, cy - 3, 6, 6);
		ui.g.color = 0xffffffff;
		ui.g.fillRect(cx - 2, cy - 2, 4, 4);
		// Val slider
		if (rowAlign) alpha ? ui.row([1/3, 1/3, 1/3]) : ui.row([1/2, 1/2]);
		var valHandle = handle.nest(0);
		valHandle.value = Math.round(cval * 100) / 100;
		cval = ui.slider(valHandle, "Value", 0.0, 1.0, true);
		if (valHandle.changed) handle.changed = ui.changed = true;
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
		ui.text("", Right, handle.color);
		return handle.color;
	}

	static inline function dist(x1: Float, y1: Float, x2: Float, y2: Float): Float {
		var vx = x1 - x2;
		var vy = y1 - y2;
		return Math.sqrt(vx * vx + vy * vy);
	}
	static inline function fract(f: Float): Float { return f - Std.int(f); }
	static inline function mix(x: Float, y: Float, a: Float): Float { return x * (1.0 - a) + y * a; }
	static inline function clamp(x: Float, minVal: Float, maxVal: Float): Float { return Math.min(Math.max(x, minVal), maxVal); }
	static inline function step(edge: Float, x: Float):Float { return x < edge ? 0.0 : 1.0; }
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
