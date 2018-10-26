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
  {{ __('footer.powered', '<a class="theme-link" href="https://hexo.io">Hexo</a>') }}
</div>

<div class="theme-info">
  {{ __('footer.theme') }} -
  <a class="theme-link" href="https://github.com/iissnan/hexo-theme-next">
    NexT.{{ theme.scheme }}
  </a>
  &nbsp;&nbsp;&nbsp;&nbsp;|
</div>

<div class="theme-info" style="margin-left:8px;">
  {{ __('<p>Hosted by <a href="https://pages.coding.me" style="font-weight: bold">Coding Pages</a></p>') }}
</div>

<div class="theme-info online-waust" style="margin-left:8px;">
<style>
	.online-waust div{margin-bottom: -3px !important;}
</style>
|&nbsp;&nbsp;&nbsp;&nbsp;<script id="_wau3i1">var _wau = _wau || []; _wau.push(["small", "2py5aq1g1u", "3i1"]);</script><script async src="//waust.at/s.js"></script>
</div>

{% endif %}
