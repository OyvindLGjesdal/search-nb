<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="xs math"
    version="3.0" expand-text="1">
    
    <xsl:param name="q" as="xs:string"/>
    
    <xsl:template name="initialTemplate">
        <xsl:variable name="query" as="xs:string" select="'http://www.nb.no/services/search/v2/search?q={$q}'"/>
        <ixsl:schedule-action document="{$query}">
            <xsl:call-template name="handleQuery">
                <xsl:with-param name="query" select="$query"/>
            </xsl:call-template>
        </ixsl:schedule-action>
    </xsl:template>
    
    <xsl:template name="handleQuery">
        <xsl:param name="query" as="xs:string"/>
        <xsl:result-document href="#result" method="ixsl:replace-content">
            <xsl:value-of select="doc($query)"/>
            <xsl:apply-templates select="doc($query)" mode="query-result"/>
        </xsl:result-document>
        
    </xsl:template>
    
    <xsl:template mode="query-result" match="*">
          <p>1st item node {name()}</p>
        <xsl:comment>
            <xsl:copy-of select="."/>
        </xsl:comment>
    </xsl:template>
</xsl:stylesheet>