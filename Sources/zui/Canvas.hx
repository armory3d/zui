package zui;

@:access(zui.Zui)
class Canvas {

	static var events:Array<String> = [];

	public static function draw(ui: Zui, canvas: TCanvas, g: kha.graphics2.Graphics):Array<String> {
		events = [];

		ui.begin(g);
		ui.g = g;

		for (elem in canvas.elements) drawElement(ui, canvas, elem);

		ui.end();
		return events;
	}

	static function drawElement(ui: Zui, canvas: TCanvas, element: TElement) {

		ui._x = canvas.x + element.x;
		ui._y = canvas.y + element.y;
		ui._w = element.width;

		switch (element.type) {
		case Text:
			var size = ui.fontSmallSize;
			ui.fontSmallSize = element.height;
			ui.text(element.text);
			ui.fontSmallSize = size;
		case Button:
			if (ui.button(element.text)) {
				events.push(element.event);
			}
		case Image:
			var image = getAsset(canvas, element.asset);
			if (image != null) {
				ui.imageScrollAlign = false;
				ui.image(image);
				ui.imageScrollAlign = true;
			}
		}

		if (element.children != null) for (c in element.children) drawElement(ui, canvas, c);
	}

	public static function getAsset(canvas: TCanvas, asset: String): kha.Image {
		for (a in canvas.assets) if (a.name == asset) return a.image;
		return null;
	}

	static var elemId = -1;
	public static function getElementId(canvas: TCanvas): Int {
		if (elemId == -1) for (e in canvas.elements) if (elemId < e.id) elemId = e.id;
		return ++elemId;
	}
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
	@:optional var text: String;
	@:optional var event: String;
	@:optional var color: Int;
	@:optional var anchor: Int;
	@:optional var children: Array<TElement>;
	@:optional var asset: String;
}

typedef TAsset = {
	var name:String;
	var file:String;
	@:optional var image: kha.Image;
	@:optional var id: Int;
}

@:enum abstract ElementType(Int) from Int {
	var Text = 0;
	var Image = 1;
	var Button = 2;
}
