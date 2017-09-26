package;
import kha.Framebuffer;
import kha.Assets;
import zui.*;

class Elements {
	var ui: Zui;
	var initialized = false;

	static inline var scale = 2.0;

	public function new() {
		Assets.loadEverything(loadingFinished);
	}

	function loadingFinished() {
		initialized = true;
		ui = new Zui({font: Assets.fonts.DroidSans, scaleFactor: scale});
	}

	public function render(framebuffer: Framebuffer): Void {
		if (!initialized) return;

		var g = framebuffer.g2;

		g.begin();
		// Draw your stuff...
		g.end();

		ui.begin(g);
		if (ui.window(Id.handle(), 10, 10, Std.int(240 * scale), 600, true)) {
			if (ui.panel(Id.handle({selected: true}), "Panel")) {
				ui.indent();
				ui.text("Text");
				ui.textInput(Id.handle({text: "Hello"}), "Input");
				ui.button("Button");
				if (ui.isHovered) ui.tooltip("Tooltip Bubble!");
				ui.check(Id.handle(), "Check Box");
				var hradio = Id.handle();
				ui.radio(hradio, 0, "Radio 1");
				ui.radio(hradio, 1, "Radio 2");
				ui.radio(hradio, 2, "Radio 3");
				ui.unindent();
			}
		}

		ui.end();	

		// Draw more of your stuff...
	}

	public function update(): Void {
		if (!initialized) return;
	}
}
