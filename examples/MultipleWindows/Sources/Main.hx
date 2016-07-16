package;

import kha.WindowOptions.Position;

class Main {
	public static function main() {
		var dwh = Std.int(kha.Display.width(0) / 2);
		var dhh = Std.int(kha.Display.height(0) / 2);

        var mwo = { title : ' | main', width : 256, height : 256, x : Fixed(dwh - 256 - 64), y : Center };
        var swo = { title : ' | sub', width : 256, height : 256, x : Fixed(dwh + 64), y : Center };

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
    var z : zui.Zui;
	var buttonText : String;

	var counter = 0;
	var nodeExpanded = false;

    public function new( windowId : Int, buttonText : String ) {
        this.z = new zui.Zui(kha.Assets.fonts.DroidSans, 24, 20, windowId);
		this.buttonText = buttonText;

		kha.System.notifyOnRender(render, windowId);
    }

    function render( fb : kha.Framebuffer ) {
        fb.g2.begin();
            z.begin(fb.g2);
				if (z.window(zui.Id.window(), 8, 8, 240, 240)) {
					nodeExpanded = z.node(zui.Id.node(), nodeExpanded ? 'close me' : 'open me', 1, nodeExpanded);

					if (nodeExpanded) {
						if (z.button(buttonText)) {
							++counter;
						}

						z.text('you clicked ${counter} time(s)');
					}
				}
            z.end();
        fb.g2.end();
    }
}
