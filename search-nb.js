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
        prefixUrl: "https://cdn.jsdelivr.net/npm/openseadragon@2.4/build/openseadragon/images/",
        tileSources: tileList
        
});
console.log('SetSeaDragon');
}
