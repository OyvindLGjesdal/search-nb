<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:flub="http://data.ub.uib.no/ns/function-library"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="xs math"
    version="3.0" expand-text="1">
    
    <xsl:param name="q" as="xs:string"/>
    
    <xsl:variable name="debug" select="true()" as="xs:boolean"/>
    <xsl:template name="callback">
        <xsl:param name="doc-request" as="xs:anyURI"/>    
        <xsl:sequence select="copy-of(document($doc-request))"/>
        
        <!--<xsl:variable name="call-template" expand-text="1">
            <xsl:text expand-text="1">&lt;xsl:call-template name=&quot;{xs:string($callback)}&quot;&gt;</xsl:text>
            <xsl:text>&lt;xsl:with-param name=&quot;doc-request&quot; select=&quot;$doc-request&quot;/&gt;</xsl:text>
            <xsl:text>&lt;/xsl:call-template&gt;</xsl:text>
        </xsl:variable>-->        
        <!--
        <xsl:if test="$debug">
        <xsl:message select="$callback"/>
        </xsl:if>
        <xsl:evaluate xpath="$call-template"/> -->       
    </xsl:template>
    
    <!--"XPath parsing error: lexical analysis failed
while expecting [IntegerLiteral, DecimalLiteral, DoubleLiteral, StringLiteral, URIQualifiedName, QName, S, Wildcard, '$', '(', '(:', '+', '-', '.', '..', '/', '//', '?', '@', '[', 'ancestor', 'ancestor-or-self', 'and', 'array', 'attribute', 'cast', 'castable', 'child', 'comment', 'descendant', 'descendant-or-self', 'div', 'document-node', 'element', 'else', 'empty-sequence', 'eq', 'every', 'except', 'following', 'following-sibling', 'for', 'function', 'ge', 'gt', 'idiv', 'if', 'instance', 'intersect', 'is', 'item', 'le', 'let', 'lt', 'map', 'mod', 'namespace', 'namespace-node', 'ne', 'node', 'or', 'parent', 'preceding', 'preceding-sibling', 'processing-instruction', 'return', 'satisfies', 'schema-attribute', 'schema-element', 'self', 'some', 'switch', 'text', 'to', 'treat', 'typeswitch', 'union']
at line 1, column 1:
...<xsl:call-template name="hello-world"><xsl:with-param name="doc-... from source:at search-nb.xsl#21"
-->
    <!-- takes a request, and a named template NCName to handle the request-->
    <xsl:function name="flub:async-doc">
        <xsl:param name="doc-request" as="xs:anyURI"/>        
        <ixsl:schedule-action document="{$doc-request}">
            <xsl:call-template name="callback">
                <xsl:with-param name="doc-request" select="$doc-request"/>
            </xsl:call-template>            
        </ixsl:schedule-action>
    </xsl:function>
    
    <xsl:template name="initialTemplate">
        <xsl:variable name="query" as="xs:string"><xsl:text>https://www.nb.no/services/search/v2/search?q={$q}</xsl:text></xsl:variable>
        <xsl:variable name="proxied-query"><xsl:text>https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20xml%20where%20url%3D%22{encode-for-uri($query)}%22&amp;format=xml</xsl:text></xsl:variable>
          
        <xsl:variable name="queries" select="flub:proxy-doc-uri($query)"/>
        
        
        
        <xsl:sequence select="flub:ypl-proxied-async-doc($query)"/>
        
        
        
    </xsl:template>
    
    <xsl:template name="hello-world">
        <xsl:param name="doc-request" as="xs:anyURI"/>
        <xsl:result-document href="#result" method="ixsl:replace-content">            
            <xsl:apply-templates select="document($doc-request)" mode="query-result"/>
        </xsl:result-document>      
        
    </xsl:template>
    
    <xsl:function name="flub:ypl-proxied-async-doc">
        <xsl:param name="query"/>
        <xsl:apply-templates select="flub:async-doc(flub:proxy-doc-uri($query))" mode="proxy-copy"/>
        
    </xsl:function>
    
    <xsl:template match="query[not(parent::*)]|query[not(parent::*)]/results" mode="proxy-copy">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template mode="proxy-copy" match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:function name="flub:proxy-doc-uri" as="xs:anyURI*">
      <xsl:param name="doc-uri" as="xs:string+"/>
        <xsl:for-each select="$doc-uri">
            <xsl:sequence select="xs:anyURI(concat('https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20xml%20where%20url%3D%22',encode-for-uri(.),'%22&amp;format=xml'))"/>
        </xsl:for-each>
    </xsl:function>
    <!-- yahoo proxy for calls to doc without cors from saxon-js-->
    <!--<xsl:function name="flub:proxy-doc">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:variable name="uri-proxied" expand-text="1" as="xs:string">https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20xml%20where%20url%3D%22{encode-for-uri($uri)}%22&amp;format=xml</xsl:variable>
        <ixsl:schedule-action document="{$uri-proxied}">
            <xsl:call-template name="getResultingDocument">
                <xsl:with-param name="uri-proxied" select="$uri-proxied"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:function>-->
    
    <xsl:output name="serializer" method="xml" indent="yes"/>    
    
    <xsl:template name="getResultingDocument" as="document-node()?">
        <xsl:param name="uri-proxied" as="xs:string"/>       
            <xsl:sequence select="parse-xml(serialize(saxon:discard-document(document($uri-proxied))/query/results/*,'serializer'))"/>      
    </xsl:template>
    
    <xsl:template name="handleQuery">
        <xsl:param name="query" as="xs:string"/>
        <xsl:result-document href="#result" method="ixsl:replace-content">            
            <xsl:apply-templates select="document($query)" mode="query-result"/>
        </xsl:result-document>        
    </xsl:template>
    
    <xsl:template mode="query-result" match="*">
          <p>1st item node {name()}</p>
        <xsl:comment>
            <xsl:copy-of select="."/>
        </xsl:comment>
    </xsl:template>
</xsl:stylesheet>