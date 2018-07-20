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
    
    
    <xsl:template name="initialTemplate">
        <xsl:variable name="query" as="xs:string"><xsl:text>https://www.nb.no/services/search/v2/search?q={$q}</xsl:text></xsl:variable>
        <xsl:variable name="proxied-query"><xsl:text>https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20xml%20where%20url%3D%22{encode-for-uri($query)}%22&amp;format=xml</xsl:text></xsl:variable>
           
        <ixsl:schedule-action document="{$proxied-query}">
            <xsl:call-template name="handleQuery">
                <xsl:with-param name="query" select="$proxied-query"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    
    <!-- yahoo proxy for calls to doc without cors-->
    <xsl:function name="flub:proxy-doc" as="element(*)?">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:variable name="uri-proxied" expand-text="1" as="xs:string">https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20xml%20where%20url%3D%22{encode-for-uri($uri)}%22&amp;format=xml</xsl:variable>
        <ixsl:schedule-action document="{$uri-proxied}">
            <xsl:call-template name="getResultingDocument">
                <xsl:with-param name="uri-proxied" select="$uri-proxied"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:function>
    
        
    <xsl:template name="getResultingDocument" as="element(*)?">
        <xsl:param name="uri-proxied" as="xs:string"/>       
        <!-- could use serialize -> parse-xml to return as document-node() to give same return type as doc?--> 
        <xsl:sequence select="saxon:discard-document(doc($uri-proxied))/query/results/*"/>
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