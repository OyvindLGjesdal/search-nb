<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
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
    
    <xsl:param name="q" as="xs:string"/>
    <xsl:param name="itemsPerPage" as="xs:integer" select="20"/>
    
    <xsl:variable name="debug" select="true()" as="xs:boolean"/>
      
    <!-- initial named template-->
    <xsl:template name="initialTemplate">
        <xsl:variable name="query" as="xs:string"><xsl:text>https://www.nb.no/services/search/v2/search?q={encode-for-uri($q)}&amp;itemsPerPage={string($itemsPerPage)}</xsl:text></xsl:variable>
        <xsl:variable name="proxied-query"><xsl:text>https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20xml%20where%20url%3D%22{encode-for-uri($query)}%22&amp;format=xml</xsl:text></xsl:variable>
        <xsl:sequence select="flub:async-request($proxied-query,'result','basic-result')"/>    
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
    
    <xsl:template mode="basic-search" priority="3.0" match="atom:feed" expand-text="1">
        
        <div class="container">
        
            <span>{opensearch:startIndex} til {xs:integer(opensearch:startIndex) + xs:integer(opensearch:itemsPerPage)-1} av {opensearch:totalResults}</span>
              
            <xsl:variable name="next" select="if (atom:link[@rel='next']) then flub:proxy-doc-uri(atom:link[@rel='next']/@href) else ()"/>
            <xsl:if test="$debug">
                <xsl:message select="concat('next: ',$next)"/>
            </xsl:if>
            <xsl:variable name="previous" select="if (atom:link[@rel='previous']) then  flub:proxy-doc-uri(atom:link[@rel='previous']/@href) else ()"/> 
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
            <xsl:variable name="result-fragment" select="id('result',ixsl:page())"/>
            <ixsl:set-property name="previous" select="$previous" object="$result-fragment"/>
            <ixsl:set-property name="next" select="$next" object="$result-fragment"/>
                    </div>
            
          <p><xsl:apply-templates mode="#current">
              <xsl:with-param tunnel="yes" name="test" select="'test2'"/>
          </xsl:apply-templates></p>
        <xsl:comment>
            <xsl:copy-of select="."/>
        </xsl:comment>
    </xsl:template>
    
    <xsl:template mode="basic-search" match="*" priority="2.0"></xsl:template>
    
    <xsl:template mode="basic-search" match="atom:entry" priority="3.0" expand-text="1">
    <div class="list-group">
        <li class="list-group-item list-group-item-action flex-column align-items-start">
        <div class="d-flex w-100 justify-content-between">
            <h5 class="mb-1">{atom:title}</h5>
            <small>{nb:namecreator} ({nb:year}) </small>
        </div>
        <p class="mb-1">{atom:summary}</p>
        </li>
    </div>
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
        
        <xsl:if test="$debug">
            <xsl:message select="'flub:async-request: ' || $doc-request"/>
        </xsl:if>
        <ixsl:schedule-action document="{$doc-request}">
            <xsl:call-template name="async-transform"  >
                <xsl:with-param name="doc-request" select="$doc-request"/>
                <xsl:with-param name="callback-name" select="$callback-name"/>
                <xsl:with-param name="id" select="xs:ID($page-id)"/>
            </xsl:call-template>            
        </ixsl:schedule-action>
    </xsl:function>  
    
    <!-- generic named template for delegating async request (ixsl:scheduled-action)-->
    <xsl:template name="async-transform">
        <xsl:param name="doc-request" as="xs:anyURI"/>
        <xsl:param name="id" as="xs:ID"/>
        <xsl:param name="callback-name" as="xs:string"/>
        <xsl:if test="not(id(string($id),ixsl:page()))">
            <xsl:message select="'id: ' || string($id) || ' not present in webpage'" terminate="yes"/>
        </xsl:if>        
        <xsl:assert test="exists(id(string($id),ixsl:page()))"/>
        <xsl:result-document href="#{string($id)}" method="ixsl:replace-content">            
            <xsl:apply-templates select="document($doc-request)/*" mode="callback">
                <xsl:with-param name="callback-name" select="$callback-name"/>
                <xsl:with-param name="id" select="$id"/>
            </xsl:apply-templates>
        </xsl:result-document>        
    </xsl:template>
    
    <!-- match for adding new modes to async doc request-->
    <xsl:template match="*" mode="callback">
        <xsl:param name="callback-name"/>
        <xsl:choose>
            <xsl:when test="$callback-name='basic-result'">
                <xsl:apply-templates select="self::node()//atom:feed[1]" mode="basic-search"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes" select="'callback-name: ',$callback-name, ' is not defined in mode transform-async'"></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- takes a uri and adds a proxy to allow cors-->
    <xsl:function name="flub:proxy-doc-uri" as="xs:anyURI*">
        <xsl:param name="doc-uri" as="xs:string+"/>
        <xsl:for-each select="$doc-uri">
            <xsl:sequence select="xs:anyURI(concat('https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20xml%20where%20url%3D%22',encode-for-uri(.),'%22&amp;format=xml'))"/>
        </xsl:for-each>
    </xsl:function>
</xsl:stylesheet>