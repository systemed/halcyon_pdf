package net.systemeD.halcyonpdf.pdfrenderer {

	import net.systemeD.halcyonpdf.connection.*;
	import net.systemeD.halcyonpdf.styleparser.*;
	import org.alivepdf.pdf.PDF;
	
	public class DrawingItem {
		protected var entity:Entity;

		// ** to be overridden
		public function getSublayer():Number { return 0; }
		public function draw(pdf:PDF,spec:MapSpec):void { }
	}
	
}
