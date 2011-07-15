** Halcyon/PDF **

== What's this? ==

It's an OpenStreetMap PDF renderer written in ActionScript 3. Throw a bbox and a MapCSS stylesheet at it, and it'll generate a PDF map.

In itself that's quite fun, but it'll be even better if we can make a desktop AIR app out of it.

== Building ==

It's a Flex app. Build it with mxmlc in the normal way. Actually most of the code is pure AS3 and not Flex, but it made testing easier!

You'll need to edit pdf.mxml to contain:
- your bbox (lines 31-32) and target scale (line 33)
- the location of your MapCSS style sheet (line 46)

== Dependencies and source ==

The MapCSS parser is exactly that of Halcyon (the Flash renderer used in Potlatch 2). The only - temporary - change is to stuff loaded images into a Loader (DisplayObject) again, at line 320 of RuleSet.as. This needs to go into an ImageBank class anyway.

The data store is also from Halcyon, but with the editing-specific stuff ripped out (in particular, all the actions). (Note to Potlatch 2 developers: I guess we probably ought to refactor Halcyon so that all the actions sit in net.systemeD.potlatch2 rather than net.systemeD.halcyon, and we have something like an INode - I for Interactive - that extends Node. Or something.) There'll be lots and lots of surplus code in there.

PDF generation is courtesy of the amazing AlivePDF. AlivePDF is the latest code from svn, not the .zip release. It's patched here to make a few things in PDF.as public rather than protected (startTransform, stopTransform and getStringWidth), and to very hackily fix the broken xPos/yPos in placeImage (also in PDF.as).

And, just like Halcyon, we use sephiroth.it's eval library.

== Known issues ==

- This is pre-pre-pre-alpha. Nothing has been tested at all. Don't even bother reporting bugs yet. But feel free to roll up your sleeves and make it awesome.
- It doesn't do multipolygons.
- It doesn't do tagged nodes in ways yet. Only POIs.
- It doesn't label POIs.
- It ought to enlarge the bbox it asks for.
- Text-on-path is a bit broken. I hate matrices and all that sort of maths crap, I really do. It would make me really happy if someone who understood maths had a look at the source and fixed that.
- It doesn't take any notice of the font you specify.
- It doesn't do text halos.
- Image paths are probably relative to the .swf (bad), not to the MapCSS stylesheet (which would be good).
- It ought to support XAPI, and local .osm files, as well as the OSM API.
- It ought to do the whole wondrous Flash Player 10 local file thing, rather than bouncing stuff via a Perl script.

== Licence ==

WTFPL. Obviously. AlivePDF is MIT-licensed.

Richard Fairhurst
richard@systemeD.net
July 2011
