package zui;

class Nodes {

	public var nodeDrag:TNode = null;
	public var nodeSelected:TNode = null;
	var linkDrag:TNodeLink = null;
	var snapFromId = -1;
	var snapToId = -1;
	var snapSocket = 0;
	var snapX = 0.0;
	var snapY = 0.0;
	var panX = 0.0;
	var panY = 0.0;
	var SCALE = 1.0;
	var handle = new Zui.Handle();

	public function new() {}

	inline function NODE_W() { return 140; }
	function NODE_H(node:TNode):Int {
		var buttonsH = 0;
		for (but in node.buttons) {
			if (but.type == 'RGBA') buttonsH += 80;
			else buttonsH += 20;
		}
		return 40 + node.inputs.length * 20 + node.outputs.length * 20 + buttonsH;
	}
	inline function NODE_X(node:TNode) { return node.x + panX; }
	inline function NODE_Y(node:TNode) { return node.y + panY; }

	inline function p(f:Float):Int { return Std.int(f * SCALE); }
	inline function SOCKET_Y(pos:Int):Int { return 40 + pos * 20; }

	function getNode(nodes: Array<TNode>, id: Int): TNode {
		for (node in nodes) if (node.id == id) return node;
		return null;
	}

	public function getNodeId(nodes: Array<TNode>): Int {
		var id = 0;
		for (n in nodes) if (n.id >= id) id = n.id + 1;
		return id;
	}

	function getLinkId(links: Array<TNodeLink>): Int {
		var id = 0;
		for (l in links) if (l.id >= id) id = l.id + 1;
		return id;
	}

	public function getSocketId(nodes: Array<TNode>): Int {
		var id = 0;
		for (n in nodes) {
			for (s in n.inputs) if (s.id >= id) id = s.id + 1;
			for (s in n.outputs) if (s.id >= id) id = s.id + 1;
		}
		return id;
	}

