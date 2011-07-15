package net.systemeD.halcyonpdf.pdfrenderer {

	import org.alivepdf.pdf.PDF;
	import org.alivepdf.drawing.*;
	import org.alivepdf.colors.*;
	import net.systemeD.halcyonpdf.connection.*;
	import net.systemeD.halcyonpdf.styleparser.*;
	
	public class CasingItem extends DrawingItem {

		protected var style:ShapeStyle;

		public function CasingItem(s:ShapeStyle, e:Entity) {
			entity=e;
			style=s;
		}

		override public function draw(pdf:PDF,spec:MapSpec):void {
			pdf.lineStyle(new RGBColor(style.casing_color ? style.casing_color : 0),
			              style.width + style.casing_width,
			              0,
			              style.casing_opacity ? style.casing_opacity : 1,
			              "EvenOdd",
			              "Normal",
			              (style.casing_dashes && style.casing_dashes.length>0) ? new DashedLine(style.casing_dashes) : null,
			              style.linecap  ? style.linecap : Caps.NONE,
			              style.linejoin ? style.linejoin : Joint.ROUND);
			StrokeItem.drawLine(pdf,spec,Way(entity));
		}

		override public function getSublayer():Number { return style.sublayer; }
	}
	
}
