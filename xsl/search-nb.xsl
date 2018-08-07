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
    
    <xsl:param name="itemsPerPage" as="xs:integer" select="20"/>
    
    <xsl:variable name="debug" select="true()" as="xs:boolean"/>
      
    <!-- proxied-uris ,http://www.nb.no/services/search/-->
    <xsl:variable name="search-api" select="'http://158.39.77.227/nb-search/'"/>
    
    <xsl:variable name="cors-proxied-uris" as="map(xs:string,xs:string)">
        <xsl:map>
            <xsl:map-entry key="'http://www.nb.no/services/search/'" select="'http://158.39.77.227/nb-search/'"/>
        </xsl:map>
    </xsl:variable>
 
    <!-- initial named template-->
    <xsl:template name="initialTemplate">
    <xsl:message select="'initial template'"/>   
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
        
        <xsl:variable name="query" as="xs:string"><xsl:text>https://www.nb.no/services/search/v2/search?q={encode-for-uri(string($search-string))}&amp;itemsPerPage={string($itemsPerPage)}</xsl:text></xsl:variable>
        
        <!--<xsl:variable name="json-manifest" select="flub:proxy-doc-uri('https://api.nb.no/catalog/v1/iiif/d8e554cada9e08d5c9ae369712dfba86/manifest')" />-->
        <xsl:message select="'button button search click',$search-string"/>
        
        <xsl:if test="string($search-string)">
       <!--<xsl:sequence select="flub:async-request($json-manifest,'result','json-manifest','json-text')"/>-->
        <xsl:sequence select="flub:async-request(xs:anyURI($query),'result','basic-result')"/>    
        </xsl:if>
    </xsl:template>
    
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
        
        <xsl:comment>
            <xsl:copy-of select="."/>
        </xsl:comment>
    </xsl:template>
    
    <xsl:template mode="basic-search" match="*" priority="2.0"></xsl:template>
    
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
    
    <!-- functions-->
    <!-- async request, which defines a request, an id to update in html-page, and a callback name to handle transformation of request
         http://www.saxonica.com/saxon-js/documentation/index.html#!ixsl-extension/instructions/schedule-action
         ixsl:scheduled-action allows exactly one named template child (async-transform), which is used to update some part of the html-page-->
       
    <xsl:function name="flub:async-request">
        <xsl:param name="doc-request" as="xs:anyURI"/>
        <xsl:param name="page-id" as="xs:string"/>
        <xsl:param name="callback-name" as="xs:string"/>
        <xsl:param name="method" as="xs:string"/>
        
        <xsl:if test="$debug">
            <xsl:message select="'flub:async-request: ' || $doc-request"/>
        </xsl:if>
        <ixsl:schedule-action document="{$doc-request}">
            <xsl:call-template name="async-transform"  >
                <xsl:with-param name="doc-request" select="$doc-request"/>
                <xsl:with-param name="callback-name" select="$callback-name"/>
                <xsl:with-param name="id" select="xs:ID($page-id)"/>
                <xsl:with-param name="method" select="$method"/>
            </xsl:call-template>            
        </ixsl:schedule-action>        
    </xsl:function>
    
    
    <xsl:function name="flub:cors-uri" as="xs:anyURI">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:variable name="proxy-uri">
            <xsl:iterate select="map:keys($cors-proxied-uris)">
                <xsl:if test="starts-with($uri,.)">
                    <xsl:sequence select="."/>
                    <xsl:break/>
                </xsl:if>
            </xsl:iterate>
        </xsl:variable>
        <xsl:if test="$proxy-uri">
            <xsl:message select="$uri, ' not found in $cors-proxied-uris map.', string-join(map:keys($cors-proxied-uris),', '), 'Add a map entry to $cors-proxied-uris' " terminate="yes"/>
        </xsl:if>
        
        <xsl:sequence select="xs:anyURI(concat($proxy-uri,substring-after($uri,$proxy-uri)))"/>
        
    </xsl:function>
    
    <xsl:function name="flub:async-request">
        <xsl:param name="doc-request" as="xs:anyURI"/>
        <xsl:param name="page-id" as="xs:string"/>
        <xsl:param name="callback-name" as="xs:string"/>        
        
        <xsl:if test="$debug">
            <xsl:message select="'flub:async-request: ' || $doc-request"/>
        </xsl:if>        
        <xsl:sequence select="flub:async-request($doc-request,$page-id,$callback-name,'xml')"/>
      </xsl:function>  
    
    <!-- generic named template for delegating async request (ixsl:scheduled-action)-->
    <xsl:template name="async-transform">
        <xsl:param name="doc-request" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:ID"/>
        <xsl:param name="callback-name" as="xs:string"/>
        <xsl:param name="method"/>
        <xsl:if test="not(id(string($id),ixsl:page()))">
            <xsl:message select="'id: ' || string($id) || ' not present in webpage'" terminate="yes"/>
        </xsl:if>        
        <xsl:assert test="exists(id(string($id),ixsl:page()))"/>
        
        <xsl:result-document href="#{string($id)}" method="ixsl:replace-content">
            <xsl:variable name="document" select="if ($method='xml' ) 
                then document($doc-request)
                else if ($method='json-text') then json-to-xml(parse-json(unparsed-text(string($doc-request)))) else ()"/>            
        
                <xsl:apply-templates select="$document/*" mode="callback">
                    <xsl:with-param name="callback-name" select="$callback-name"/>
                    <xsl:with-param name="id" select="$id"/>
                </xsl:apply-templates>
        </xsl:result-document>        
    </xsl:template>
    
    <!-- match for adding new modes to async doc request-->
    <xsl:template match="*" mode="callback">
        <xsl:param name="callback-name"/>
        <xsl:choose>
            <xsl:when test="$callback-name='cache'">
                <xsl:if test="$debug">
             <xsl:message select="concat(base-uri(),' added to cache')"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$callback-name='json-manifest'">
                <xsl:message select="concat('hello json', self::node()/name())"/>
            </xsl:when>
            <xsl:when test="$callback-name='basic-result'">
                <xsl:apply-templates select="self::node()//atom:feed[1]" mode="basic-search"/>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:message terminate="yes" select="'callback-name: ',$callback-name, ' is not defined in mode transform-async'"></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
</xsl:stylesheet>