	public function nodeCanvas(ui: Zui, canvas: TNodeCanvas) {
		SCALE = ui.ops.scaleFactor;
		var wx = ui._windowX;
		var wy = ui._windowY;

		// Pan cavas
		if (ui.inputDownR) { panX += ui.inputDX; panY += ui.inputDY; }

		for (link in canvas.links) {
			var from = getNode(canvas.nodes, link.from_id);
			var to = getNode(canvas.nodes, link.to_id);
			var fromX = from == null ? ui.inputX : wx + NODE_X(from) + NODE_W();
			var fromY = from == null ? ui.inputY : wy + NODE_Y(from) + SOCKET_Y(link.from_socket);
			var toX = to == null ? ui.inputX : wx + NODE_X(to);
			var toY = to == null ? ui.inputY : wy + NODE_Y(to) + SOCKET_Y(link.to_socket + to.outputs.length);

			// Snap to nearest socket
			if (linkDrag == link) {
				if (snapFromId != -1) { fromX = snapX; fromY = snapY; }
				if (snapToId != -1) { toX = snapX; toY = snapY; }
				snapFromId = snapToId = -1;

				for (node in canvas.nodes) {
					var inps = node.inputs;
					var outs = node.outputs;
					var nodeh = NODE_H(node);
					if (ui.getInputInRect(wx + NODE_X(node) - 10, wy + NODE_Y(node) - 10, NODE_W() + 20, nodeh + 20)) {
						// Snap to output
						if (from == null && node.id != to.id) {
							for (i in 0...outs.length) {
								var sx = wx + NODE_X(node) + NODE_W();
								var sy = wy + NODE_Y(node) + SOCKET_Y(i);
								if (ui.getInputInRect(sx - 10, sy - 10, 20, 20)) {
									snapX = sx;
									snapY = sy;
									snapFromId = node.id;
									snapSocket = i;
									break;
								}
							}
						}
						// Snap to input
						else if (to == null && node.id != from.id) {
							for (i in 0...inps.length) {
								var sx = wx + NODE_X(node) ;
								var sy = wy + NODE_Y(node) + SOCKET_Y(i + outs.length);
								if (ui.getInputInRect(sx - 10, sy - 10, 20, 20)) {
									snapX = sx;
									snapY = sy;
									snapToId = node.id;
									snapSocket = i;
									break;
								}
							}
						}
					}
				}
			}
			drawLink(ui, fromX - wx, fromY - wy, toX - wx, toY - wy);
		}

		for (node in canvas.nodes) {
			var inps = node.inputs;
			var outs = node.outputs;

			// Drag node
			var nodeh = NODE_H(node);
			if (ui.inputStarted && ui.getInputInRect(wx + NODE_X(node) - 10, wy + NODE_Y(node), NODE_W() + 20, 20)) {
				nodeDrag = node;
				nodeSelected = nodeDrag;
			}
			if (ui.inputStarted && ui.getInputInRect(wx + NODE_X(node) - 10, wy + NODE_Y(node) - 10, NODE_W() + 20, nodeh + 20)) {
				// Check sockets
				for (i in 0...outs.length) {
					var sx = wx + NODE_X(node) + NODE_W();
					var sy = wy + NODE_Y(node) + SOCKET_Y(i);
					if (ui.getInputInRect(sx - 10, sy - 10, 20, 20)) {
						// New link from output
						var l = { id: getLinkId(canvas.links), from_id: node.id, from_socket: i, to_id: -1, to_socket: -1 };
						canvas.links.push(l);
						linkDrag = l;
						break;
					}
				}
				if (linkDrag == null) {
					for (i in 0...inps.length) {
						var sx = wx + NODE_X(node);
						var sy = wy + NODE_Y(node) + SOCKET_Y(i + outs.length);
						if (ui.getInputInRect(sx - 10, sy - 10, 20, 20)) {
							// Already has a link - disconnect
							for (l in canvas.links) {
								if (l.to_id == node.id && l.to_socket == i) {
									l.to_id = l.to_socket = -1;
									linkDrag = l;
									break;
								}
							}
							if (linkDrag != null) break;
							// New link from input
							var l = { id: getLinkId(canvas.links), from_id: -1, from_socket: -1, to_id: node.id, to_socket: i };
							canvas.links.push(l);
							linkDrag = l;
							break;
						}
					}
				}
			}
			else if (ui.inputReleased) {
				// Connect to input
				if (snapToId != -1) {
					// Force single link per input
					for (l in canvas.links) {
						if (l.to_id == snapToId && l.to_socket == snapSocket) {
							canvas.links.remove(l);
							break;
						}
					}
					linkDrag.to_id = snapToId;
					linkDrag.to_socket = snapSocket;
				}
				// Connect to output
				else if (snapFromId != -1) {
					linkDrag.from_id = snapFromId;
					linkDrag.from_socket = snapSocket;
				}
				// Remove dragged link
				else if (linkDrag != null) {
					canvas.links.remove(linkDrag);
				}
				snapToId = snapFromId = -1;
				linkDrag = null;
				nodeDrag = null;
			}
			if (nodeDrag == node) {
				// handle.redraws = 2;
				node.x += Std.int(ui.inputDX);
				node.y += Std.int(ui.inputDY);
			}

			drawNode(ui, node);
		}
	}

