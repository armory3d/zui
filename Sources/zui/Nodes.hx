package zui;

@:access(zui.Zui)
class Nodes {

	public var nodesDrag = false;
	public var nodesSelected: Array<TNode> = [];
	public var panX = 0.0;
	public var panY = 0.0;
	public var zoom = 1.0;
	public var uiw = 0;
	public var uih = 0;
	public var SCALE = 1.0;
	var dragged = false;
	var moveOnTop: TNode = null;
	var linkDrag: TNodeLink = null;
	var snapFromId = -1;
	var snapToId = -1;
	var snapSocket = 0;
	var snapX = 0.0;
	var snapY = 0.0;
	var handle = new Zui.Handle();
	var lastNodesCount = 0;
	static var elementsBaked = false;
	static var socketImage: kha.Image = null;
	static var clipboard = "";

	public static var excludeRemove: Array<String> = []; // No removal for listed node types

	public function new() {}

	public inline function PAN_X(): Float { var zoomPan = (1.0 - zoom) * uiw / 2.5; return panX * SCALE + zoomPan; }
	public inline function PAN_Y(): Float { var zoomPan = (1.0 - zoom) * uih / 2.5; return panY * SCALE + zoomPan; }
	inline function LINE_H(): Int { return Std.int(22 * SCALE); }
	function BUTTONS_H(node: TNode): Int {
		var buttonsH = 0.0;
		for (but in node.buttons) {
			if (but.type == 'RGBA') buttonsH += 132 * SCALE;
			else if (but.type == 'VECTOR') buttonsH += LINE_H() * 4;
			else if (but.type == 'RAMP') buttonsH += LINE_H() * 9.5;
			else if (but.type == 'CURVES') buttonsH += LINE_H() * 8;
			else buttonsH += LINE_H();
		}
		return Std.int(buttonsH);
	}
	inline function NODE_H(node: TNode): Int {
		return Std.int(LINE_H() * 2 + node.inputs.length * LINE_H() + node.outputs.length * LINE_H() + BUTTONS_H(node));
	}
	inline function NODE_W(): Int { return Std.int(140 * SCALE); }
	inline function NODE_X(node: TNode) { return node.x * SCALE + PAN_X(); }
	inline function NODE_Y(node: TNode) { return node.y * SCALE + PAN_Y(); }
	inline function SOCKET_Y(pos: Int): Int { return LINE_H() * 2 + pos * LINE_H(); }
	inline function p(f: Float): Float { return f * SCALE; }

	public function getNode(nodes: Array<TNode>, id: Int): TNode {
		for (node in nodes) if (node.id == id) return node;
		return null;
	}

	var nodeId = -1;
	public function getNodeId(nodes: Array<TNode>): Int {
		if (nodeId == -1) for (n in nodes) if (nodeId < n.id) nodeId = n.id;
		return ++nodeId;
	}

