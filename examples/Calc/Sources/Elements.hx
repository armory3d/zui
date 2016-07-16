package;
import kha.Framebuffer;
import kha.Assets;
import zui.Zui;
import zui.Id;

class Elements {
	var ui: Zui;
	var initialized = false;
 	var lastState = 0.0;
	var state(default, set) = "0";
	var op = "";

	function set_state(s:String) {
		if (s.length > 1 && s.charAt(0) == "0" && s.charAt(1) != ".") s = s.substr(1); // Trim leading 0
		return state = s;
	}

	public function new() {
		Assets.loadEverything(loadingFinished);
	}

	function loadingFinished() {
		initialized = true;
		ui = new Zui(Assets.fonts.DroidSans, 17, 16, 0, 1.5);
	}

	public function render(framebuffer: Framebuffer): Void {
		if (!initialized) return;
		var g = framebuffer.g2;

		ui.begin(g);
		if (ui.window(Id.window(), 0, 0, 250, 600)) {
			if (ui.node(Id.node(), "Calc", 0, true)) {
				ui.separator();
				ui.text(state, Right);
				ui.row([3/4, 1/4]);
				if (ui.button("C")) { op = ""; lastState = 0; state = "0"; }
				if (ui.button("/")) { op = "/"; lastState = Std.parseFloat(state); state = "0"; }
				ui.row([1/4, 1/4, 1/4, 1/4]);
				if (ui.button("7")) state += "7";
				if (ui.button("8")) state += "8";
				if (ui.button("9")) state += "9";
				if (ui.button("*")) { op = "*"; lastState = Std.parseFloat(state); state = "0"; }
				ui.row([1/4, 1/4, 1/4, 1/4]);
				if (ui.button("4")) state += "4";
				if (ui.button("5")) state += "5";
				if (ui.button("6")) state += "6";
				if (ui.button("-")) { op = "-"; lastState = Std.parseFloat(state); state = "0"; }
				ui.row([1/4, 1/4, 1/4, 1/4]);
				if (ui.button("1")) state += "1";
				if (ui.button("2")) state += "2";
				if (ui.button("3")) state += "3";
				if (ui.button("+")) { op = "+"; lastState = Std.parseFloat(state); state = "0"; }
				ui.row([2/4, 1/4, 1/4]);
				if (ui.button("0")) state += "0";
				if (ui.button(".")) state += ".";
				if (ui.button("=")) {
					if (op == "+") state = (lastState + Std.parseFloat(state)) + "";
					else if (op == "-") state = (lastState - Std.parseFloat(state)) + "";
					else if (op == "*") state = (lastState * Std.parseFloat(state)) + "";
					else if (op == "/") state = (lastState / Std.parseFloat(state)) + "";
					op = "";
				}
			}
		}
		ui.end();
	}
}
