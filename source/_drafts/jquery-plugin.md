## 纯js插件

优点是依赖性小，不依赖于jQuery等函数库；缺点是比较繁琐；一般不涉及到Dom树的可使用纯js写插件（如：日期库插件moment.js）

## 基于jquery编写插件

jQuery插件开发方式主要有三种：

1. 通过$.extend()来扩展jQuery
2. 通过$.fn 向jQuery添加新的方法
3. 通过$.widget()应用jQuery UI的部件工厂方式创建

第一种方式太简单，仅仅是在jQuery命名空间或者理解成jQuery身上添加了一个静态方法而以，通常我们使用第二种方法来进行简单插件开发，说简单是相对于第三种方式。第三种方式是用来开发更高级jQuery部件的，这里不细说。

### $.extend()用法

- 给extend方法传递单个对象的情况下，这个对象会合并到jQuery身上，所以我们就可以在jQuery身上调用新合并对象里包含的方法了

  ```js
  $.extend({
      log: function(str) {
          console.log(str ? str : 'Good!');
      }
  })
  //调用
  $.log(); // Good!
  $.log('Hello!'); // Hello!
  ```

- 当给extend方法传递一个以上的参数时，它会将所有参数对象合并到第一个里。同时，如果对象中有同名属性时，合并的时候后面的会覆盖前面的（经常用于$.fn写法的参数处理上）

  ```js
  var defaults = {'name': 'smalle', 'age': 18};
  var options = {'name': 'aezo', 'sex': 'boy'};
  var settings = $.extend({}, defaults, options);
  console.log(settings); // Object {name: "aezo", age: 18, sex: "boy"}
  ```

### $.fn用法

- 基本格式：

  ```js
  // $.fn. 后面接为插件名
  $.fn.pluginName = function() {
      //your code goes here
  }
  ```

- this说明：**在插件名字定义的这个函数内部** ，this指代的是我们在调用该插件时，用jQuery选择器选中的元素，一般是一个 **jQuery类型** 的集合。

  ```js
  $.fn.myPlugin = function() {
      this.css('color', 'red');
  }
  // 如：$('a').myPlugin(); 则 this = $('a')
  ```

  > - 比如 $('a') 返回的是页面上所有 a 标签的集合，且这个集合已经是 jQuery 包装类型了，也就是说，在对其进行操作的时候可以直接调用jQuery的其他方法而不需要再用美元符号来包装一下。
  > - 那么通过调用 jQuery 的 .each() 方法就可以处理合集中的每个元素了，但此刻要注意的是，在 each 方法内部，this 指带的是普通的 DOM 元素了，如果需要调用 jQuery 的方法那就需要用$来重新包装一下。

- 参数处理：包括默认参数和传入参数，可以使用`$.extend()`进行处理

- 支持链式调用：jQuery的一个特性是支持链式调用，选择好DOM元素后可以不断地调用其他方法。要让插件不打破这种链式调用，只需return一下即可。

  ```js
  $.fn.myPlugin = function() {
      var defaults = {
          'color': 'red',
          'fontSize': '12px'
      };
      var settings = $.extend({}, defaults, options);

      return this.each(function(){
          $(this).css({
            'color': settings.color,
            'fontSize': settings.fontSize
          });
      });
  }
  ```

- 面向对象(方便维护、代码清晰)

  > 如果将需要的重要变量定义到对象的属性上，函数变成对象的方法，当我们需要的时候通过对象来获取，一来方便管理，二来不会影响外部命名空间，因为所有这些变量名还有方法名都是在对象内部。以后要加新功能新方法，只需向对象添加新变量及方法即可，然后在插件里实例化后即可调用新添加的东西。

