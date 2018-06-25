package zui;
import zui.Zui;


@:access(zui.Zui)
class Canvas {

	public static var assetMap = new Map<Int, kha.Image>();
	static var events:Array<String> = [];

	public static var screenW = -1;
	public static var screenH = -1;
	static var _ui: Zui;

	public static function draw(ui: Zui, canvas: TCanvas, g: kha.graphics2.Graphics, previewMode = false, coff=0, hwin:Handle=null): Array<String> {
		
		if (screenW == -1) {
			screenW = kha.System.windowWidth();
			screenH = kha.System.windowHeight();
		}

		events = [];

		_ui = ui;
		ui.begin(g);
		ui.g = g;
		if(previewMode){
			var windows =[];
			if(ui.window(hwin,coff,coff,screenW,screenH,true)){
				for (elem in canvas.elements) elem.type != Window ?	drawElement(ui, canvas, elem):windows.push(elem);
			}
			for(window in windows) drawElement(ui,canvas,window);
		}
		else{
			var windows =[];
			for (elem in canvas.elements) elem.type != Window ?	drawElement(ui, canvas, elem):windows.push(elem);
			for(window in windows) drawElement(ui,canvas,window);
		}
		

		ui.end();
		return events;
	}

	static function drawElement(ui: Zui, canvas: TCanvas, element: TElement, px = 0.0, py = 0.0) {

		if (!element.visible) return;

		ui._x = canvas.x + scaled(element.x) + scaled(px);
		ui._y = canvas.y + scaled(element.y) + scaled(py);
		ui._w = scaled(element.width);

		var cw = scaled(canvas.width);
		var ch = scaled(canvas.height);

		switch (element.anchor) {
		case Top:
			ui._x -= (cw - screenW) / 2;
		case TopRight:
			ui._x -= cw - screenW;
		case CenterLeft:
			ui._y -= (ch - screenH) / 2;
		case Center:
			ui._x -= (cw - screenW) / 2;
			ui._y -= (ch - screenH) / 2;
		case CenterRight:
			ui._x -= cw - screenW;
			ui._y -= (ch - screenH) / 2;
		case BottomLeft:
			ui._y -= ch - screenH;
		case Bottom:
			ui._x -= (cw - screenW) / 2;
			ui._y -= ch - screenH;
		case BottomRight:
			ui._x -= cw - screenW;
			ui._y -= ch - screenH;
		}

		var rotated = element.rotation != null && element.rotation != 0;
		if (rotated) ui.g.pushRotation(element.rotation, ui._x + scaled(element.width) / 2, ui._y + scaled(element.height) / 2);

		switch (element.type) {
		case Text:
			var size = ui.fontSize;
			var tcol = ui.t.TEXT_COL;
			ui.fontSize = scaled(element.height);
			ui.t.TEXT_COL = element.color;
			ui.text(element.text);
			ui.fontSize = size;
			ui.t.TEXT_COL = tcol;
		case TextInput:
			ui.g.font = ui.ops.font;
			var str = ui.textInput(Id.handle().nest(element.id, {text: element.text}),element.name,Left);
			if(Reflect.isFunction(element.subDefine.callback)) element.subDefine.callback({text: str});
		case Button:
			if (ui.button(element.text)) {
				if(Reflect.isFunction(element.subDefine.callback)) element.subDefine.callback({text: element.text});
			}
		case Image:
			var image = getAsset(canvas, element.asset);
			if (image != null) {
				ui.imageScrollAlign = false;
				var tint = element.color != null ? element.color : 0xffffffff;
				if (ui.image(image, tint, scaled(element.height)) == zui.Zui.State.Released) {
					var e = element.event;
					if (e != null && e != "") events.push(e);
				}
				ui.imageScrollAlign = true;
			}
		case Combo:
			var comboIndex = ui.combo(Id.handle().nest(element.id),element.subDefine.texts,element.text,element.subDefine.showLabel);
			if( comboIndex != element.subDefine.currentValue){
				element.subDefine.currentValue = comboIndex; 
			}
		case Slider:
			var sliderValue = ui.slider(Id.handle().nest(element.id),element.name,element.subDefine.from, element.subDefine.to,
			element.subDefine.filled,element.subDefine.precision,element.subDefine.displayValue);
			if( sliderValue > element.subDefine.currentFValue || sliderValue < element.subDefine.currentFValue){
				element.subDefine.currentFValue = sliderValue;
			}
		case ElementGroup:
			Ext.elementGroup(ui,element);

		case Check:
			var checked = ui.check(Id.handle().nest(element.id), element.text);
			if(Reflect.isFunction(element.subDefine.callback)) element.subDefine.callback({isCheck: checked, text: element.text});
			
		case Radio:
			if(ui.radio(Id.handle().nest(element.id),element.subDefine.currentValue,element.text)){
				var e = element.event;
				if (e != null && e != "") events.push(e);
			}
		case InlineRadio:
			var inlineIndex = ui.inlineRadio(Id.handle().nest(element.id),element.subDefine.texts);
			if(inlineIndex != element.subDefine.currentValue){
				element.subDefine.currentValue = inlineIndex;
				var e = element.event;
				if (e != null && e != "") events.push(e);
			}
		case Panel:
			if(ui.panel(Id.handle().nest(element.id,{selected: element.subDefine.selected}), element.text,element.subDefine.accent,element.subDefine.isTree)){
				if (element.children != null) for (c in element.children) drawElement(ui, canvas, c, element.x, element.y);
			}
		case Tab:
			if(ui.tab(Id.handle().nest(element.id), element.text)){
				if (element.children != null) for (c in element.children) drawElement(ui, canvas, c, element.x, element.y);
			}
		case Window:
			if(ui.window(Id.handle().nest(element.id), Std.int(element.x),Std.int(element.y),element.width,element.height,element.subDefine.draggable)){
				if (element.children != null) for (c in element.children) drawElement(ui, canvas, c);
			}
		case RadioGroup:
		case ButtonGroup:
		case CheckGroup:
		case Count:
		}
		if (rotated) ui.g.popTransformation();
	}

