<div class="copyright" >
  {% set current = date(Date.now(), "YYYY") %}
  &copy; {% if theme.since and theme.since != current %} {{ theme.since }} - {% endif %}
  <span itemprop="copyrightYear">{{ current }}</span>
  <span class="with-love">
    <i class="fa fa-{{ theme.authoricon }}"></i>
  </span>
  <span class="author" itemprop="copyrightHolder">{{ config.author }}</span>&nbsp;&nbsp;&nbsp;&nbsp;

  {% if theme.copyright %}
  <div class="powered-by">
    {{ __('footer.powered', '<a class="theme-link" target="_blank" href="https://hexo.io">Hexo</a>') }}
  </div>

  <div class="powered-by">
    {{ __('footer.theme') }} -
    <a class="theme-link" target="_blank" href="https://github.com/iissnan/hexo-theme-next">
      NexT.{{ theme.scheme }}
    </a>
  </div>
  {% endif %}

  <div class="theme-info cnzz" style="margin: 0 0 -5px 10px;">
    <script type="text/javascript">var cnzz_protocol = (("https:" == document.location.protocol) ? "https://" : "http://");document.write(unescape("%3Cspan id='cnzz_stat_icon_1276691827'%3E%3C/span%3E%3Cscript src='" + cnzz_protocol + "s23.cnzz.com/z_stat.php%3Fid%3D1276691827%26show%3Dpic1' type='text/javascript'%3E%3C/script%3E"));</script>
  </div>
</div>

<div class="ad">
  <span style="font-weight: bold">AD&nbsp;&nbsp;&nbsp;&nbsp;</span>
  <div class="theme-info">
    <a target="_blank" href="https://promotion.aliyun.com/ntms/yunparter/invite.html?userCode=oby5nolb">阿里云大礼包</a>
  </div>
</div>

<div class="aezocn">
  <span style="font-weight: bold">@AEZO.CN&nbsp;&nbsp;&nbsp;&nbsp;</span>
  <div class="theme-info">
    <a target="_blank" href="http://shop.aezo.cn/">杂货铺</a>
  </div>
</div>

<!-- 实时沟通，或可使用 http://www.daovoice.io/ -->
<!-- Start of Async Drift Code -->
<!--
<script>
"use strict";

!function() {
  var t = window.driftt = window.drift = window.driftt || [];
  if (!t.init) {
    if (t.invoked) return void (window.console && console.error && console.error("Drift snippet included twice."));
    t.invoked = !0, t.methods = [ "identify", "config", "track", "reset", "debug", "show", "ping", "page", "hide", "off", "on" ],
    t.factory = function(e) {
      return function() {
        var n = Array.prototype.slice.call(arguments);
        return n.unshift(e), t.push(n), t;
      };
    }, t.methods.forEach(function(e) {
      t[e] = t.factory(e);
    }), t.load = function(t) {
      var e = 3e5, n = Math.ceil(new Date() / e) * e, o = document.createElement("script");
      o.type = "text/javascript", o.async = !0, o.crossorigin = "anonymous", o.src = "https://js.driftt.com/include/" + n + "/" + t + ".js";
      var i = document.getElementsByTagName("script")[0];
      i.parentNode.insertBefore(o, i);
    };
  }
}();
drift.SNIPPET_VERSION = '0.3.1';
drift.load('e4wbzuxev4zt');
</script>
-->
<!-- End of Async Drift Code -->