- 命名空间

  不仅仅是jQuery插件的开发，我们在写任何JS代码时都应该注意的一点是不要污染全局命名空间。因为随着你代码的增多，如果有意无意在全局范围内定义一些变量的话，最后很难维护，也容易跟别人写的代码有冲突。

  比如你在代码中向全局window对象添加了一个变量status用于存放状态，同时页面中引用了另一个别人写的库，也向全局添加了这样一个同名变量，最后的结果肯定不是你想要的。所以不到万不得已，一般我们不会将变量定义成全局的。

  一个好的做法是始终用`自调用匿名函数`包裹你的代码，这样就可以完全放心，安全地将它用于任何地方了，绝对没有冲突。

  ```js
  ;(function($, window, document,undefined) {
      //定义Beautifier的构造函数
      var Beautifier = function(ele, opt) {
          this.$element = ele,
          this.defaults = {
              'color': 'red',
              'fontSize': '12px',
              'textDecoration': 'none'
          },
          this.options = $.extend({}, this.defaults, opt)
      }
      //定义Beautifier的方法
      Beautifier.prototype = {
          beautify: function() {
              return this.$element.css({
                  'color': this.options.color,
                  'fontSize': this.options.fontSize,
                  'textDecoration': this.options.textDecoration
              });
          }
      }
      //在插件中使用Beautifier对象
      $.fn.myPlugin = function(options) {
          //创建Beautifier的实体
          var beautifier = new Beautifier(this, options);
          //调用其方法
          return beautifier.beautify();
      }
  })(jQuery, window, document);
  ```

  - 开头的 `;` 防止别人的代码没有以分号结尾，导致我们的代码编译出错
  - 传入系统变量，那么window等系统变量在插件内部就有了一个局部的引用，对访问速度有些许提升
  - 关于参数`undefined`：为了得到没有被修改的undefined，我们并没有传递这个参数，但却在接收时接收了它，因为实际并没有传，所以undefined那个位置接收到的就是真实的undefined了

- jQuery选择器

  - 尽量使用Id选择器。jQuery的选择器使用的API都是基于getElementById或getElementsByTagName，因此可以知道 效率最高的是Id选择器，因为jQuery会直接调用getElementById去获取dom，而通过样式选择器获取jQuery对象时往往会使用 getElementsByTagName去获取然后筛选。

  - 样式选择器应该尽量明确指定tagName, 如果开发人员使用样式选择器来获取dom，且这些dom属于同一类型，例如获取所有className为jquery的div，那么我们应该使用的写法 是`$('div.jquery')`而不是$('.jquery')，这样写的好处非常明显，在获取dom时jQuery会获取div然后进行筛选，而不是 获取所有dom再筛选。

  - 避免迭代，很多同学在使用jQuery获取指定上下文中的dom时喜欢使用迭代方式，如$('.jquery .child')，获取className为jquery的dom下的所有className为child的节点，其实这样编写代码付出的代价是非常大 的，jQuery会不断的进行深层遍历来获取需要的元素，即使确实需要，我们也应该使用诸如`$(selector, context)`, `$('selector1>selector2')`, `$(selector1).children(selector2)`, `$(selctor1).find(selector2)`之类的方式。

### 插件开发注意事项

- 变量定义

  好的做法是把将要使用的变量名用一个var关键字一并定义在代码开头，变量名间用逗号隔开。原因有二：
  - 一是便于理解，同时代码显得整洁且有规律，也方便管理，变量定义与逻辑代码分开；
  - 二是因为JavaScript中所有变量及函数名会自动提升，也称之为JavaScript的Hoist特性，即使你将变量的定义穿插在逻辑代码中，在代码解析运行期间，这些变量的声明还是被提升到了当前作用域最顶端的，所以我们将变量定义在一个作用域的开头是更符合逻辑的一种做法。当然，再次说明这只是一种约定，不是必需的。

- 变量及函数命名

  一般使用驼峰命名法（CamelCase）。对于常量，所有字母采用大写，多个单词用下划线隔开；当变量是jQuery类型时，建议以$开头。

- 插件文件的命名

  `.min` 表示压缩版；大小写字母敏感；如果基于 jquery 或者 bootstrap 等插件开发的，一般会以 `jquery.` 开头（如：jquery.PluginName.js）；

- 插件的压缩

  去掉换行、空格、注释，可以将进场出现的单词用某个字母代替，压缩后文件名一般加上`.min`

- 插件相关的样式（或主题）文件

  好处：用户可直接看到很好的效果，拿来即用；坏处：对用户局限太大（如果我们插件中使用bootstrap样式，那么用户向去掉这个风格会很麻烦）

- 插件的国际化

- 单元测试

  一些最常见的JavaScript单元测试工具：QUnit(是jQuery团队开发并使用的单元测试框架)、YUI Test和JSTestDriver



> 参考文章
>
> - http://www.cnblogs.com/Wayou/p/jquery_plugin_tutorial.html#home
