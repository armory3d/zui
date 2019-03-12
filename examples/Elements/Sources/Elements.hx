package;
import kha.Framebuffer;
import kha.Assets;
import zui.*;

class Elements {
	var ui: Zui;
	var itemList = ["Item 1", "Item 2", "Item 3"];

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
		// window() returns true if redraw is needed - windows are cached into textures
		if (ui.window(Id.handle(), 10, 10, 240, 600, true)) {
			if (ui.panel(Id.handle({selected: true}), "Panel")) {
				ui.indent();
				ui.text("Text");
				ui.textInput(Id.handle({text: "Hello"}), "Input");
				ui.button("Button");
				if (ui.isHovered) ui.tooltip("Tooltip Bubble!\nWith multi-line support!\nWoo!");
				
				ui.check(Id.handle(), "Check Box");
				var hradio = Id.handle();
				ui.radio(hradio, 0, "Radio 1");
				ui.radio(hradio, 1, "Radio 2");
				ui.radio(hradio, 2, "Radio 3");
				ui.inlineRadio(Id.handle(), ["High", "Medium", "Low"]);
				ui.combo(Id.handle(), ["Item 1", "Item 2", "Item 3"], "Combo", true);
				if (ui.panel(Id.handle({selected: false}), "Nested Panel")) {
					ui.indent();
					ui.text("Row");
					ui.row([2/5, 2/5, 1/5]);
					ui.button("A");
					ui.button("B");
					ui.check(Id.handle(), "C");
					ui.text("Simple list");
					Ext.list(ui, Id.handle(), itemList);
					ui.unindent();
				}
				Ext.floatInput(ui, Id.handle({value: 42.0}), "Float Input");
				ui.slider(Id.handle({value: 0.2}), "Slider", 0, 1);
				if (ui.isHovered) ui.tooltip("Slider tooltip");
				ui.slider(Id.handle({value: 0.4}), "Slider 2", 0, 1.2, true);
				Ext.colorPicker(ui, Id.handle());
				ui.separator();
				ui.unindent();
			}
		}

		if (ui.window(Id.handle(), 270, 10, 240, 250, true)) {
			if (ui.panel(Id.handle({selected: true}), "File Browser")) {
				var h = Id.handle();
				ui.text(h.text);
				Ext.fileBrowser(ui, h);
			}
		}

		if (ui.window(Id.handle(), 540, 10, 240, 200)) {
			var htab = Id.handle({position: 0});
			if (ui.tab(htab, "Tab 1")) {
				ui.button("A");
				ui.button("B");
				ui.button("C");
			}
			if (ui.tab(htab, "Tab 2")) {
				ui.button("D");
				ui.button("E");
				ui.button("F");
				ui.button("G");
				ui.button("H");
				ui.button("J");
				ui.button("K");
				ui.button("L");
				ui.button("M");
				ui.button("N");
				ui.button("O");
				ui.button("P");
				ui.button("Q");
				ui.button("R");
				ui.button("S");
			}
			if (ui.tab(htab, "Another Tab")) {
				ui.text("Lorem ipsum dolor sit amet");
				ui.check(Id.handle(), "Check Box 1");
				ui.check(Id.handle(), "Check Box 2");
			}
		}

		ui.end();	

		// Draw more of your stuff...
	}
}
