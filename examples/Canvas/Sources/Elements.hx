package;
import kha.Framebuffer;
import kha.Assets;
import zui.*;
import zui.Canvas;

class Elements {
	var ui: Zui;

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
				text: "Label",
				color: 0xffff0000
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
			},
			{
				id: 2,
				type: ElementType.Image,
				name: "Image",
				x: 300,
				y: 100,
				width: 140,
				height: 140,
				asset: "kode"
			}
		],
		assets: [
			{
				id: 0,
				name: "kode",
				file: "kode.png"
			}
		]
	};

	public function new() {
		Assets.loadEverything(loadingFinished);
	}

	function loadingFinished() {
		ui = new Zui({font: Assets.fonts.DroidSans});

		// Map images referenced in canvas
		for (a in canvas.assets) {
			Canvas.assetMap.set(0, Reflect.field(kha.Assets.images, a.name));
		}

		kha.System.notifyOnFrames(render);
	}

	public function render(framebuffers: Array<Framebuffer>): Void {
		var g = framebuffers[0].g2;

		g.begin();
		Canvas.draw(ui, canvas, g);
		g.end();
	}
}
