!function($,window,document){"use strict";Foundation.libs.section={name:"section",version:"4.3.2",settings:{deep_linking:!1,small_breakpoint:768,one_up:!0,multi_expand:!1,section_selector:"[data-section]",region_selector:"section, .section, [data-section-region]",title_selector:".title, [data-section-title]",resized_data_attr:"data-section-resized",small_style_data_attr:"data-section-small-style",content_selector:".content, [data-section-content]",nav_selector:'[data-section="vertical-nav"], [data-section="horizontal-nav"]',active_class:"active",callback:function(){}},init:function(scope,method,options){var self=this;return Foundation.inherit(this,"throttle data_options position_right offset_right"),"object"==typeof method&&$.extend(!0,self.settings,method),"string"!=typeof method?(this.events(),!0):this[method].call(this,options)},events:function(){for(var self=this,click_title_selectors=[],section_selector=self.settings.section_selector,region_selectors=self.settings.region_selector.split(","),title_selectors=self.settings.title_selector.split(","),i=0,len=region_selectors.length;len>i;i++)for(var region_selector=region_selectors[i],j=0,len1=title_selectors.length;len1>j;j++){var title_selector=section_selector+">"+region_selector+">"+title_selectors[j];click_title_selectors.push(title_selector+" a"),click_title_selectors.push(title_selector)}$(self.scope).on("click.fndtn.section",click_title_selectors.join(","),function(e){var title=$(this).closest(self.settings.title_selector);self.close_navs(title),title.siblings(self.settings.content_selector).length>0&&self.toggle_active.call(title[0],e)}),$(window).on("resize.fndtn.section",self.throttle(function(){self.resize()},30)).on("hashchange.fndtn.section",self.set_active_from_hash),$(document).on("click.fndtn.section",function(e){e.isPropagationStopped&&e.isPropagationStopped()||e.target!==document&&self.close_navs($(e.target).closest(self.settings.title_selector))}),$(window).triggerHandler("resize.fndtn.section"),$(window).triggerHandler("hashchange.fndtn.section")},close_navs:function(except_nav_with_title){var self=Foundation.libs.section,navsToClose=$(self.settings.nav_selector).filter(function(){return!$.extend({},self.settings,self.data_options($(this))).one_up});if(except_nav_with_title.length>0){var section=except_nav_with_title.parent().parent();(self.is_horizontal_nav(section)||self.is_vertical_nav(section))&&(navsToClose=navsToClose.filter(function(){return this!==section[0]}))}navsToClose.children(self.settings.region_selector).removeClass(self.settings.active_class)},toggle_active:function(e){var $this=$(this),self=Foundation.libs.section,region=$this.parent(),content=$this.siblings(self.settings.content_selector),section=region.parent(),settings=$.extend({},self.settings,self.data_options(section)),prev_active_region=section.children(self.settings.region_selector).filter("."+self.settings.active_class);!settings.deep_linking&&content.length>0&&e.preventDefault(),e.stopPropagation(),region.hasClass(self.settings.active_class)?(region.hasClass(self.settings.active_class)&&self.is_accordion(section)||!settings.one_up&&(self.small(section)||self.is_vertical_nav(section)||self.is_horizontal_nav(section)||self.is_accordion(section)))&&(region.removeClass(self.settings.active_class),region.trigger("closed.fndtn.section")):((!self.is_accordion(section)||self.is_accordion(section)&&!self.settings.multi_expand)&&(prev_active_region.removeClass(self.settings.active_class),prev_active_region.trigger("closed.fndtn.section")),region.addClass(self.settings.active_class),self.resize(region.find(self.settings.section_selector).not("["+self.settings.resized_data_attr+"]"),!0),region.trigger("opened.fndtn.section")),settings.callback(section)},check_resize_timer:null,resize:function(sections,ensure_has_active_region){var self=Foundation.libs.section,section_container=$(self.settings.section_selector),is_small_window=self.small(section_container),should_be_resized=function(section,now_is_hidden){return!(self.is_accordion(section)||section.is("["+self.settings.resized_data_attr+"]")||is_small_window&&!self.is_horizontal_tabs(section)||now_is_hidden!==("none"===section.css("display")||!section.parent().is(":visible")))};sections=sections||$(self.settings.section_selector),clearTimeout(self.check_resize_timer),is_small_window||sections.removeAttr(self.settings.small_style_data_attr),sections.filter(function(){return should_be_resized($(this),!1)}).each(function(){var section=$(this),regions=section.children(self.settings.region_selector),titles=regions.children(self.settings.title_selector),content=regions.children(self.settings.content_selector),titles_max_height=0;if(ensure_has_active_region&&0==section.children(self.settings.region_selector).filter("."+self.settings.active_class).length){var settings=$.extend({},self.settings,self.data_options(section));settings.deep_linking||!settings.one_up&&(self.is_horizontal_nav(section)||self.is_vertical_nav(section)||self.is_accordion(section))||regions.filter(":visible").first().addClass(self.settings.active_class)}if(self.is_horizontal_tabs(section)||self.is_auto(section)){var titles_sum_width=0;titles.each(function(){var title=$(this);if(title.is(":visible")){title.css(self.rtl?"right":"left",titles_sum_width);var title_h_border_width=parseInt(title.css("border-"+(self.rtl?"left":"right")+"-width"),10);"Nan"===title_h_border_width.toString()&&(title_h_border_width=0),titles_sum_width+=self.outerWidth(title)-title_h_border_width,titles_max_height=Math.max(titles_max_height,self.outerHeight(title))}}),titles.css("height",titles_max_height),regions.each(function(){var region=$(this),region_content=region.children(self.settings.content_selector),content_top_border_width=parseInt(region_content.css("border-top-width"),10);"Nan"===content_top_border_width.toString()&&(content_top_border_width=0),region.css("padding-top",titles_max_height-content_top_border_width)}),section.css("min-height",titles_max_height)}else if(self.is_horizontal_nav(section)){var first=!0;titles.each(function(){titles_max_height=Math.max(titles_max_height,self.outerHeight($(this)))}),regions.each(function(){var region=$(this);region.css("margin-left","-"+(first?section:region.children(self.settings.title_selector)).css("border-left-width")),first=!1}),regions.css("margin-top","-"+section.css("border-top-width")),titles.css("height",titles_max_height),content.css("top",titles_max_height),section.css("min-height",titles_max_height)}else if(self.is_vertical_tabs(section)){var titles_sum_height=0;titles.each(function(){var title=$(this);if(title.is(":visible")){title.css("top",titles_sum_height);var title_top_border_width=parseInt(title.css("border-top-width"),10);"Nan"===title_top_border_width.toString()&&(title_top_border_width=0),titles_sum_height+=self.outerHeight(title)-title_top_border_width}}),content.css("min-height",titles_sum_height+1)}else if(self.is_vertical_nav(section)){var titles_max_width=0,first1=!0;titles.each(function(){titles_max_width=Math.max(titles_max_width,self.outerWidth($(this)))}),regions.each(function(){var region=$(this);region.css("margin-top","-"+(first1?section:region.children(self.settings.title_selector)).css("border-top-width")),first1=!1}),titles.css("width",titles_max_width),content.css(self.rtl?"right":"left",titles_max_width),section.css("width",titles_max_width)}section.attr(self.settings.resized_data_attr,!0)}),$(self.settings.section_selector).filter(function(){return should_be_resized($(this),!0)}).length>0&&(self.check_resize_timer=setTimeout(function(){self.resize(sections.filter(function(){return should_be_resized($(this),!1)}),!0)},700)),is_small_window&&sections.attr(self.settings.small_style_data_attr,!0)},is_vertical_nav:function(el){return/vertical-nav/i.test(el.data("section"))},is_horizontal_nav:function(el){return/horizontal-nav/i.test(el.data("section"))},is_accordion:function(el){return/accordion/i.test(el.data("section"))},is_horizontal_tabs:function(el){return/^tabs$/i.test(el.data("section"))},is_vertical_tabs:function(el){return/vertical-tabs/i.test(el.data("section"))},is_auto:function(el){var data_section=el.data("section");return""===data_section||/auto/i.test(data_section)},set_active_from_hash:function(){var selectedSection,self=Foundation.libs.section,hash=window.location.hash.substring(1),sections=$(self.settings.section_selector);sections.each(function(){var section=$(this),regions=section.children(self.settings.region_selector);return regions.each(function(){var region=$(this),data_slug=region.children(self.settings.content_selector).data("slug");return new RegExp(data_slug,"i").test(hash)?(selectedSection=section,!1):void 0}),null!=selectedSection?!1:void 0}),null!=selectedSection&&sections.each(function(){if(selectedSection==$(this)){var section=$(this),settings=$.extend({},self.settings,self.data_options(section)),regions=section.children(self.settings.region_selector),set_active_from_hash=settings.deep_linking&&hash.length>0,selected=!1;regions.each(function(){var region=$(this);if(selected)region.removeClass(self.settings.active_class);else if(set_active_from_hash){var data_slug=region.children(self.settings.content_selector).data("slug");data_slug&&new RegExp(data_slug,"i").test(hash)?(region.hasClass(self.settings.active_class)||region.addClass(self.settings.active_class),selected=!0):region.removeClass(self.settings.active_class)}else region.hasClass(self.settings.active_class)&&(selected=!0)}),selected||!settings.one_up&&(self.is_horizontal_nav(section)||self.is_vertical_nav(section)||self.is_accordion(section))||regions.filter(":visible").first().addClass(self.settings.active_class)}})},reflow:function(){var self=Foundation.libs.section;$(self.settings.section_selector).removeAttr(self.settings.resized_data_attr),self.throttle(function(){self.resize()},30)()},small:function(el){var settings=$.extend({},this.settings,this.data_options(el));return this.is_horizontal_tabs(el)?!1:el&&this.is_accordion(el)?!0:$("html").hasClass("lt-ie9")?!0:$("html").hasClass("ie8compat")?!0:$(this.scope).width()<settings.small_breakpoint},off:function(){$(this.scope).off(".fndtn.section"),$(window).off(".fndtn.section"),$(document).off(".fndtn.section")}},$.fn.reflow_section=function(ensure_has_active_region){var section=this,self=Foundation.libs.section;return section.removeAttr(self.settings.resized_data_attr),self.throttle(function(){self.resize(section,ensure_has_active_region)},30)(),this}}(Foundation.zj,window,document);