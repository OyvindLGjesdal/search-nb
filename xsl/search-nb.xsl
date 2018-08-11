<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/"
    xmlns:nb="http://www.nb.no/xml/search/1.0/"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:flub="http://data.ub.uib.no/ns/function-library"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="xs math atom opensearch nb"
    version="3.0" expand-text="1">
    <!-- default values-->
    <xsl:param name="itemsPerPage" as="xs:integer" select="20"/>
    <xsl:param name="mediatype" select="'bøker'"/>
    <xsl:param name="digitized" select="'True'"/>
    
    <xsl:import href="lib/saxon-js-utils.xsl"/>
    <xsl:include href="lib/nb-open-search.xsl"/>
    <xsl:variable name="debug" select="true()" as="xs:boolean"/>
    <xsl:variable name="cors-proxied-uris" as="map(xs:string,xs:string)">
        <xsl:map>
            <xsl:map-entry key="'https://www.nb.no/services/search/'" select="'https://158.39.77.227/nb-search/'"/>
            <xsl:map-entry key="'http://www.nb.no/services/search/'" select="'https://www.nb.no/services/search/'"/>
        </xsl:map>
    </xsl:variable>
 
    <!-- initial named template-->
    <xsl:template name="initialTemplate">
    <xsl:message select="'initial template'"/>
        <xsl:variable name="main" select="id('main',ixsl:page())"/>
        <!-- insert default (@todo local_storage?) values for query-->
        <ixsl:set-property name="itemsPerPage" select="$itemsPerPage" object="$main"/>
        <ixsl:set-property name="mediatype" select="$mediatype" object="$main"/>
        <ixsl:set-property name="digital" select="$digitized" object="$main"/>
        
        </xsl:template>
    
    <!-- interactive actions-->
    <xsl:template mode="ixsl:onclick" match="button[(@name='next-result' or @name='previous-result')
        and not(@disabled)]">
        <xsl:variable name="action" select="xs:anyURI(
            ixsl:get(
            id('result',ixsl:page()),
            if (@name='next-result') then 'next' else 'previous'))"/>
        <xsl:if test="$debug">
            <xsl:message select="concat('action:', $action)"/>
        </xsl:if>        
        <xsl:sequence select="flub:async-request($action,'result','basic-result')"/>        
    </xsl:template>
    
    <xsl:template match="button[@name='button-search']" mode="ixsl:onclick">
        <xsl:variable name="search-string" select="ixsl:get(id('search-field1',ixsl:page()),'value')"/>        
        <xsl:variable name="query" as="xs:string"><xsl:text>https://www.nb.no/services/search/v2/search?q={encode-for-uri(string($search-string))}&amp;{flub:get-params()}</xsl:text></xsl:variable>
        
        <!--<xsl:variable name="json-manifest" select="flub:proxy-doc-uri('https://api.nb.no/catalog/v1/iiif/d8e554cada9e08d5c9ae369712dfba86/manifest')" />-->
        <xsl:message select="'button button search click',$search-string"/>
        
        <xsl:if test="string($search-string)">
       <!--<xsl:sequence select="flub:async-request($json-manifest,'result','json-manifest','json-text')"/>-->
        <xsl:sequence select="flub:async-request(xs:anyURI(flub:cors-uri($query)),'result','basic-result')"/>    
        </xsl:if>
    </xsl:template>
    
    <!-- adding modes to update on action-->
    <!-- basic search -->
    <xsl:template mode="basic-search" priority="3.0" match="atom:feed" expand-text="1">
        <xsl:variable name="next" select="if (atom:link[@rel='next']) then  flub:cors-uri(atom:link[@rel='next']/@href) else ()"/>
        <xsl:if test="$debug">
            <xsl:message select="concat('next: ',$next)"/>
        </xsl:if>
        <xsl:variable name="previous" select="if (atom:link[@rel='previous']) then  flub:cors-uri(atom:link[@rel='previous']/@href) else ()"/> 
       
        <div class="container">                 
            <span>Resultat av søket: {opensearch:startIndex} til {xs:integer(opensearch:startIndex) + xs:integer(opensearch:itemsPerPage)-1} av {opensearch:totalResults}</span>
            <div>
                <button name="previous-result" class="btn">
                    <xsl:if test="not($previous)">
                        <xsl:attribute name="disabled"/>
                    </xsl:if>
                    <i class="fas fa-arrow-left"/>
                </button>            
                <button name="next-result" class="btn">
                    <xsl:if test="not($next)">
                        <xsl:attribute name="disabled"/>
                    </xsl:if>
                    <i class="fas fa-arrow-right"/>
                </button>                
            </div>  
        <xsl:variable name="result-fragment" select="id('result',ixsl:page())"/>
            <ixsl:set-property name="previous" select="$previous" object="$result-fragment"/>
            <ixsl:set-property name="next" select="$next" object="$result-fragment"/>
        </div>            
        <div class="list-group" id="basic-search-result">
            <xsl:apply-templates mode="#current"/>          
        </div>
    </xsl:template>
    
    <xsl:template mode="basic-search" match="*" priority="2.0"/>
    
    <xsl:template mode="basic-search" match="atom:entry" priority="3.0" expand-text="1">
        <li class="list-group-item list-group-item-action flex-column align-items-start">
        <div class="d-flex w-100 justify-content-between">
            <h5 class="mb-1">{atom:title}</h5>
            <small>{nb:namecreator} ({(nb:year,'Ikke oppgitt')[1]}) </small>
        </div>
        <p class="mb-1">{atom:summary}</p>
        </li>
        <!-- get stuff from manifest https://api.nb.no/catalog/v1/iiif/d8e554cada9e08d5c9ae369712dfba86/manifest
        -->
    </xsl:template>
    
    <!-- match for adding new modes to async doc request-->
    <xsl:template match="*" mode="callback">
        <xsl:param name="callback-name"/>
        <xsl:choose>         
            <xsl:when test="$callback-name='json-manifest'">
                <xsl:message select="concat('hello json', self::node()/name())"/>
            </xsl:when>
            <xsl:when test="$callback-name='basic-result'">
                <xsl:apply-templates select="descendant-or-self::atom:feed[1]" mode="basic-search"/>
            </xsl:when>            
            <xsl:otherwise>
                <xsl:message terminate="yes" select="'callback-name: ',$callback-name, ' is not defined in mode transform-async'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:function name="flub:get-params" as="xs:string?">
        <xsl:variable name="main-object" select="id('main',ixsl:page())"/>
        <xsl:variable name="itemsPerPage" as="xs:string?" select="flub:property-helper($main-object,'itemsPerPage')"/>
        <xsl:variable name="mediatype" as="xs:string?" select="flub:property-helper($main-object,'mediatype')"/>
        <xsl:variable name="digitized" as="xs:string?" select="flub:property-helper($main-object,'digital')"/>
        <xsl:value-of select="string-join(($itemsPerPage,$mediatype,$digitized),'&amp;')"
        />
    </xsl:function>    
</xsl:stylesheet>