<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/"
    xmlns:nb="http://www.nb.no/xml/search/1.0/"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:flub="http://data.ub.uib.no/ns/function-library"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:js="http://saxonica.com/ns/globalJS"
    exclude-result-prefixes="xs math atom opensearch nb"
    version="3.0" expand-text="1">
    <!-- default values-->
    <xsl:param name="itemsPerPage" as="xs:integer" select="20"/>
    <xsl:param name="mediatype" select="'bøker'" as="xs:string"/>
    <xsl:param name="digitized" select="'True'" as="xs:string"/>
    <xsl:param name="ignore-facets" select="'ddc1','ddc2', 'ddc3','day','month','dra_base'"/>
    
    <xsl:import href="lib/saxon-js-utils.xsl"/>
    <xsl:include href="lib/nb-open-search.xsl"/>
    <xsl:variable name="debug" select="true()" as="xs:boolean"/>
    <xsl:variable name="cors-proxied-uris" as="map(xs:string,xs:string)">
        <xsl:map>
            <xsl:map-entry key="'https://www.nb.no/services/search/'" select="'https://www.nb.no/services/search/'"/>
            <xsl:map-entry key="'http://www.nb.no/services/search/'" select="'https://www.nb.no/services/search/'"/>
            <xsl:map-entry key="'https://158.39.77.227/'" select="'https://158.39.77.227/'"/>
            <xsl:map-entry key="'https://api.nb.no/'" select="'https://oyvindg.no/nb-api/'"/>
        </xsl:map>
    </xsl:variable>
    <!-- https://developer.mozilla.org/en-US/docs/Web/Events -->
    
    <!-- initial named template-->
    <xsl:template name="initialTemplate">
    <xsl:if test="$debug">
        <xsl:message select="'initial template'"/>
    </xsl:if>
        <xsl:variable name="main" select="id('main',ixsl:page())"/>
        <xsl:variable name="facets" select="id('facets',ixsl:page())"/>
        <!-- insert default (@todo local_storage?) values for query-->
        <ixsl:set-property name="itemsPerPage" select="$itemsPerPage" object="$main"/>
        <ixsl:set-property name="mediatype" select="$mediatype" object="$main"/>
        <ixsl:set-property name="digital" select="$digitized" object="$main"/>  
        <ixsl:set-property name="numPerFacet" select="8" object="$facets"/>        
        </xsl:template>
    <!--https://api.nb.no/catalog/v1/items/51a97ce22ce73c66bfa9d73a16064250/--> <!--agris, nora_dc,marcxchange-->
    <!--http://oai.bibsys.no/oai/repository?verb=getRecord&metadataPrefix=oai_dc&set=bibsys_autoritetsregister&identifier=oai:bibsys.no:authority:x90114212-->
    <!-- interactive actions-->
    <!-- previous and next button-->
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
    
    <!-- click facet-->
    <xsl:template match="a[starts-with(@id,'facet_result_')]" mode="ixsl:onclick">
         <xsl:variable name="query" select="ixsl:get(id('result',ixsl:page()),'query')"/>
        <xsl:variable name="facet-string" select="tokenize(@id,'_')[3]"/>
        <xsl:variable name="facet-uri-component" select="flub:facet-uri-component($facet-string,span[@class='facet-value'])"/>
        <xsl:variable name="new-query">
            <xsl:text>{flub:set-startindex($query,1)}{$facet-uri-component}</xsl:text>
        </xsl:variable>        
        <xsl:choose>
            <xsl:when test="contains($query,$facet-uri-component)">
                <xsl:variable name="remove-facet-query" select="flub:set-startindex(
                    substring-before($query,$facet-uri-component) || substring-after($query,$facet-uri-component)
                    ,1)" as="xs:string"/>
                <xsl:sequence select="flub:async-request(xs:anyURI(flub:cors-uri($remove-facet-query)),'result','basic-result')"/>
                <xsl:sequence select="flub:async-request(xs:anyURI(flub:facet-query($remove-facet-query)),'facets','facet')"/>
                <ixsl:set-attribute name="class" select="replace(@class,'\sactive','')"/>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-attribute name="class" select="@class || ' active'"/>
                <xsl:sequence select="flub:async-request(xs:anyURI(flub:cors-uri($new-query)),'result','basic-result')"/>
                <xsl:sequence select="flub:async-request(xs:anyURI(flub:facet-query($new-query)),'facets','facet')"/>
                
            </xsl:otherwise>
        </xsl:choose>
        </xsl:template>
    
    <!-- fire search on keyup enter search -->
    <xsl:template mode="ixsl:onkeyup"
        match="
            .[lower-case(ixsl:get(ixsl:event(), 'key')) = 'enter'
            and ixsl:get(ixsl:get(ixsl:event(), 'target'), 'id') = 'search-field1']">
        <xsl:call-template name="basic-search"/>

        <xsl:if test="$debug">
            <xsl:variable name="event" select="ixsl:event()"/>
            <xsl:message
                select="'event: ', ixsl:get($event, 'type'), 'key:', ixsl:get($event, 'key'), 'id ', ixsl:get(ixsl:get($event, 'target'), 'id')"
            />
        </xsl:if>
    </xsl:template>
    
    <!-- search-->
    <xsl:template match="button[@name='button-search']"
        mode="ixsl:onclick">        
     <xsl:call-template name="basic-search"/>
    </xsl:template>
    
    <!-- click search result item-->
    <xsl:template match="li[starts-with(@id,'sesam_')]" mode="ixsl:onclick">
        <xsl:message select="'result item'"/>
        <xsl:variable name="request" as="xs:string"><xsl:text expand-text="1">https://api.nb.no/catalog/v1/iiif/{substring-after(@id,'sesam_')}/manifest</xsl:text></xsl:variable>
        <xsl:variable name="request-map" select="
            map{
            'method': 'GET',
            'href': string(flub:cors-uri($request)),
           'media-type': 'text/plain'
            } "/>
        <ixsl:schedule-action http-request="$request-map">
            <xsl:call-template name="manifest">
            </xsl:call-template>
        </ixsl:schedule-action>      
    </xsl:template>
    <!-- adding modes to update on action-->    
    
    <!-- basic search -->
    <xsl:template mode="basic-search" priority="3.0" match="atom:feed" expand-text="1">
        <xsl:param name="query" tunnel="yes"/>
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
        </div>            
        <div class="list-group" id="basic-search-result">
            <xsl:apply-templates mode="#current"/>          
        </div>
        <xsl:if test="$debug">
            <xsl:message select="'mode facet query:' || $query"/>
        </xsl:if>
        
        <xsl:variable name="result-fragment" select="id('result',ixsl:page())"/>
        <ixsl:set-property name="previous" select="$previous" object="$result-fragment"/>
        <ixsl:set-property name="next" select="$next" object="$result-fragment"/>
        <ixsl:set-property name="query" select="$query" object="$result-fragment" />
    </xsl:template>
        
    <xsl:template mode="basic-search" match="*" priority="2.0"/>
    
    <xsl:template mode="basic-search" match="atom:entry" priority="3.0" expand-text="1">
        <li class="list-group-item list-group-item-action flex-column align-items-start" id="sesam_{nb:sesamid}">
        <div class="d-flex w-100 justify-content-between">
            
            <h5 class="mb-1">{atom:title}</h5>
            <small>{nb:namecreator} ({(nb:year,'Ikke oppgitt')[1]}) </small>
        </div>
        <p class="mb-1">{atom:summary}</p>
        </li>
        <!-- get stuff from manifest https://api.nb.no/catalog/v1/iiif/d8e554cada9e08d5c9ae369712dfba86/manifest
        -->
    </xsl:template>
    
    <!-- begin facet-->
    
    <xsl:template match="atom:feed" mode="facet">       
        <xsl:apply-templates mode="facet"/>   
    </xsl:template>    
    
    <xsl:template match="nb:facet[nb:name=$ignore-facets] | text()" mode="facet" priority="4.0"/>
    
    <xsl:template match="nb:facet[nb:values/nb:value]" mode="facet">
        <div class="ui" id="facet_{nb:name}">
            <h3><xsl:value-of select="nb:name"/></h3>
        
        <div class="list-group">
            <xsl:apply-templates mode="facet"/>
        </div>
            </div>
    </xsl:template>
   
    <xsl:template match="nb:value" mode="facet">
        <xsl:param name="query" as="xs:string" tunnel="yes"/>
        <xsl:variable name="facet-name" select="ancestor::nb:facet/nb:name" as="xs:string"/>
        <xsl:variable name="facet-comp" select="flub:facet-uri-component($facet-name,.)" as="xs:string"/>
        <xsl:variable name="is-active" select="contains($query,$facet-comp)" as="xs:boolean"/>
        <xsl:if test="(count(preceding-sibling::*)+count(following-sibling::*[contains($query,flub:facet-uri-component($facet-name,.))])) &lt; 8
            or $is-active">
        <a id="facet_result_{$facet-name}_{generate-id()}" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center
            {if ($is-active)
            then 
            ' active' 
            else ''}">
            <xsl:if test="$is-active">
                <xsl:attribute name="style" select="'color: white'"/>
            </xsl:if>
            <span class="facet-value"><xsl:value-of select="."/></span>
            <span class="badge badge-primary badge-pill">
                <xsl:if test="$is-active">
                    <xsl:attribute name="style" select="'background-color: white; color: black'"/>
                </xsl:if>{@nb:count}</span>
        </a>
        </xsl:if>
    </xsl:template>    
    
    
    <!-- match for adding new modes to async doc request-->
    <xsl:template match="*" mode="callback">
        <xsl:param name="callback-name" as="xs:string"/>
        <xsl:param name="query" as="xs:string"/>
        <xsl:choose>         
            <xsl:when test="$callback-name='json-manifest'">
                <xsl:message select="concat('hello json', self::node()/name())"/>
            </xsl:when>
            <xsl:when test="$callback-name='facet'">
                <xsl:apply-templates select="descendant-or-self::atom:feed[1]" mode="facet">
                    <xsl:with-param name="query" tunnel="yes" select="$query"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$callback-name='basic-result'">
                <xsl:apply-templates select="descendant-or-self::atom:feed[1]" mode="basic-search">
                    <xsl:with-param name="query" select="$query" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>            
            <xsl:otherwise>
                <xsl:message terminate="yes" select="'callback-name: ',$callback-name, ' is not defined in mode transform-async'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>    
    
    <xsl:template mode="manifest" match="*">
        <xsl:message select="name()"/>
        <xsl:apply-templates mode="manifest"/>
    </xsl:template>
    <!-- map of sequence where paged-->
    <xsl:template match="fn:map[fn:string[@key='viewingHint']='paged']" mode="manifest">
        <xsl:variable name="pages" as="xs:string+">
            <xsl:sequence select="for $x in fn:array[@key='canvases']/fn:map/fn:string[@key='@id'] 
                return concat('https://www.nb.no/services/image/resolver/'  
                ,tokenize($x,'/')[last()]
                ,'/info.json')"/>
        </xsl:variable>
        <xsl:if test="$debug">
            <xsl:message select="$pages[1]"/>
        </xsl:if>
        <xsl:sequence select="js:SetSeaDragon($pages)[2=1]"/>
    </xsl:template>
    
    <xsl:template match="text()" mode="manifest"/>
    
    <xsl:template name="manifest">
        <xsl:for-each select="?body">
            <ixsl:set-style name="visibility" select="'hidden'" object="id('search',ixsl:page())"/>
            <xsl:sequence select="id('search',ixsl:page())"/>
            <xsl:result-document href="#manifest" method="ixsl:replace-content">
                <div id="open-seadragon-viewer"/>
            <xsl:apply-templates select="json-to-xml(.)" mode="manifest"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <!-- named templates used for multiple interactive modes -->    
    <xsl:template name="basic-search">
    <xsl:variable name="main" select="id('main',ixsl:page())"/>
    <xsl:variable name="search-string" select="ixsl:get(id('search-field1',ixsl:page()),'value')"/>        
    <xsl:variable name="query" as="xs:string"><xsl:text>https://www.nb.no/services/search/v2/search?q={encode-for-uri(string($search-string))}&amp;{flub:get-params()}</xsl:text></xsl:variable>
    
    
    <!--<xsl:variable name="json-manifest" select="flub:proxy-doc-uri('https://api.nb.no/catalog/v1/iiif/d8e554cada9e08d5c9ae369712dfba86/manifest')" />-->
    <xsl:message select="'button button search click',$search-string"/>
    
    <xsl:if test="string($search-string)">
        <!--<xsl:sequence select="flub:async-request($json-manifest,'result','json-manifest','json-text')"/>-->
        <xsl:sequence select="flub:async-request(xs:anyURI(flub:cors-uri($query)),'result','basic-result')"/>    
        <xsl:sequence select="flub:async-request(flub:facet-query($query),'facets','facet')"/>
        <xsl:sequence select="ixsl:call(self::node(),'blur',[])"/>
    </xsl:if> 
    </xsl:template>
    <!-- functions-->
    <xsl:function name="flub:get-params" as="xs:string?">
        <xsl:variable name="main-object" select="id('main',ixsl:page())"/>
        <xsl:variable name="itemsPerPage" as="xs:string?" select="flub:param-helper($main-object,'itemsPerPage')"/>
        <xsl:variable name="mediatype" as="xs:string?" select="flub:param-helper($main-object,'mediatype')"/>
        <xsl:variable name="digitized" as="xs:string?" select="flub:param-helper($main-object,'digital')"/>
        <xsl:value-of select="string-join(($itemsPerPage,$mediatype,$digitized),'&amp;')"
        />
    </xsl:function>    
</xsl:stylesheet>