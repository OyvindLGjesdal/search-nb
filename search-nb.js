"use strict";

var SearchNB = new Object();

SearchNB.globalParams = new Object();
SearchNB.paramNames =[ "itemsPerPage", "item", "itemView"];

writeParamsToObject();

SaxonJS.transform({
    stylesheetLocation: "xsl/search-nb.sef",
    initialTemplate: "initialTemplate",
    stylesheetParams: SearchNB.globalParams
});
/* options for seadragon; http://openseadragon.github.io/docs/OpenSeadragon.html#.Options
 *
 *  immediateRender for mobile? */

function writeParamsToObject() {
    var params = new URLSearchParams(window.location);
    SearchNB.paramNames.forEach(function (paramName) {
        if (params.has(paramName)) {
            var paramValues = params.getAll(paramName);
            if (paramValues.length === 1) {
                paramValues = paramValues.get(0);
            }
            SearchNB.globalParams[paramName] = paramValues;
        }
    })
    if (params.has("itemsPerPage")) {
        globalParams.itemsPerPage = params.get("itemsPerPage");
    }
}


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

function downloadFile(object) {
    URL.createObjectURL(object)
}