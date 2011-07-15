package net.systemeD.halcyonpdf.connection {

    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.*;
    
    import net.systemeD.halcyonpdf.AttentionEvent;
    import net.systemeD.halcyonpdf.MapEvent;
    import net.systemeD.halcyonpdf.Globals;

	/*	Changes for Halcyon/PDF:
		- methods that call Actions have been removed
		- error-handling has been removed
	*/

	public class Connection extends EventDispatcher {

		public var name:String;
		public var statusFetcher:StatusFetcher;
        protected var apiBaseURL:String;
        protected var policyURL:String;
        protected var params:Object;

		public function Connection(cname:String,api:String,policy:String,initparams:Object=null) {
			initparams = (initparams!=null ? initparams:{});
			name=cname;
			apiBaseURL=api;
			policyURL=policy;
			params=initparams;
		}

        public function getParam(name:String, defaultValue:String):String {
			if (params[name]) return params[name];
			if (Globals.vars.flashvars[name]) return Globals.vars.flashvars[name];  // REFACTOR - given the profusion of connections, should this be removed?
			return defaultValue;
        }

        public function get apiBase():String {
            return apiBaseURL;
        }

        public function get serverName():String {
            return getParam("serverName", "Localhost");
        }

		public function getEnvironment(responder:Responder):void {}

        // connection events
        public static var LOAD_STARTED:String = "load_started";
        public static var LOAD_COMPLETED:String = "load_completed";
        public static var SAVE_STARTED:String = "save_started";
        public static var SAVE_COMPLETED:String = "save_completed";
        public static var DATA_DIRTY:String = "data_dirty";
        public static var DATA_CLEAN:String = "data_clean";
        public static var NEW_CHANGESET:String = "new_changeset";
        public static var NEW_CHANGESET_ERROR:String = "new_changeset_error";
        public static var NEW_NODE:String = "new_node";
        public static var NEW_WAY:String = "new_way";
        public static var NEW_RELATION:String = "new_relation";
        public static var NEW_POI:String = "new_poi";
        public static var NEW_MARKER:String = "new_marker";
        public static var NODE_RENUMBERED:String = "node_renumbered";
        public static var WAY_RENUMBERED:String = "way_renumbered";
        public static var RELATION_RENUMBERED:String = "relation_renumbered";
        public static var TAG_CHANGED:String = "tag_changed";
        public static var STATUS_CHANGED:String = "status_changed";
        public static var NODE_MOVED:String = "node_moved";
        public static var NODE_ALTERED:String = "node_altered";
        public static var WAY_NODE_ADDED:String = "way_node_added";
        public static var WAY_NODE_REMOVED:String = "way_node_removed";
        public static var WAY_REORDERED:String = "way_reordered";
        public static var ENTITY_DRAGGED:String = "entity_dragged";
		public static var NODE_DELETED:String = "node_deleted";
		public static var WAY_DELETED:String = "way_deleted";
		public static var RELATION_DELETED:String = "relation_deleted";
		public static var RELATION_MEMBER_ADDED:String = "relation_member_added";
		public static var RELATION_MEMBER_REMOVED:String = "relation_member_deleted";
		public static var ADDED_TO_RELATION:String = "added_to_relation";
		public static var REMOVED_FROM_RELATION:String = "removed_from_relation";
		public static var SUSPEND_REDRAW:String = "suspend_redraw";
		public static var RESUME_REDRAW:String = "resume_redraw";
        public static var TRACES_LOADED:String = "traces_loaded";

        // store the data we download
        private var negativeID:Number = -1;
        private var nodes:Object = {};
        private var ways:Object = {};
        private var relations:Object = {};
        private var markers:Object = {};
        private var pois:Array = [];
        private var changeset:Changeset = null;
		private var changesetUpdated:Number;
		private var modified:Boolean = false;
		public var nodecount:int=0;
		public var waycount:int=0;
		public var relationcount:int=0;
        private var traces:Array = [];
        private var nodePositions:Object = {};
        protected var traces_loaded:Boolean = false;
		private var loadedBboxes:Array = [];

		/** maximum number of ways to keep in memory before purging */
		protected const MAXWAYS:uint=3000;

        protected function get nextNegative():Number {
            return negativeID--;
        }

        protected function setNode(node:Node, queue:Boolean):void {
			if (!nodes[node.id]) { nodecount++; }
            nodes[node.id] = node;
            addDupe(node);
            if (node.loaded) { sendEvent(new EntityEvent(NEW_NODE, node),queue); }
        }

        protected function setWay(way:Way, queue:Boolean):void {
			if (!ways[way.id] && way.loaded) { waycount++; }
            ways[way.id] = way;
            if (way.loaded) { sendEvent(new EntityEvent(NEW_WAY, way),queue); }
        }

        protected function setRelation(relation:Relation, queue:Boolean):void {
			if (!relations[relation.id]) { relationcount++; }
            relations[relation.id] = relation;
            if (relation.loaded) { sendEvent(new EntityEvent(NEW_RELATION, relation),queue); }
        }

		protected function setOrUpdateNode(newNode:Node, queue:Boolean):void {
        	if (nodes[newNode.id]) {
				var wasDeleted:Boolean=nodes[newNode.id].isDeleted();
				nodes[newNode.id].update(newNode.version, newNode.getTagsHash(), true, newNode.parentsLoaded, newNode.lat, newNode.lon, newNode.uid, newNode.timestamp);
				if (wasDeleted) sendEvent(new EntityEvent(NEW_NODE, nodes[newNode.id]), false);
			} else {
				setNode(newNode, queue);
			}
		}

		protected function renumberNode(oldID:Number, newID:Number, version:uint):void {
			var node:Node=nodes[oldID];
			if (oldID!=newID) { removeDupe(node); }
			node.renumber(newID, version);
			if (oldID==newID) return;					// if only a version change, return
			nodes[newID]=node;
			addDupe(node);
			if (node.loaded) { sendEvent(new EntityRenumberedEvent(NODE_RENUMBERED, node, oldID),false); }
			delete nodes[oldID];
		}

		protected function renumberWay(oldID:Number, newID:Number, version:uint):void {
			var way:Way=ways[oldID];
			way.renumber(newID, version);
			if (oldID==newID) return;
			ways[newID]=way;
			if (way.loaded) { sendEvent(new EntityRenumberedEvent(WAY_RENUMBERED, way, oldID),false); }
			delete ways[oldID];
		}

		protected function renumberRelation(oldID:Number, newID:Number, version:uint):void {
			var relation:Relation=relations[oldID];
			relation.renumber(newID, version);
			if (oldID==newID) return;
			relations[newID] = relation;
			if (relation.loaded) { sendEvent(new EntityRenumberedEvent(RELATION_RENUMBERED, relation, oldID),false); }
			delete relations[oldID];
		}


		public function sendEvent(e:*,queue:Boolean):void {
			// queue is only used for AMFConnection
			dispatchEvent(e);
		}

        public function registerPOI(node:Node):void {
            if ( pois.indexOf(node) < 0 ) {
                pois.push(node);
                sendEvent(new EntityEvent(NEW_POI, node),false);
            }
        }

        public function unregisterPOI(node:Node):void {
            var index:uint = pois.indexOf(node);
            if ( index >= 0 ) {
                pois.splice(index,1);
            }
        }

        public function getNode(id:Number):Node {
            return nodes[id];
        }

        public function getWay(id:Number):Way {
            return ways[id];
        }

        public function getRelation(id:Number):Relation {
            return relations[id];
        }

        public function getMarker(id:Number):Marker {
            return markers[id];
        }

		protected function findEntity(type:String, id:*):Entity {
			var i:Number=Number(id);
			switch (type.toLowerCase()) {
				case 'node':     return getNode(id);
				case 'way':      return getWay(id);
				case 'relation': return getRelation(id);
				default:         return null;
			}
		}

		// Remove data from Connection
		// These functions are used only internally to stop redundant data hanging around
		// (either because it's been deleted on the server, or because we have panned away
		//  and need to reduce memory usage)

		protected function killNode(id:Number):void {
			if (!nodes[id]) return;
            nodes[id].dispatchEvent(new EntityEvent(Connection.NODE_DELETED, nodes[id]));
			removeDupe(nodes[id]);
			if (nodes[id].parentRelations.length>0) {
				nodes[id].nullify();
			} else {
				delete nodes[id];
			}
			nodecount--;
		}

		protected function killWay(id:Number):void {
			if (!ways[id]) return;
            ways[id].dispatchEvent(new EntityEvent(Connection.WAY_DELETED, ways[id]));
			if (ways[id].parentRelations.length>0) {
				ways[id].nullify();
			} else {
				delete ways[id];
			}
			waycount--;
		}

		protected function killRelation(id:Number):void {
			if (!relations[id]) return;
            relations[id].dispatchEvent(new EntityEvent(Connection.RELATION_DELETED, relations[id]));
			if (relations[id].parentRelations.length>0) {
				relations[id].nullify();
			} else {
				delete relations[id];
			}
			relationcount--;
		}

		protected function killWayWithNodes(id:Number):void {
			var way:Way=ways[id];
			var node:Node;
			for (var i:uint=0; i<way.length; i++) {
				node=way.getNode(i);
				if (node.isDirty) { continue; }
				if (node.parentWays.length>1) {
					node.removeParent(way);
				} else {
					killNode(node.id);
				}
			}
			killWay(id);
		}
		
		protected function killEntity(entity:Entity):void {
			if (entity is Way) { killWay(entity.id); }
			else if (entity is Node) { killNode(entity.id); }
			else if (entity is Relation) { killRelation(entity.id); }
		}

        public function getAllNodeIDs():Array {
            var list:Array = [];
            for each (var node:Node in nodes)
                list.push(node.id);
            return list;
        }

        public function getAllWayIDs():Array {
            var list:Array = [];
            for each (var way:Way in ways)
                list.push(way.id);
            return list;
        }

        public function getAllRelationIDs():Array {
            var list:Array = [];
            for each (var relation:Relation in relations)
                list.push(relation.id);
            return list;
        }

		public function getAllLoadedEntities():Array {
			var list:Array = []; var entity:Entity;
			for each (entity in relations) { if (entity.loaded && !entity.deleted) list.push(entity); }
			for each (entity in ways     ) { if (entity.loaded && !entity.deleted) list.push(entity); }
			for each (entity in nodes    ) { if (entity.loaded && !entity.deleted) list.push(entity); }
			return list;
		}

        /** Returns all available relations that match all of {k1: [v1,v2,...], k2: [v1...] ...} 
        * where p1 is an array [v1, v2, v3...] */
        public function getMatchingRelationIDs(match:Object):Array {
            var list:Array = [];
            for each (var relation:Relation in relations) {
                var ok: Boolean = true;
				if (relation.deleted) { continue; }
				for (var k:String in match) {
					var v:String = relation.getTagsHash()[k];
					if (!v || match[k].indexOf(v) < 0) { 
					   ok = false; break;  
					}
				}
				if (ok) { list.push(relation.id); }
			}
            return list;
        }

		public function getObjectsByBbox(left:Number, right:Number, top:Number, bottom:Number):Object {
			var o:Object = { poisInside: [], poisOutside: [], waysInside: [], waysOutside: [],
                              markersInside: [], markersOutside: [] };
			for each (var way:Way in ways) {
				if (way.within(left,right,top,bottom)) { o.waysInside.push(way); }
				                                  else { o.waysOutside.push(way); }
			}
			for each (var poi:Node in pois) {
				if (poi.within(left,right,top,bottom)) { o.poisInside.push(poi); }
				                                  else { o.poisOutside.push(poi); }
			}
            for each (var marker:Marker in markers) {
                if (marker.within(left,right,top,bottom)) { o.markersInside.push(marker); }
                                                     else { o.markersOutside.push(marker); }
            }
			return o;
		}

		public function purgeOutside(left:Number, right:Number, top:Number, bottom:Number):void {
			for each (var way:Way in ways) {
				if (!way.within(left,right,top,bottom) && !way.isDirty && !way.locked && !way.hasLockedNodes()) {
					killWayWithNodes(way.id);
				}
			}
			for each (var poi:Node in pois) {
				if (!poi.within(left,right,top,bottom) && !poi.isDirty && !poi.locked) {
					killNode(poi.id);
				}
			}
			// ** should purge relations too, if none of their members are on-screen
		}

		public function markDirty():void {
            if (!modified) { dispatchEvent(new Event(DATA_DIRTY)); }
			modified=true;
		}
		public function markClean():void {
            if (modified) { dispatchEvent(new Event(DATA_CLEAN)); }
			modified=false;
		}
		public function get isDirty():Boolean {
			return modified;
		}

		// Keep track of the bboxes we've loaded

		/** Has the data within this bbox already been loaded? */
		protected function isBboxLoaded(left:Number,right:Number,top:Number,bottom:Number):Boolean {
			var l:Number,r:Number,t:Number,b:Number;
			for each (var box:Array in loadedBboxes) {
				l=box[0]; r=box[1]; t=box[2]; b=box[3];
				if (left>=l && left<=r && right>=l && right<=r && top>=b && top<=t && bottom>=b && bottom<=t) {
					return true;
				}
			}
			return false;
		}
		/** Mark that bbox is loaded */
		protected function markBboxLoaded(left:Number,right:Number,top:Number,bottom:Number):void {
			if (isBboxLoaded(left,right,top,bottom)) return;
			loadedBboxes.push([left,right,top,bottom]);
		}
		/** Purge all data if number of ways exceeds limit */
		public function purgeIfFull(left:Number,right:Number,top:Number,bottom:Number):void {
			if (waycount<=MAXWAYS) return;
			purgeOutside(left,right,top,bottom);
			loadedBboxes=[[left,right,top,bottom]];
		}

		// Changeset tracking

        protected function setActiveChangeset(changeset:Changeset):void {
            this.changeset = changeset;
			changesetUpdated = new Date().getTime();
            sendEvent(new EntityEvent(NEW_CHANGESET, changeset),false);
        }

		protected function freshenActiveChangeset():void {
			changesetUpdated = new Date().getTime();
		}
		
		protected function closeActiveChangeset():void {
			changeset = null;
		}
        
        public function getActiveChangeset():Changeset {
			if (changeset && (new Date().getTime()) > (changesetUpdated+58*60*1000)) {
				closeActiveChangeset();
			}
            return changeset;
        }

        protected function addTrace(t:Object):void {
            traces.push(t);
        }

        protected function clearTraces():void {
            traces = [];
        }

        public function getTraces():Array {
            return traces;
        }

        public function addDupe(node:Node):void {
            if (getNode(node.id) != node) { return; } // make sure it's on this connection
            var a:String = node.lat+","+node.lon;
            if(!nodePositions[a]) {
              nodePositions[a] = [];
            }
            nodePositions[a].push(node);
            if (nodePositions[a].length > 1) { // don't redraw if it's the only node in town
              for each (var n:Node in nodePositions[a]) {
                n.dispatchEvent(new Event(Connection.NODE_ALTERED));
              }
            }
        }

        public function removeDupe(node:Node):void {
            if (getNode(node.id) != node) { return; } // make sure it's on this connection
            var a:String = node.lat+","+node.lon;
            var redraw:Boolean=node.isDupe();
            var dupes:Array = [];
            for each (var dupe:Node in nodePositions[a]) {
              if (dupe!=node) { dupes.push(dupe); }
            }
            nodePositions[a] = dupes;
            for each (var n:Node in nodePositions[a]) { // redraw any nodes remaining
              n.dispatchEvent(new Event(Connection.NODE_ALTERED));
            }
            if (redraw) { node.dispatchEvent(new Event(Connection.NODE_ALTERED)); } //redraw the one being moved
        }

        public function nodesAtPosition(lat:Number, lon:Number):uint {
            if (nodePositions[lat+","+lon]) {
              return nodePositions[lat+","+lon].length;
            }
            return 0;
        }

        public function getNodesAtPosition(lat:Number, lon:Number):Array {
            if (nodePositions[lat+","+lon]) {
              return nodePositions[lat+","+lon];
            }
            return [];
        }

		public function identicalNode(node:Node):Node {
			for each (var dupe:Node in nodePositions[node.lat+","+node.lon]) {
				if (node.lat==dupe.lat && node.lon==dupe.lon && node.sameTags(dupe)) return dupe;
			}
			return null;
		}

        // these are functions that the Connection implementation is expected to
        // provide. This class has some generic helpers for the implementation.
		public function loadBbox(left:Number, right:Number,
								top:Number, bottom:Number):void {
	    }
	    public function loadEntityByID(type:String, id:Number):void {}
	    public function setAuthToken(id:Object):void {}
        public function setAccessToken(key:String, secret:String):void {}
	    public function createChangeset(tags:Object):void {}
		public function closeChangeset():void {}
        public function uploadChanges():* {}
        public function fetchUserTraces(refresh:Boolean=false):void {}
        public function fetchTrace(id:Number, callback:Function):void {}
        public function hasAccessToken():Boolean { return false; }

		public function loadEntity(entity:Entity):void {
			loadEntityByID(entity.getType(),entity.id);
		}

    }

}

