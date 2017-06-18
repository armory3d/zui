package zui;

import zui.Zui;

class Ext {

	public static function list(ui: Zui, handle: Handle, ar: Array<Dynamic>,
								addCb: String->Void = null,
								removeCb: Int->Void = null,
								getNameCb: Int->String = null,
								setNameCb: Int->String->Void = null,
								itemDrawCb: Handle->Int->Void = null,
								showRadio = false,
								editable = true,
								showAdd = true): Int {
		var selected = 0;

		if (addCb == null) addCb = function(name: String) { ar.push(name); };
		if (removeCb == null) removeCb = function(i: Int) { ar.splice(i, 1); };
		if (getNameCb == null) getNameCb = function(i: Int) { return ar[i]; };
		if (setNameCb == null) setNameCb = function(i: Int, name: String) { ar[i] = name; };

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
			editable ? setNameCb(i, ui.textInput(itemHandle, getNameCb(i))) : ui.text(getNameCb(i));
			if (ui.button("X")) removeCb(i);
			else i++;

			if (itemDrawCb != null) itemDrawCb(itemHandle.nest(i), i - 1);
		}
		if (showAdd && ui.button("Add")) addCb("untitled");

		return selected;
	}

	public static function panelList(ui: Zui, handle: Handle, ar: Array<Dynamic>,
									 addCb: String->Void = null,
									 removeCb: Int->Void = null,
									 getNameCb: Int->String = null,
									 setNameCb: Int->String->Void = null,
									 itemDrawCb: Handle->Int->Void = null,
									 editable = true,
									 showAdd = true) {

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
		if (showAdd && ui.button("Add")) {
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

	public static function fileBrowser(ui: Zui, handle: Handle): String {
		#if kha_krom

		var cmd = "ls ";
		if (handle.text == "") {
			var systemId = kha.System.systemId;
			initPath(handle, systemId);
			if (systemId == "Windows") cmd = "dir ";
		}

		var save = Krom.savePath() + "/dir.txt";
		Krom.sysCommand(cmd + handle.text + ' > ' + '"' + save + '"');
		var str = haxe.io.Bytes.ofData(Krom.loadBlob(save)).toString();
		var files = str.split("\n");
		
		#elseif kha_kore

		if (handle.text == "") initPath(handle, kha.System.systemId);
		var files = sys.FileSystem.readDirectory(handle.text);

		#elseif kha_webgl

		var files:Array<String> = [];
		if (untyped process.versions['electron'] != null) {
			if (handle.text == "") {
				var pp = untyped process.platform;
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

		var nested = handle.text.indexOf("/", 1) != -1 || handle.text.indexOf("\\", 2) != -1;
		if (nested && ui.button("..", Align.Left)) {
			handle.text = handle.text.substring(0, handle.text.lastIndexOf("/"));
		}

		for (f in files) {
			if (f != "" && f.charAt(0) != "." && ui.button(f, Align.Left)) {
				handle.text += '/' + f;
			}
		}
		
		return handle.text;
	}
}
