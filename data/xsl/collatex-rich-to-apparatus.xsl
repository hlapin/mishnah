<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:cx="http://interedition.eu/collatex/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:my="http://dev.digitalmishnah.org/local-functions.uri"
    xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xd cx tei my" version="2.0">
    <xsl:output method="html" indent="yes" encoding="UTF-8"/>
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Dec 8, 2011</xd:p>
            <xd:p><xd:b>Author:</xd:b> hlapin</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <!-- xslt transformation of output from collatex demo for automated transformation in Cocoon
pipeline. -->
    <!-- Parameters for cocoon transformation -->
    <xsl:param name="rqs" xpath-default-namespace="http://www.tei-c.org/ns/1.0"></xsl:param>
    <xsl:param name="mcite" select="'4.2.2.1'"/>
    <xsl:variable name="cite" select="if (string-length($mcite) = 0) then '4.2.2.1' else $mcite"/>
    <xsl:variable name="queryParams" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
        <xsl:variable name="params">
            <xsl:call-template name="tokenize-params">
                <xsl:with-param name="src" select="$rqs"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:for-each select="$params/*[text()]">
            <xsl:sort select="@sortOrder"/>
            <xsl:copy-of select="."/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:template match="tei:text"/>
    <xsl:variable name="sortlist" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
        select="document('../tei/ref.xml')/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listWit//tei:witness[@corresp]"> </xsl:variable>
    <xsl:variable name="refList" select="for $ab in
        document('../tei/ref.xml')/tei:TEI/tei:text/tei:body/tei:div1/tei:div2/tei:div3[@xml:id='ref.4.2.2']/tei:ab
        return substring-after($ab/@xml:id, 'ref.')"/>
    
    <xsl:template match="/">
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <link rel="stylesheet" type="text/css"
                    href="http://www.jewishstudies.umd.edu/faculty/Lapin/MishnahProject/CollatexOutput.css"
                    title="Documentary"/>
                <title>Sample Output Collatex Output</title>
                <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
            </head>
            <body xsl:exclude-result-prefixes="#all" dir="rtl">
                <h1>Digital Mishnah Project</h1>
                <h2>Sample Collatex Output</h2>
                <h2>
                    <xsl:variable name="ref-cit" select="tei:TEI/tei:text/tei:body/tei:div/@n"> </xsl:variable>
                    <xsl:variable name="look-up">
                        <xsl:analyze-string select="$ref-cit"
                            regex="^([0-9])\.([0-9]{{1,2}})\.([0-9]{{1,2}})\.([0-9]{{1,2}})$">
                            <xsl:matching-substring>#ref.<xsl:value-of select="regex-group(1)"
                                    />.<xsl:value-of select="regex-group(2)"/>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:variable name="look-up-text">
                        <xsl:copy-of
                            select="document(normalize-space(concat('../tei/ref.xml',$look-up)),document(''))"
                        />
                    </xsl:variable>
                    <span class="tractate">
                        <xsl:value-of select="translate($look-up-text/*/@n,'_',' ')"/>
                    </span>
                    <xsl:analyze-string select="$ref-cit"
                        regex="^([0-9])\.([0-9]{{1,2}})\.([0-9]{{1,2}})\.([0-9]{{1,2}})$">
                        <xsl:matching-substring><xsl:text> </xsl:text><xsl:value-of
                                select="regex-group(3)"/>:<xsl:value-of select="regex-group(4)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </h2>
                <h3>1. Select a Passage</h3>
                <form name="selection" action="collate-hl" method="get">                <div dir="ltr" style="text-align: center">
                    <select name="mcite">
                        <xsl:for-each select="$refList">
                            <option>
                                <xsl:attribute name="value">
                                    <xsl:value-of select="."/>
                                </xsl:attribute>
                                <xsl:if test=". = $cite">
                                    <xsl:attribute name="selected">selected</xsl:attribute>
                                </xsl:if> 
                                <xsl:variable name="lookup-text">
                                    <xsl:copy-of select="document(normalize-space(concat('../tei/ref.xml#ref.', substring(., 1, 3))),document(''))"/>
                                </xsl:variable>
                                <xsl:value-of select="translate($lookup-text/*/@n,'_',' ')"/>
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="substring(., 5)"/>
                                <!--<xsl:value-of select="normalize-space(concat('../tei/ref.xml#ref.', substring($cite, 1, 3)))"/>-->
                            </option>
                        </xsl:for-each>
                    </select>
                </div>
                
                <h3>2. Sources for Collation</h3>
                <table class="sources" dir="ltr">
                    
                        <xsl:for-each select="$sortlist">
                            <xsl:variable name="witName" select="@xml:id"></xsl:variable>
                            <tr>
                                <td class="ref-wit">
                                    <xsl:value-of select="$witName"/>
                                </td>
                                <td>
                                    <input name="{$witName}" type="text" maxlength="3" size="3">
                                        <xsl:attribute name="id">
                                            <xsl:text>sel+</xsl:text>
                                            <xsl:value-of select="@xml:id"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="value">
                                            <xsl:choose><xsl:when test="$queryParams/tei:sortWit[text() =
                                                $witName]/@sortOrder != '0'"><xsl:value-of select="$queryParams/tei:sortWit[text() =
                                                $witName]/@sortOrder"></xsl:value-of></xsl:when>
                                            <xsl:otherwise><xsl:value-of select="''"></xsl:value-of></xsl:otherwise></xsl:choose>
                                            <!--<xsl:choose>
                                                <xsl:when test="$queryParams/tei:sortWit[text() =
                                                    $witName]/@sortOrder = 0"><xsl:value-of
                                                        select="''"></xsl:value-of></xsl:when>
                                                <xsl:otherwise><xsl:value-of select="$queryParams/*[text() =
                                                    $witName]/@sortOrder"></xsl:value-of></xsl:otherwise>
                                            </xsl:choose>-->
                                        </xsl:attribute>
                                        
                                    </input>
                                </td>
                                <td class="ref-data">
                                    <xsl:value-of select="text()"/>
                                </td>
                            </tr>
                        </xsl:for-each>
                        <tr/>
                        <tr>
                            <td dir="ltr">
                                <input type="submit" value="Collate"/>
                            </td>
                        </tr>
                    
                </table></form>
                <h3 dir="ltr">2. Alignment Table Format</h3>
                <p class="descr-text">The alignment table may scroll to the left. Use the scroll bar
                    to see additional columns. </p>
                <div class="alignment-table">
                    <table dir="rtl">
                        <xsl:for-each select="tei:TEI/tei:text/tei:body/tei:div/tei:ab">
                            <tr>
                                <td class="wit">
                                    <xsl:value-of select="./@n"/>
                                </td>
                                <xsl:for-each select="./tei:w">
                                    <td>
                                        <xsl:if test="@type ='variant'">
                                            <xsl:attribute name="class" select="'variant'"/>
                                        </xsl:if>
                                        <xsl:if test="@type='invariant'">
                                            <xsl:attribute name="class" select="'invariant'"/>
                                        </xsl:if>
                                        <xsl:variable name="text">
                                            <xsl:value-of select="text()"/>
                                        </xsl:variable>
                                        <xsl:choose>
                                            <xsl:when
                                                test="normalize-space(translate($text,'[]','')) != ''">
                                                <xsl:value-of select="$text"/>
                                            </xsl:when>
                                            <xsl:when
                                                test="normalize-space(translate($text,'[]','')) = ''">
                                                <xsl:text>–</xsl:text>
                                            </xsl:when>
                                        </xsl:choose>
                                    </td>
                                </xsl:for-each>
                                <td class="wit">
                                    <xsl:value-of select="./@n"/>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </table>
                </div>
                <div class="text" dir="rtl">
                    <h3 dir="ltr">3. Text of <xsl:value-of
                            select="tei:TEI/tei:text/tei:body/tei:div/tei:ab[1]/@n"/></h3>
                    <xsl:for-each select="tei:TEI/tei:text/tei:body/tei:div/tei:ab[1]/*">
                        <xsl:choose>
                            <xsl:when test="self::tei:w and text() != ''">
                                <!-- insert text where it exists -->
                                <xsl:sequence select="text()"/>
                                <xsl:text> </xsl:text>
                            </xsl:when>
                            <xsl:when test="self::tei:label">
                                <span class="label">
                                    <xsl:value-of select="text()"/>
                                    <xsl:text> </xsl:text>
                                </span>
                            </xsl:when>
                            <xsl:when test="self::tei:lb and @n mod 10 = 0">
                                <xsl:text> | </xsl:text>
                                <span class="lb">
                                    <xsl:value-of select="@n"/>
                                </span>
                            </xsl:when>
                            <xsl:when test="self::tei:pb">
                                <xsl:text> ¶ </xsl:text>
                                <span class="page">
                                    <xsl:value-of select="@n"/>
                                    <xsl:if test="following-sibling::element()[1][self::tei:cb]">
                                        <xsl:analyze-string select="following-sibling::tei:cb/@n"
                                            regex="^([0-9]{{1,3}})[rv]([AB])$">
                                            <xsl:matching-substring>
                                                <xsl:text> </xsl:text>
                                                <xsl:value-of select="regex-group(2)"/>
                                            </xsl:matching-substring>
                                        </xsl:analyze-string>
                                    </xsl:if>
                                </span>
                            </xsl:when>
                            <xsl:when test="self::tei:cb">
                                <xsl:if test="preceding-sibling::element()[1][not(self::tei:pb)]">
                                    <xsl:text> | </xsl:text>
                                    <span class="col">
                                        <xsl:analyze-string select="@n"
                                            regex="^([0-9]{{1,3}}[rv])([AB])$">
                                            <xsl:matching-substring>
                                                <xsl:value-of select="regex-group(1)"/>
                                                <xsl:text> </xsl:text>
                                                <xsl:value-of select="regex-group(2)"/>
                                            </xsl:matching-substring>
                                        </xsl:analyze-string>
                                    </span>
                                </xsl:if>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </div>
                <div class="apparatus" dir="rtl">
                    <h3 dir="ltr">4. Sample Apparatus, Text of <xsl:value-of
                            select="tei:TEI/tei:text/tei:body/tei:div/tei:ab[1]/@n"/> as Base Text </h3>
                    <xsl:variable name="numbWits"
                        select="count(tei:TEI/tei:text/tei:body/tei:div/tei:ab)"/>
                    <xsl:variable name="wit-list">
                        <xsl:for-each select="tei:TEI/tei:text/tei:body/tei:div/tei:ab">
                            <xsl:element name="my:sigil"
                                namespace="http://dev.digitalmishnah.org/local-functions.uri">
                                <xsl:value-of select="@n"/>
                            </xsl:element>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:variable name="readings-list">
                        <xsl:for-each select="tei:TEI/tei:text/tei:body/tei:div/tei:ab[1]/tei:w">
                            <xsl:variable name="position"
                                select="count(preceding-sibling::tei:w) + 1"/>
                            <xsl:variable name="by-position">
                                <xsl:element name="tei:readings">
                                    <xsl:copy-of select="ancestor::tei:div/tei:ab/tei:w[$position]"
                                    />
                                </xsl:element>
                            </xsl:variable>
                            <my:lemma>
                                <xsl:namespace name="my"
                                    select="'http://dev.digitalmishnah.org/local-functions.uri'"/>
                                <xsl:attribute name="position" select="$position"/>
                                <xsl:for-each select="$by-position/tei:readings/tei:w">
                                    <xsl:variable name="sort-order" select="position()"/>
                                    <my:reading>
                                        <xsl:namespace name="my"
                                            select="'http://dev.digitalmishnah.org/local-functions.uri'"/>
                                        <xsl:attribute name="sort-order" select="$sort-order"/>
                                        <xsl:attribute name="witness">
                                            <xsl:value-of
                                                select="normalize-space($wit-list/element()[$sort-order])"
                                            />
                                        </xsl:attribute>
                                        <xsl:attribute name="rdg">
                                            <xsl:variable name="text">
                                                <xsl:value-of
                                                  select="$by-position/tei:readings/tei:w[$sort-order]/text()"
                                                />
                                            </xsl:variable>
                                            <xsl:choose>
                                                <xsl:when
                                                  test="normalize-space(translate($text,'[]',''))
                                                != ''">
                                                  <xsl:value-of select="normalize-space($text)"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                  <xsl:text>–</xsl:text>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:attribute>
                                        <xsl:variable name="text-to-put">
                                            <xsl:value-of
                                                select="$by-position/tei:readings/tei:w[$sort-order]/tei:reg"
                                            />
                                        </xsl:variable>
                                        <xsl:choose>
                                            <xsl:when
                                                test="normalize-space(translate($text-to-put,'[]',''))
                                            != ''">
                                                <xsl:value-of select="normalize-space($text-to-put)"
                                                />
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:text>–</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </my:reading>
                                </xsl:for-each>
                            </my:lemma>
                        </xsl:for-each>
                    </xsl:variable>
                    <!-- Check if base text has a missing reading relative to others and group on
