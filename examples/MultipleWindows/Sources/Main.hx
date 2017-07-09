package;

import kha.WindowOptions;
import kha.WindowOptions.Position;

class Main {
	public static function main() {
		var dwh = Std.int(kha.Display.width(0) / 2);
		var dhh = Std.int(kha.Display.height(0) / 2);

        var mwo: WindowOptions = { title : ' | main', width : 256, height : 256, x : Fixed(dwh - 256 - 64), y : Center };
        var swo: WindowOptions = { title : ' | sub', width : 256, height : 256, x : Fixed(dwh + 64), y : Center };

		kha.System.initEx('MultipleWindows', [mwo, swo], windowIds.push, kha.Assets.loadEverything.bind(assets_loadedHandler));
	}

    static function assets_loadedHandler() {
		mainwindow = new ExampleWindow(windowIds[0], 'click me!');
        subwindow = new ExampleWindow(windowIds[1], 'click me harder!');
	}

    static var windowIds = new Array<Int>();
	static var mainwindow : ExampleWindow;
	static var subwindow : ExampleWindow;
}

private class ExampleWindow {
    var ui : zui.Zui;
	var buttonText : String;

	var counter = 0;
	var panelExpanded = false;

    public function new( windowId : Int, buttonText : String ) {
		this.ui = new zui.Zui({ font: kha.Assets.fonts.DroidSans, khaWindowId: windowId});
		this.buttonText = buttonText;

		kha.System.notifyOnRender(render, windowId);
    }

    function render( fb : kha.Framebuffer ) {
		ui.begin(fb.g2);
			if (ui.window(zui.Id.handle(), 8, 8, 240, 240)) {
				panelExpanded = ui.panel(zui.Id.handle(), panelExpanded ? 'close me' : 'open me', 1);

				if (panelExpanded) {
					if (ui.button(buttonText)) {
						++counter;
					}

					ui.text('you clicked ${counter} time(s)');
				}
			}
		ui.end();
    }
}
