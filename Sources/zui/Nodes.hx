package zui;

class Nodes {

	static var nodeDrag:TNode = null;
	static var linkDrag:TNodeLink = null;
	static var snapFromId = -1;
	static var snapToId = -1;
	static var snapSocket = 0;
	static var snapX = 0.0;
	static var snapY = 0.0;

	static function getNode(nodes: Array<TNode>, id: Int): TNode {
		for (node in nodes) if (node.id == id) return node;
		return null;
	}

	public static function getNodeId(nodes: Array<TNode>): Int {
		var id = 0;
		for (n in nodes) if (n.id >= id) id = n.id + 1;
		return id;
	}

	static function getLinkId(links: Array<TNodeLink>): Int {
		var id = 0;
		for (l in links) if (l.id >= id) id = l.id + 1;
		return id;
	}

	public static function nodeCanvas(ui: Zui, canvas: TNodeCanvas) {
		var nodew = 120;
		for (link in canvas.links) {
			var from = getNode(canvas.nodes, link.fromId);
			var to = getNode(canvas.nodes, link.toId);
			var fromX = from == null ? ui.inputX : from.x + nodew;
			var fromY = from == null ? ui.inputY : from.y + nodeSocketY(link.fromSocket);
			var toX = to == null ? ui.inputX : to.x;
			var toY = to == null ? ui.inputY : to.y + nodeSocketY(link.toSocket + to.outputs.length);

			// Snap to nearest socket
			if (linkDrag == link) {
				if (snapFromId != -1) { fromX = snapX; fromY = snapY; }
				if (snapToId != -1) { toX = snapX; toY = snapY; }
				snapFromId = snapToId = -1;

				for (node in canvas.nodes) {
					var inps = node.inputs;
					var outs = node.outputs;
					var nodeh = nodeHeight(inps.length, outs.length);
					if (ui.getInputInRect(node.x - 5, node.y - 5, nodew + 10, nodeh + 10)) {
						// Snap to output
						if (from == null && node.id != to.id) {
							for (i in 0...outs.length) {
								var sx = node.x + nodew;
								var sy = node.y + nodeSocketY(i);
								if (ui.getInputInRect(sx - 5, sy - 5, 10, 10)) {
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
								var sx = node.x ;
								var sy = node.y + nodeSocketY(i + outs.length);
								if (ui.getInputInRect(sx - 5, sy - 5, 10, 10)) {
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
			drawLink(ui, fromX, fromY, toX, toY);
		}

		for (node in canvas.nodes) {
			var inps = node.inputs;
			var outs = node.outputs;

			// Drag
			var nodeh = nodeHeight(inps.length, outs.length);
			if (ui.inputStarted && ui.getInputInRect(node.x - 5, node.y - 5, nodew + 10, nodeh + 10)) {
				// Check sockets
				for (i in 0...outs.length) {
					var sx = node.x + nodew;
					var sy = node.y + nodeSocketY(i);
					if (ui.getInputInRect(sx - 5, sy - 5, 10, 10)) {
						// New link from output
						var l = { id: getLinkId(canvas.links), fromId: node.id, fromSocket: i, toId: -1, toSocket: -1 };
						canvas.links.push(l);
						linkDrag = l;
						break;
					}
				}
				if (linkDrag == null) {
					for (i in 0...inps.length) {
						var sx = node.x;
						var sy = node.y + nodeSocketY(i + outs.length);
						if (ui.getInputInRect(sx - 5, sy - 5, 10, 10)) {
							// Already has a link - disconnect
							for (l in canvas.links) {
								if (l.toId == node.id && l.toSocket == i) {
									l.toId = l.toSocket = -1;
									linkDrag = l;
									break;
								}
							}
							if (linkDrag != null) break;
							// New link from input
							var l = { id: getLinkId(canvas.links), fromId: -1, fromSocket: -1, toId: node.id, toSocket: i };
							canvas.links.push(l);
							linkDrag = l;
							break;
						}
					}
				}
				// Otherwise drag node
				if (linkDrag == null) nodeDrag = node;
			}
			else if (ui.inputReleased) {
				// Connect to input
				if (snapToId != -1) {
					// Force single link per input
					for (l in canvas.links) {
						if (l.toId == snapToId && l.toSocket == snapSocket) {
							canvas.links.remove(l);
							break;
						}
					}
					linkDrag.toId = snapToId;
					linkDrag.toSocket = snapSocket;
				}
				// Connect to output
				else if (snapFromId != -1) {
					linkDrag.fromId = snapFromId;
					linkDrag.fromSocket = snapSocket;
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

	static function nodeHeight(inputsLength:Int, outputsLength:Int):Int {
		return 40 + inputsLength * 20 + outputsLength * 20;
	}

	static function nodeSocketY(pos:Int):Int {
		return 40 + pos * 20;
	}

	public static function drawNode(ui: Zui, node: TNode) {
		var w = 120;
		var g = ui.g;
		var h = nodeHeight(node.inputs.length, node.outputs.length);
		var nx = node.x;
		var ny = node.y;
		var text = node.name;

		// Header
		g.color = 0xff444444;
		g.fillRect(nx, ny, w, 20);

		// Title
		g.color = 0xffffffff;
		g.font = ui.ops.font;
		g.fontSize = ui.fontSize;
		g.drawString(text, nx, ny);

		// Body
		ny += 20;
		g.color = 0xff222222;
		g.fillRect(nx, ny, w, h - 20);

		// Outputs
		g.color = 0xffffffff;
		for (out in node.outputs) {
			ny += 20;
			kha.graphics2.GraphicsExtension.fillCircle(g, nx + w, ny, 5);
			var strw = ui.ops.font.width(ui.fontSize, out.name);
			g.drawString(out.name, nx + w - strw - 10, ny - 10);
		}

		// Inputs
		for (inp in node.inputs) {
			ny += 20;
			kha.graphics2.GraphicsExtension.fillCircle(g, nx, ny, 5);
			g.drawString(inp.name, nx + 10, ny - 10);
		}
	}

	public static function drawLink(ui: Zui, x1: Float, y1: Float, x2: Float, y2: Float) {
		var g = ui.g;
		var curve = Math.min(Math.abs(y2 - y1) / 6.0, 40.0);
		g.color = 0xffffffff;
		kha.graphics2.GraphicsExtension.drawCubicBezier(g, [x1, x1 + curve, x2 - curve, x2], [y1, y1 + curve, y2 - curve, y2], 20, 2.0);
	}
}

typedef TNodeCanvas = {
	public var nodes: Array<TNode>;
	public var links: Array<TNodeLink>;
}

typedef TNode = {
	public var id: Int;
	public var name: String;
	public var x: Float;
	public var y: Float;
	public var inputs: Array<TNodeSocket>;
	public var outputs: Array<TNodeSocket>;
}

typedef TNodeSocket = {
	public var name: String;
	public var linksId: Array<Int>;
}

typedef TNodeLink = {
	public var id: Int;
	public var fromId: Int;
	public var fromSocket: Int;
	public var toId: Int;
	public var toSocket: Int;
}
