package net.systemeD.halcyonpdf.pdfrenderer {

	import org.alivepdf.pdf.PDF;
	import net.systemeD.halcyonpdf.connection.*;
	import net.systemeD.halcyonpdf.styleparser.*;
	
	public class MapSpec {

		public var minlon:Number;
		public var minlat:Number;
		public var maxlon:Number;
		public var maxlat:Number;
		
		public var minscale:uint;
		public var maxscale:uint;
		public var scale:uint;
		
		public var minlayer:int;
		public var maxlayer:int;

		public var boxwidth:Number;
		public var boxheight:Number;
		public var boxoriginx:Number;
		public var boxoriginy:Number;

		private var baselon:Number;
		private var baselatp:Number;
		public var boxscale:Number;

		public function initProjection():void {
			baselon=minlon;
			baselatp=Node.lat2latp(minlat);
			var maxlatp:Number=Node.lat2latp(maxlat);
			boxscale=Math.max((maxlon-minlon)/boxwidth, (maxlatp-baselatp)/boxheight);
			boxwidth=(maxlon-minlon)/boxscale;
			boxheight=(maxlatp-baselatp)/boxscale;
		}
		
		public function x(lon:Number):Number {
			var x:Number=lon-baselon;
			x/=boxscale;
			x+=boxoriginx;
			return x;
		}
		public function y(latp:Number):Number {
			var y:Number=latp-baselatp;
			y/=boxscale;
			y=(boxheight-boxoriginy-y);
			return y;
		}

		public function pointAt(way:Way,t:Number,pathlength:Number):Array {
			var totallen:Number = t*pathlength;
			var curlen:Number = 0;
			var dx:Number, dy:Number, seglen:Number;
			for (var i:int = 1; i < way.length; i++){
				dx=x(way.getNode(i).lon )-x(way.getNode(i-1).lon );
				dy=y(way.getNode(i).latp)-y(way.getNode(i-1).latp);
				seglen=Math.sqrt(dx*dx+dy*dy);
				if (totallen > curlen+seglen) { curlen+=seglen; continue; }
				return new Array(x(way.getNode(i-1).lon )+(totallen-curlen)/seglen*dx,
								 y(way.getNode(i-1).latp)+(totallen-curlen)/seglen*dy,
								 Math.atan2(dy,dx));
			}
			return new Array(0, 0, 0);
		}

	}
	
}
