"use strict";
function transformSaxon(query){
console.log(query);

SaxonJS.transform({
         stylesheetLocation: "xsl/search-nb.sef",
         initialTemplate: "initialTemplate",
         styleSheetParams: { "Q{}q" : query}}
)
console.log(query);
}