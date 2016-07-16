package;
import kha.Framebuffer;
import kha.Assets;

import zui.Zui;
import zui.Id;

class Elements {
	var ui: Zui;
	var initialized = false;

	public function new() {
		Assets.loadEverything(loadingFinished);
	}

	function loadingFinished() {
		initialized = true;
		ui = new Zui(Assets.fonts.DroidSans, 20, 14, 0, 1.5);
	}

	public function render(framebuffer: Framebuffer): Void {
		if (!initialized) return;

		var g = framebuffer.g2;
		g.begin();
		g.color = 0xffffffff;
		g.drawImage(Assets.images.bg, 0, 0);
		g.end();

		ui.begin(g);
		if (ui.window(Id.window(), 50, 50, 700, 500)) {
			ui.text("GAME SETTINGS", Zui.ALIGN_CENTER, 0xff222222);

			ui.row([0.5, 0.5]);
			ui.text("Window mode");
			ui.inlineRadio(Id.radio(), ["Fullscreen", "Windowed"]);
			
			ui.row([0.5, 0.5]);
			ui.text("Model detail");
			ui.inlineRadio(Id.radio(), ["High", "Medium", "Low"]);
			
			ui.row([0.5, 0.5]);
			ui.text("Textures");
			ui.inlineRadio(Id.radio(), ["High", "Medium", "Low"]);

			ui.row([0.5, 0.5]);
			ui.text("Shadows");
			ui.inlineRadio(Id.radio(), ["High", "Medium", "Low"]);

			ui.row([0.5, 0.5]);
			ui.text("Console");
			ui.inlineRadio(Id.radio(), ["On", "Off"]);

			ui.row([0.5, 0.5]);
			ui.text("Brightness");
			ui.slider(Id.slider(), "", 0, 1, true, 100, false);

			ui.row([0.5, 0.5]);
			ui.text("Volume");
			ui.slider(Id.slider(), "", 0, 1, true, 100, false);

			ui.row([0.5, 0.5]);
			ui.button("Discard");
			ui.button("Apply");
		}
		ui.end();	
	}

	public function update(): Void {
		if (!initialized) return;
	}
}
