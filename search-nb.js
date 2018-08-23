"use strict";

var basicResult = new Object();

SaxonJS.transform({
         stylesheetLocation: "xsl/search-nb.sef",
         initialTemplate: "initialTemplate"}
);
/* options for seadragon; http://openseadragon.github.io/docs/OpenSeadragon.html#.Options
 * 
 *  immediateRender for mobile? */
function SetSeaDragon(tileList) {
    var viewer =  OpenSeadragon({
        id: "openseadragon-viewer",
        sequenceMode: true,
        showRotationControl: true,
        prefixUrl: "images/",
        tileSources: tileList
        
});
}
