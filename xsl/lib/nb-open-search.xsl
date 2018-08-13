<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:flub="http://data.ub.uib.no/ns/function-library"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="xs math"
    version="3.0">
    <xsl:variable name="fq" select="'year',
        'month',
        'day',
        (:: 'digital' må spesialbehandles, trenger = istedenfor : for å virke::)
        'mediatype',
        'languages',
        'publisher',
        'namecreator'" as="xs:string+"/>
    
    <xsl:function name="flub:get-opensearch-param-prefix" visibility="private">
        <xsl:param name="paramname" as="xs:string"/>
        <xsl:sequence select="if (some $x in $fq satisfies $x=$paramname) 
            then 'fq='|| $paramname || ':'
            else if ($paramname = 'digital') 
            then 'fq=digital='
            else $paramname || '='"/> 
    </xsl:function>
    
    <xsl:function name="flub:param-helper" as="xs:string?" visibility="private">
        <xsl:param name="object"/>        
        <xsl:param name="name" as="xs:string"/>
        <xsl:variable name="value" as="xs:string?" select="string(ixsl:get($object,$name))"/>
        <xsl:sequence select="if (string($value)) 
            then flub:get-opensearch-param-prefix($name) || $value
            else ()"/>
    </xsl:function>
    
    <xsl:function name="flub:facet-query" as="xs:anyURI">
        <xsl:param name="query" as="xs:string"/>
        <xsl:sequence select="xs:anyURI(
            replace(
            replace($query,'itemsPerPage=[0-9]+','itemsPerPage=1')
            ,'&amp;facet=all','')
            || '&amp;facet=all')"/>
    </xsl:function>
    
    <xsl:function name="flub:set-startindex" as="xs:string">
        <xsl:param name="query" as="xs:string"/>
        <xsl:param name="index" as="xs:integer"/>
        <xsl:value-of select="replace($query,'&amp;startIndex=[0-9]+','') || concat('&amp;startIndex=',string($index))"/>
    </xsl:function>
    
    <xsl:function name="flub:facet-uri-component">
        <xsl:param name="facet-name" as="xs:string"/>
        <xsl:param name="facet-value" as="xs:string"/>
        <xsl:value-of select="concat('&amp;fq=',$facet-name,':',encode-for-uri(concat('&quot;',$facet-value,'&quot;')))"/>
    </xsl:function>
</xsl:stylesheet>