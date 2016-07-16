package;
import kha.System;

class Main {
	public static function main() {
		System.init({ title: "Elements", width: 800, height: 600 }, initialized);
	}
	
	private static function initialized(): Void {
		var game = new Elements();
		System.notifyOnRender(game.render);
	}
}
