"use strict";

SaxonJS.transform({
    stylesheetLocation: "xsl/search-nb.sef",
    initialTemplate: "initialTemplate"
});
/* options for seadragon; http://openseadragon.github.io/docs/OpenSeadragon.html#.Options
 *
 *  immediateRender for mobile? */

var SearchNB = new Object();

function SetSeaDragon(tileList) {
    closeSeaDragon();
    SearchNB.seadragon = OpenSeadragon({
        id: "openseadragon-viewer",
        sequenceMode: true,
        showRotationControl: true,
        prefixUrl: "images/",
        tileSources: tileList
    });
}

function seadragonIsDefined() {
    if (SearchNB.seadragon === undefined || SearchNB.seadragon === null) {
        return false;
    } else {
        return true;
    }
}

function currentPage() {
    if (seadragonIsDefined())
      {
        SearchNB.seadragon.Viewer.currentPage();
    }
}

function goToPage(num) {
    if (seadragonIsDefined())
      {
        SearchNB.seadragon.Viewer.goToPage(num);
    }
}

function closeSeaDragon() {
    if (seadragonIsDefined()) {
        SearchNB.seadragon.destroy();
        SearchNB.seadragon = null;
    }
}

function rewriteURI (newURI) {
    window.history.pushState({
    },
    null, newURI);
}