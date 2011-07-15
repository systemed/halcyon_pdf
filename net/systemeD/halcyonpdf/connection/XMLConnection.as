package net.systemeD.halcyonpdf.connection {

    import flash.events.*;
	import mx.rpc.http.HTTPService;
	import mx.rpc.events.*;
	import flash.system.Security;
	import flash.net.*;
	import net.systemeD.halcyonpdf.MapEvent;

	/*	Changes for Halcyon/PDF:
		- OAuth stuff removed
		- upload stuff removed
		- traces stuff removed
		This should probably become XMLReadOnlyConnection.as
	*/

    /**
    * XMLConnection provides all the methods required to connect to a live
    * OSM server. See OSMConnection for connecting to a read-only .osm file
    */
	public class XMLConnection extends XMLBaseConnection {

		public function XMLConnection(name:String,api:String,policy:String,initparams:Object) {

			super(name,api,policy,initparams);
			if (policyURL != "") Security.loadPolicyFile(policyURL);

		}
		
		override public function loadBbox(left:Number,right:Number,
								top:Number,bottom:Number):void {
            purgeIfFull(left,right,top,bottom);
            if (isBboxLoaded(left,right,top,bottom)) return;

            // enlarge bbox by 20% on each edge
            var xmargin:Number=(right-left)/5;
            var ymargin:Number=(top-bottom)/5;
            left-=xmargin; right+=xmargin;
            bottom-=ymargin; top+=ymargin;

            var mapVars:URLVariables = new URLVariables();
            mapVars.bbox= left+","+bottom+","+right+","+top;

            var mapRequest:URLRequest = new URLRequest(apiBaseURL+"map");
            mapRequest.data = mapVars;

            sendLoadRequest(mapRequest);
		}

		override public function loadEntityByID(type:String, id:Number):void {
			var url:String=apiBaseURL + type + "/" + id;
			if (type=='way') url+="/full";
			sendLoadRequest(new URLRequest(url));
		}

		private function sendLoadRequest(request:URLRequest):void {
			var mapLoader:URLLoader = new URLLoader();
			mapLoader.addEventListener(Event.COMPLETE, loadedMap);
			mapLoader.addEventListener(IOErrorEvent.IO_ERROR, errorOnMapLoad);
			mapLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, mapLoadStatus);
            request.requestHeaders.push(new URLRequestHeader("X-Error-Format", "XML"));
			mapLoader.load(request);
			dispatchEvent(new Event(LOAD_STARTED));
		}

        private function errorOnMapLoad(event:Event):void {
			dispatchEvent(new MapEvent(MapEvent.ERROR, { message: "Couldn't load the map" } ));
			dispatchEvent(new Event(LOAD_COMPLETED));
        }
        private function mapLoadStatus(event:HTTPStatusEvent):void {
            trace("loading map status = "+event.status);
        }


	}
}
