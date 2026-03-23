<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="Show_All">
    <html>
      <head>
        <title>Actions</title>
        <style>
           .action_name { font-family: courier; font-size: 110%; text-transform: lowercase }
        </style>
      </head>
      <body>
        <xsl:for-each select="Action">
          <xsl:element name="form">
            <xsl:attribute name="method">GET</xsl:attribute>
            <xsl:attribute name="action"><xsl:value-of select="Tag_Name"/></xsl:attribute>
            <span class="action_name"><strong><xsl:value-of select="Tag_Name"/></strong>?set=</span>
            <xsl:element name="input">
              <xsl:attribute name="type">text</xsl:attribute>
              <xsl:attribute name="name">set</xsl:attribute>
              <xsl:attribute name="value"><xsl:value-of select="set"/></xsl:attribute>
              <xsl:attribute name="size">40</xsl:attribute>
              <xsl:attribute name="style">font-family: courier; font-size: 110%</xsl:attribute>
            </xsl:element>
            <input style="font-family: courier" type="submit" value="Go"/>
          </xsl:element>
        </xsl:for-each>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
