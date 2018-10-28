<div class="copyright" >
  {% set current = date(Date.now(), "YYYY") %}
  &copy; {% if theme.since and theme.since != current %} {{ theme.since }} - {% endif %}
  <span itemprop="copyrightYear">{{ current }}</span>
  <span class="with-love">
    <i class="fa fa-{{ theme.authoricon }}"></i>
  </span>
  <span class="author" itemprop="copyrightHolder">{{ config.author }}</span>
</div>

{% if theme.copyright %}
<div class="powered-by">
  {{ __('footer.powered', '<a class="theme-link" target="_blank" href="https://hexo.io">Hexo</a>') }}
</div>

<div class="theme-info">
  {{ __('footer.theme') }} -
  <a class="theme-link" target="_blank" href="https://github.com/iissnan/hexo-theme-next">
    NexT.{{ theme.scheme }}
  </a>
  &nbsp;&nbsp;&nbsp;&nbsp;|
</div>

<div class="theme-info" style="margin-left:8px;">
  {{ __('<p>Hosted by <a target="_blank" href="https://pages.coding.me" style="font-weight: bold">Coding Pages</a></p>') }}
</div>

<div class="theme-info online-waust" style="margin-left:8px;">
<style>
	.online-waust div{margin-bottom: -3px !important;}
</style>
|&nbsp;&nbsp;&nbsp;&nbsp;<script id="_wau3i1">var _wau = _wau || []; _wau.push(["small", "2py5aq1g1u", "3i1"]);</script><script async src="//waust.at/s.js"></script>
</div>

<div class="theme-info" style="margin-left:8px;">
|&nbsp;&nbsp;&nbsp;&nbsp;<a target="_blank" href="https://promotion.aliyun.com/ntms/yunparter/invite.html?userCode=oby5nolb" style="font-weight: bold">阿里云大礼包</a>
</div>

{% endif %}
