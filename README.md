# zui

Portable user interface library designed for tooling and game debug. Built with Haxe and Kha.

![](img/zui.jpg)

## Getting started
- Clone into *your_kha_project/Libraries*
- Add `project.addLibrary('zui');` into *khafile.js*
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
panel(id: Handle, text: String, accent = 1): Bool;
image(image: Image): Void;
text(text: String, align = Left, bg = 0): Void;
textInput(id: Handle, text: String, label = ""): String;
button(text: String, align = Center): Bool;
check(id: Handle, text: String): Bool;
radio(groupId: Handle, pos: Int, text: String): Bool;
inlineRadio(id: Handle, texts: Array<String>): Int;
combo(id: Handle, texts: Array<String>, label = ""): Int;
slider(id: String, text: String, from: Float, to: Float, filled = false, precision = 100, displayValue = true): Float;

// Formating
row(ratios: Array<Float>);
separator();
indent();
unindent();
```

Id.hx - simple macros to generate handles
``` hx
var state = ui.check(Id.handle(), "Check Box");
```

Ext.hx - prebuilt elements:
``` hx
list(...);
panelList(...);
colorPicker(...);
fileBrowser(...); // See examples
```

Nodes.hx - drawing node systems
``` hx
nodes.nodeCanvas(...); // See examples
```

Canvas.hx - drawing custom layouts
``` hx
Canvas.draw(...); // See examples
```

## Examples
Check out examples/ folder. To run specific example, simply drop it's folder into [KodeStudio](https://github.com/KTXSoftware/KodeStudio/releases) and hit run.

## Theming
Themes can be defined using TTheme typedef. Check zui.Themes class for example. Set ZuiOptions.theme when creating new Zui instance to overwrite default theme.

## Snippets

**Check element for changes**
```hx
var hcombo = Id.handle();
ui.combo(hcombo, ["Item 1", "item 2"]);
if (hcombo.changed) {
	trace("Combo value changed this frame");
}
```

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
Using the powerful render target system of Kha, it is possible to easily integrate the library into any scenario. Set ZuiOptions.autoNotifyInput to false when creating a new Zui instance. You can then manually process the input and render the resulting texture in any way you may need.
``` hx
zui.onMouseDown(button:Int, x:Int, y:Int)
zui.onMouseUp(button:Int, x:Int, y:Int)
zui.onMouseMove(x:Int, y:Int, movementX:Int, movementY:Int)
zui.onMouseWheel(delta:Int)
```
![](img/zui2.jpg)

---

Inspired by [imgui](https://github.com/ocornut/imgui).
