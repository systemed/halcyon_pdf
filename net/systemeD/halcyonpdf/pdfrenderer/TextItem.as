package net.systemeD.halcyonpdf.pdfrenderer {

	import org.alivepdf.pdf.PDF;
	import org.alivepdf.fonts.*;
	import org.alivepdf.colors.*;
	import net.systemeD.halcyonpdf.connection.*;
	import net.systemeD.halcyonpdf.styleparser.*;
	
	public class TextItem extends DrawingItem {

		protected var style:TextStyle;
		private var pathlength:Number;

		public function TextItem(s:TextStyle, e:Entity, p:Number=0) {
			entity=e;
			style=s;
			pathlength=p;
		}

		override public function draw(pdf:PDF, spec:MapSpec):void {
			if (entity is Way) writeNameOnPath(pdf,spec,Way(entity));
			else if (entity is Node) writeNameLabel(pdf,spec,Node(entity));
		}
		
		private function writeNameOnPath(pdf:PDF, spec:MapSpec, way:Way):void {
			var txt:String=way.getTag(style.text);
			if (!txt) return;

			// ** FIXME: set the font properly!
			// ** FIXME: take some notice of bold, italic, underline, etc. etc.
			// ** FIXME: do halos
			var helvetica:IFont = new CoreFont(FontFamily.HELVETICA);
			var charheight:Number = style.font_size ? style.font_size : 8;
			var textOffset:Number=style.text_offset ? style.text_offset : 0;
			pdf.setFont(helvetica,charheight);
			pdf.textStyle(new RGBColor(style.text_color ? style.text_color : 0));

			var textwidth:Number = pdf.getStringWidth(txt);
			if (pathlength<textwidth) return;

			var t1:Number = (pathlength/2 - textwidth/2) / pathlength; var p1:Array=spec.pointAt(way, t1, pathlength);
			var t2:Number = (pathlength/2 + textwidth/2) / pathlength; var p2:Array=spec.pointAt(way, t1, pathlength);

			var angleOffset:Number; // so we can do a 180º if we're running backwards
			var offsetSign:Number;  // -1 if we're starting at t2
			var tStart:Number;      // t1 or t2
			var charwidth:Number;
			
			// make sure text doesn't run right->left or upside down
			if (p1[0] < p2[0] && 
				p1[2] < Math.PI/2 &&
				p1[2] > -Math.PI/2) {
				angleOffset = Math.PI; offsetSign = -1; tStart = t2;
			} else {
				angleOffset = 0; offsetSign = 1; tStart = t1;
			} 

			// make a textfield for each char, centered on the line,
			// using getCharBoundaries to rotate it around its center point
			var chars:Array = txt.split('');
			var charpos:Number = 0;
			for (var i:int = 0; i < chars.length; i++) {
				charwidth=pdf.getStringWidth(chars[i]);
				var p:Array=spec.pointAt(way, tStart+offsetSign*(charpos+charwidth/2)/pathlength, pathlength);
				var degrees:Number=(p[2]+angleOffset)*(180/Math.PI);
				// ** FIXME: this is broken. .rotate should be (x,y) and .addText should be (p[0],p[1]), or something.
				// ** cf Halcyon code (RotatedLetter in WayUI.as), .rotate in PDF.as, and maths. I hate maths.
				var x:Number=p[0]-charwidth/2;
				var y:Number=p[1]+charheight/2+textOffset;

				pdf.startTransform();
				pdf.rotate(degrees, x, y);
				pdf.addText(chars[i], x, y);
				pdf.stopTransform();
				charpos+=charwidth;
			}
		}

		private function writeNameLabel(pdf:PDF, spec:MapSpec, node:Node):void {
		}

		override public function getSublayer():Number { return style.sublayer; }

	}
	
}
