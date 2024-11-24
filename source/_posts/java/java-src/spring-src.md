---
layout: "post"
title: "Spring源码解析"
date: "2020-09-08 09:25"
categories: [java]
tags: [spring, src]
---

## 初始化

- 参考[Spring IOC源码解析](/_posts/java/java-src/spring-src-ioc.md)

## 事物

- 参考：https://www.cnblogs.com/dennyzhangdd/p/9602673.html
- PlatformTransactionManager 接口
    - TransactionStatus getTransaction(@Nullable TransactionDefinition definition) throws TransactionException;
    - void commit(TransactionStatus status) throws TransactionException;
    - void rollback(TransactionStatus status) throws TransactionException;

### TransactionAspectSupport

- TransactionInterceptor

```java
// 存在事物调用时才会进入此拦截器
@Override
@Nullable
public Object invoke(MethodInvocation invocation) throws Throwable {
    // Work out the target class: may be {@code null}.
    // The TransactionAttributeSource should be passed the target class
    // as well as the method, which may be from an interface.
    Class<?> targetClass = (invocation.getThis() != null ? AopUtils.getTargetClass(invocation.getThis()) : null);

    // Adapt to TransactionAspectSupport's invokeWithinTransaction...
    return invokeWithinTransaction(invocation.getMethod(), targetClass, invocation::proceed);
}
```

- TransactionAspectSupport.java

```java
protected Object invokeWithinTransaction(Method method, Class<?> targetClass, final InvocationCallback invocation)
            throws Throwable {
    final TransactionAttribute txAttr = getTransactionAttributeSource().getTransactionAttribute(method, targetClass);
    final PlatformTransactionManager tm = determineTransactionManager(txAttr);
    final String joinpointIdentification = methodIdentification(method, targetClass, txAttr);
    // 标准声明式事务：如果事务属性为空 或者 非回调偏向的事务管理器
    if (txAttr == null || !(tm instanceof CallbackPreferringPlatformTransactionManager)) {
        // 如果有必要，创建事务。最终进入到下文 getTransaction 方法
        TransactionInfo txInfo = createTransactionIfNecessary(tm, txAttr, joinpointIdentification);
        Object retVal = null;
        try {
            // 这里就是一个环绕增强，在这个proceed前后可以自己定义增强实现
            // 方法执行
            retVal = invocation.proceedWithInvocation();
        }
        catch (Throwable ex) {
            // 根据事务定义的，该异常需要回滚就回滚，否则提交事务
            completeTransactionAfterThrowing(txInfo, ex);
            throw ex;
        }
        finally {
            //清空当前事务信息，重置为老的
            cleanupTransactionInfo(txInfo);
        }
        //返回结果之前提交事务
        commitTransactionAfterReturning(txInfo);
        return retVal;
    }
    // 编程式事务：（回调偏向）
    else {
        final ThrowableHolder throwableHolder = new ThrowableHolder();

        // It's a CallbackPreferringPlatformTransactionManager: pass a TransactionCallback in.
        try {
            Object result = ((CallbackPreferringPlatformTransactionManager) tm).execute(txAttr,
                    new TransactionCallback<Object>() {
                        @Override
                        public Object doInTransaction(TransactionStatus status) {
                            TransactionInfo txInfo = prepareTransactionInfo(tm, txAttr, joinpointIdentification, status);
                            try {
                                return invocation.proceedWithInvocation();
                            }
                            catch (Throwable ex) {// 如果该异常需要回滚
                                if (txAttr.rollbackOn(ex)) {
                                    // 如果是运行时异常返回
                                    if (ex instanceof RuntimeException) {
                                        throw (RuntimeException) ex;
                                    }// 如果是其它异常都抛ThrowableHolderException
                                    else {
                                        throw new ThrowableHolderException(ex);
                                    }
                                }// 如果不需要回滚
                                else {
                                    // 定义异常，最终就直接提交事务了
                                    throwableHolder.throwable = ex;
                                    return null;
                                }
                            }
                            finally {//清空当前事务信息，重置为老的
                                cleanupTransactionInfo(txInfo);
                            }
                        }
                    });

            // 上抛异常
            if (throwableHolder.throwable != null) {
                throw throwableHolder.throwable;
            }
            return result;
        }
        catch (ThrowableHolderException ex) {
            throw ex.getCause();
        }
        catch (TransactionSystemException ex2) {
            if (throwableHolder.throwable != null) {
                logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
                ex2.initApplicationException(throwableHolder.throwable);
            }
            throw ex2;
        }
        catch (Throwable ex2) {
            if (throwableHolder.throwable != null) {
                logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
            }
            throw ex2;
        }
    }
}
```

