package game;

import kha.Assets;
import zui.Zui;
import zui.Ext;
import zui.Id;

class Test {
	var ui:Zui;

    public function new() {
        super();
    }

    function init() {
        ui = new Zui(Assets.fonts.DroidSans);
    }

    function render(g:kha.graphics2.Graphics) {
        g.begin();
        g.end();
		
		ui.begin(g);
		if (ui.window(Id.window(), 0, 0, 250, kha.System.windowHeight())) {
			if (ui.node(Id.node(), "Weapon Material", 0, true)) {
				ui.indent();
				ui.separator();
				ui.textInput(Id.textInput(), "Material.001", "Name");
				Ext.colorPicker(ui, Id.colorPicker());
				ui.slider(Id.slider(), "Roughness", 0, 1, true, 100);
				ui.slider(Id.slider(), "Metalness", 0, 1, true, 100);
				ui.check(Id.check(), "HDR");
				ui.button("Load");
				ui.button("Reset");
				ui.unindent();
			}
			if (ui.node(Id.node(), "Character Material", 0, true)) {
				ui.indent();
				ui.separator();
				ui.textInput(Id.textInput(), "Material.002", "Name");
				Ext.colorPicker(ui, Id.colorPicker());
				ui.slider(Id.slider(), "Roughness", 0, 1, true, 100);
				ui.slider(Id.slider(), "Metalness", 0, 1, true, 100);
				ui.check(Id.check(), "HDR");
				ui.button("Load");
				ui.button("Reset");
				ui.unindent();
			}
			if (ui.node(Id.node(), "Armor Material", 0, true)) {
				ui.indent();
				ui.separator();
				ui.textInput(Id.textInput(), "Material.003", "Name");
				Ext.colorPicker(ui, Id.colorPicker());
				ui.slider(Id.slider(), "Roughness", 0, 1, true, 100);
				ui.slider(Id.slider(), "Metalness", 0, 1, true, 100);
				ui.check(Id.check(), "HDR");
				ui.button("Load");
				ui.button("Reset");
				ui.unindent();
			}
		}
		
		if (ui.window(Id.window(), kha.System.windowWidth() - Std.int(250 * 1.5), 0, 250, kha.System.windowHeight())) {
			if (ui.node(Id.node(), "Character", 0, true)) {
				ui.indent();
				ui.textInput(Id.textInput(), "Unnamed Hero", "Name");
				ui.slider(Id.slider(), "Health", 0, 100, true, 1);
				ui.slider(Id.slider(), "Strength", 0, 100, true, 1);
				ui.slider(Id.slider(), "Speed", 0, 100, true, 1);
				ui.check(Id.check(), "Water resistant");
				ui.check(Id.check(), "Fire resistant");
				ui.check(Id.check(), "Air resistant");
				ui.button("Reset");
				ui.button("Respawn");
				ui.unindent();
			}
			if (ui.node(Id.node(), "Equipment", 0, true)) {
				ui.indent();
				ui.separator();	
				ui.text("Weapon");
				ui.indent();
				var id = Id.radio();
				ui.radio(id, Id.pos(), "Revolver");
				ui.radio(id, Id.pos(), "Rifle");
				ui.image(Assets.images.gun);
				ui.slider(Id.slider(), "Fire range", 0, 30, false, 10);
				ui.slider(Id.slider(), "Fire rate", 0, 5, false, 100);
				ui.slider(Id.slider(), "Ammo", 0, 100, false, 1);
				ui.unindent();
				ui.text("Armor");
				ui.indent();
				ui.slider(Id.slider(), "Strength", 0, 100, false, 1);
				ui.unindent();
				ui.button("Equip");
			}
		}
		ui.end();	
    }
}
