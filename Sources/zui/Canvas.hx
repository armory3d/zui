package zui;

class Canvas {

	public static function draw(ui: Zui, canvas: TCanvas, g: kha.graphics2.Graphics) {

		ui.begin(g);
		ui.g = g;

		for (elem in canvas.elements) drawElement(ui, canvas, elem);

		ui.end();
	}

	static function getAsset(canvas: TCanvas, asset:String): kha.Image {
		for (a in canvas.assets) if (a.name == asset) return a.image;
		return null;
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
			ui.button(element.text);
		case Image:
			if (element.image == null) element.image = getAsset(canvas, element.asset);
			if (element.image != null) ui.image(element.image);
		}

		if (element.children != null) for (c in element.children) drawElement(ui, canvas, c);
	}
}

typedef TCanvas = {
	public var name: String;
	public var x: Float;
	public var y: Float;
	public var width: Int;
	public var height: Int;
	public var elements: Array<TElement>;
	@:optional public var assets: Array<TAsset>;
}

typedef TElement = {
	public var id: Int;
	public var type: ElementType;
	public var name: String;
	public var event: String;
	public var x: Float;
	public var y: Float;
	public var width: Int;
	public var height: Int;
	public var text: String;
	public var asset: String;
	public var color: Int;
	public var anchor: Int;
	public var children: Array<TElement>;
	@:optional public var image: kha.Image;
}

typedef TAsset = {
	public var name:String;
	public var file:String;
	public var image:kha.Image;
}

@:enum abstract ElementType(Int) from Int {
	var Text = 0;
	var Image = 1;
	var Button = 2;
}
