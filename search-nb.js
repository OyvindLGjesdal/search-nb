"use strict";
function transformSaxon(query){
console.log(query);

SaxonJS.transform({
         stylesheetLocation: "xsl/search-nb.sef",
         initialTemplate: "initialTemplate",
         stylesheetParams: { "q" : query}}
)
console.log(query);
}

var basicResult = new Object();