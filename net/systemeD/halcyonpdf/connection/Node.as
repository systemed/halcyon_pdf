package net.systemeD.halcyonpdf.connection {

	/*	Changes for Halcyon/PDF:
		- all methods referencing actions deleted
		  (includes lat/lon setters)
	*/

    public class Node extends Entity {
        private var _lat:Number;
        private var _latproj:Number;
        private var _lon:Number;

        public function Node(connection:Connection, id:Number, version:uint, tags:Object, loaded:Boolean, lat:Number, lon:Number, uid:Number = NaN, timestamp:String = null) {
            super(connection, id, version, tags, loaded, uid, timestamp);
            this._lat = lat;
            this._latproj = lat2latp(lat);
            this._lon = lon;
        }

		public function update(version:uint, tags:Object, loaded:Boolean, parentsLoaded:Boolean, lat:Number, lon:Number, uid:Number = NaN, timestamp:String = null):void {
			updateEntityProperties(version,tags,loaded,parentsLoaded,uid,timestamp); setLatLonImmediate(lat,lon);
		}

        public function get lat():Number {
            return _lat;
        }

        public function get latp():Number {
            return _latproj;
        }

        public function get lon():Number {
            return _lon;
        }

        private function setLatLonImmediate(lat:Number, lon:Number):void {
            connection.removeDupe(this);
            this._lat = lat;
            this._latproj = lat2latp(lat);
            this._lon = lon;
            connection.addDupe(this);
			for each (var way:Way in this.parentWays) {
				way.expandBbox(this);
			}
        }
        
        public override function toString():String {
            return "Node("+id+"@"+version+"): "+lat+","+lon+" "+getTagList();
        }

		public override function within(left:Number,right:Number,top:Number,bottom:Number):Boolean {
			if (_lon<left || _lon>right || _lat<bottom || _lat>top || deleted) { return false; }
			return true;
		}

        public function isDupe():Boolean {
            if (connection.getNode(this.id) == this // node could be part of a vector layer
                && connection.nodesAtPosition(lat, lon) > 1) {
              return true;
            }
            return false;
        }

		internal override function isEmpty():Boolean {
			return deleted;
		}

        public static function lat2latp(lat:Number):Number {
            return 180/Math.PI * Math.log(Math.tan(Math.PI/4+lat*(Math.PI/180)/2));
        }

		public static function latp2lat(a:Number):Number {
		    return 180/Math.PI * (2 * Math.atan(Math.exp(a*Math.PI/180)) - Math.PI/2);
		}
		
		public override function getType():String {
			return 'node';
		}
		
    }

}