	public function getLinkId(links: Array<TNodeLink>): Int {
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

	function bakeElements(ui: Zui) {
		ui.g.end();
		elementsBaked = true;
		socketImage = kha.Image.createRenderTarget(20, 20);
		var g = socketImage.g2;
		g.begin(true, 0x00000000);
		g.color = 0xff000000;
		kha.graphics2.GraphicsExtension.fillCircle(g, 10, 10, 10);
		g.color = 0xffffffff;
		kha.graphics2.GraphicsExtension.fillCircle(g, 10, 10, 8);
		g.end();
		ui.g.begin(false);
	}

	public function nodeCanvas(ui: Zui, canvas: TNodeCanvas) {
		if (!elementsBaked) bakeElements(ui);
		if (lastNodesCount > canvas.nodes.length) ui.changed = true;
		lastNodesCount = canvas.nodes.length;

		var wx = ui._windowX;
		var wy = ui._windowY;

		// Pan cavas
		if (ui.inputDownR) {
			panX += ui.inputDX / SCALE;
			panY += ui.inputDY / SCALE;
		}

		// Zoom canvas
		if (ui.inputWheelDelta != 0) {
			zoom += -ui.inputWheelDelta / 10;
			if (zoom < 0.5) zoom = 0.5;
			else if (zoom > 1.0) zoom = 1.0;
			zoom = Math.round(zoom * 10) / 10;
			uiw = ui._w;
			uih = ui._h;
		}
		SCALE = ui.ops.scaleFactor * zoom;
		var _SCALE = ui.SCALE;
		ui.setScale(SCALE); // Apply zoomed scale
		ui.elementsBaked = true;
		ui.g.font = ui.ops.font;
		ui.g.fontSize = ui.fontSize;

		for (link in canvas.links) {
			var from = getNode(canvas.nodes, link.from_id);
			var to = getNode(canvas.nodes, link.to_id);
			var fromX = from == null ? ui.inputX : wx + NODE_X(from) + NODE_W();
			var fromY = from == null ? ui.inputY : wy + NODE_Y(from) + SOCKET_Y(link.from_socket);
			var toX = to == null ? ui.inputX : wx + NODE_X(to);
			var toY = to == null ? ui.inputY : wy + NODE_Y(to) + SOCKET_Y(link.to_socket + to.outputs.length) + BUTTONS_H(to);

			// Snap to nearest socket
			if (linkDrag == link) {
				if (snapFromId != -1) { fromX = snapX; fromY = snapY; }
				if (snapToId != -1) { toX = snapX; toY = snapY; }
				snapFromId = snapToId = -1;

				for (node in canvas.nodes) {
					var inps = node.inputs;
					var outs = node.outputs;
					var nodeh = NODE_H(node);
					var rx = wx + NODE_X(node) - LINE_H() / 2;
					var ry = wy + NODE_Y(node) - LINE_H() / 2;
					var rw = NODE_W() + LINE_H();
					var rh = nodeh + LINE_H();
					if (ui.getInputInRect(rx, ry, rw, rh)) {
						// Snap to output
						if (from == null && node.id != to.id) {
							for (i in 0...outs.length) {
								var sx = wx + NODE_X(node) + NODE_W();
								var sy = wy + NODE_Y(node) + SOCKET_Y(i);
								var rx = sx - LINE_H() / 2;
								var ry = sy - LINE_H() / 2;
								if (ui.getInputInRect(rx, ry, LINE_H(), LINE_H())) {
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
								var sy = wy + NODE_Y(node) + SOCKET_Y(i + outs.length) + BUTTONS_H(node);
								var rx = sx - LINE_H() / 2;
								var ry = sy - LINE_H() / 2;
								if (ui.getInputInRect(rx, ry, LINE_H(), LINE_H())) {
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

			var selected = false;
			for (n in nodesSelected) {
				if (link.from_id == n.id || link.to_id == n.id) {
					selected = true;
					break;
				}
			}

			drawLink(ui, fromX - wx, fromY - wy, toX - wx, toY - wy, selected);
		}

		for (node in canvas.nodes) {
			var inps = node.inputs;
			var outs = node.outputs;

			// Drag node
			var nodeh = NODE_H(node);
			if (ui.getInputInRect(wx + NODE_X(node) - LINE_H() / 2, wy + NODE_Y(node), NODE_W() + LINE_H(), LINE_H())) {
				if (ui.inputStarted) {
					if (ui.isShiftDown) {
						// Add to selection or deselect
						isSelected(node) ?
							nodesSelected.remove(node) :
							nodesSelected.push(node);
					}
					else if (nodesSelected.length <= 1) {
						// Selecting single node, otherwise wait for input release
						nodesSelected = [node];
					}
					moveOnTop = node; // Place selected node on top
					nodesDrag = true;
					dragged = false;
				}
				else if (ui.inputReleased && !ui.isShiftDown && !dragged) {
					// No drag performed, select single node
					nodesSelected = [node];
				}
			}
			if (ui.inputStarted && ui.getInputInRect(wx + NODE_X(node) - LINE_H() / 2, wy + NODE_Y(node) - LINE_H() / 2, NODE_W() + LINE_H(), nodeh + LINE_H())) {
				// Check sockets
				for (i in 0...outs.length) {
					var sx = wx + NODE_X(node) + NODE_W();
					var sy = wy + NODE_Y(node) + SOCKET_Y(i);
					if (ui.getInputInRect(sx - LINE_H() / 2, sy - LINE_H() / 2, LINE_H(), LINE_H())) {
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
						var sy = wy + NODE_Y(node) + SOCKET_Y(i + outs.length) + BUTTONS_H(node);
						if (ui.getInputInRect(sx - LINE_H() / 2, sy - LINE_H() / 2, LINE_H(), LINE_H())) {
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
					ui.changed = true;
				}
				// Connect to output
				else if (snapFromId != -1) {
					linkDrag.from_id = snapFromId;
					linkDrag.from_socket = snapSocket;
					ui.changed = true;
				}
				// Remove dragged link
				else if (linkDrag != null) {
					canvas.links.remove(linkDrag);
					ui.changed = true;
				}
				snapToId = snapFromId = -1;
				linkDrag = null;
				nodesDrag = false;
			}
			if (nodesDrag && isSelected(node) && !ui.inputDownR) {
				if (ui.inputDX != 0 || ui.inputDY != 0) {
					dragged = true;
					node.x += Std.int(ui.inputDX / SCALE);
					node.y += Std.int(ui.inputDY / SCALE);
				}
			}

			drawNode(ui, node, canvas);
		}

		// Place selected node on top
		if (moveOnTop != null) {
			canvas.nodes.remove(moveOnTop);
			canvas.nodes.push(moveOnTop);
			moveOnTop = null;
		}

		// Node copy & paste
		var cutSelected = false;
		if (Zui.isCopy) {
			var copyNodes: Array<TNode> = [];
			for (n in nodesSelected) {
				if (excludeRemove.indexOf(n.type) >= 0) continue;
				copyNodes.push(n);
			}
			var copyLinks: Array<TNodeLink> = [];
			for (l in canvas.links) {
				if (getNode(nodesSelected, l.from_id) != null &&
					getNode(nodesSelected, l.to_id) != null) {
					copyLinks.push(l);
				}
			}
			var copyCanvas: TNodeCanvas = { name: canvas.name, nodes: copyNodes, links: copyLinks };
			clipboard = haxe.Json.stringify(copyCanvas);
			cutSelected = Zui.isCut;
		}
		if (Zui.isPaste) {
			var pasteCanvas: TNodeCanvas = haxe.Json.parse(clipboard);
			for (l in pasteCanvas.links) {
				// Assign unique link id
				l.id = getLinkId(canvas.links);
				canvas.links.push(l);
			}
			for (n in pasteCanvas.nodes) {
				// Assign unique node id
				var old_id = n.id;
				n.id = getNodeId(canvas.nodes);
				for (l in pasteCanvas.links) {
					if (l.from_id == old_id) l.from_id = n.id;
					else if (l.to_id == old_id) l.to_id = n.id;
				}
				n.x += 10;
				n.y += 10;
				canvas.nodes.push(n);
			}
			nodesSelected = pasteCanvas.nodes;
		}

		// Select all nodes
		if (ui.isCtrlDown && ui.key == kha.input.KeyCode.A) {
			nodesSelected = [];
			for (n in canvas.nodes) nodesSelected.push(n);
		}

		// Node removal
		if ((ui.isBackspaceDown || ui.isDeleteDown || cutSelected) && !ui.isTyping) {
			var i = nodesSelected.length - 1;
			while (i >= 0) {
				var n = nodesSelected[i--];
				if (excludeRemove.indexOf(n.type) >= 0) continue;
				removeNode(n, canvas);
				ui.changed = true;
			}
		}

		ui.setScale(_SCALE); // Restore non-zoomed scale
		ui.elementsBaked = true;
	}

	// Global enum mapping for now..
	public static var getEnumTexts: Void->Array<String> = null;
	public static var mapEnum: String->String = null;
	
	inline function isSelected(node: TNode) { return nodesSelected.indexOf(node) >= 0; }

	public function drawNode(ui: Zui, node: TNode, canvas: TNodeCanvas) {
		var wx = ui._windowX;
		var wy = ui._windowY;
		var uiX = ui._x;
		var uiY = ui._y;
		var uiW = ui._w;
		var w = NODE_W();
		var g = ui.g;
		var h = NODE_H(node);
		var nx = NODE_X(node);
		var ny = NODE_Y(node);
		var text = node.name;
		var lineh = LINE_H();

		// Outline
		g.color = isSelected(node) ? 0xffaaaaaa : 0xff202020;
		g.fillRect(nx - 1, ny - 1, w + 2, h + 2);

		// Header
		g.color = node.color;
		g.fillRect(nx, ny, w, lineh);

		// Body
		g.color = ui.t.WINDOW_BG_COL;
		g.fillRect(nx, ny + lineh, w, h - lineh);

		// Title
		g.color = 0xffa0e0e0;
		var textw = g.font.width(ui.fontSize, text);
		g.drawString(text, nx + w / 2 - textw / 2, ny + p(4));
		ny += lineh;

		// Outputs
		for (out in node.outputs) {
			ny += lineh;
			g.color = out.color;
			g.drawScaledImage(socketImage, nx + w - p(5), ny - p(5), p(10), p(10));
		}
		ny -= lineh * node.outputs.length;
		g.color = 0xffa0e0e0;
		for (out in node.outputs) {
			ny += lineh;
			var strw = ui.ops.font.width(ui.fontSize, out.name);
			g.drawString(out.name, nx + w - strw - p(12), ny - p(7));
		}

		// Buttons
		var nhandle = handle.nest(node.id);
		ny -= lineh / 3; // Fix align
		for (buti in 0...node.buttons.length) {
			var but = node.buttons[buti];

			if (but.type == 'RGBA') {
				ny += lineh; // 18 + 2 separator
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				var val = node.outputs[but.output].default_value;
				nhandle.color = kha.Color.fromFloats(val[0], val[1], val[2]);
				Ext.colorWheel(ui, nhandle, false);
				val[0] = nhandle.color.R; val[1] = nhandle.color.G; val[2] = nhandle.color.B;
			}
			else if (but.type == 'VECTOR') {
				ny += lineh;
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				var min = but.min != null ? but.min : 0.0;
				var max = but.max != null ? but.max : 1.0;
				var labelCol = ui.t.LABEL_COL;
				var textOff = ui.t.TEXT_OFFSET;
				ui.t.LABEL_COL = 0xffa0e0e0;
				ui.t.TEXT_OFFSET = 6;
				ui.text(but.name);
				but.default_value[0] = ui.slider(nhandle.nest(buti).nest(0, {value: but.default_value[0]}), "X", min, max, true, 100, true, Left);
				but.default_value[1] = ui.slider(nhandle.nest(buti).nest(1, {value: but.default_value[1]}), "Y", min, max, true, 100, true, Left);
				but.default_value[2] = ui.slider(nhandle.nest(buti).nest(2, {value: but.default_value[2]}), "Z", min, max, true, 100, true, Left);
				ui.t.LABEL_COL = labelCol;
				ui.t.TEXT_OFFSET = textOff;
				if (but.output != null) node.outputs[but.output].default_value = but.default_value;
				ny += lineh * 3;
			}
			else if (but.type == 'VALUE') {
				ny += lineh;
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				var soc = node.outputs[but.output];
				var min = but.min != null ? but.min : 0.0;
				var max = but.max != null ? but.max : 1.0;
				var labelCol = ui.t.LABEL_COL;
				var textOff = ui.t.TEXT_OFFSET;
				ui.t.LABEL_COL = 0xffa0e0e0;
				ui.t.TEXT_OFFSET = 6;
				soc.default_value = ui.slider(nhandle.nest(0, {value: soc.default_value}), "Value", min, max, true, 100, true, Left);
				ui.t.LABEL_COL = labelCol;
				ui.t.TEXT_OFFSET = textOff;
			}
			else if (but.type == 'STRING') {
				ny += lineh;
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				var soc = but.output != null ? node.outputs[but.output] : null;
				but.default_value = ui.textInput(nhandle.nest(0, {text: soc != null ? soc.default_value : ""}), but.name);
				if (soc != null) soc.default_value = but.default_value;
			}
			else if (but.type == 'ENUM') {
				ny += lineh;
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				var arrayData = Std.is(but.data, Array);
				var texts = arrayData ? but.data : getEnumTexts();
				but.default_value = ui.combo(nhandle.nest(buti, {position: but.default_value}), texts, but.name);
				if (!arrayData) but.data = mapEnum(texts[but.default_value]);
			}
			else if (but.type == 'BOOL') {
				ny += lineh;
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				ui.check(nhandle.nest(0, {selected: but.default_value}), but.name);
			}
			else if (but.type == 'RAMP') {
				ny += lineh;
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				// Preview
				var vals:Array<Array<Float>> = but.default_value;
				var sw = w / SCALE;
				for (val in vals) {
					var pos = val[4];
					var col = kha.Color.fromFloats(val[0], val[1], val[2]);
					ui.fill(pos * sw, 0, (1.0 - pos) * sw, lineh - 2 * SCALE, col);
				}
				ui._y += lineh;
				// Edit
				var ihandle = nhandle.nest(2);
				ui.row([1/4, 1/4, 2/4]);
				if (ui.button("+")) {
					var last = vals[vals.length - 1];
					vals.push([last[0], last[1], last[2], last[3], 1.0]); // [[r, g, b, a, pos], ..]
					ihandle.value += 1;
				}
				if (ui.button("-") && vals.length > 1) {
					vals.pop();
					ihandle.value -= 1;
				}
				but.data = ui.combo(nhandle.nest(1, {position: but.data}), ["Linear", "Constant"], "Interpolate");
				ui.row([1/2, 1/2]);
				var i = Std.int(ui.slider(ihandle, "Index", 0, vals.length - 1, false, 1, true, Left));
				var val = vals[i];
				nhandle.nest(3).value = val[4];
				val[4] = ui.slider(nhandle.nest(3), "Pos", 0, 1, true, 100, true, Left);
				var chandle = nhandle.nest(4);
				chandle.color = kha.Color.fromFloats(val[0], val[1], val[2]);
				Ext.colorWheel(ui, chandle, false);
				val[0] = chandle.color.R;
				val[1] = chandle.color.G;
				val[2] = chandle.color.B;
				ny += lineh * 8 + lineh * 0.5;
			}
			else if (but.type == 'CURVES') {
				ny += lineh;
				ui._x = nx;
				ui._y = ny;
				ui._w = w;
				ui.row([1/3, 1/3, 1/3]);
				ui.radio(nhandle.nest(1), 0, "X");
				ui.radio(nhandle.nest(1), 1, "Y");
				ui.radio(nhandle.nest(1), 2, "Z");
				// Preview
				var axis = nhandle.nest(1).position;
				var val:Array<Float> = but.default_value[axis]; // [[x, y, x, y,..], [x, y], ..]
				var num = Std.int(val.length / 2);
				// for (i in 0...num) { ui.line(); }
				ui._y += lineh * 5;
				// Edit
				ui.row([1/5, 1/5, 3/5]);
				if (ui.button("+")) {
					val.push(0); val.push(0);
				}
				if (ui.button("-")) {
					if (val.length > 4) { val.pop(); val.pop(); }
				}
				var i = Std.int(ui.slider(nhandle.nest(2).nest(axis, {position: 0}), "Index", 0, num - 1, false, 1, true, Left));
				ui.row([1/2, 1/2]);
				nhandle.nest(3).value = val[i * 2    ];
				nhandle.nest(4).value = val[i * 2 + 1];
				val[i * 2    ] = ui.slider(nhandle.nest(3, {value: 0}), "X", -1, 1, true, 100, true, Left);
				val[i * 2 + 1] = ui.slider(nhandle.nest(4, {value: 0}), "Y", -1, 1, true, 100, true, Left);
				ny += lineh * 7;
			}
		}
		ny += lineh / 3; // Fix align

		// Inputs
		for (i in 0...node.inputs.length) {
			var inp = node.inputs[i];
			ny += lineh;
			g.color = inp.color;
			g.drawScaledImage(socketImage, nx - p(5), ny - p(5), p(10), p(10));
			var isLinked = false;
			for (l in canvas.links) if (l.to_id == node.id && l.to_socket == i) { isLinked = true; break; }
			if (!isLinked && inp.type == 'VALUE') {
				ui._x = nx + p(6);
				ui._y = ny - p(9);
				ui._w = Std.int(w - p(6));
				var soc = inp;
				var min = soc.min != null ? soc.min : 0.0;
				var max = soc.max != null ? soc.max : 1.0;
				var labelCol = ui.t.LABEL_COL;
				var textOff = ui.t.TEXT_OFFSET;
				ui.t.LABEL_COL = 0xffa0e0e0;
				ui.t.TEXT_OFFSET = 6;
				soc.default_value = ui.slider(nhandle.nest(i, {value: soc.default_value}), inp.name, min, max, true, 100, true, Left);
				ui.t.LABEL_COL = labelCol;
				ui.t.TEXT_OFFSET = textOff;
			}
			else {
				g.color = 0xffa0e0e0;
				g.drawString(inp.name, nx + p(12), ny - p(7));
			}
		}

		ui._x = uiX;
		ui._y = uiY;
		ui._w = uiW;
	}

	public function drawLink(ui: Zui, x1: Float, y1: Float, x2: Float, y2: Float, highlight: Bool = false) {
		var g = ui.g;
		g.color = highlight ? 0xccadadad : 0xcc777777;
		// var curve = Math.min(Math.abs(y2 - y1) / 6.0, 40.0);
		// kha.graphics2.GraphicsExtension.drawCubicBezier(g, [x1, x1 + curve, x2 - curve, x2], [y1, y1 + curve, y2 - curve, y2], 20, 2.0);
		g.drawLine(x1, y1, x2, y2, 1.0);
		g.color = highlight ? 0x99adadad : 0x99777777;
		g.drawLine(x1 + 0.5, y1, x2 + 0.5, y2, 1.0);
		g.drawLine(x1 - 0.5, y1, x2 - 0.5, y2, 1.0);
		g.drawLine(x1, y1 + 0.5, x2, y2 + 0.5, 1.0);
		g.drawLine(x1, y1 - 0.5, x2, y2 - 0.5, 1.0);
		// g.color = 0x66adadad;
		// g.drawLine(x1 + 1.0, y1, x2 + 1.0, y2, 1.0);
		// g.drawLine(x1 - 1.0, y1, x2 - 1.0, y2, 1.0);
		// g.drawLine(x1, y1 + 1.0, x2, y2 + 1.0, 1.0);
		// g.drawLine(x1, y1 - 1.0, x2, y2 - 1.0, 1.0);
	}

	public function removeNode(n: TNode, canvas: TNodeCanvas) {
		if (n == null) return;
		var i = 0;
		while (i < canvas.links.length) {
			var l = canvas.links[i];
			if (l.from_id == n.id || l.to_id == n.id) {
				canvas.links.splice(i, 1);
			}
			else i++;
		}
		canvas.nodes.remove(n);
	}
}

typedef TNodeCanvas = {
	var name: String;
	var nodes: Array<TNode>;
	var links: Array<TNodeLink>;
}

typedef TNode = {
	var id: Int;
	var name: String;
	var type: String;
	var x: Float;
	var y: Float;
	var inputs: Array<TNodeSocket>;
	var outputs: Array<TNodeSocket>;
	var buttons: Array<TNodeButton>;
	var color: Int;
}

typedef TNodeSocket = {
	var id: Int;
	var node_id: Int;
	var name: String;
	var type: String;
	var color: Int;
	var default_value: Dynamic;
	@:optional var min: Null<Float>;
	@:optional var max: Null<Float>;
}

typedef TNodeLink = {
	var id: Int;
	var from_id: Int;
	var from_socket: Int;
	var to_id: Int;
	var to_socket: Int;
}

typedef TNodeButton = {
	var name: String;
	var type: String;
	@:optional var output: Null<Int>;
	@:optional var default_value: Dynamic;
	@:optional var data: Dynamic;
	@:optional var min: Null<Float>;
	@:optional var max: Null<Float>;
}
