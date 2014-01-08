/*!
 * jQuery Cookie Plugin v1.3
 * https://github.com/carhartl/jquery-cookie
 *
 * Copyright 2011, Klaus Hartl
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.opensource.org/licenses/GPL-2.0
 *
 * Modified to work with Zepto.js by ZURB
 */
!function($,document,undefined){function raw(s){return s}function decoded(s){return decodeURIComponent(s.replace(pluses," "))}var pluses=/\+/g,config=$.cookie=function(key,value,options){if(value!==undefined){if(options=$.extend({},config.defaults,options),null===value&&(options.expires=-1),"number"==typeof options.expires){var days=options.expires,t=options.expires=new Date;t.setDate(t.getDate()+days)}return value=config.json?JSON.stringify(value):String(value),document.cookie=[encodeURIComponent(key),"=",config.raw?value:encodeURIComponent(value),options.expires?"; expires="+options.expires.toUTCString():"",options.path?"; path="+options.path:"",options.domain?"; domain="+options.domain:"",options.secure?"; secure":""].join("")}for(var decode=config.raw?raw:decoded,cookies=document.cookie.split("; "),i=0,l=cookies.length;l>i;i++){var parts=cookies[i].split("=");if(decode(parts.shift())===key){var cookie=decode(parts.join("="));return config.json?JSON.parse(cookie):cookie}}return null};config.defaults={},$.removeCookie=function(key,options){return null!==$.cookie(key)?($.cookie(key,null,options),!0):!1}}(Foundation.zj,document);