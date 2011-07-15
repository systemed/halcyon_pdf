package net.systemeD.halcyonpdf.pdfrenderer {

	import org.alivepdf.pdf.PDF;
	import net.systemeD.halcyonpdf.connection.*;
	import net.systemeD.halcyonpdf.styleparser.*;
	
	public class DisplayList {

		private var list:Array=[];
		private var ruleset:RuleSet;
		private var spec:MapSpec;

		public function DisplayList(rs:RuleSet, s:MapSpec) {
			ruleset=rs;
			spec=s;
		}

		// ------------------------------------
		// compileWay
		// add way DrawingItems to DisplayList
		// ------------------------------------

		public function compileWay(way:Way):void {
			if (way.length==0) return;

			// calculate midpoint etc.
			var lx:Number, ly:Number, sc:Number;
			var node:Node, latp:Number, lon:Number;
			var cx:Number=0, cy:Number=0;
			
			var pathlength:Number=0;
			var patharea:Number=0;
			var heading:Array=[];
			var centroid_x:Number, centroid_y:Number;

			lx = way.getNode(way.length-1).lon;
			ly = way.getNode(way.length-1).latp;
			for ( var i:uint = 0; i < way.length; i++ ) {
				node = way.getNode(i);
				latp = node.latp;
				lon  = node.lon;

				// length and area
				if ( i>0 ) { pathlength += Math.sqrt( Math.pow(lon-lx,2)+Math.pow(latp-ly,2) ); }
				sc = (lx*latp-lon*ly)/spec.boxscale;
				cx += (lx+lon)*sc;
				cy += (ly+latp)*sc;
				patharea += sc;
				
				// heading
				if (i>0) { heading[i-1]=Math.atan2((lon-lx),(latp-ly)); }

				lx=lon; ly=latp;
			}
			heading[way.length-1]=heading[way.length-2];

			pathlength/=spec.boxscale;
			patharea/=2;
			if (patharea!=0 && way.isArea()) {
				centroid_x=spec.x(cx/patharea/6);
				centroid_y=spec.y(cy/patharea/6);
			} else if (pathlength>0) {
				var c:Array=spec.pointAt(way,0.5,pathlength);
				centroid_x=c[0];
				centroid_y=c[1];
			}

			// get tags
            var tags:Object = way.getTagsCopy();
            if (way.isArea()) tags[':area']='yes';
			if (way.status) { tags['_status']=way.status; }

			// find style
			var styleList:StyleList=ruleset.getStyles(way, tags, spec.scale);
			var layer:Number=styleList.layerOverride();
			if (isNaN(layer)) layer=tags['layer'] ? layer=Math.min(Math.max(tags['layer'],spec.minlayer),spec.maxlayer) : 0;
			var maxwidth:Number=4;

			// part of multipolygon?
			var multis:Array=way.findParentRelationsOfType('multipolygon','outer');
			var inners:Array=[];
			for each (var m:Relation in multis)
				inners=inners.concat(m.findMembersByRole('inner',Way));

			// add entry for each subpart
			for each (var subpart:String in styleList.subparts) {

				// StrokeItem, FillItem, CasingItem
				// when it comes to drawing, we need to iterate through all the FillItems,
				// then all the CasingItems, then all the StrokeItems
				if (styleList.shapeStyles[subpart]) {
					var s:ShapeStyle=styleList.shapeStyles[subpart];
					var filled:Boolean= (!isNaN(s.fill_color) || s.fill_image) && way.findParentRelationsOfType('multipolygon','inner').length==0;

					if (s.width)        addItem(layer, new StrokeItem(s,way));
					if (filled)         addItem(layer, new FillItem(s,way));
					if (s.casing_width) addItem(layer, new CasingItem(s,way));

					maxwidth = s.width        ? Math.max(maxwidth,s.width       ) : s.width;
					maxwidth = s.casing_width ? Math.max(maxwidth,s.casing_width) : s.casing_width;
				}
			
				// TextItem
				if (styleList.textStyles[subpart])
					addItem(layer, new TextItem(styleList.textStyles[subpart], way, pathlength));
			}
		}

		// ------------------------------------
		// compilePOI
		// add POI DrawingItems to DisplayList
		// ------------------------------------
		
		public function compilePOI(poi:Node):void {
			// get tags
            var tags:Object = poi.getTagsCopy();
			if (poi.status) { tags['_status']=poi.status; }
			if (!poi.hasParentWays) { tags['poi']='yes'; }
			if (poi.numParentWays>1) { tags['junction']='yes'; }
			if (poi.hasInterestingTags()) { tags['hasTags']='yes'; }
			if (poi.isDupe()) { tags['dupe']='yes'; }

			// find style
			var styleList:StyleList=ruleset.getStyles(poi, tags, spec.scale);
			var layer:Number=styleList.layerOverride();
			if (isNaN(layer)) layer=tags['layer'] ? layer=Math.min(Math.max(tags['layer'],spec.minlayer),spec.maxlayer) : 0;

			// add entry for each subpart
			for each (var subpart:String in styleList.subparts) {
				if (styleList.pointStyles[subpart]) 
					addItem(layer, new PointItem(styleList.pointStyles[subpart], poi,
				                             	(styleList.shapeStyles[subpart] ? styleList.shapeStyles[subpart] : null)));
				if (styleList.textStyles[subpart])
					addItem(layer, new TextItem(styleList.textStyles[subpart], poi));
			}
		}

		// ------------------------------------
		// addItem
		// add an item to this list
		// ------------------------------------
		
		private function addItem(layer:uint, item:DrawingItem):void {
			var sublayer:Number=item.getSublayer();
			var l:Number=layer-spec.minlayer;
			
			if (list[l]==undefined) list[l]=[];
			if (list[l][sublayer]==undefined) list[l][sublayer]=[];
			list[l][sublayer].push(item);
		}

		// ------------------------------------
		// draw
		// Draw all items onto a PDF: the page should already have been created
		// ** FIXME: cope with different size pages, etc. etc.
		// ------------------------------------

		public function draw(pdf:PDF):void {
			for (var layer:uint=0; layer<list.length; layer++) {
				if (!list[layer]) continue;
				drawItemsOfClass(pdf,list[layer],FillItem);
				drawItemsOfClass(pdf,list[layer],CasingItem);
				drawItemsOfClass(pdf,list[layer],StrokeItem);
				drawItemsOfClass(pdf,list[layer],PointItem);
				drawItemsOfClass(pdf,list[layer],TextItem);
			}
		}
		
		private function drawItemsOfClass(pdf:PDF, items:Array, itemClass:Class):void {
			for (var sublayer:uint=0; sublayer<items.length; sublayer++) {
				if (!items[sublayer]) continue;
				for each (var item:DrawingItem in items[sublayer]) {
					if (item is itemClass) item.draw(pdf,spec);
				}
			}
		}

	}
	
}
