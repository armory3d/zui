package;
import kha.Framebuffer;
import kha.Assets;

import zui.Zui;
import zui.Ext;
import zui.Id;

class Empty {
	
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
		
		ui.begin(g);

		// window() returns true if redraw is needed - windows are cached into textures
		if (ui.window(Id.window(), 0, 0, 250, 600)) {

			if (ui.node(Id.node(), "Node", 2, true)) {
				ui.text("Text");
				ui.textInput(Id.textInput(), "Hello", "Input");
				ui.button("Button");
				ui.check(Id.check(), "Check Box");
				var id = Id.radio();
				ui.radio(id, Id.pos(), "Radio 1");
				ui.radio(id, Id.pos(), "Radio 2");
				ui.radio(id, Id.pos(), "Radio 3");
				if (ui.node(Id.node(), "Nested Node", 1)) {
					ui.text("Row");
					ui.row([2/5, 2/5, 1/5]);
					ui.button("A");
					ui.button("B");
					ui.check(Id.check(), "C");
					ui.text("Simple list");
					Ext.drawList(ui, Id.list(), ["Item 1", "Item 2", "Item 3"]);
				}
			}
		}

		ui.end();
	}
	
	public function update(): Void {
		if (!initialized) return;
	}
}
