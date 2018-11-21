package zui;

@:access(zui.Zui)
class Canvas {

	public static var assetMap = new Map<Int, kha.Image>();
	static var events:Array<String> = [];

	public static var screenW = -1;
	public static var screenH = -1;
	static var _ui: Zui;

	public static function draw(ui: Zui, canvas: TCanvas, g: kha.graphics2.Graphics): Array<String> {
		
		if (screenW == -1) {
			screenW = kha.System.windowWidth();
			screenH = kha.System.windowHeight();
		}

		events = [];

		_ui = ui;
		ui.begin(g);
		ui.g = g;

		for (elem in canvas.elements) {
			if (elem.parent == null) drawElement(ui, canvas, elem);
		}

		ui.end();
		return events;
	}

	static function drawElement(ui: Zui, canvas: TCanvas, element: TElement, px = 0.0, py = 0.0) {

		if (element == null || !element.visible) return;

		ui._x = canvas.x + scaled(element.x) + scaled(px);
		ui._y = canvas.y + scaled(element.y) + scaled(py);
		ui._w = scaled(element.width);

		var cw = scaled(canvas.width);
		var ch = scaled(canvas.height);

		switch (element.anchor) {
		case Top:
			ui._x -= (cw - screenW) / 2;
		case TopRight:
			ui._x -= cw - screenW;
		case CenterLeft:
			ui._y -= (ch - screenH) / 2;
		case Center:
			ui._x -= (cw - screenW) / 2;
			ui._y -= (ch - screenH) / 2;
		case CenterRight:
			ui._x -= cw - screenW;
			ui._y -= (ch - screenH) / 2;
		case BottomLeft:
			ui._y -= ch - screenH;
		case Bottom:
			ui._x -= (cw - screenW) / 2;
			ui._y -= ch - screenH;
		case BottomRight:
			ui._x -= cw - screenW;
			ui._y -= ch - screenH;
		}

		var rotated = element.rotation != null && element.rotation != 0;
		if (rotated) ui.g.pushRotation(element.rotation, ui._x + scaled(element.width) / 2, ui._y + scaled(element.height) / 2);

		switch (element.type) {
		case Text:
			var size = ui.fontSize;
			var tcol = ui.t.TEXT_COL;
			ui.fontSize = scaled(element.height);
			ui.t.TEXT_COL = element.color;
			ui.text(element.text);
			ui.fontSize = size;
			ui.t.TEXT_COL = tcol;
		case Button:
			var bh = ui.t.BUTTON_H;
			ui.t.BUTTON_H = scaled(element.height);
			if (ui.button(element.text)) {
				var e = element.event;
				if (e != null && e != "") events.push(e);
			}
			ui.t.BUTTON_H = bh;
		case Image:
			var image = getAsset(canvas, element.asset);
			if (image != null) {
				ui.imageScrollAlign = false;
				var tint = element.color != null ? element.color : 0xffffffff;
				if (ui.image(image, tint, scaled(element.height)) == zui.Zui.State.Released) {
					var e = element.event;
					if (e != null && e != "") events.push(e);
				}
				ui.imageScrollAlign = true;
			}
		}

		if (element.children != null) {
			for (id in element.children) {
				drawElement(ui, canvas, elemById(canvas, id), element.x + px, element.y + py);
			}
		}

		if (rotated) ui.g.popTransformation();
	}

	public static function getAsset(canvas: TCanvas, asset: String): kha.Image {
		for (a in canvas.assets) if (a.name == asset) return assetMap.get(a.id);
		return null;
	}

	static var elemId = -1;
	public static function getElementId(canvas: TCanvas): Int {
		if (elemId == -1) for (e in canvas.elements) if (elemId < e.id) elemId = e.id;
		return ++elemId;
	}

	static var assetId = -1;
	public static function getAssetId(canvas: TCanvas): Int {
		if (assetId == -1) for (a in canvas.assets) if (assetId < a.id) assetId = a.id;
		return ++assetId;
	}

	static function elemById(canvas: TCanvas, id: Int): TElement {
		for (e in canvas.elements) if (e.id == id) return e;
		return null;
	}

	static inline function scaled(f: Float): Int { return Std.int(f * _ui.SCALE); }
}

typedef TCanvas = {
	var name: String;
	var x: Float;
	var y: Float;
	var width: Int;
	var height: Int;
	var elements: Array<TElement>;
	@:optional var assets: Array<TAsset>;
}

typedef TElement = {
	var id: Int;
	var type: ElementType;
	var name: String;
	var x: Float;
	var y: Float;
	var width: Int;
	var height: Int;
	@:optional var rotation: Null<Float>;
	@:optional var text: String;
	@:optional var event: String;
	@:optional var color: Null<Int>;
	@:optional var anchor: Null<Int>;
	@:optional var parent: Null<Int>; // id
	@:optional var children: Array<Int>; // ids
	@:optional var asset: String;
	@:optional var visible: Null<Bool>;
}

typedef TAsset = {
	var id: Int;
	var name:String;
	var file:String;
}

@:enum abstract ElementType(Int) from Int {
	var Text = 0;
	var Image = 1;
	var Button = 2;
}

@:enum abstract Anchor(Int) from Int {
	var TopLeft = 0;
	var Top = 1;
	var TopRight = 2;
	var CenterLeft = 3;
	var Center = 4;
	var CenterRight = 5;
	var BottomLeft = 6;
	var Bottom = 7;
	var BottomRight = 8;
}
