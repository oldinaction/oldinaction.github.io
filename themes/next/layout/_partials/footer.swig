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

  <div class="theme-info">
    Hosted by <a target="_blank" href="https://pages.coding.me" style="font-weight: bold">Coding Pages</a>
  </div>
  {% endif %}
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





