// ==UserScript==
// @name         Block reklama okoun
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://www.okoun.cz/boards*
// @match        http://www.okoun.cz/boards*
// @match        https://www.okoun.cz/*
// @match        http://www.okoun.cz/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';
    var nodes = document.evaluate (
        "descendant::div[contains(@id,'adwrapper')]",
        document,
        null,
        6,
        null
    );

    for (var i = 0, l = nodes.snapshotLength; i < l; i++)
    {
        nodes.snapshotItem(i).style.display = "none";
    }
})();