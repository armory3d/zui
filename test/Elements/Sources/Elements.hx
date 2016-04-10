package;
import kha.Framebuffer;
import kha.Assets;

import zui.Zui;
import zui.Ext;
import zui.Id;

class Elements {
	var ui:Zui;
	var initialized = false;

	public function new() {
		Assets.loadEverything(loadingFinished);
	}

	function loadingFinished() {
		initialized = true;
		ui = new Zui(Assets.fonts.roboto);
	}

	public function render(framebuffer: Framebuffer): Void {
		if (!initialized) return;

		var g = framebuffer.g2;

		g.begin();
		// Draw your stuff...
		g.end();

		ui.begin(g);
		// window() returns true if redraw is needed - windows are cached into textures
		if (ui.window(Id.window(), 0, 0, 250, 600)) {
			if (ui.node(Id.node(), "Node", 0, true)) {
				ui.indent();
				ui.separator();
				ui.text("Text");
				ui.textInput(Id.textInput(), "Hello", "Input");
				ui.button("Button");
				ui.check(Id.check(), "Check Box");
				var id = Id.radio();
				ui.radio(id, Id.pos(), "Radio 1");
				ui.radio(id, Id.pos(), "Radio 2");
				ui.radio(id, Id.pos(), "Radio 3");
				if (ui.node(Id.node(), "Nested Node")) {
					ui.indent();
					ui.separator();
					ui.text("Row");
					ui.row([2/5, 2/5, 1/5]);
					ui.button("A");
					ui.button("B");
					ui.check(Id.check(), "C");
					ui.text("Simple list");
					Ext.drawList(ui, Id.list(), ["Item 1", "Item 2", "Item 3"]);
					ui.unindent();
				}
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
