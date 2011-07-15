package net.systemeD.halcyonpdf.connection {
    import flash.geom.Point;
    
	/*	Changes for Halcyon/PDF:
		- all methods referencing actions deleted
	*/

    public class Way extends Entity {
        private var nodes:Array;
		private var edge_l:Number;
		private var edge_r:Number;
		private var edge_t:Number;
		private var edge_b:Number;
		public static var entity_type:String = 'way';

        public function Way(connection:Connection, id:Number, version:uint, tags:Object, loaded:Boolean, nodes:Array, uid:Number = NaN, timestamp:String = null) {
            super(connection, id, version, tags, loaded, uid, timestamp);
            this.nodes = nodes;
			for each (var node:Node in nodes) { node.addParent(this); }
			calculateBbox();
        }

		public function update(version:uint, tags:Object, loaded:Boolean, parentsLoaded:Boolean, nodes:Array, uid:Number = NaN, timestamp:String = null):void {
			var node:Node;
			for each (node in this.nodes) { node.removeParent(this); }
			updateEntityProperties(version,tags,loaded,parentsLoaded,uid,timestamp); this.nodes=nodes;
			for each (node in nodes) { node.addParent(this); }
			calculateBbox();
		}
		
        public function get length():uint {
            return nodes.length;
        }

		private function calculateBbox():void {
			edge_l=999999; edge_r=-999999;
			edge_b=999999; edge_t=-999999;
			for each (var node:Node in nodes) { expandBbox(node); }
		}

		public function expandBbox(node:Node):void {
			edge_l=Math.min(edge_l,node.lon);
			edge_r=Math.max(edge_r,node.lon);
			edge_b=Math.min(edge_b,node.lat);
			edge_t=Math.max(edge_t,node.lat);
		}
		
		public override function within(left:Number,right:Number,top:Number,bottom:Number):Boolean {
			if (!edge_l ||
				(edge_l<left   && edge_r<left  ) ||
			    (edge_l>right  && edge_r>right ) ||
			    (edge_b<bottom && edge_t<bottom) ||
			    (edge_b>top    && edge_b>top   ) || deleted) { return false; }
			return true;
		}

        public function getNode(index:uint):Node {
            return nodes[index];
        }

        public function getFirstNode():Node {
            return nodes[0];
        }

		public function getLastNode():Node {
			return nodes[nodes.length-1];
		}
		
		/** Given one node, return the next in sequence, cycling around a loop if necessary. */
		// TODO make behave correctly for P-shaped topologies?
		public function getNextNode(node:Node):Node {
			// If the last node in a loop is selected, this behaves correctly.
		    var i:uint = indexOfNode(node);
		    if(i < length-1)
	            return nodes[i+1];
	        return null;
	        // What should happen for very short lengths?      
		}
        
        // TODO make behave correctly for P-shaped topologies?
        /** Given one node, return the previous, cycling around a loop if necessary. */
        public function getPrevNode(node:Node):Node {
            var i:uint = indexOfNode(node);
            if(i > 0)
                return nodes[i-1];
            if(i == 0 && isArea() )
                return nodes[nodes.length - 2]
            return null;
            // What should happen for very short lengths?      
        }

        // return the index of the Node, or -1 if not found
        public function indexOfNode(node:Node):int {
            return nodes.indexOf(node);
        }

		public function hasOnceOnly(node:Node):Boolean {
			return nodes.indexOf(node)==nodes.lastIndexOf(node);
		}
		
		public function hasLockedNodes():Boolean {
			for each (var node:Node in nodes) {
				if (node.locked) { return true; }
			}
			return false;
		}

		public function sliceNodes(start:int,end:int):Array {
			return nodes.slice(start,end);
		}


        private function calculateSnappedPoint(p1:Point, p2:Point, nP:Point):Point {
            var w:Number = p2.x - p1.x;
            var h:Number = p2.y - p1.y;
            var u:Number = ((nP.x-p1.x) * w + (nP.y-p1.y) * h) / (w*w + h*h);
            return new Point(p1.x + u*w, p1.y+u*h);
        }
        
        public override function toString():String {
            return "Way("+id+"@"+version+"): "+getTagList()+
                     " "+nodes.map(function(item:Node,index:int, arr:Array):String {return item.id.toString();}).join(",");
        }

		public function isArea():Boolean {
			if (nodes.length==0) { return false; }
			return (nodes[0].id==nodes[nodes.length-1].id && nodes.length>2);
		}
		
		public function endsWith(node:Node):Boolean {
			return (nodes[0]==node || nodes[nodes.length-1]==node);
		}
		
		public override function nullify():void {
			nullifyEntity();
			nodes=[];
			edge_l=edge_r=edge_t=edge_b=NaN;
		}
		
		public function get clockwise():Boolean {
			var lowest:uint=0;
			var xmin:Number=-999999; var ymin:Number=-999999;
			for (var i:uint=0; i<nodes.length; i++) {
				if      (nodes[i].latp> ymin) { lowest=i; xmin=nodes[i].lon; ymin=nodes[i].latp; }
				else if (nodes[i].latp==ymin
					  && nodes[i].lon > xmin) { lowest=i; xmin=nodes[i].lon; ymin=nodes[i].latp; }
			}
			return (this.onLeft(lowest)>0);
		}
		
		private function onLeft(j:uint):Number {
			var left:Number=0;
			var i:int, k:int;
			if (nodes.length>=3) {
				i=j-1; if (i==-1) { i=nodes.length-2; }
				k=j+1; if (k==nodes.length) { k=1; }
				left=((nodes[j].lon-nodes[i].lon) * (nodes[k].latp-nodes[i].latp) -
					  (nodes[k].lon-nodes[i].lon) * (nodes[j].latp-nodes[i].latp));
			}
			return left;
		}

        public function get angle():Number {
            var dx:Number = nodes[nodes.length-1].lon - nodes[0].lon;
            var dy:Number = nodes[nodes.length-1].latp - nodes[0].latp;
            if (dx != 0 || dy != 0) {
                return Math.atan2(dx,dy)*(180/Math.PI);
            } else {
                return 0;
            }
        }

		internal override function isEmpty():Boolean {
			return (deleted || (nodes.length==0));
		}

		public override function getType():String {
			return 'way';
		}
		
		public override function isType(str:String):Boolean {
			if (str=='way') return true;
			if (str=='line' && !isArea()) return true;
			if (str=='area' &&  isArea()) return true;
			return false;
		}
		
		/** Whether the way has a loop that joins back midway along its length */
		public function isPShape():Boolean {
			return getFirstNode() != getLastNode() && (!hasOnceOnly(getFirstNode()) || !hasOnceOnly(getLastNode()) );
		}
		
		/** Given a P-shaped way, return the index of midway node that one end connects back to. */
		public function getPJunctionNodeIndex():uint {
			if (isPShape()) {
			    if (hasOnceOnly(getFirstNode())) {
			        // nodes[0] is the free end
			        return nodes.indexOf(getLastNode());
			    } else {
			        // nodes[0] is in the loop
			        return nodes.lastIndexOf(getFirstNode());
			    }
			}
			return null;
		}

		public function intersects(left:Number,right:Number,top:Number,bottom:Number):Boolean {
			// simple test first: are any nodes contained?
			for (var i:uint=0; i<nodes.length; i++) {
				if (nodes[i].within(left,right,top,bottom)) return true;
			}
			// more complex test: do any segments cross?
			for (i=0; i<nodes.length-1; i++) {
				if (lineIntersectsRectangle(
					nodes[i  ].lon, nodes[i  ].lat,
					nodes[i+1].lon, nodes[i+1].lat,
					left,right,top,bottom)) return true;
			}
			return false;
		}
		
		private function lineIntersectsRectangle(x0:Number, y0:Number, x1:Number, y1:Number, l:Number, r:Number, b:Number, t:Number):Boolean {
			// from http://sebleedelisle.com/2009/05/super-fast-trianglerectangle-intersection-test/
			// note that t and b are transposed above because we're dealing with lat (top=90), not AS3 pixels (top=0)
			var m:Number = (y1-y0) / (x1-x0);
			var c:Number = y0 -(m*x0);
			var top_intersection:Number, bottom_intersection:Number;
			var toptrianglepoint:Number, bottomtrianglepoint:Number;

			if (m>0) {
				top_intersection = (m*l  + c);
				bottom_intersection = (m*r  + c);
			} else {
				top_intersection = (m*r  + c);
				bottom_intersection = (m*l  + c);
			}

			if (y0<y1) {
				toptrianglepoint = y0;
				bottomtrianglepoint = y1;
			} else {
				toptrianglepoint = y1;
				bottomtrianglepoint = y0;
			}

			var topoverlap:Number = top_intersection>toptrianglepoint ? top_intersection : toptrianglepoint;
			var botoverlap:Number = bottom_intersection<bottomtrianglepoint ? bottom_intersection : bottomtrianglepoint;
			return (topoverlap<botoverlap) && (!((botoverlap<t) || (topoverlap>b)));
		}


    }
}