	public function drawNode(ui: Zui, node: TNode) {
		var wx = ui._windowX;
		var wy = ui._windowY;
		var w = p(NODE_W());
		var g = ui.g;
		var h = p(NODE_H(node));
		var nx = p(NODE_X(node));
		var ny = p(NODE_Y(node));
		var text = node.name;
		var lineh = p(20);

		// Outline
		g.color = node == nodeSelected ? 0xffaaaaaa : 0xff202020;
		g.fillRect(nx - 1, ny - 1, w + 2, h + 2);

		// Header
		g.color = node.color;
		g.fillRect(nx, ny, w, lineh);

		// Title
		g.color = 0xffe7e7e7;
		g.font = ui.ops.font;
		g.fontSize = ui.fontSize;
		var textw = g.font.width(g.fontSize, text);
		g.drawString(text, nx + w / 2 - textw / 2, ny + 3);

		// Body
		ny += lineh;
		g.color = 0xff303030;
		g.fillRect(nx, ny, w, h - lineh);

		// Outputs
		for (out in node.outputs) {
			ny += lineh;
			g.color = out.color;
			kha.graphics2.GraphicsExtension.fillCircle(g, nx + w, ny, 5);
			var strw = ui.ops.font.width(ui.fontSize, out.name);
			g.color = 0xffe7e7e7;
			g.drawString(out.name, nx + w - strw - 12, ny - 7);
		}

		// Buttons
		var nhandle = handle.nest(node.id);
		for (but in node.buttons) {

			if (but.type == 'RGBA') {
				var val = node.outputs[but.output].default_value;

				ny += lineh; // 18 + 2 separator
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				val[0] = ui.slider(nhandle.nest(0, {value: val[0]}), "R", 0.0, 1.0, true);

				ny += lineh;
				val[1] = ui.slider(nhandle.nest(1, {value: val[1]}), "G", 0.0, 1.0, true);
			
				ny += lineh;
				val[2] = ui.slider(nhandle.nest(2, {value: val[2]}), "B", 0.0, 1.0, true);

				ny += lineh;
				ui.text("", Right, kha.Color.fromFloats(val[0], val[1], val[2], val[3]));
			}
			else if (but.type == 'VALUE') {
				ny += lineh;
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				var soc = node.outputs[but.output];
				soc.default_value = ui.slider(nhandle.nest(0, {value: soc.default_value}), "Value", 0.0, 1.0, true);
			}
			else if (but.type == 'STRING') {
				ny += lineh;
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				// TODO: Handle both color and alpha, .output to array?
				var soc = node.outputs[but.output];
				soc.default_value = but.default_value = ui.textInput(nhandle.nest(0, {text: soc.default_value}), "");
				ny += 10; // Fix align?
			}
		}

		// Inputs
		for (inp in node.inputs) {
			ny += lineh;
			g.color = inp.color;
			kha.graphics2.GraphicsExtension.fillCircle(g, nx, ny, 5);
			g.color = 0xffe7e7e7;
			g.drawString(inp.name, nx + 12, ny - 7);
		}
	}

	public function drawLink(ui: Zui, x1: Float, y1: Float, x2: Float, y2: Float) {
		var g = ui.g;
		var curve = Math.min(Math.abs(y2 - y1) / 6.0, 40.0);
		g.color = 0xffadadad;
		// kha.graphics2.GraphicsExtension.drawCubicBezier(g, [x1, x1 + curve, x2 - curve, x2], [y1, y1 + curve, y2 - curve, y2], 20, 2.0);
		g.drawLine(p(x1), p(y1), p(x2), p(y2), 2.0);
	}
}

typedef TNodeCanvas = {
	public var nodes: Array<TNode>;
	public var links: Array<TNodeLink>;
}

typedef TNode = {
	public var id: Int;
	public var name: String;
	public var type: String;
	public var x: Float;
	public var y: Float;
	public var inputs: Array<TNodeSocket>;
	public var outputs: Array<TNodeSocket>;
	public var buttons: Array<TNodeButton>;
	public var color: Int;
}

typedef TNodeSocket = {
	public var id: Int;
	public var node_id: Int;
	public var name: String;
	public var type: String;
	public var default_value: Dynamic;
	public var color: Int;
}

typedef TNodeLink = {
	public var id: Int;
	public var from_id: Int;
	public var from_socket: Int;
	public var to_id: Int;
	public var to_socket: Int;
}

typedef TNodeButton = {
	public var name: String;
	public var type: String;
	public var output: Int;
	@:optional public var default_value: Dynamic;
}
