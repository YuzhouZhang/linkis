SET @ENGINE_LABEL="trino-371";
SET @ENGINE_IDE=CONCAT('*-IDE,',@ENGINE_LABEL);
SET @ENGINE_ALL=CONCAT('*-*,',@ENGINE_LABEL);
SET @ENGINE_NAME="trino";

-- 1. 注册 Trino 引擎 Label
INSERT INTO `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) 
VALUES ('combined_userCreator_engineType', @ENGINE_ALL, 'OPTIONAL', 2, now(), now());

INSERT INTO `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) 
VALUES ('combined_userCreator_engineType', @ENGINE_IDE, 'OPTIONAL', 2, now(), now());

SELECT @label_id := id FROM `linkis_cg_manager_label` WHERE label_value = @ENGINE_IDE;
INSERT INTO `linkis_ps_configuration_category` (`label_id`, `level`) VALUES (@label_id, 2);

-- 2. 插入 Trino 配置 Key
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.trino.default.limit', '查询的结果集返回条数限制', '结果集条数限制', '5000', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.trino.http.connectTimeout', '连接Trino服务器的超时时间', '连接超时时间（秒）', '60', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.trino.http.readTimeout', '等待Trino服务器返回数据的超时时间', '传输超时时间（秒）', '60', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.trino.resultSet.cache.max', 'Trino结果集缓冲区大小', '结果集缓冲区', '512k', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.trino.url', 'Trino服务器URL', 'Trino服务器URL', 'http://trino:8080', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.trino.user', '用于连接Trino查询服务的用户名', '用户名', 'null', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.trino.password', '用于连接Trino查询服务的密码', '密码', 'null', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.trino.catalog', '连接Trino查询时使用的catalog', 'Catalog', 'mysql', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.trino.schema', '连接Trino查询服务的默认schema', 'Schema', '', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) 
VALUES ('linkis.engineconn.concurrent.limit', '引擎最大并发', '引擎最大并发', '100', 'None', '', @ENGINE_NAME, 0, 0, 1, '数据源配置');

-- 3. 关联关系
INSERT INTO `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(SELECT config.id AS config_key_id, label.id AS engine_type_label_id FROM `linkis_ps_configuration_config_key` config
INNER JOIN `linkis_cg_manager_label` label ON config.engine_conn_type = @ENGINE_NAME AND label_value = @ENGINE_ALL);

-- 4. 默认配置项
INSERT INTO `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(SELECT relation.config_key_id AS config_key_id, '' AS config_value, relation.engine_type_label_id AS config_label_id FROM `linkis_ps_configuration_key_engine_relation` relation
INNER JOIN `linkis_cg_manager_label` label ON relation.engine_type_label_id = label.id AND label.label_value = @ENGINE_ALL);
