// ==UserScript==
// @name         Block reklama lupa
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://www.lupa.cz/*
// @match        http://www.lupa.cz/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';
    var nodes = document.evaluate (
        "descendant::div[contains(@class,'js-adverts-header-wrapper')] | descendant::div[contains(@class,'js-advert-position-mark-index-articles-bottom')]",
        document,
        null,
        6,
        null
    );

    //console.log("Nodes count:");
    //console.log(nodes.snapshotLength);
    for (var i = 0, l = nodes.snapshotLength; i < l; i++)
    {
       // console.log(nodes.snapshotItem(i));
        nodes.snapshotItem(i).style.display = "none";
    }
})();