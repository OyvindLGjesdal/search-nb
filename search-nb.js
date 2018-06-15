"use strict";
function transformSaxon(query){
       SaxonJS.transform({
         stylesheetLocation: "xsl/search-nb.sef",
         initialTemplate: "initialTemplate",
         styleSheetParams: { q : query}}
)
console.log(query);
}