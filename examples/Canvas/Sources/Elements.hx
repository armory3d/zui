package;
import kha.Framebuffer;
import kha.Assets;
import zui.*;
import zui.Canvas;

class Elements {
	var ui: Zui;
	var initialized = false;

	public function new() {
		Assets.loadEverything(loadingFinished);
	}

	function loadingFinished() {
		initialized = true;
		ui = new Zui({font: Assets.fonts.DroidSans});
	}

	var canvas:TCanvas = {
		name: "Canvas",
		x: 0,
		y: 0,
		width: 400,
		height: 400,
		elements: [
			{
				id: 0,
				type: ElementType.Text,
				name: "Text",
				x: 0,
				y: 0,
				width: 200,
				height: 50,
				text: "Label"
			},
			{
				id: 1,
				type: ElementType.Button,
				name: "Button",
				x: 100,
				y: 100,
				width: 100,
				height: 50,
				text: "Button"
			}
		]
	};

	public function render(framebuffer: Framebuffer): Void {
		if (!initialized) return;
		var g = framebuffer.g2;

		g.begin();
		Canvas.draw(ui, canvas, g);
		g.end();
	}

	public function update(): Void {
		if (!initialized) return;
	}
}
