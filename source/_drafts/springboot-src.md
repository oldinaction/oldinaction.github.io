---
layout: "post"
title: "SpringBoot源码分析"
date: "2021-07-09 20:20"
categories: [java]
tags: [SpringBoot, src]
---

## spring.factories机制

- 使用参考[springboot.md#spring.factories文件](/_posts/java/springboot.md#spring.factories文件)
- 原理：基于`SpringFactoriesLoader`类实现
    - loadFactories 根据接口类获取其实现类的实例，这个方法返回的是对象列表
    - instantiateFactory 根据类创建实例对象
    - loadFactoryNames 扫描spring.factories文件，并解析其值到`Map<String, List<String>>`对象中
- 代码举例说明(还有其他地方也可能会调起loadFactories方法)
    - 另外如 AutoConfigurationImportSelector、TemplateAvailabilityProviders

```java
// spring-boot-2.1.13.RELEASE.jar
// SmartApplicationListener -> ApplicationListener
public class ConfigFileApplicationListener implements EnvironmentPostProcessor, SmartApplicationListener, Ordered {
    // 监听事件
    @Override
	public void onApplicationEvent(ApplicationEvent event) {
		if (event instanceof ApplicationEnvironmentPreparedEvent) {
            // 环境准备事件
			onApplicationEnvironmentPreparedEvent((ApplicationEnvironmentPreparedEvent) event);
		}
		if (event instanceof ApplicationPreparedEvent) {
			onApplicationPreparedEvent(event);
		}
	}

    private void onApplicationEnvironmentPreparedEvent(ApplicationEnvironmentPreparedEvent event) {
		List<EnvironmentPostProcessor> postProcessors = loadPostProcessors();
		postProcessors.add(this);
		AnnotationAwareOrderComparator.sort(postProcessors);
		for (EnvironmentPostProcessor postProcessor : postProcessors) {
			postProcessor.postProcessEnvironment(event.getEnvironment(), event.getSpringApplication());
		}
	}

    List<EnvironmentPostProcessor> loadPostProcessors() {
        // 调用 SpringFactoriesLoader 获取示例对象
		return SpringFactoriesLoader.loadFactories(EnvironmentPostProcessor.class, getClass().getClassLoader());
	}

    Loader(ConfigurableEnvironment environment, ResourceLoader resourceLoader) {
        this.environment = environment;
        this.placeholdersResolver = new PropertySourcesPlaceholdersResolver(this.environment);
        this.resourceLoader = (resourceLoader != null) ? resourceLoader : new DefaultResourceLoader();
        // 也会调起
        this.propertySourceLoaders = SpringFactoriesLoader.loadFactories(PropertySourceLoader.class,
                getClass().getClassLoader());
    }
}
```
