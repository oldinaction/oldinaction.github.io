---
layout: "post"
title: "GrapesJS可视化元素拖拽代码生成"
date: "2020-11-16 10:28"
categories: web
tags: [js, lib]
---

## 简介

- [github](https://github.com/artf/grapesjs)
- GrapesJS 是一个免费开源的 Web 模板编辑器，可进行元素拖拽，包括元素的常用属性设置，从而生成HTML页面
- GrapesJS 引入了 backone.js，参考[backone-underscore-js.md](/_posts/web/backone-underscore-js.md)

## 初始化渲染源码解析

```js
grapesjs.init({...})

// index.js
init(config = {}) {
	// 实例化 Editor 对象
	const editor = new Editor(config).init();
	// ...
	// 渲染 DOM
	config.autorender && editor.render();
}

// editor/index.js
var em = new EditorModel(c);
var editorView = new EditorView({
	model: em,
	config: c
});
return {
	init(opts = {}) {
		// 1.实例化 EditorModel
		em.init(this, { ...c, ...opts });
	},
	render() {
		// 2.渲染 DOM
		editorView.render();
		return editorView.el;
	}
}

// 1. model 创建
// editor/model/Editor.js
export default Backbone.Model.extend({
	// 继承了 Model, 实例化时会自动调用
	initialize(c = {}) {
		// ...
		// 依次加载模块
		deps.forEach(name => this.loadModule(name));
	}),
	loadModule(moduleName) {
		// ...
		cfg.em = this;
		Mod.init({ ...cfg });

		// 将模块设置为 EditorModel 的属性
		!Mod.private && this.set(Mod.name, Mod);
	},
})

// canvas/index.js
init(config = {}) {
	// 实例化 CanvasModel
	canvas = new Canvas(config);
	CanvasView = new canvasView({
		model: canvas,
		config: c
	});
}

// canvas/model/Canvas.js
initialize(config = {}) {
    const { em } = config;
    const { styles = [], scripts = [] } = config;
	// 此处 root 优先赋值为 EditorModel 对象，并传入到 Frame 示例(保存为其 attributes 属性)。最终在渲染 FrameView 时，将 grapesjs.init 初始化时容器 container 的子 DOM 元素加入到 iframe 中
    const root = em && em.getWrapper();
    const css = em && em.getStyle();
	// 实例化 Frame
    const frame = new Frame({ root, styles: css }, config);
    styles.forEach(style => frame.addLink(style));
    scripts.forEach(script => frame.addScript(script));
    this.em = em;
    this.set('frame', frame);
	// 实例化 Frames(Collection: [frame])
    this.set('frames', new Frames([frame], config));
    this.listenTo(this, 'change:zoom', this.onZoomChange);
    this.listenTo(em, 'change:device', this.updateDevice);
}

// canvas/model/Frames.js
import model from './Frame';
export default Backbone.Collection.extend({
	model,
	// ...
});

// canvas/model/Frame.js
import model from './Frame';
export default Backbone.Model.extend({
	// 由于继承了Backbone.Model，实例化时，会自动将 props 传入值设置到 attributes 属性中。Frame 的实例化参考上文 Canvas 实例化
	initialize(props, opts = {}) {
		// 从 attributes 获取 root 和 components 等。此处的root为 grapesjs.init 初始化时，容器 container 的子 DOM 元素，在渲染 FrameView 时会用到
		const { root, styles, components } = this.attributes;
		// ...
		// 如果 root 不存在，则使用一个默认的 Component 代替
		!root &&
		  this.set(
			'root',
			new Component(
			  {
				type: 'wrapper',
				components: components || []
			  },
			  modOpts
			)
		  );
		// ...
	}
});


// 2. view 视图渲染
// editor/view/EditorView.js
export default Backbone.View.extend({
  initialize() {
	// ...
    this.pn = model.get('Panels');
	// 获取 Canvas 模块
    this.cv = model.get('Canvas');
	// ...
  },

  render() {
	// ...
	// 渲染 Canvas 模块
    $el.append(this.cv.render());
    $el.append(this.pn.render());
	// ...
  }
});

// canvas/view/CanvasView.js
export default Backbone.View.extend({
	initialize(o) {
		// ...
		const frames = model.get('frames');
		// ...
		this.frames = new FramesView({
		  collection: frames, // 设置 collection 属性
		  config: {
			...config,
			canvasView: this,
			renderContent: 1
		  }
		});
		// ...
	},
	render() {
		// ...
		const frms = model.get('frames');
		frms.listenToLoad();
		// 渲染 Frames
		frames.render();
		// ...
	}
})

// canvas/view/FramesView.js
import DomainViews from 'domain_abstract/view/DomainViews';
import FrameWrapView from './FrameWrapView';

export default DomainViews.extend({
  itemView: FrameWrapView,
  autoAdd: 1,
  // ...
});

// domain_abstract/view/DomainViews.js
export default Backbone.View.extend({
  initialize(opts = {}, config) {
    this.config = config || opts.config || {};
	// 如果启动自动添加，则监听 collection 的 add 方法调用，如果调用了则执行 this.addTo
    this.autoAdd && this.listenTo(this.collection, 'add', this.addTo);
    this.items = [];
    this.init();
  },
  addTo(model) {
    this.add(model);
  },
  add(model, fragment) {
	// ...
	// 渲染 itemView
	var itemView = this.itemView;
	// ...
	// 判断model(如果是继承，则model为子类的model属性)，不符合则渲染 itemView 属性值
	if (model.view && reuseView) {
      view = model.view;
    } else {
      view = new itemView({ model, config }, config);
    }

    items && items.push(view);
	// 渲染
    const rendered = view.render().el;
	// ...
  },
  render() {
    var frag = document.createDocumentFragment();
    this.clearItems();
    this.$el.empty();

    if (this.collection.length)
	  // 将集合中的元素添加到 DOM 容器
      this.collection.each(function(model) {
        this.add(model, frag);
      }, this);

    this.$el.append(frag);
    this.onRender();
    return this;
  },
})

// canvas/view/FrameWrapView.js
export default Backbone.View.extend({
  initialize(opts = {}, conf = {}) {
	// ...
    this.em = em;
    this.canvas = em && em.get('Canvas');
    this.ppfx = config.pStylePrefix || '';
	// 实例化 FrameView
    this.frame = new FrameView({ model, config });
    // ...
  },
  render() {
	const { frame, $el, ppfx, cv, model, el } = this;
    const { onRender } = model.attributes;
	// 渲染 FrameView(实际是生成一个 iframe 标签)
    frame.render();
	// ...
  }
})

// canvas/view/FrameView.js
render() {
    const { el, $el, ppfx, config } = this;
    $el.attr({ class: ppfx + 'frame' });

    if (config.scripts.length) {
	  // 如果有额外的scripts标签需要加入到iframe中时执行，最终仍然会执行渲染 Body 部分
      this.renderScripts();
    } else if (config.renderContent) {
	  // 渲染 Body 部分
      el.onload = this.renderBody.bind(this);
    }

    return this;
},
renderBody() {
    const { config, model, ppfx } = this;
	// 从 FrameModel 实例中获取，最早是在 Canvas 实例化传入的 EditorModel 值
    const root = model.get('root');
    const styles = model.get('styles');
    const { em } = config;
	// 由于实例化FrameView时，会自动创建iframe标签，所有此时渲染可以获取其 contentDocument 值
    const doc = this.getDoc();
    const head = this.getHead();
    const body = this.getBody();
    const win = this.getWindow();
	// ...
	// root 为 grapesjs.init 初始化时，容器 container 的子 DOM 元素。将此 DOM 元素用 ComponentView 包装，并加入到 Body 节点中
	this.root = new ComponentView({
      model: root,
      config: {
        ...root.config,
        frameView: this
      }
    }).render();
    append(body, this.root.el);
	// ...
}
```