### AbstractPlatformTransactionManager

```java
// 如有必要则创建事物对象(不存在事物对象TransactionStatus时)
@Override
public final TransactionStatus getTransaction(@Nullable TransactionDefinition definition)
        throws TransactionException {

    // Use defaults if no transaction definition given.
    TransactionDefinition def = (definition != null ? definition : TransactionDefinition.withDefaults());

    Object transaction = doGetTransaction();
    boolean debugEnabled = logger.isDebugEnabled();

    if (isExistingTransaction(transaction)) {
        // Existing transaction found -> check propagation behavior to find out how to behave.
        return handleExistingTransaction(def, transaction, debugEnabled);
    }

    // Check definition settings for new transaction.
    if (def.getTimeout() < TransactionDefinition.TIMEOUT_DEFAULT) {
        throw new InvalidTimeoutException("Invalid transaction timeout", def.getTimeout());
    }

    // No existing transaction found -> check propagation behavior to find out how to proceed.
    if (def.getPropagationBehavior() == TransactionDefinition.PROPAGATION_MANDATORY) {
        throw new IllegalTransactionStateException(
                "No existing transaction found for transaction marked with propagation 'mandatory'");
    }
    else if (def.getPropagationBehavior() == TransactionDefinition.PROPAGATION_REQUIRED ||
            def.getPropagationBehavior() == TransactionDefinition.PROPAGATION_REQUIRES_NEW ||
            def.getPropagationBehavior() == TransactionDefinition.PROPAGATION_NESTED) {
        SuspendedResourcesHolder suspendedResources = suspend(null);
        if (debugEnabled) {
            logger.debug("Creating new transaction with name [" + def.getName() + "]: " + def);
        }
        try {
            boolean newSynchronization = (getTransactionSynchronization() != SYNCHRONIZATION_NEVER);
            DefaultTransactionStatus status = newTransactionStatus(
                    def, transaction, true, newSynchronization, debugEnabled, suspendedResources);
            doBegin(transaction, def);
            prepareSynchronization(status, def);
            return status;
        }
        catch (RuntimeException | Error ex) {
            resume(null, suspendedResources);
            throw ex;
        }
    }
    else {
        // Create "empty" transaction: no actual transaction, but potentially synchronization.
        if (def.getIsolationLevel() != TransactionDefinition.ISOLATION_DEFAULT && logger.isWarnEnabled()) {
            logger.warn("Custom isolation level specified but no actual transaction initiated; " +
                    "isolation level will effectively be ignored: " + def);
        }
        boolean newSynchronization = (getTransactionSynchronization() == SYNCHRONIZATION_ALWAYS);
        return prepareTransactionStatus(def, null, true, newSynchronization, debugEnabled, null);
    }
}

// 提交事物
@Override
public final void commit(TransactionStatus status) throws TransactionException {
    if (status.isCompleted()) {
        throw new IllegalTransactionStateException(
                "Transaction is already completed - do not call commit or rollback more than once per transaction");
    }

    DefaultTransactionStatus defStatus = (DefaultTransactionStatus) status;
    if (defStatus.isLocalRollbackOnly()) {
        if (defStatus.isDebug()) {
            logger.debug("Transactional code has requested rollback");
        }
        processRollback(defStatus, false);
        return;
    }

    if (!shouldCommitOnGlobalRollbackOnly() && defStatus.isGlobalRollbackOnly()) {
        if (defStatus.isDebug()) {
            logger.debug("Global transaction is marked as rollback-only but transactional code requested commit");
        }
        processRollback(defStatus, true);
        return;
    }

    processCommit(defStatus);
}

// 回滚事物
@Override
public final void rollback(TransactionStatus status) throws TransactionException {
    if (status.isCompleted()) {
        throw new IllegalTransactionStateException(
                "Transaction is already completed - do not call commit or rollback more than once per transaction");
    }

    DefaultTransactionStatus defStatus = (DefaultTransactionStatus) status;
    processRollback(defStatus, false);
}
```
