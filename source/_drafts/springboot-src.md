---
layout: "post"
title: "SpringBoot源码分析"
date: "2021-07-09 20:20"
categories: [java]
tags: [SpringBoot, src]
---

## 简介

- SpringApplication准备阶段源码分析: https://saint.blog.csdn.net/article/details/124741566

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

## Condition机制

- 加载图解

  ![condition.png](/data/images/2025/java/condition.png)
- 参考文章
  - [图文精讲@Conditional条件装配实现原理](https://blog.csdn.net/Saintmm/article/details/124872624)
  - [@ConditionalOnMissingBean注解居然失效了](https://developer.aliyun.com/article/1058251)
- SpringBoot3.4.5 (Spring6)

```java
// org.springframework.context
public abstract class AbstractApplicationContext extends DefaultResourceLoader
		implements ConfigurableApplicationContext {
    @Override
	public void refresh() throws BeansException, IllegalStateException {
        // ...
        // 1.注册Bean => 调用工厂处理器，注册bean到上下文中，会把所有配置类和其依赖的bean注册进beanFactory，但是此处并没有实例化
        // -> PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, getBeanFactoryPostProcessors()); -> invokeBeanDefinitionRegistryPostProcessors
        // -> ConfigurationClassPostProcessor#postProcessBeanDefinitionRegistry -> processConfigBeanDefinitions
        // --> parser.parse(candidates);
        invokeBeanFactoryPostProcessors(beanFactory);
        
        // ...
        
        // 2.创建Bean => 初始化所有的 singleton beans （lazy-init 的除外）
        finishBeanFactoryInitialization(beanFactory);
	}
}

public class ConfigurationClassPostProcessor ...{
    public void processConfigBeanDefinitions(BeanDefinitionRegistry registry) {
        // ...
        // 1.以启动类为入口, 解析所有配置类. 将解析的配置类放到 configurationClasses 中. candidates=[MySpringBootApplication]
        // --> ConfigurationClassParser#parse --> processConfigurationClass 见下文
        parser.parse(candidates);
        // ...
        
        Set<ConfigurationClass> configClasses = new LinkedHashSet<>(parser.getConfigurationClasses());
        
        // 2.将解析出的所有配置类注册到 Spring 容器中: loadBeanDefinitions
        if (this.reader == null) {
            this.reader = new ConfigurationClassBeanDefinitionReader(
                    registry, this.sourceExtractor, this.resourceLoader, this.environment,
                    this.importBeanNameGenerator, parser.getImportRegistry());
        }
        this.reader.loadBeanDefinitions(configClasses);
    }
}

class ConfigurationClassParser {
    public void parse(Set<BeanDefinitionHolder> configCandidates) {
        // ...
        // -> new ConfigurationClass -> processConfigurationClass 见下文
        configClass = parse(annotatedBeanDef, holder.getBeanName());
        // ...
        
        // 处理上文 @Import 临时存储的 deferredImportSelectors, 将所有自动装配类全路径类名放到 configurationClasses 中
        this.deferredImportSelectorHandler.process();
    }
    
    private ConfigurationClass parse(AnnotatedBeanDefinition beanDef, String beanName) {
		ConfigurationClass configClass = new ConfigurationClass(
				beanDef.getMetadata(), beanName, (beanDef instanceof ScannedGenericBeanDefinition));
		processConfigurationClass(configClass, DEFAULT_EXCLUSION_FILTER);
		return configClass;
	}
    
    protected void processConfigurationClass(ConfigurationClass configClass, Predicate<String> filter) {
        // 判断是否需要跳过此 bean 的解析
		if (this.conditionEvaluator.shouldSkip(configClass.getMetadata(), ConfigurationPhase.PARSE_CONFIGURATION)) {
			return;
		}
		// ...
		
		SourceClass sourceClass = null;
		try {
			sourceClass = asSourceClass(configClass, filter);
			do {
				// 递归地处理配置类及其父类
				sourceClass = doProcessConfigurationClass(configClass, sourceClass, filter);
			}
			while (sourceClass != null);
		}
	    // ...
	    
	    this.configurationClasses.put(configClass, configClass);
	}
	
	protected final SourceClass doProcessConfigurationClass(
			ConfigurationClass configClass, SourceClass sourceClass, Predicate<String> filter)
			throws IOException {
		// 如果当前配置类本身被 @Component 注解标记，则递归处理其内部的嵌套类
		// @Configuration/@Controller等继承自@Component, 也包含在里面. 处理其内部嵌套类即可处理 @Autowired、@Bean
	    if (configClass.getMetadata().isAnnotated(Component.class.getName())) {
			// Recursively process any member (nested) classes first
			processMemberClasses(configClass, sourceClass, filter);
		}
		
		// Process any @PropertySource annotations ...
		
		// Search for locally declared @ComponentScan annotations first ...
		
		// 如果是 ImportSelector 类型的, 将其放到 deferredImportSelectors 集合中稍后处理 (上文 deferredImportSelectorHandler)
		// Process any @Import annotations
		processImports(configClass, sourceClass, getImports(sourceClass), filter, true);
		
		// Process any @ImportResource annotations ...
		
		// Process individual @Bean methods ...
		
		// Process default methods on interfaces
		
		// Process superclass, if any
    }
}

// org.springframework.context.annotation.ConditionEvaluator
class ConditionEvaluator {
    public boolean shouldSkip(@Nullable AnnotatedTypeMetadata metadata, @Nullable ConfigurationPhase phase) {
        // metadata.className / metadata.methodName(如@Bean在方法上时只有methodName)
        if (metadata == null || !metadata.isAnnotated(Conditional.class.getName())) {
			return false;
		}
		
		if (phase == null) {
			if (metadata instanceof AnnotationMetadata annotationMetadata &&
					ConfigurationClassUtils.isConfigurationCandidate(annotationMetadata)) {
				return shouldSkip(metadata, ConfigurationPhase.PARSE_CONFIGURATION);
			}
			return shouldSkip(metadata, ConfigurationPhase.REGISTER_BEAN);
		}

		List<Condition> conditions = collectConditions(metadata);
		for (Condition condition : conditions) {
			ConfigurationPhase requiredPhase = null;
			if (condition instanceof ConfigurationCondition configurationCondition) {
				requiredPhase = configurationCondition.getConfigurationPhase();
			}
			// 进行匹配
			if ((requiredPhase == null || requiredPhase == phase) && !condition.matches(this.context, metadata)) {
				return true;
			}
		}

		return false;
    }
}
```
