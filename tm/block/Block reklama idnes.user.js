// ==UserScript==
// @name         Block reklama idnes
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://www.idnes.cz/*
// @match        http://www.idnes.cz/*
// @grant        none

// ==/UserScript==

(function() {
    'use strict';

    var targEval = document.evaluate (
        "descendant::div[contains(@class,'s-art')]|descendant::div[contains(@class,'col-b')]|descendant::div[contains(@id,'r98')]",
        document,
        null,
        XPathResult.ORDERED_NODE_ITERATOR_TYPE,
        null
    );

    var targNode = targEval.iterateNext();
    while(targNode)
    {
        targNode.style.display = "none";
        targNode = targEval.iterateNext();
    }
    
    targEval = document.evaluate (
        "descendant::div[contains(@class,'col')]/comment()",
        document,
        null,
        XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,
        null
    );

    for(var i=0; i<targEval.snapshotLength;i++)
    {
        targEval.snapshotItem(i).nodeValue="REMOVED";
    }

    targEval = document.evaluate (
        "descendant::table[contains(@id,'r98')]",
        document,
        null,
        XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,
        null
    );

    for(var i=0; i<targEval.snapshotLength;i++)
    {
        var table = targEval.snapshotItem(i);
        table.parentNode.removeChild(table);
    }
    
  
    var scripts = document.getElementsByTagName('script');

for (var J = scripts.length-1;  J >=0;  --J)
{
    if ((!scripts[J].src) | (scripts[J].src.indexOf("http://www.idnes.cz")== -1))
    {
        console.log ("Killed", scripts[J].src);
        scripts[J].parentNode.removeChild (scripts[J]);        
    }
}
})();