# zui

Immediate-mode graphical user interface designed for tools and game debug. The library is built with Haxe and Kha to reach ultra portability. Inspired by [imgui](https://github.com/ocornut/imgui).

## Update notice
The library went through a slight makeover which brings a few breaking changes.
If you wish, revert to [older build](https://github.com/armory3d/zui/releases/tag/17.02).

Changes:
- Create Zui instance using ZuiOptions:
`var ui = new Zui({ font: myFont, theme: myTheme, ... });`
- Replace `Id.*()` calls with the new unified `Id.handle()` for all elements
- Replace `ui.node()` with `ui.panel()`
- Pass initial element state in a handle: `ui.check(Id.handle({ selected: true }), "Check Box")`

![](img/zui.jpg)

## Getting started
- Clone into 'your_kha_project/Libraries'
- Add 'project.addLibrary('zui');' into khafile.js
``` hx
	// In init()
	var ui = new Zui({ font:Font, khaWindowId = 0, scaleFactor = 1.0 });

	// In render()
	public function render(frame:Framebuffer) {
		var g = frame.g2;
		g.begin();
		// Draw your stuff...
		g.end();
		
		ui.begin(g);
		if (ui.window(Id.handle(), x, y, w, h, drag)) {
			if (ui.button("Hello")) {
				trace("World");
			}
		}
		ui.end();

		// Draw more stuff...
	}
```

## Elements
``` hx
panel(id: String, text: String, accent = 1): Bool;
image(image: Image): Void;
text(text: String, align = Left, bg = 0): Void;
textInput(id: String, text: String, label = ""): String;
button(text: String): Bool;
check(id: String, text: String): Bool;
radio(groupId: String, pos: Int, text: String): Bool;
inlineRadio(id: String, texts: Array<String>): Int;
slider(id: String, text: String, from: Float, to: Float, filled = false, precision = 100, displayValue = true): Float;

// Formating
row(ratios: Array<Float>);
separator();
indent();
unindent();
```

Ext.hx - prebuilt elements:
``` hx
list(...);
panelList(...);
colorPicker(...);
```

Id.hx - simple macros to generate handles
``` hx
var state = ui.check(Id.handle(), "Check Box");
```

## Examples
Check out examples/ folder. To run specific example, simply drop it's folder into [KodeStudio](https://github.com/KTXSoftware/KodeStudio/releases) and hit run.

## Theming
Themes can be defined using TTheme typedef. Check zui.Themes class for example. Set ZuiOptions.theme when creating new Zui instance to overwrite default theme.

## Snippets

**Force redrawing zui window on demand**
```hx
function render(..) {
    // Get window handle
    var hwin = Id.handle();
    // Force redraw - set each frame or whenever desired
    hwin.redraws = 1;
    if (ui.window(hwin, x, y, w, h)) { ... }
}
```

**Using render targets - prevent nested begin/end calls**
```hx
g2.begin();
..
g2.end();

renderTarget.g2.begin();
..
renderTarget.g2.end();

zui.begin(); // Zui also draws to texture..
..
zui.end();

g2.begin();
..
g2.end();
```

## Custom integration
Thanks to the powerful render target system of Kha, it is possible to easily integrate the library into any scenario. Set ZuiOptions.autoNotifyInput to false when creating a new Zui instance. You can then manually process the input and render the resulting texture in any way you may need.
``` hx
zui.onMouseDown(button:Int, x:Int, y:Int)
zui.onMouseUp(button:Int, x:Int, y:Int)
zui.onMouseMove(x:Int, y:Int, movementX:Int, movementY:Int)
zui.onMouseWheel(delta:Int)
```
![](img/zui2.jpg)
