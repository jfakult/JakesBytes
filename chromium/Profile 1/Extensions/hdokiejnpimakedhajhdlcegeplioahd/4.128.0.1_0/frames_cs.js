var MAX_DIALOG_WIDTH=400;function LP_getLPIframe(e,t){if(!(e=e||LP_derive_doc()))return null;var r=null,i=null,o;if(t&&(i=e.getElementById(t))&&"IFRAME"==i.tagName.toUpperCase()&&i.name==i.id)return r=i;var n,n=(n=g_popupfill_parent)||g_popupfill_parent_last;if((t=LP_getLPIframeID(e,n))&&(i=e.getElementById(t))&&"IFRAME"==i.tagName.toUpperCase()&&i.name==i.id)return r=i;for(var l=e.getElementsByTagName("IFRAME"),o=0;o<l.length;o++)if((i=l[o])&&void 0!==i.id&&null!=i.id){var a=LPMAGICIFRAME;if(0==i.id.indexOf(a)){r=i;break}}return r}function relocate_LPIframe(e,t){var r,i,o,n,l;return!!(e=e||LP_derive_doc())&&(r=!0,(o=LP_getLPIframe(e,LP_getLPIframeID(e)))?(n=LP_getComputedStyle(e,o),g_iframe_docked&&(l=LP_getAbsolutePos(e,g_popupfill_parent))):r=!1,r)}function resize_LPIframe(e,t){if(!(e=e||LP_derive_doc())||!t)return!1;var r="px",i={};if(g_drag_type=LP_DRAG_NODRAG,void 0===t.height||void 0===t.width){if(void 0===t.delx||void 0===t.dely)return!1;g_drag_type=LP_DRAG_RESIZE}var o=!1,n,l=LP_getLPIframe(e,LP_getLPIframeID(e)),l,i;return l&&(g_draggable&&g_drag_type===LP_DRAG_RESIZE?(i={width:(l=LP_getAbsolutePos(e,l)).width+t.delx,height:l.height+t.dely},g_minwidth_override=i.width,g_minheight_override=i.height):i={width:t.width,height:t.height},o=place_LPIframe(e,i)),o}function place_LPIframe(t,e){if(!(t=t||LP_derive_doc())||!e)return!1;var r=sprintf,i=("undefined"!=typeof g_isie&&g_isie&&(init_LPfn(),"undefined"!=typeof LPfn)&&(r=LPfn.sprintf),!0),o="px",n,l=LP_getLPIframe(t,LP_getLPIframeID(t));if(l){var a=LP_getAbsolutePos(t,l);if(null===a||parseInt(e.width)<0||parseInt(e.height)<0)verbose_log("invalid iframe pos"),i=!1;else{var _=parseInt(a.top)+o,s=parseInt(a.left)+o,f=parseInt(a.height)+o,a=parseInt(a.width)+o,p="",r=(void 0===e.height||""===(p=parseInt(e.height))||isNaN(p)||(f=p+o),void 0===e.width||""===(p=parseInt(e.width))||isNaN(p)||(a=p+o),void 0===e.left||""===(p=parseInt(e.left))||isNaN(p)||(s=p+o),r("width: %s !important; height: %s !important; top: %s !important; left:%s !important;",a,f,_=void 0===e.top||""===(p=parseInt(e.top))||isNaN(p)?_:p+o,s));if(""==g_frame_css_str)try{var d=document.body.getAttribute("data-lp-gcss");d&&(g_frame_css_str=LPJSON.parse(d),document.body.removeAttribute("data-lp-gcss"))}catch(e){write_error_to_history(t,"resize_LPIframe",e)}var e=g_frame_css_str+r;e.match(/position: *absolute/)||(e+=" position: absolute;"),normalize_css(l.style.cssText)!=normalize_css(e)&&(l.style.cssText=e,l.setAttribute("width",parseInt(a)),l.setAttribute("height",parseInt(f)))}}else i=!1;return i}function LP_getLPIframeID(e,t){var r,e,r;return(e=(e=!e&&t?t.ownerDocument:e)||LP_derive_doc())?(r=null,t?(e=LP_pickFieldName(e,t),LPMAGICIFRAME+e):void 0):null}function LP_computeLPIframeID(e){var t;return"undefined"==typeof SHA256?LPMAGICIFRAME+e:(t=sprintf,"undefined"!=typeof g_isie&&g_isie&&(init_LPfn(),"undefined"!=typeof LPfn)&&(t=LPfn.sprintf),SHA256(t("%d-%s",Date.now(),e)))}function rot13(e){if(!e)return"$str =~ tr/a-zA-Z/n-za-mN-ZA-M/";for(var t="",r=0;r<e.length;r++){var i=e.charCodeAt(r);65<=i&&i<=77||97<=i&&i<=109?i+=13:(78<=i&&i<=90||110<=i&&i<=122)&&(i-=13),t+=String.fromCharCode(i)}return t}function LP_inIframe(e){if(e=e||window,null!=g_inframe)return g_inframe;try{var t=get_win_self(e);return t!==e.top&&(!is_edge()||t.location.href!=e.top.location.href||e.frameElement)}catch(e){return!0}}function is_your_popup_showing(e){if(null!=e){var t=e.defaultView,r=(t||"undefined"==typeof window||(t=window),!1),i;try{null==e.location&&(verbose_log("is_your_popup_showing given a firefox zombie document?"),i=(void 0!==LP.lpGetCurrentWindow().getBrowser?LP.lpGetCurrentWindow():LP).getBrowser().contentDocument,closepopupfills(i),r=!0)}catch(e){r=!0}if(!r){if(g_isfirefox&&verbose_log("entered is_your_popup_showing for doc="+e.location.href),g_create_iframe_in_top&&!g_isie&&!g_isfirefox&&LP_inIframe(t))return toplevel_iframe_state_get();if(0<e.location.href.indexOf("popupfilltab.xul"))return!0;for(var o=e.getElementsByTagName("iframe"),n=0;n<o.length;n++)if("function"!=typeof o.hasOwnProperty||o.hasOwnProperty(n)){var l=LPMAGICIFRAME;if(0==o[n].id.indexOf(l))return!0}}}return!1}function enableScrollOnIframe(e,t){if(null==(t=null==t?document||LP.getBrowser().contentDocument:t))return null;verbose_log("enabling Scroll on Iframe for "+t.location.href);var r=t.getElementsByTagName("IFRAME"),i,o=null;if(null!=r&&0<r.length)for(i=0;i<r.length;i++){var o=r[i],n=e.replace(/^(https:|http:)/,"");verbose_log("checking iframe src="+lp_ofa(o.src)+" passed href="+lp_ofa(e)),(o.src==e||0<o.src.indexOf(e)||0<o.src.indexOf(n))&&("undefined"!=typeof g_isie&&g_isie?(o.setAttribute("scrolling","auto"),o.style.overflow="visible",o.style.maxHeight="none"):(o.setAttribute("scrolling","auto"),o.style.overflow="auto"),verbose_log("enabling scroll on iframe to "+lp_ofa(e)))}}function enableScrollWithinIframe(e,t){if(!(e=e||LP_derive_doc()))return!1;var t;null==t&&(t=window),is_your_popup_showing(e)&&get_win_self(t)!=t.top&&(verbose_log("enabling scroll on body of iframe"),!g_isfirefox&&g_isie?(t=0,7<(t="undefined"!=typeof init_LPfn&&init_LPfn()&&LPfn?LPfn.getDocumentMode(document):t)?(e.body.style.overflow="visible",e.body.setAttribute("scroll","auto")):e.body.setAttribute("overflow","auto")):e.body.style.overflow="auto")}function LP_getIframeBySrc(e,t){for(var r,i=(e=null==e?document:e).getElementsByTagName("IFRAME"),o,o=0;o<i.length;o++)if(i[o].src==t)return i[o];return null}function toplevelpopupsetstate_handler(e){g_create_iframe_in_top&&toplevel_iframe_state_set(!!e)}function toplevel_iframe_state_get(){return g_toplevel_iframe_exists}function toplevel_iframe_state_set(e){g_toplevel_iframe_exists=e}function LP_do_toplevel_iframe_hack(e){return!!e&&!g_isie&&!g_isfirefox}function relocate_popupfill_iframes(t,e){try{var r=t,i;if(g_isfirefox&&(r=(void 0!==LP.lpGetCurrentWindow().getBrowser?LP.lpGetCurrentWindow():LP).getBrowser().contentDocument),!t||!r)return null;if(g_isfirefox&&null==t.location)return verbose_log("relocate_popupfill_iframes given zombie document?"),i=(void 0!==LP.lpGetCurrentWindow().getBrowser?LP.lpGetCurrentWindow():LP).getBrowser().contentDocument,void closepopupfills(i);for(var o=!1,n=!1,l,l,a,_=(l=(l=l||t.defaultView)||t.parentWindow,"undefined"!=typeof g_iscasper&&g_iscasper&&(l=t.defaultView),null),s=r.getElementsByTagName("iframe"),a=0;a<s.length;a++){var f=s[a],p,d,g,o,u,m,c,h,v,P,I,L,y,v,P,I,L,_=null;void 0!==f.id&&null!=f.id&&(p=LPMAGICIFRAME,0==f.id.indexOf(p))&&(g=d=f.id.substr(p.length),o=!0,u=LP_getElementByIdOrName(t,d),g_isfirefox||null!=u&&lpIsVisible(u,!e)?(h=c=0,v=null,g_isfirefox?null!=(v=ff_get_iframe_pos(t,l,u,g,r))&&(n=!0):(v=calculate_iframe_pos(t,u,0<g_minwidth_override?g_minwidth_override:0),g_draggable&&!g_iframe_docked&&(L=I=!(P=!0),y=LP_getAbsolutePos(t,f,L),v.posx=y.left,v.posy=y.top)),null!=v&&place_iframe_absolute(t,l,f,v,r)):!g_create_iframe_in_top||g_isie||g_isfirefox||LP_inIframe(l)||!toplevel_iframe_state_get()?g_isfirefox||g_double_password_hack||g_double_secret_password_hack||LP_element_is_MaskedField(u)||LP_element_is_UnmaskedField(u)||closepopupfills(t):(L=I=!(P=!0),(v=LP_getAbsolutePos(t,f,L)).posx=v.left,v.posy=v.top,place_iframe_absolute(t,l,f,v,r)))}g_isfirefox&&!n&&o&&(verbose_log("found orphan iframe, remove it"),closepopupfills(t))}catch(e){lplog("relocate_popupfill_iframe failed, "+e.message),do_bgiconinput||end_weasel(t),g_isfirefox&&closepopupfills(t)}}function place_iframe_absolute(e,t,r,i,o){if(!(r&&e&&t&&i))return!1;var n=null,l;if("undefined"!=typeof Math){var a=null;g_draggable&&!g_iframe_docked&&(a=LP_getComputedStyle(t,r));try{var _=i.posx,s=i.posy,f=parseInt(_)+"px",p=parseInt(s)+"px",d=0,g=(0<parseInt(g_minwidth_override)?(d=Math.max(parseInt(g_popupfill_iframe_width_save),parseInt(g_minwidth_override))+"px",(l=LP_getWindowWidth(t,!0))&&parseInt(d)+parseInt(f)>l&&(f=l-parseInt(d)-20+"px")):d=0<parseInt(g_popupfill_iframe_width_save)?parseInt(g_popupfill_iframe_width_save)+"px":(n=null==n?LP_getComputedStyle(t,r):n).width,parseInt(f)<0&&(f="0px"),parseInt(p)<0&&(p="0px"),0),u,m,c,c,h,v,P,I,L,y,b;0<parseInt(g_minheight_override)?g=Math.max(parseInt(g_popupfill_iframe_height_save),parseInt(g_minheight_override))+"px":""!=g_popupfill_iframe_height_save&&0<parseInt(g_popupfill_iframe_height_save)?g=parseInt(g_popupfill_iframe_height_save)+"px":(n=null==n?LP_getComputedStyle(t,r):n)&&(g=n.height),d=Math.min(parseInt(d),MAX_DIALOG_WIDTH)+"px",g_iframe_scroll_hack&&!g_frame_scrollable_set&&(u=parseInt(g),m=parseInt(d),c=t&&void 0!==t.getComputedStyle?g_isfirefox?LP_getComputedStyle(t,e.documentElement):LP_getComputedStyle(t,e.body):void 0!==e.documentElement?LP_getComputedStyle(t,e.documentElement):LP_getComputedStyle(t,e.body),h=parseInt(c.height),v=parseInt(c.width),P=t.innerHeight,I=t.innerWidth,void 0===P&&(P=LP_getWindowHeight(t,e)),void 0===I&&(I=LP_getWindowWidth(t)),null!=u&&0<u&&null!=P&&0<P||null!=m&&0<m&&null!=I&&0<I)&&(parseInt(s)+u>P||parseInt(_)+m>I)&&LP_inIframe(t)&&(g_isfirefox?(enableScrollWithinIframe(e,t),(b=(y=LP.getBrowser())?y.contentDocument:null)&&b!=e&&enableScrollOnIframe(e.location.href,o)):g_isie||(verbose_log("ensuring this frame/iframe has scrolling enabled"),sendBG({cmd:"iframescrollenable",href:e.location.href})),g_frame_scrollable_set=!0),g_draggable&&!g_iframe_docked&&a&&(i&&void 0!==i.posx&&void 0!==i.posy?(p=parseInt(i.posy)+"px",f=parseInt(i.posx)+"px",parseInt(i.posy)<0&&(p="0px"),parseInt(i.posx)<0&&(f="0px")):(p=a.top,f=a.left)),place_LPIframe(e,{width:d,height:g,top:p,left:f})||(verbose_log("invalid iframe pos"),debug_checkpoint("failed to place iframe"),closepopupfills(e))}catch(e){verbose&&alert("place_abs "+e.message)}return True}}function normalize_css(e){return e=(e=(e=(e=e.replace(/ /g,"")).replace(/1\.0/g,"1")).replace(/2147483647/g,"2147483648")).replace("border-top-style:none!important;border-right-style:none!important;border-bottom-style:none!important;border-left-style:none!important;","border-style:none!important;"),e=g_isie?(e=(e=e.replace("filter:alpha(opacity=100)!important;","")).replace("border-style:none!important;","")).split(";").sort().join(";"):e}function moveIframe_handler(e,t){var r,i,o,n,l,a,_,r;(e=e||LP_derive_doc())&&(r=(r=e.defaultView)||window,g_draggable)&&void 0!==t.delx&&void 0!==t.dely&&(i=!(g_iframe_docked=!1),n=!(o=!1),l=LP_getLPIframe(e))&&(a=LP_getAbsolutePos(e,l))&&place_iframe_absolute(e,r,l,{posx:a.left+t.delx,posy:a.top+t.dely})}function resizeIframe_handler(e,t){(e=e||LP_derive_doc())&&t&&resize_LPIframe(e,t)}