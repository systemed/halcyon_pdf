package net.systemeD.halcyonpdf.pdfrenderer {

	import org.alivepdf.pdf.PDF;
	import org.alivepdf.colors.*;
	import net.systemeD.halcyonpdf.connection.*;
	import net.systemeD.halcyonpdf.styleparser.*;
	import flash.display.Bitmap;
	import mx.core.Application;
	// ** FIXME: we really shouldn't be referring to Application here. Let's use a static image bank or something
	
	public class FillItem extends DrawingItem {

		protected var style:ShapeStyle;

		public function FillItem(s:ShapeStyle, e:Entity) {
			entity=e;
			style=s;
		}

		override public function draw(pdf:PDF, spec:MapSpec):void {
			pdf.setAlpha(style.fill_opacity ? style.fill_opacity : 1);
			if (style.fill_image) {
				pdf.beginBitmapFill(Bitmap(Application.application.images[style.fill_image].content).bitmapData);
			} else {
				pdf.beginFill(new RGBColor(style.fill_color));
			}
			StrokeItem.drawLine(pdf,spec,Way(entity),true);
			pdf.endFill();
			pdf.setAlpha(1);
		}

		override public function getSublayer():Number { return style.sublayer; }
	}
	
}