	public static function getAsset(canvas: TCanvas, asset: String): kha.Image {
		for (a in canvas.assets) if (a.name == asset) return assetMap.get(a.id);
		return null;
	}

	static var elemId = -1;
	public static function getElementId(canvas: TCanvas): Int {
		if (elemId == -1) for (e in canvas.elements) if (elemId < e.id) elemId = e.id;
		return ++elemId;
	}

	static var assetId = -1;
	public static function getAssetId(canvas: TCanvas): Int {
		if (assetId == -1) for (a in canvas.assets) if (assetId < a.id) assetId = a.id;
		return ++assetId;
	}

	static inline function scaled(f: Float): Int { return Std.int(f * _ui.SCALE); }
}

typedef TCanvas = {
	var name: String;
	var x: Float;
	var y: Float;
	var width: Int;
	var height: Int;
	var elements: Array<TElement>;
	@:optional var assets: Array<TAsset>; 
}

typedef TElement = {
	var id: Int;
	var type: ElementType;
	var name: String;
	var x: Float;
	var y: Float;
	var width: Int;
	var height: Int;
	@:optional var rotation: Null<Float>;
	@:optional var text: String;
	@:optional var event: String;
	@:optional var color: Null<Int>;
	@:optional var anchor: Null<Int>;
	@:optional var children: Array<TElement>;
	@:optional var asset: String;
	@:optional var visible: Null<Bool>;
	@:optional var subDefine: TSubDefines;
}
class TSubDefines {

	public function new(){};
	@:optional public var texts: Array<String>;
	@:optional public var currentValue: Int;
	@:optional public var currentFValue: Float;
	@:optional public var from: Float;
	@:optional public var to: Float;
	@:optional public var filled: Bool;
	@:optional public var displayValue: Bool;
	@:optional public var precision: Int;
	@:optional public var selected: Bool;
	@:optional public var accent: Int;
	@:optional public var isTree: Bool;
	@:optional public var showLabel: Bool;
	@:optional public var draggable: Bool;
	@:optional public var callback: TMessage-> Void;
}
@:struct  @:structInit class TMessage {
	@:optional public var text: String;
	@:optional public var position: Int;
	@:optional public var isCheck: Bool;

}

typedef TAsset = {
	var id: Int;
	var name:String;
	var file:String;
}


@:enum abstract ElementType(Int) from Int {
	var Text = 0;
	var TextInput = 1;
	var Image = 2;
	var Button = 3;
	var ButtonGroup = 4;
	var Combo = 5;
	var Slider = 6;
	var Radio = 7;
	var RadioGroup = 8;
	var Check = 9;
	var CheckGroup = 10;
	var InlineRadio = 11;
	var ElementGroup =12;
	var Panel = 13;
	var Tab = 14;
	var Window = 15;
	var Count = 16;
	public static function getType(name: String):Int{
		switch(name){
			case 'Text':
				return 0;
			case 'TextInput':
				return 1;
			case 'Image':
				return 2;
			case 'Button':
				return 3;
			case 'ButtonGroup':
				return 4;
			case 'Combo':
				return 5;
			case 'Slider':
				return 6;
			case 'Radio':
				return 7;
			case 'RadioGroup':
				return 8;
			case 'Check':
				return 9;
			case 'CheckGroup':
				return 10;
			case 'InlineRadio':
				return 11;
			case 'ElementGroup':
				return 12;
			case 'Panel':
				return 13;
			case 'Tab':
				return 14;
			case 'Window':
				return 15;
			default:
				return -1;
		}
	}
}

@:enum abstract Anchor(Int) from Int {
	var TopLeft = 0;
	var Top = 1;
	var TopRight = 2;
	var CenterLeft = 3;
	var Center = 4;
	var CenterRight = 5;
	var BottomLeft = 6;
	var Bottom = 7;
	var BottomRight = 8;
}
