package;
import kha.Framebuffer;
import kha.Assets;
import zui.*;

class Elements {
	var ui: Zui;

	public function new() {
		Assets.loadEverything(loadingFinished);
	}

	function loadingFinished() {
		ui = new Zui({font: Assets.fonts.DroidSans, color_wheel: Assets.images.color_wheel});
		kha.System.notifyOnFrames(render);
	}

	public function render(framebuffers: Array<Framebuffer>): Void {
		var g = framebuffers[0].g2;

		g.begin();
		// Draw your stuff...
		g.end();

		ui.begin(g);
		// window() returns true if redraw is needed - windows are cached into textures
		if (ui.window(Id.handle(), 10, 10, 360, 600, true)) {
			if (ui.panel(Id.handle({selected: true}), "Panel")) {
				var hwheel = Id.handle();
				var color = Ext.colorWheel(ui, hwheel);
				if (hwheel.changed) trace(color.Rb, color.Gb, color.Bb);
			}
		}

		ui.end();	

		// Draw more of your stuff...
	}
}
