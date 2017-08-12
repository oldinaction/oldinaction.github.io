---
layout: "post"
title: "sharding-jdbc 源码学习"
date: "2016-08-31 20:13"
categories: db
tags: [shading, shading-jdbc]
---

> 文档来源：胡翔宇。此处仅作存档学习！

1. ShardingDataSource   
	类图
	![](http://i.imgur.com/3bajMxv.png)
	类解析（由父类向下）

		WrapperAdapter：Wrapper适配类主要作用是额外记录jdbc方法调用以及回放。
		    /**
    		 * 记录方法调用.
    		 *
    		 * @param targetClass 目标类
   			 * @param methodName 方法名称
    		 * @param argumentTypes 参数类型
    		 * @param arguments 参数
    		 */
		    protected final void recordMethodInvocation(final Class<?> targetClass, final String methodName, final Class<?>[] argumentTypes, final Object[] arguments) {
		        try {
		            jdbcMethodInvocations.add(new JdbcMethodInvocation(targetClass.getMethod(methodName, argumentTypes), arguments));
		        } catch (final NoSuchMethodException ex) {
		            throw new ShardingJdbcException(ex);
		        }
		    }

		    /**
		     * 回放记录的方法调用.
		     *
		     * @param target 目标对象
		     */
		    protected final void replayMethodsInvocation(final Object target) {
		        for (JdbcMethodInvocation each : jdbcMethodInvocations) {
		            each.invoke(target);
		        }
		    }

		AbstractUnsupportedOperationDataSource ： 声明不支持操作的数据源对象。
		AbstractDataSourceAdapter ： 适配基类没有实际的业务操作，拓展使用（如图后加入的读写分离就是最好的例子）。

	ShardingDataSource ： 支持分片的数据源。

		重点内容  
		ShardingProperties 变量 ： 主要是jdbc的配置
		shardingContext :  数据源运行期上下文。   此处要注意的是上下文是分库分表规则的持有者，也是路由引擎，执行引擎的持有者
		方法  
		getDatabaseProductName ： 根据分库分表规则获取数据库类型（有主从的时候，与其他区分处理）。
		getConnection()： 获取数据库连接 返回 ShardingConnection 连接。

	使用方法

		 DataSourceRule dataSourceRule = new DataSourceRule(createDataSourceMap());
		//order 分表
        TableRule orderTableRule = TableRule.builder("t_order").actualTables(Arrays.asList("t_order_0", "t_order_1")).dataSourceRule(dataSourceRule).build();
		// order_iterm 分表
        TableRule orderItemTableRule = TableRule.builder("t_order_item").actualTables(Arrays.asList("t_order_item_0", "t_order_item_1")).dataSourceRule(dataSourceRule).build();
        ShardingRule shardingRule = ShardingRule.builder().dataSourceRule(dataSourceRule).tableRules(Arrays.asList(orderTableRule, orderItemTableRule))
                .bindingTableRules(Collections.singletonList(new BindingTableRule(Arrays.asList(orderTableRule, orderItemTableRule))))
                .databaseShardingStrategy(new DatabaseShardingStrategy("user_id", new ModuloDatabaseShardingAlgorithm()))
                .tableShardingStrategy(new TableShardingStrategy("order_id", new ModuloTableShardingAlgorithm())).build();
		//同时会new 一个 ShardingProperties初始化
        return new ShardingDataSource(shardingRule);

		//设置分库 ds_0,ds_1
		 private static Map<String, DataSource> createDataSourceMap() {
	        Map<String, DataSource> result = new HashMap<>(2);
	        result.put("ds_0", createDataSource("ds_0"));
	        result.put("ds_1", createDataSource("ds_1"));
        	return result;
    	}
2. ShardingConnection  
 类图
![](http://i.imgur.com/KFTd9ZT.png)
 类解析（由父类向下）

 		AbstractUnsupportedOperationConnection： 声明不支持操作的数据库连接对象.主要就是自定义不支持异常抛出
		AbstractConnectionAdapter :  数据库连接适配器，公共方法（可拓展）。
			setAutoCommit（） ： 设置分库分表自动提交。
			commit（）： 提交操作
			rollback（） ： 回滚

		ShardingConnection ： 分库分表connection
			connectionMap 变量 connection的持有者（一个库对应一个connection）
			shardingContext : 略
			getConnectionInternal（）：getConnection（）实际调用该方法。
				 private Connection getConnectionInternal(final String dataSourceName, final SQLStatementType sqlStatementType) throws SQLException {
					//已经生成的connection直接返回
			        if (connectionMap.containsKey(dataSourceName)) {
			            return connectionMap.get(dataSourceName);
			        }
					//用到 guava [http://ifeve.com/google-guava/](http://ifeve.com/google-guava/ "guava"),计时
			        Context metricsContext = MetricsContext.start(Joiner.on("-").join("ShardingConnection-getConnection", dataSourceName));
			        DataSource dataSource = shardingContext.getShardingRule().getDataSourceRule().getDataSource(dataSourceName);
			        if (dataSource instanceof MasterSlaveDataSource) {
			            dataSource = ((MasterSlaveDataSource) dataSource).getDataSource(sqlStatementType);
			        }
			        Connection result = dataSource.getConnection();
			        MetricsContext.stop(metricsContext);
			        connectionMap.put(dataSourceName, result);
			        return result;
			    }

			close（）： 连接关闭
			 	@Override
			    public void close() throws SQLException {
			        super.close();
					//清理线索分片管理器的本地线程持有者.（此处是一个问题，接下来要仔细分析一下）
			        HintManagerHolder.clear();
					//此处是个问题
			        MasterSlaveDataSource.resetDMLFlag();
			    }
使用

		 Connection conn = dataSource.getConnection();

3. ShardingStatement ： 支持分片的静态语句对象（不支持存储过程）.
	类图
	![](http://i.imgur.com/Gd6DBKS.png)
	 类解析（由父类向下）

		AbstractStatementAdapter：静态语句对象适配类.
			closed : 关闭标识
			poolable ： 暂未看
			fetchSize ： 条数
			//获取更新条数
			 @Override
		    public final int getUpdateCount() throws SQLException {
		        int result = 0;
		        for (Statement each : getRoutedStatements()) {
		            result += each.getUpdateCount();
		        }
		        return result;
		    }
			其他方法略

			ShardingStatement ： 支持分片的静态语句对象.
				shardingConnection：
				resultSetType：
				resultSetConcurrency ：
				resultSetHoldability：
				cachedRoutedStatements ： statemnets持有者
				mergeContext ： 结果归并上下文.
 				currentResultSet ：
				//执行查询
				 @Override
			    public ResultSet executeQuery(final String sql) throws SQLException {
			        if (null != currentResultSet && !currentResultSet.isClosed()) {
			            currentResultSet.close();
			        }
					//先生成执行器，然后执行查询（归并mergeContext页作为参数传过去以便最后归并），整个过程下面会详细说
			        currentResultSet = ResultSetFactory.getResultSet(generateExecutor(sql).executeQuery(), mergeContext);
			        return currentResultSet;
			    }

			    private StatementExecutor generateExecutor(final String sql) throws SQLException {
			        StatementExecutor result = new StatementExecutor(shardingConnection.getShardingContext().getExecutorEngine());
			        //路由sql 下面详细讲解
			        SQLRouteResult sqlRouteResult = shardingConnection.getShardingContext().getSqlRouteEngine().route(sql);
			        mergeContext = sqlRouteResult.getMergeContext();
					//将路由结果放置到执行器中，以便后面执行（
			        for (SQLExecutionUnit each : sqlRouteResult.getExecutionUnits()) {
			            Statement statement = getStatement(shardingConnection.getConnection(each.getDataSource(), sqlRouteResult.getSqlStatementType()), each.getSql());
			            replayMethodsInvocation(statement);
						//StatementExecutorWrapper 执行单位，和 statement组合放入执行器中
			            result.addStatement(new StatementExecutorWrapper(statement, each));
			        }
			        return result;
			    }


4. ShardingPreparedStatement ：  支持分片的预编译语句对象.
5. 解析
6. 路由
	类图
	![](http://i.imgur.com/xeGFWga.png)

		 /**
	     * SQL路由.非预编译
	     *
	     * @param logicSql 逻辑SQL
	     * @return 路由结果
	     * @throws SQLParserException SQL解析失败异常
	     */
	    public SQLRouteResult route(final String logicSql) throws SQLParserException {
	        return route(logicSql, Collections.emptyList());
	    }
		/**
	     * SQL路由.
	     *
	     * @param logicSql 逻辑SQL
	     * @param parameters 参数列表
	     * @return 路由结果
	     * @throws SQLParserException SQL解析失败异常
	     */
	    public SQLRouteResult route(final String logicSql, final List<Object> parameters) throws SQLParserException {
			//先执行一遍，解析（接下载解析模块说明），解析的时候会设置SqlStatementType
	        return routeSQL(parseSQL(logicSql, parameters), parameters);
	    }
		 SQLRouteResult routeSQL(final SQLParsedResult parsedResult, final List<Object> parameters) {
			//计时
	        Context context = MetricsContext.start("Route SQL");
	        SQLRouteResult result = new SQLRouteResult(parsedResult.getRouteContext().getSqlStatementType(), parsedResult.getMergeContext());
			//遍历解析结果
	        for (ConditionContext each : parsedResult.getConditionContexts()) {
				//将实际路由的   执行单元加入路由结果中
	            result.getExecutionUnits().addAll(routeSQL(each, Sets.newLinkedHashSet(Collections2.transform(parsedResult.getRouteContext().getTables(), new Function<Table, String>() {

	                @Override
	                public String apply(final Table input) {
	                    return input.getName();
	                }
	            })), parsedResult.getRouteContext().getSqlBuilder(), parsedResult.getRouteContext().getSqlStatementType()));
	        }
			//判断是否有限定结果集计算.
	        processLimit(result.getExecutionUnits(), parsedResult, parameters);
			//计时
	        MetricsContext.stop(context);
	        log.debug("final route result:{}", result.getExecutionUnits());
	        log.debug("merge context:{}", result.getMergeContext());
	        return result;
	    }

		SQLParsedResult parseSQL(final String logicSql, final List<Object> parameters) {
		        Context context = MetricsContext.start("Parse SQL");
		        SQLParsedResult result = SQLParserFactory.create(databaseType, logicSql, parameters, shardingRule.getAllShardingColumns()).parse();
		        MetricsContext.stop(context);
		        return result;
		    }

		private Collection<SQLExecutionUnit> routeSQL(final ConditionContext conditionContext, final Set<String> 	logicTables, final SQLBuilder sqlBuilder, final SQLStatementType type) {
	        RoutingResult result;
			//判断逻辑表数量，就是看看是否是单表操作
	        if (1 == logicTables.size()) {
	            result = new SingleTableRouter(shardingRule, logicTables.iterator().next(), conditionContext, type).route();
	        }
			//判断逻辑表名称集合是否全部属于Binding表.(绑定表代表一组表，这组表的逻辑表与实际表之间的映射关系是相同的。比如t_order与t_order_item就是这样一组绑定表关系,它们的分库与分表策略是完全相同的,那么可以使用它们的表规则将它们配置成绑定表)
			else if (shardingRule.isAllBindingTables(logicTables)) {
	            result = new BindingTablesRouter(shardingRule, logicTables, conditionContext, type).route();
	        } else {
	            // TODO 可配置是否执行笛卡尔积
	            result = new MixedTablesRouter(shardingRule, logicTables, conditionContext, type).route();
	        }
	        if (null == result) {
	            throw new ShardingJdbcException("Sharding-JDBC: cannot route any result, please check your sharding rule.");
	        }
	        return result.getSQLExecutionUnits(sqlBuilder);
	    }

		单表路由
		/**
	     * 路由.
	     *
	     * @return 路由结果
	     */
	    public SingleRoutingResult route() {
			//多库则返回多个库名称
	        Collection<String> routedDataSources = routeDataSources();
	        Collection<String> routedTables = routeTables(routedDataSources);
	        return generateRoutingResult(routedDataSources, routedTables);
	    }

		//路由数据库
		private Collection<String> routeDataSources() {
	        DatabaseShardingStrategy strategy = shardingRule.getDatabaseShardingStrategy(tableRule);
	        List<ShardingValue<?>> shardingValues;
	        if (HintManagerHolder.isUseShardingHint()) {
	            shardingValues = getDatabaseShardingValuesFromHint(strategy.getShardingColumns());
	        } else {
				//[ShardingValue(logicTableName=t_order, columnName=user_id, value=10, values=[], valueRange=null)]
				//* @param logicTable 逻辑表名称 * @param shardingColumn 分片键  * @param value 分片值
	            shardingValues = getShardingValues(strategy.getShardingColumns());
	        }
	        logBeforeRoute("database", logicTable, tableRule.getActualDatasourceNames(), strategy.getShardingColumns(), shardingValues);
	        Collection<String> result = new HashSet<>(strategy.doStaticSharding(sqlStatementType, tableRule.getActualDatasourceNames(), shardingValues));
	        logAfterRoute("database", logicTable, result);
	        Preconditions.checkState(!result.isEmpty(), "no database route info");
	        return result;
	    }
		 /**
	     * 计算静态分片.
	     *
	     * @param sqlStatementType SQL语句的类型
	     * @param availableTargetNames 所有的可用分片资源集合
	     * @param shardingValues 分片值集合
	     * @return 分库后指向的数据源名称集合
	     */
	    public Collection<String> doStaticSharding(final SQLStatementType sqlStatementType, final Collection<String> availableTargetNames, final Collection<ShardingValue<?>> shardingValues) {
	        if (shardingValues.isEmpty()) {
	            Preconditions.checkState(!isInsertMultiple(sqlStatementType, availableTargetNames), "INSERT statement should contain sharding value.");
	            return availableTargetNames;
	        }
			//分片算法是这边调用的，返回路由结果（实际表，实际数据库）
	        return doSharding(shardingValues, availableTargetNames);
	    }
		//路由实际表
		 private Collection<String> routeTables(final Collection<String> routedDataSources) {
	        TableShardingStrategy strategy = shardingRule.getTableShardingStrategy(tableRule);
	        List<ShardingValue<?>> shardingValues;
	        if (HintManagerHolder.isUseShardingHint()) {
	            shardingValues = getTableShardingValuesFromHint(strategy.getShardingColumns());
	        } else {
	            shardingValues = getShardingValues(strategy.getShardingColumns());
	        }
	        logBeforeRoute("table", logicTable, tableRule.getActualTables(), strategy.getShardingColumns(), shardingValues);
	        Collection<String> result;
	        if (tableRule.isDynamic()) {
	            result = new HashSet<>(strategy.doDynamicSharding(shardingValues));
	        } else {
	            result = new HashSet<>(strategy.doStaticSharding(sqlStatementType, tableRule.getActualTableNames(routedDataSources), shardingValues));    
	        }
	        logAfterRoute("table", logicTable, result);
	        Preconditions.checkState(!result.isEmpty(), "no table route info");
	        return result;
	    }

	    private SingleRoutingResult generateRoutingResult(final Collection<String> routedDataSources, final 			Collection<String> routedTables) {
	        SingleRoutingResult result = new SingleRoutingResult();
			//[DataNode(dataSourceName=ds_0, tableName=t_order_1), DataNode(dataSourceName=ds_1, tableName=t_order_1), DataNode(dataSourceName=ds_0, tableName=t_order_0), DataNode(dataSourceName=ds_1, tableName=t_order_0)]（第一次生成4个）
			//该方法会调用多次
	        for (DataNode each : tableRule.getActualDataNodes(routedDataSources, routedTables)) {
	            result.put(each.getDataSourceName(), new SingleRoutingTableFactor(logicTable, each.getTableName()));
	        }
	        return result;
	    }

7. 执行
	类图
	![](http://i.imgur.com/b1XLRum.png)

		首先executeQuery 由 ShardingStatement（ShardingPreparedStatement）调用
		 @Override
	    public ResultSet executeQuery(final String sql) throws SQLException {
	        if (null != currentResultSet && !currentResultSet.isClosed()) {
	            currentResultSet.close();
	        }
	        currentResultSet = ResultSetFactory.getResultSet(generateExecutor(sql).executeQuery(), mergeContext);
	        return currentResultSet;
	    }

		private StatementExecutor generateExecutor(final String sql) throws SQLException {
	        StatementExecutor result = new StatementExecutor(shardingConnection.getShardingContext().getExecutorEngine());
	        //路由sql
	        SQLRouteResult sqlRouteResult = shardingConnection.getShardingContext().getSqlRouteEngine().route(sql);
	        mergeContext = sqlRouteResult.getMergeContext();
	        for (SQLExecutionUnit each : sqlRouteResult.getExecutionUnits()) {
	            Statement statement = getStatement(shardingConnection.getConnection(each.getDataSource(), sqlRouteResult.getSqlStatementType()), each.getSql());
	            replayMethodsInvocation(statement);
				//SQLExecutionUnit，statement 组装成发给StatementExecutorWrapper 给执行器执行
	            result.addStatement(new StatementExecutorWrapper(statement, each));
	        }
	        return result;
    	}

		可以看出 generateExecutor 方法生成 StatementExecutor 执行器 接着调用 executeQuery
		 /**
	     * 执行SQL查询.
	     *
	     * @return 结果集列表
	     */
	    public List<ResultSet> executeQuery() {
			//计时
	        Context context = MetricsContext.start("ShardingStatement-executeQuery");
	        postExecutionEvents();//（此处是一个问题，接下来要仔细分析一下）
	        final boolean isExceptionThrown = ExecutorExceptionHandler.isExceptionThrown();
	        final Map<String, Object> dataMap = ExecutorDataMap.getDataMap();
	        List<ResultSet> result;
	        try {
	            if (1 == statementExecutorWrappers.size()) {
	                return Collections.singletonList(executeQueryInternal(statementExecutorWrappers.iterator().next(), isExceptionThrown, dataMap));
	            }
	            result = executorEngine.execute(statementExecutorWrappers, new ExecuteUnit<StatementExecutorWrapper, ResultSet>() {

	                @Override
	                public ResultSet execute(final StatementExecutorWrapper input) throws Exception {
	                    return executeQueryInternal(input, isExceptionThrown, dataMap);
	                }
	            });
	        } finally {
	            MetricsContext.stop(context);
	        }
	        return result;
	    }

		/**
	     * 多线程执行任务.（运用谷歌com.google.common.util.concurrent）
	     *
	     * @param inputs 输入参数
	     * @param executeUnit 执行单元
	     * @param <I> 入参类型
	     * @param <O> 出参类型
	     * @return 执行结果
	     */
	    public <I, O> List<O> execute(final Collection<I> inputs, final ExecuteUnit<I, O> executeUnit) {
	        ListenableFuture<List<O>> futures = submitFutures(inputs, executeUnit);
	        addCallback(futures);
	        return getFutureResults(futures);
	    }

		private ResultSet executeQueryInternal(final StatementExecutorWrapper statementExecutorWrapper, final boolean isExceptionThrown, final Map<String, Object> dataMap) {
	        ResultSet result;
	        ExecutorExceptionHandler.setExceptionThrown(isExceptionThrown);
	        ExecutorDataMap.setDataMap(dataMap);
	        try {
				//statementExecutorWrapper.getSqlExecutionUnit().getSql() 要参考 SqlExecutionUnit 里面的 sql参数生成过程
	            result = statementExecutorWrapper.getStatement().executeQuery(statementExecutorWrapper.getSqlExecutionUnit().getSql());
	        } catch (final SQLException ex) {
	            postExecutionEventsAfterExecution(statementExecutorWrapper, EventExecutionType.EXECUTE_FAILURE, Optional.of(ex));
	            ExecutorExceptionHandler.handleException(ex);
	            return null;
	        }
	        postExecutionEventsAfterExecution(statementExecutorWrapper);
	        return result;
	    }

8. 归并
	类图
	![](http://i.imgur.com/czM6sto.png)

		ResultSetFactory ： 分片结果集归并工厂.
		 /**
	     * 获取结果集.
	     *
	     * @param resultSets 结果集列表
	     * @param mergeContext 结果归并上下文
	     * @return 结果集包装
	     */
	    public static ResultSet getResultSet(final List<ResultSet> resultSets, final MergeContext mergeContext) throws SQLException {
	        ShardingResultSets shardingResultSets = new ShardingResultSets(resultSets);
	        log.trace("Sharding-JDBC: Sharding result sets type is '{}'", shardingResultSets.getType().toString());
	        switch (shardingResultSets.getType()) {
	            case EMPTY:
	                return buildEmpty(resultSets);
	            case SINGLE:
	                return buildSingle(shardingResultSets, mergeContext);
	            case MULTIPLE:
	                return buildMultiple(shardingResultSets, mergeContext);
	            default:
	                throw new UnsupportedOperationException(shardingResultSets.getType().toString());
	        }
	    }
		//直接看buildMultiple 上面比较简单直接返回即可
		private static ResultSet buildMultiple(final ShardingResultSets shardingResultSets, final MergeContext mergeContext) throws SQLException {
			//实例化 ResultSetMergeContext
	        ResultSetMergeContext resultSetMergeContext = new ResultSetMergeContext(shardingResultSets, mergeContext);
	        return buildCoupling(buildReducer(resultSetMergeContext), resultSetMergeContext);
  		}
		public ResultSetMergeContext(final ShardingResultSets shardingResultSets, final MergeContext mergeContext) throws SQLException {
	        this.shardingResultSets = shardingResultSets;
	        this.mergeContext = mergeContext;
	        currentOrderByKeys = new LinkedList<>();
	        init();
	    }

	    private void init() throws SQLException {
			//初始化 AbstractResultSetAdapter 一个实例  看下 AbstractResultSetAdapter 初始化干了什么
	        setColumnIndex(((AbstractResultSetAdapter) shardingResultSets.getResultSets().get(0)).getColumnLabelIndexMap());
	        currentOrderByKeys.addAll(mergeContext.getOrderByColumns());
	    }

		private void setColumnIndex(final Map<String, Integer> columnLabelIndexMap) {
	        for (IndexColumn each : getAllFocusedColumns()) {
	            if (each.getColumnIndex() > 0) {
	                continue;
	            }
	            Preconditions.checkState(
	                    columnLabelIndexMap.containsKey(each.getColumnLabel().orNull()) || columnLabelIndexMap.containsKey(each.getColumnName().orNull()), String.format("%s has not index", each));
	            if (each.getColumnLabel().isPresent() && columnLabelIndexMap.containsKey(each.getColumnLabel().get())) {
	                each.setColumnIndex(columnLabelIndexMap.get(each.getColumnLabel().get()));
	            } else if (each.getColumnName().isPresent() && columnLabelIndexMap.containsKey(each.getColumnName().get())) {
	                each.setColumnIndex(columnLabelIndexMap.get(each.getColumnName().get()));
	            }
	        }
    	}
