<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:its="http://www.w3.org/2005/11/its" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all" version="2.0"
    xmlns:local="local-functions.uri" >
    <xsl:strip-space elements="tei:*"/><xsl:output indent="yes" method="xml"
        omit-xml-declaration="no" encoding="UTF-8"/>
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Apr 9, 2012</xd:p>
            <xd:p><xd:b>Author:</xd:b> hlapin</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="rqs"
        ></xsl:param>
    <xsl:param name="mcite" select="'4.2.2.1'"/>
    <xsl:variable name="cite" select="if (string-length($mcite) = 0) then '4.2.2.1' else $mcite"/>
    <xsl:variable name="witlist">
        <xsl:variable name="params">
            <xsl:call-template name="tokenize-params">
                <xsl:with-param name="src" select="$rqs"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:for-each select="$params/tei:sortWit[text()]">
            <xsl:sort select="@sortOrder"/>
            <xsl:copy-of select="."/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:template match="tei:div[contains(@n,'mcite')]">
        <cx:collation xmlns:cx="http://interedition.eu/collatex/ns/1.0">
        <xsl:apply-templates select="tei:ab"/>
        </cx:collation>
    </xsl:template>
    <xsl:template match="tei:div[@n = 'selectList']"/>
    <xsl:template match="tei:ab">
        <cx:witness xmlns:cx="http://interedition.eu/collatex/ns/1.0">
            <xsl:attribute name="sigil"><xsl:value-of select="./@n"/></xsl:attribute>
            <xsl:variable name="pass-1"><xsl:apply-templates select="tei:w"></xsl:apply-templates>
        </xsl:variable>
        <xsl:value-of select="normalize-space($pass-1)"></xsl:value-of></cx:witness>
    </xsl:template>
    <xsl:template match="tei:w">
        <xsl:value-of select="normalize-space(./tei:reg)"></xsl:value-of><xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="tei:teiHeader"></xsl:template>
    <!-- Same technique used to tokenize the passed parameter data -->
    <xsl:template name="tokenize-params">
        <xsl:param name="src"/>
        <xsl:choose>
            <xsl:when test="contains($src,'&amp;')">
                <!-- build first token element -->
                <xsl:if test="not(contains(substring-before($src,'&amp;'),'mcite'))">
                    <sortWit>
                        <xsl:attribute name="sortOrder">
                            <xsl:choose>
                                <xsl:when
                                    test="substring-after(substring-before($src,'&amp;'),'=')
                                    =''">
                                    <xsl:value-of select="0"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of
                                        select="substring-after(substring-before($src,'&amp;'),'=')"
                                    />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:value-of select="substring-before(substring-before($src,'&amp;'),'=')"
                        />
                    </sortWit>
                </xsl:if>
                <!-- recurse -->
                <xsl:call-template name="tokenize-params">
                    <xsl:with-param name="src" select="substring-after($src,'&amp;')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- last token, end recursion -->
                <sortWit>
                    <xsl:attribute name="sortOrder">
                        <xsl:choose>
                            <xsl:when
                                test="substring-after($src,'=')
                                =''">
                                <xsl:value-of select="0"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="substring-after($src,'=')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:value-of select="substring-before($src,'=')"/>
                </sortWit>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>