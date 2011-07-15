package net.systemeD.halcyonpdf.pdfrenderer {

	import org.alivepdf.pdf.PDF;
	import org.alivepdf.colors.*;
	import org.alivepdf.layout.*;
	import net.systemeD.halcyonpdf.connection.*;
	import net.systemeD.halcyonpdf.styleparser.*;
	import net.systemeD.halcyonpdf.ImageBank;
	import flash.geom.Rectangle;
	import flash.display.*;
	import mx.core.Application;	// ** FIXME: don't do this, use ImageBank instead
	
	public class PointItem extends DrawingItem {

		protected var style:PointStyle;
		protected var shapestyle:ShapeStyle;

		public function PointItem(s:PointStyle, e:Entity, ss:ShapeStyle) {
			entity=e;
			style=s;
			shapestyle=ss;
		}
		
		override public function draw(pdf:PDF, spec:MapSpec):void {
			// ** FIXME: do fill opacity on square/circle
			var x:Number=spec.x(Node(entity).lon);
			var y:Number=spec.y(Node(entity).latp);
			if (style.icon_image=='square') {
				// draw square
				if (!isNaN(shapestyle.color)) { pdf.beginFill(new RGBColor(shapestyle.color)); }
				if (shapestyle.casing_width || !isNaN(shapestyle.casing_color))
					pdf.lineStyle(new RGBColor(shapestyle.color ? shapestyle.color : 0),
								  shapestyle.casing_width ? shapestyle.casing_width : 1,
								  shapestyle.opacity ? shapestyle.opacity : 1);
				pdf.drawRect(new Rectangle(x-style.icon_width/2, y-style.icon_width/2, style.icon_width, style.icon_width));
				pdf.endFill();

			} else if (style.icon_image=='circle') {
				// draw circle
				if (!isNaN(shapestyle.color)) { pdf.beginFill(new RGBColor(shapestyle.color)); }
				if (shapestyle.casing_width || !isNaN(shapestyle.casing_color))
					pdf.lineStyle(new RGBColor(shapestyle.color ? shapestyle.color : 0),
								  shapestyle.casing_width ? shapestyle.casing_width : 1,
								  shapestyle.opacity ? shapestyle.opacity : 1);
				pdf.drawCircle(x, y, style.icon_width);
				pdf.endFill();

			} else if (Application.application.ruleset.images[style.icon_image]) {
				// place icon
				// ** FIXME: check it's centered
				// ** FIXME: rather than coercing into a Loader and getting from Application.application,
				//    we should be using ImageBank
				pdf.addImage(Application.application.ruleset.images[style.icon_image],
				             new Resize(Mode.NONE, Position.LEFT),
				             x,y,0,0,0,1,false);
			}
			
		}

		override public function getSublayer():Number { return style.sublayer; }
	}
	
}
