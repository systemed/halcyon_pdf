package net.systemeD.halcyonpdf.pdfrenderer {

	import org.alivepdf.pdf.PDF;
	import org.alivepdf.colors.*;
	import org.alivepdf.display.Display;
	import org.alivepdf.drawing.*;
	import org.alivepdf.fonts.*;
	import org.alivepdf.images.ColorSpace;
	import org.alivepdf.layout.*;
	import org.alivepdf.pages.Page;
	import net.systemeD.halcyonpdf.connection.*;
	import net.systemeD.halcyonpdf.styleparser.*;
	
	public class StrokeItem extends DrawingItem {

		// ** FIXME: doesn't do line decoration yet (e.g. arrows)
		// ** FIXME: doesn't do multipolygons yet

		protected var style:ShapeStyle;

		public function StrokeItem(s:ShapeStyle, e:Entity) {
			entity=e;
			style=s;
		}

		override public function getSublayer():Number { return style.sublayer; }

		override public function draw(pdf:PDF,spec:MapSpec):void {
			pdf.lineStyle(new RGBColor(style.color ? style.color : 0),
			              style.width,
			              0,
			              style.opacity ? style.opacity : 1,
			              "EvenOdd",
			              "Normal",
			              (style.dashes && style.dashes.length>0) ? new DashedLine(style.dashes) : null,
			              style.linecap  ? style.linecap : Caps.NONE,
			              style.linejoin ? style.linejoin : Joint.ROUND);
			drawLine(pdf,spec,Way(entity));
		}
		
		public static function drawLine(pdf:PDF, spec:MapSpec, way:Way, fill:Boolean=false):void {
            var node:Node = way.getNode(0);
 			pdf.moveTo(spec.x(node.lon),spec.y(node.latp));
			for (var i:uint=1; i<way.length; i++) {
				node=way.getNode(i);
				pdf.lineTo(spec.x(node.lon),spec.y(node.latp));
			}
			pdf.end(fill);
//			if (!fill) pdf.moveTo(spec.x(way.getNode(0).lon),
//			                      spec.y(way.getNode(0).latp));
//			pdf.end();
		}
	}
	
}
