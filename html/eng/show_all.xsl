<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  
  <xsl:template match="Show_All">
    
    <html>
      <head>
        <title>show_all.xsl</title>
        <style>
           b {text-transform: lowercase;
              font-family: "Arial";}
        </style>
      </head>
      <body bgcolor="white">
        
        <br/>

        <xsl:for-each select="Action">

          <xsl:element name="form">
            <xsl:attribute name="method">GET</xsl:attribute>
            <xsl:attribute name="action"><xsl:value-of select="Tag_Name"/></xsl:attribute>

            <b><xsl:value-of select="Tag_Name"/></b>?set=

            <xsl:element name="input">
              <xsl:attribute name="type">text</xsl:attribute>

              <xsl:attribute name="name">set</xsl:attribute>
              <xsl:attribute name="value"><xsl:value-of select="set"/></xsl:attribute>
              <xsl:attribute name="size">70</xsl:attribute>
            </xsl:element>

            <br/>
            <input type="submit" value="enter"/><br/>

          </xsl:element>
        </xsl:for-each>

      </body>
    </html>

  </xsl:template>

</xsl:stylesheet>
