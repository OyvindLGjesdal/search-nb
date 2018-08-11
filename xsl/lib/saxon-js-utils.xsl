<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:flub="http://data.ub.uib.no/ns/function-library"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="xs math"
    version="3.0">    
    <xsl:param name="debug" as="xs:boolean" select="false()"/>
    
    <xsl:variable name="cors-proxied-uris" as="map(*)?">
        <xsl:message terminate="yes" select="'variable $cors-proxied-uris must be overriden by importing stylesheet.'"/>
    </xsl:variable>
    
    <xsl:template match="*" mode="callback">
        <xsl:message select="'saxon-js-utils: template match =* mode callback must be implemented in importing stylesheet'" terminate="yes"/>
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
        
    <xsl:function name="flub:async-request">
        <xsl:param name="doc-request" as="xs:anyURI"/>
        <xsl:param name="page-id" as="xs:string"/>
        <xsl:param name="callback-name" as="xs:string"/>        
        
        <xsl:if test="$debug">
            <xsl:message select="'flub:async-request: ' || $doc-request"/>
        </xsl:if>        
        <xsl:sequence select="flub:async-request($doc-request,$page-id,$callback-name,'xml')"/>
    </xsl:function>  
    
    <!-- translating cors uri by looking up an uri, and checking for existence -->
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
        
        <xsl:if test="not(map:get($cors-proxied-uris,$proxy-uri))">
            <xsl:message select="$uri, ' not f ound in $cors-proxied-uris map.', string-join(map:keys($cors-proxied-uris),', '), 'Add a map entry to $cors-proxied-uris' " terminate="yes"/>
        </xsl:if>
        
        <xsl:sequence select="xs:anyURI(concat(map:get($cors-proxied-uris,$proxy-uri),substring-after($uri,$proxy-uri)))"/>
        
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
        <!-- assert not in saxon-js (1.1) yet-->
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
    
</xsl:stylesheet>