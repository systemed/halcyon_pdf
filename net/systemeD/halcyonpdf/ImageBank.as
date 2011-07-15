package net.systemeD.halcyonpdf {
    import flash.events.*;
	import flash.display.*;
	import flash.net.*;

    public class ImageBank extends EventDispatcher{
		public var images:Array=[];
		private var imageCount:uint=0;
		
		public static const IMAGES_LOADED:String="imagesLoaded";
		
		private static const GLOBAL_INSTANCE:ImageBank = new ImageBank();
		public static function getInstance():ImageBank {
			return GLOBAL_INSTANCE;
		}

		public function loadPDFImage(filename:String):void {
			imageCount++;
			var loader:Loader=new Loader();
			images[filename]=loader;
			var request:URLRequest=new URLRequest(filename);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,						loadedPDFImage);
			loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS,			httpStatusHandler);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler);
			loader.load(request);
		}

		private function loadedPDFImage(event:Event):void {
			imageCount--;
			if (imageCount==0) { dispatchEvent(new Event(IMAGES_LOADED)); }
		}

		private function httpStatusHandler( event:HTTPStatusEvent ):void { trace("httpEvent"); }
		private function securityErrorHandler( event:SecurityErrorEvent ):void { trace("securityErrorEvent"); }
		private function ioErrorHandler( event:IOErrorEvent ):void { trace("ioErrorEvent"); }
			
		
	}
}