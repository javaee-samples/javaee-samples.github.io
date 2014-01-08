!function($,window,document,undefined){"use strict";var noop=function(){},Orbit=function(el,settings){if(el.hasClass(settings.slides_container_class))return this;var container,number_container,bullets_container,timer_container,animate,timer,self=this,slides_container=el,idx=0,locked=!1;slides_container.children().first().addClass(settings.active_slide_class),self.update_slide_number=function(index){settings.slide_number&&(number_container.find("span:first").text(parseInt(index)+1),number_container.find("span:last").text(slides_container.children().length)),settings.bullets&&(bullets_container.children().removeClass(settings.bullets_active_class),$(bullets_container.children().get(index)).addClass(settings.bullets_active_class))},self.update_active_link=function(index){var link=$('a[data-orbit-link="'+slides_container.children().eq(index).attr("data-orbit-slide")+'"]');link.parents("ul").find("[data-orbit-link]").removeClass(settings.bullets_active_class),link.addClass(settings.bullets_active_class)},self.build_markup=function(){slides_container.wrap('<div class="'+settings.container_class+'"></div>'),container=slides_container.parent(),slides_container.addClass(settings.slides_container_class),settings.navigation_arrows&&(container.append($('<a href="#"><span></span></a>').addClass(settings.prev_class)),container.append($('<a href="#"><span></span></a>').addClass(settings.next_class))),settings.timer&&(timer_container=$("<div>").addClass(settings.timer_container_class),timer_container.append("<span>"),timer_container.append($("<div>").addClass(settings.timer_progress_class)),timer_container.addClass(settings.timer_paused_class),container.append(timer_container)),settings.slide_number&&(number_container=$("<div>").addClass(settings.slide_number_class),number_container.append("<span></span> "+settings.slide_number_text+" <span></span>"),container.append(number_container)),settings.bullets&&(bullets_container=$("<ol>").addClass(settings.bullets_container_class),container.append(bullets_container),slides_container.children().each(function(idx){var bullet=$("<li>").attr("data-orbit-slide",idx);bullets_container.append(bullet)})),settings.stack_on_small&&container.addClass(settings.stack_on_small_class),self.update_slide_number(0),self.update_active_link(0)},self._goto=function(next_idx,start_timer){if(next_idx===idx)return!1;"object"==typeof timer&&timer.restart();var slides=slides_container.children(),dir="next";locked=!0,idx>next_idx&&(dir="prev"),next_idx>=slides.length?next_idx=0:0>next_idx&&(next_idx=slides.length-1);var current=$(slides.get(idx)),next=$(slides.get(next_idx));current.css("zIndex",2),current.removeClass(settings.active_slide_class),next.css("zIndex",4).addClass(settings.active_slide_class),slides_container.trigger("orbit:before-slide-change"),settings.before_slide_change(),self.update_active_link(next_idx);var callback=function(){var unlock=function(){idx=next_idx,locked=!1,start_timer===!0&&(timer=self.create_timer(),timer.start()),self.update_slide_number(idx),slides_container.trigger("orbit:after-slide-change",[{slide_number:idx,total_slides:slides.length}]),settings.after_slide_change(idx,slides.length)};slides_container.height()!=next.height()&&settings.variable_height?slides_container.animate({height:next.height()},250,"linear",unlock):unlock()};if(1===slides.length)return callback(),!1;var start_animation=function(){"next"===dir&&animate.next(current,next,callback),"prev"===dir&&animate.prev(current,next,callback)};next.height()>slides_container.height()&&settings.variable_height?slides_container.animate({height:next.height()},250,"linear",start_animation):start_animation()},self.next=function(e){e.stopImmediatePropagation(),e.preventDefault(),self._goto(idx+1)},self.prev=function(e){e.stopImmediatePropagation(),e.preventDefault(),self._goto(idx-1)},self.link_custom=function(e){e.preventDefault();var link=$(this).attr("data-orbit-link");if("string"==typeof link&&""!=(link=$.trim(link))){var slide=container.find("[data-orbit-slide="+link+"]");-1!=slide.index()&&self._goto(slide.index())}},self.link_bullet=function(){var index=$(this).attr("data-orbit-slide");"string"==typeof index&&""!=(index=$.trim(index))&&self._goto(parseInt(index))},self.timer_callback=function(){self._goto(idx+1,!0)},self.compute_dimensions=function(){var current=$(slides_container.children().get(idx)),h=current.height();settings.variable_height||slides_container.children().each(function(){$(this).height()>h&&(h=$(this).height())}),slides_container.height(h)},self.create_timer=function(){var t=new Timer(container.find("."+settings.timer_container_class),settings,self.timer_callback);return t},self.stop_timer=function(){"object"==typeof timer&&timer.stop()},self.toggle_timer=function(){var t=container.find("."+settings.timer_container_class);t.hasClass(settings.timer_paused_class)?("undefined"==typeof timer&&(timer=self.create_timer()),timer.start()):"object"==typeof timer&&timer.stop()},self.init=function(){self.build_markup(),settings.timer&&(timer=self.create_timer(),timer.start()),animate=new FadeAnimation(settings,slides_container),"slide"===settings.animation&&(animate=new SlideAnimation(settings,slides_container)),container.on("click","."+settings.next_class,self.next),container.on("click","."+settings.prev_class,self.prev),container.on("click","[data-orbit-slide]",self.link_bullet),container.on("click",self.toggle_timer),settings.swipe&&container.on("touchstart.fndtn.orbit",function(e){e.touches||(e=e.originalEvent);var data={start_page_x:e.touches[0].pageX,start_page_y:e.touches[0].pageY,start_time:(new Date).getTime(),delta_x:0,is_scrolling:undefined};container.data("swipe-transition",data),e.stopPropagation()}).on("touchmove.fndtn.orbit",function(e){if(e.touches||(e=e.originalEvent),!(e.touches.length>1||e.scale&&1!==e.scale)){var data=container.data("swipe-transition");if("undefined"==typeof data&&(data={}),data.delta_x=e.touches[0].pageX-data.start_page_x,"undefined"==typeof data.is_scrolling&&(data.is_scrolling=!!(data.is_scrolling||Math.abs(data.delta_x)<Math.abs(e.touches[0].pageY-data.start_page_y))),!data.is_scrolling&&!data.active){e.preventDefault();var direction=data.delta_x<0?idx+1:idx-1;data.active=!0,self._goto(direction)}}}).on("touchend.fndtn.orbit",function(e){container.data("swipe-transition",{}),e.stopPropagation()}),container.on("mouseenter.fndtn.orbit",function(){settings.timer&&settings.pause_on_hover&&self.stop_timer()}).on("mouseleave.fndtn.orbit",function(){settings.timer&&settings.resume_on_mouseout&&timer.start()}),$(document).on("click","[data-orbit-link]",self.link_custom),$(window).on("resize",self.compute_dimensions),$(window).on("load",self.compute_dimensions),$(window).on("load",function(){container.prev(".preloader").css("display","none")}),slides_container.trigger("orbit:ready")},self.init()},Timer=function(el,settings,callback){var start,timeout,self=this,duration=settings.timer_speed,progress=el.find("."+settings.timer_progress_class),left=-1;this.update_progress=function(w){var new_progress=progress.clone();new_progress.attr("style",""),new_progress.css("width",w+"%"),progress.replaceWith(new_progress),progress=new_progress},this.restart=function(){clearTimeout(timeout),el.addClass(settings.timer_paused_class),left=-1,self.update_progress(0)},this.start=function(){return el.hasClass(settings.timer_paused_class)?(left=-1===left?duration:left,el.removeClass(settings.timer_paused_class),start=(new Date).getTime(),progress.animate({width:"100%"},left,"linear"),timeout=setTimeout(function(){self.restart(),callback()},left),el.trigger("orbit:timer-started"),void 0):!0},this.stop=function(){if(el.hasClass(settings.timer_paused_class))return!0;clearTimeout(timeout),el.addClass(settings.timer_paused_class);var end=(new Date).getTime();left-=end-start;var w=100-left/duration*100;self.update_progress(w),el.trigger("orbit:timer-stopped")}},SlideAnimation=function(settings){var duration=settings.animation_speed,is_rtl=1===$("html[dir=rtl]").length,margin=is_rtl?"marginRight":"marginLeft",animMargin={};animMargin[margin]="0%",this.next=function(current,next,callback){next.animate(animMargin,duration,"linear",function(){current.css(margin,"100%"),callback()})},this.prev=function(current,prev,callback){prev.css(margin,"-100%"),prev.animate(animMargin,duration,"linear",function(){current.css(margin,"100%"),callback()})}},FadeAnimation=function(settings){{var duration=settings.animation_speed;1===$("html[dir=rtl]").length}this.next=function(current,next,callback){next.css({margin:"0%",opacity:"0.01"}),next.animate({opacity:"1"},duration,"linear",function(){current.css("margin","100%"),callback()})},this.prev=function(current,prev,callback){prev.css({margin:"0%",opacity:"0.01"}),prev.animate({opacity:"1"},duration,"linear",function(){current.css("margin","100%"),callback()})}};Foundation.libs=Foundation.libs||{},Foundation.libs.orbit={name:"orbit",version:"4.3.2",settings:{animation:"slide",timer_speed:1e4,pause_on_hover:!0,resume_on_mouseout:!1,animation_speed:500,stack_on_small:!1,navigation_arrows:!0,slide_number:!0,slide_number_text:"of",container_class:"orbit-container",stack_on_small_class:"orbit-stack-on-small",next_class:"orbit-next",prev_class:"orbit-prev",timer_container_class:"orbit-timer",timer_paused_class:"paused",timer_progress_class:"orbit-progress",slides_container_class:"orbit-slides-container",bullets_container_class:"orbit-bullets",bullets_active_class:"active",slide_number_class:"orbit-slide-number",caption_class:"orbit-caption",active_slide_class:"active",orbit_transition_class:"orbit-transitioning",bullets:!0,timer:!0,variable_height:!1,swipe:!0,before_slide_change:noop,after_slide_change:noop},init:function(scope,method){var self=this;if(Foundation.inherit(self,"data_options"),"object"==typeof method&&$.extend(!0,self.settings,method),$(scope).is("[data-orbit]")){var $el=$(scope),opts=self.data_options($el);new Orbit($el,$.extend({},self.settings,opts))}$("[data-orbit]",scope).each(function(idx,el){var $el=$(el),opts=self.data_options($el);new Orbit($el,$.extend({},self.settings,opts))})}}}(Foundation.zj,this,this.document);