this -->
                    <xsl:for-each-group select="$readings-list/my:lemma"
                        group-adjacent="my:reading[@sort-order = 1] =
                        '–' or following::my:reading[1][@sort-order = 1] = '–'">
                        <xsl:choose>
                            <xsl:when test="current-grouping-key()">
                                <xsl:variable name="temp-group">
                                    <xsl:copy-of select="current-group()"/>
                                </xsl:variable>
                                <!-- 1. Copy current group to text -->
                                <!-- 2. Process using for each to generate strings of text (complex
                                    readings) for each witness -->
                                <!-- 3. Then copy the whole to a new variable, to process with
                                    grouping as with the single readings (below) -->
                                <!-- There has got to be a better way of doing this! -->
                                <xsl:variable name="complex-readings-group">
                                    <xsl:for-each
                                        select="$temp-group/my:lemma[1]/my:reading/@sort-order">
                                        <xsl:variable name="sort-order" select="."/>
                                        <my:complex-reading>
                                            <xsl:namespace name="my"
                                                select="'http://dev.digitalmishnah.org/local-functions.uri'"/>
                                            <xsl:attribute name="witness">
                                                <xsl:value-of select="parent::my:reading/@witness"/>
                                            </xsl:attribute>
                                            <xsl:attribute name="sort-order" select="$sort-order"/>
                                            <xsl:attribute name="position"
                                                select="$temp-group/my:lemma[1]/@position"/>
                                            <xsl:for-each select="$temp-group/my:lemma">
                                                <xsl:variable name="position">
                                                  <xsl:value-of select="@position"/>
                                                </xsl:variable>
                                                <xsl:value-of
                                                  select="normalize-space($temp-group/my:lemma[@position =
                                                  $position]/my:reading[@sort-order =
                                                  $sort-order]/@rdg)"/>
                                                <xsl:text> </xsl:text>
                                            </xsl:for-each>
                                        </my:complex-reading>
                                    </xsl:for-each>
                                </xsl:variable>
                                <span class="reading-group">
                                    <xsl:for-each-group
                                        select="$complex-readings-group/my:complex-reading"
                                        group-by="text()">
                                        <xsl:choose>
                                            <!-- process base text -->
                                            <xsl:when test="current-grouping-key()">
                                                <xsl:choose>
                                                  <xsl:when
                                                  test="current-group()/self::my:complex-reading[@sort-order='1']">
                                                  <span class="lemma">
                                                  <!-- Check if empty (emdash) and process -->
                                                  <xsl:value-of
                                                  select="normalize-space(translate(self::my:complex-reading[@sort-order='1']/text(),'–',''))"
                                                  />
                                                  </span>
                                                  <span class="matches">
                                                  <xsl:for-each-group select="current-group()"
                                                  group-by="@sort-order">
                                                  <xsl:choose>
                                                  <xsl:when
                                                  test="current-group()/self::my:complex-reading[@sort-order='1']"/>
                                                  <xsl:otherwise>
                                                  <xsl:value-of select="current-group()/@witness"/>
                                                  <xsl:text> </xsl:text>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </xsl:for-each-group>
                                                  </span>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <span class="readings">
                                                  <xsl:choose>
                                                  <xsl:when test="current-group()[1]='–'">
                                                  <bdo dir="rtl">–</bdo>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <bdo dir="rtl">
                                                  <xsl:value-of
                                                  select="translate(current-group()[1],'–',
