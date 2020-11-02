// ==UserScript==
// @name         Block_okoun
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://www.okoun.cz/boards/evropska_unie*
// @match        http://www.okoun.cz/boards/evropska_unie*
// @match        https://www.okoun.cz/boards/komentare_k_aktualitam*
// @match        http://www.okoun.cz/boards/komentare_k_aktualitam*
// @match        https://www.okoun.cz/boards/spolecnost*
// @match        http://www.okoun.cz/boards/spolecnost*
// @match        https://www.okoun.cz/boards/orwell_%3A_1984*
// @match        http://www.okoun.cz/boards/orwell_%3A_1984*
// @match        https://www.okoun.cz/boards/historie_a_antropologie*
// @match        http://www.okoun.cz/boards/historie_a_antropologie*
// @match        https://www.okoun.cz/msgbox.jsp
// @grant        none
// ==/UserScript==
(function() {
    'use strict';
    var nodes = document.evaluate (
        "descendant::span[text()='tigr_papirosowy']/../.. | descendant::span[text()='Hele']/../.. | descendant::span[text()='Herbergk']/../.. | descendant::span[text()='Shake']/../..",
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