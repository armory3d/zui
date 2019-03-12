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
		ui = new Zui({font: Assets.fonts.DroidSans});
		kha.System.notifyOnFrames(render);
	}

	public function render(framebuffers: Array<Framebuffer>): Void {
		var g = framebuffers[0].g2;

		g.begin();
		// Draw your stuff...
		g.end();

		ui.begin(g);
		
		if (ui.window(Id.handle(), 10, 10, 400, 300, true)) {
			if (ui.panel(Id.handle({selected: true}), "File Browser")) {
				
				var h = Id.handle();
				//var h = Id.handle({text: "C:\\"}); // Set initial path
				
				ui.row([1/2, 1/2]);
				ui.button("Cancel");
				if (ui.button("Load")) {
					trace(h.text);
				}
				
				h.text = ui.textInput(h, "Path");
				Ext.fileBrowser(ui, h);
			}
		}

		ui.end();	

		// Draw more of your stuff...
	}
}