'')"/>
                                                  </bdo>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </span>
                                                  <span class="witnesses">
                                                  <xsl:value-of select="current-group()/@witness"/>
                                                  <xsl:text> </xsl:text>
                                                  </span>
                                                  </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:when>
                                        </xsl:choose>
                                    </xsl:for-each-group>
                                </span>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- Now process all the "single" readings -->
                                <xsl:for-each select="current-group()">
                                    <!-- Condition for processing: all readings are not identical -->
                                    <xsl:variable name="string">
                                        <xsl:value-of select="./my:reading[1]"/>
                                    </xsl:variable>
                                    <xsl:if
                                        test="count(my:reading[text() = $string]) &lt; $numbWits">
                                        <span class="reading-group">
                                            <xsl:for-each-group select="my:reading"
                                                group-by="text()">
                                                <xsl:choose>
                                                  <xsl:when test="current-grouping-key()">
                                                  <xsl:choose>
                                                  <xsl:when
                                                  test="current-group()/self::my:reading[@sort-order='1']">
                                                  <span class="lemma">
                                                  <!-- Check if empty (emdash) and process -->
                                                  <xsl:choose>
                                                  <!-- If empty -->
                                                  <xsl:when
                                                  test="normalize-space(self::my:reading[@sort-order='1'])
                                                  = ''">
                                                  <xsl:text>(</xsl:text>
                                                  <xsl:value-of
                                                  select="count(preceding::my:lemma[my:reading[@sort-order
                                                  = 1] = ''])+1"/>
                                                  <xsl:text>) </xsl:text>
                                                  <xsl:value-of
                                                  select="self::my:reading[@sort-order='1']/@witness"/>
                                                  <xsl:text>
                                                          </xsl:text>
                                                  <xsl:text>ח׳</xsl:text>
                                                  </xsl:when>
                                                  <!-- If not empty -->
                                                  <xsl:otherwise>
                                                  <xsl:value-of
                                                  select="self::my:reading[@sort-order='1']/@rdg"/>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </span>
                                                  <span class="matches">
                                                  <xsl:for-each-group select="current-group()"
                                                  group-by="@sort-order">
                                                  <xsl:choose>
                                                  <xsl:when
                                                  test="current-group()/self::my:reading[@sort-order='1']/text()"/>
                                                  <xsl:otherwise>
                                                  <xsl:value-of select="current-group()/@witness"/>
                                                  <xsl:text> </xsl:text>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </xsl:for-each-group>
                                                  </span>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <span class="readings">
                                                  <bdo dir="rtl">
                                                  <xsl:value-of select="current-group()[1]/@rdg"/>
                                                  </bdo>
                                                  </span>
                                                  <span class="witnesses">
                                                  <xsl:value-of select="current-group()/@witness"/>
                                                  <xsl:text> </xsl:text>
                                                  </span>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </xsl:when>
                                                </xsl:choose>
                                            </xsl:for-each-group>
                                        </span>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group>
                </div>
            </body>
        </html>
    </xsl:template>
    <xsl:template name="tokenize-params">
        <xsl:param name="src"/>
        <xsl:choose>
            <xsl:when test="contains($src,'&amp;')">
                <!-- build first token element -->
                <xsl:if test="not(contains(substring-before($src,'&amp;'),'mcite'))">
                    <tei:sortWit xpath-default-namespace="http://www.tei-c.org/ns/1.0">
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
                    </tei:sortWit>
                </xsl:if>
                <!-- recurse -->
                <xsl:call-template name="tokenize-params">
                    <xsl:with-param name="src" select="substring-after($src,'&amp;')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- last token, end recursion -->
                <tei:sortWit xpath-default-namespace="http://www.tei-c.org/ns/1.0">
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
                </tei:sortWit>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
