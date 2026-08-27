/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


-- Non-unique indexes are named according to "idx_fieldname[_fieldname]". For example idx_age_name
-- The unique index is named according to "uniq_field name[_field name]". For example uniq_age_name
-- It is recommended to include all field names for composite indexes, and the long field names can be abbreviated. For example idx_age_name_add
-- The index name should not exceed 50 characters, and the name should be lowercase
--
-- 非唯一索引按照“idx_字段名称[_字段名称]”进用行命名。例如idx_age_name
-- 唯一索引按照“uniq_字段名称[_字段名称]”进用行命名。例如uniq_age_name
-- 组合索引建议包含所有字段名,过长的字段名可以采用缩写形式。例如idx_age_name_add
-- 索引名尽量不超过50个字符，命名应该使用小写


-- 注意事项
-- 1. TDSQL层面做了硬性规定，对于varchar索引，字段总长度不能超过768个字节，建议组合索引的列的长度根据实际列数值的长度定义，比如身份证号定义长度为varchar(20)，不要定位为varchar(100)，
--   同时，由于TDSQL默认采用UTF8字符集，一个字符3个字节，因此，实际索引所包含的列的长度要小于768/3=256字符长度。
-- 2. AOMP 执行sql 语句 create table 可以带反撇号，alter 语句不能带反撇号
-- 3. 使用 alter 添加、修改字段时请带要字符集和排序规则 CHARSET utf8mb4 COLLATE utf8mb4_bin

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS `linkis_ps_configuration_config_key`;
CREATE TABLE `linkis_ps_configuration_config_key`(
    `id`               bigint(20) NOT NULL AUTO_INCREMENT,
    `key`              varchar(150)  DEFAULT NULL COMMENT 'Set key, e.g. spark.executor.instances',
    `description`      varchar(200) DEFAULT NULL,
    `name`             varchar(100)  DEFAULT NULL,
    `default_value`    varchar(200) DEFAULT NULL COMMENT 'Adopted when user does not set key',
    `validate_type`    varchar(50)  DEFAULT NULL COMMENT 'Validate type, one of the following: None, NumInterval, FloatInterval, Include, Regex, OPF, Custom Rules',
    `validate_range`   varchar(150)  DEFAULT NULL COMMENT 'Validate range',
    `engine_conn_type` varchar(50)  DEFAULT '' COMMENT 'engine type,such as spark,hive etc',
    `is_hidden`        tinyint(1)   DEFAULT NULL COMMENT 'Whether it is hidden from user. If set to 1(true), then user cannot modify, however, it could still be used in back-end',
    `is_advanced`      tinyint(1)   DEFAULT NULL COMMENT 'Whether it is an advanced parameter. If set to 1(true), parameters would be displayed only when user choose to do so',
    `level`            tinyint(1)   DEFAULT NULL COMMENT 'Basis for displaying sorting in the front-end. Higher the level is, higher the rank the parameter gets',
    `treeName`         varchar(100)  DEFAULT NULL COMMENT 'Reserved field, representing the subdirectory of engineType',
    `boundary_type`    tinyint(2) NOT NULL DEFAULT '0'  COMMENT '0  none/ 1 with mix /2 with max / 3 min and max both',
    `en_description` varchar(200) DEFAULT NULL COMMENT 'english description',
    `en_name` varchar(100) DEFAULT NULL COMMENT 'english name',
    `en_treeName` varchar(100) DEFAULT NULL COMMENT 'english treeName',
    `template_required` tinyint(1) DEFAULT 0 COMMENT 'template required 0 none / 1 must',
    UNIQUE INDEX `uniq_key_ectype` (`key`,`engine_conn_type`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


DROP TABLE IF EXISTS `linkis_ps_configuration_key_engine_relation`;
CREATE TABLE `linkis_ps_configuration_key_engine_relation`(
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_key_id` bigint(20) NOT NULL COMMENT 'config key id',
  `engine_type_label_id` bigint(20) NOT NULL COMMENT 'engine label id',
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uniq_kid_lid` (`config_key_id`, `engine_type_label_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


DROP TABLE IF EXISTS `linkis_ps_configuration_config_value`;
CREATE TABLE `linkis_ps_configuration_config_value`(
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_key_id` bigint(20),
  `config_value` varchar(500),
  `config_label_id`int(20),
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uniq_kid_lid` (`config_key_id`, `config_label_id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_ps_configuration_category`;
CREATE TABLE `linkis_ps_configuration_category` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `label_id` int(20) NOT NULL,
  `level` int(20) NOT NULL,
  `description` varchar(200),
  `tag` varchar(200),
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uniq_label_id` (`label_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP  TABLE IF EXISTS `linkis_ps_configuration_template_config_key`;
CREATE TABLE IF NOT EXISTS `linkis_ps_configuration_template_config_key` (
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
    `template_name` VARCHAR(200) NOT NULL COMMENT 'Configuration template name redundant storage',
    `template_uuid` VARCHAR(36) NOT NULL COMMENT 'uuid template id recorded by the third party',
    `key_id` BIGINT(20) NOT NULL COMMENT 'id of linkis_ps_configuration_config_key',
    `config_value` VARCHAR(200) NULL DEFAULT NULL COMMENT 'configuration value',
    `max_value` VARCHAR(50) NULL DEFAULT NULL COMMENT 'upper limit value',
    `min_value` VARCHAR(50) NULL DEFAULT NULL COMMENT 'Lower limit value (reserved)',
    `validate_range` VARCHAR(50) NULL DEFAULT NULL COMMENT 'Verification regularity (reserved)',
    `is_valid` VARCHAR(2) DEFAULT 'Y' COMMENT 'Is it valid? Reserved Y/N',
    `create_by` VARCHAR(50) NOT NULL COMMENT 'Creator',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
    `update_by` VARCHAR(50) NULL DEFAULT NULL COMMENT 'Update by',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'update time',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uniq_tid_kid` (`template_uuid`, `key_id`),
    UNIQUE INDEX `uniq_tname_kid` (`template_uuid`, `key_id`)
    )ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP  TABLE IF EXISTS `linkis_ps_configuration_key_limit_for_user`;
CREATE TABLE IF NOT EXISTS `linkis_ps_configuration_key_limit_for_user` (
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
    `user_name` VARCHAR(50) NOT NULL COMMENT 'username',
    `combined_label_value` VARCHAR(128) NOT NULL COMMENT 'Combined label combined_userCreator_engineType such as hadoop-IDE,spark-2.4.3',
    `key_id` BIGINT(20) NOT NULL COMMENT 'id of linkis_ps_configuration_config_key',
    `config_value` VARCHAR(200) NULL DEFAULT NULL COMMENT 'configuration value',
    `max_value` VARCHAR(50) NULL DEFAULT NULL COMMENT 'upper limit value',
    `min_value` VARCHAR(50) NULL DEFAULT NULL COMMENT 'Lower limit value (reserved)',
    `latest_update_template_uuid` VARCHAR(36) NOT NULL COMMENT 'uuid template id recorded by the third party',
    `is_valid` VARCHAR(2) DEFAULT 'Y' COMMENT 'Is it valid? Reserved Y/N',
    `create_by` VARCHAR(50) NOT NULL COMMENT 'Creator',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
    `update_by` VARCHAR(50) NULL DEFAULT NULL COMMENT 'Update by',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'update time',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uniq_com_label_kid` (`combined_label_value`, `key_id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP  TABLE IF EXISTS `linkis_ps_configutation_lm_across_cluster_rule`;
CREATE TABLE IF NOT EXISTS linkis_ps_configutation_lm_across_cluster_rule (
    id INT AUTO_INCREMENT COMMENT 'Rule ID, auto-increment primary key',
    cluster_name char(32) NOT NULL COMMENT 'Cluster name, cannot be empty',
    creator char(32) NOT NULL COMMENT 'Creator, cannot be empty',
    username char(32) NOT NULL COMMENT 'User, cannot be empty',
    create_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time, cannot be empty',
    create_by char(32) NOT NULL COMMENT 'Creator, cannot be empty',
    update_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Modification time, cannot be empty',
    update_by char(32) NOT NULL COMMENT 'Updater, cannot be empty',
    rules varchar(256) NOT NULL COMMENT 'Rule content, cannot be empty',
    is_valid VARCHAR(2) DEFAULT 'N' COMMENT 'Is it valid Y/N',
    PRIMARY KEY (id),
    UNIQUE KEY idx_creator_username (creator, username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- New linkis job
--

DROP  TABLE IF EXISTS `linkis_ps_job_history_group_history`;
CREATE TABLE `linkis_ps_job_history_group_history` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Primary Key, auto increment',
  `job_req_id` varchar(64) DEFAULT NULL COMMENT 'job execId',
  `submit_user` varchar(50) DEFAULT NULL COMMENT 'who submitted this Job',
  `execute_user` varchar(50) DEFAULT NULL COMMENT 'who actually executed this Job',
  `source` text DEFAULT NULL COMMENT 'job source',
  `labels` text DEFAULT NULL COMMENT 'job labels',
  `params` text DEFAULT NULL COMMENT 'job params',
  `progress` varchar(32) DEFAULT NULL COMMENT 'Job execution progress',
  `status` varchar(50) DEFAULT NULL COMMENT 'Script execution status, must be one of the following: Inited, WaitForRetry, Scheduled, Running, Succeed, Failed, Cancelled, Timeout',
  `log_path` varchar(200) DEFAULT NULL COMMENT 'File path of the job log',
  `error_code` int DEFAULT NULL COMMENT 'Error code. Generated when the execution of the script fails',
  `error_desc` varchar(1000) DEFAULT NULL COMMENT 'Execution description. Generated when the execution of script fails',
  `created_time` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'Creation time',
  `updated_time` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'Update time',
  `instances` varchar(250) DEFAULT NULL COMMENT 'Entrance instances',
  `metrics` text DEFAULT NULL COMMENT   'Job Metrics',
  `engine_type` varchar(32) DEFAULT NULL COMMENT 'Engine type',
  `execution_code` text DEFAULT NULL COMMENT 'Job origin code or code path',
  `result_location` varchar(500) DEFAULT NULL COMMENT 'File path of the resultsets',
  `observe_info` varchar(500) DEFAULT NULL COMMENT 'The notification information configuration of this job',
  PRIMARY KEY (`id`),
  KEY `idx_created_time` (`created_time`),
  KEY `idx_submit_user` (`submit_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


DROP  TABLE IF EXISTS `linkis_ps_job_history_detail`;
CREATE TABLE `linkis_ps_job_history_detail` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Primary Key, auto increment',
  `job_history_id` bigint(20) NOT NULL COMMENT 'ID of JobHistory',
  `result_location` varchar(500) DEFAULT NULL COMMENT 'File path of the resultsets',
  `execution_content` text DEFAULT NULL COMMENT 'The script code or other execution content executed by this Job',
  `result_array_size` int(4) DEFAULT 0 COMMENT 'size of result array',
  `job_group_info` text DEFAULT NULL COMMENT 'Job group info/path',
  `created_time` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'Creation time',
  `updated_time` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'Update time',
  `status` varchar(32) DEFAULT NULL COMMENT 'status',
  `priority` int(4) DEFAULT 0 COMMENT 'order of subjob',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP  TABLE IF EXISTS `linkis_ps_common_lock`;
CREATE TABLE `linkis_ps_common_lock` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lock_object` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `locker` VARCHAR(255) CHARSET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'locker',
  `time_out` longtext COLLATE utf8_bin,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_lock_object` (`lock_object`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;



SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for linkis_ps_udf_manager
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_udf_manager`;
CREATE TABLE `linkis_ps_udf_manager` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_name` varchar(20) DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


-- ----------------------------
-- Table structure for linkis_ps_udf_shared_group
-- An entry would be added when a user share a function to other user group
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_udf_shared_group`;
CREATE TABLE `linkis_ps_udf_shared_group` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `udf_id` bigint(20) NOT NULL,
  `shared_group` varchar(50) NOT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_ps_udf_shared_info`;
CREATE TABLE `linkis_ps_udf_shared_info`
(
   `id` bigint(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
   `udf_id` bigint(20) NOT NULL,
   `user_name` varchar(50) NOT NULL,
   `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
   `create_time` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_udf_tree
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_udf_tree`;
CREATE TABLE `linkis_ps_udf_tree` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `parent` bigint(20) NOT NULL,
  `name` varchar(50) DEFAULT NULL COMMENT 'Category name of the function. It would be displayed in the front-end',
  `user_name` varchar(50) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `category` varchar(50) DEFAULT NULL COMMENT 'Used to distinguish between udf and function',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_parent_name_uname_category` (`parent`,`name`,`user_name`,`category`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


-- ----------------------------
-- Table structure for linkis_ps_udf_user_load
-- Used to store the function a user selects in the front-end
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_udf_user_load`;
CREATE TABLE `linkis_ps_udf_user_load` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `udf_id` bigint(20) NOT NULL,
  `user_name` varchar(50) NOT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_uid_uname` (`udf_id`, `user_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_ps_udf_baseinfo`;
CREATE TABLE `linkis_ps_udf_baseinfo` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `create_user` varchar(50) NOT NULL,
  `udf_name` varchar(255) NOT NULL,
  `udf_type` int(11) DEFAULT '0',
  `tree_id` bigint(20) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sys` varchar(255) NOT NULL DEFAULT 'ide' COMMENT 'source system',
  `cluster_name` varchar(255) NOT NULL,
  `is_expire` bit(1) DEFAULT NULL,
  `is_shared` bit(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- default_db.linkis_ps_udf_version definition
DROP TABLE IF EXISTS `linkis_ps_udf_version`;
CREATE TABLE `linkis_ps_udf_version` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `udf_id` bigint(20) NOT NULL,
  `path` varchar(255) NOT NULL COMMENT 'Source path for uploading files',
  `bml_resource_id` varchar(50) NOT NULL,
  `bml_resource_version` varchar(20) NOT NULL,
  `is_published` bit(1) DEFAULT NULL COMMENT 'is published',
  `register_format` varchar(255) DEFAULT NULL,
  `use_format` varchar(255) DEFAULT NULL,
  `description` varchar(255) NOT NULL COMMENT 'version desc',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for linkis_ps_variable_key_user
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_variable_key_user`;
CREATE TABLE `linkis_ps_variable_key_user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `application_id` bigint(20) DEFAULT NULL COMMENT 'Reserved word',
  `key_id` bigint(20) DEFAULT NULL,
  `user_name` varchar(50) DEFAULT NULL,
  `value` varchar(200) DEFAULT NULL COMMENT 'Value of the global variable',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_aid_kid_uname` (`application_id`,`key_id`,`user_name`),
  KEY `idx_key_id` (`key_id`),
  KEY `idx_aid` (`application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


-- ----------------------------
-- Table structure for linkis_ps_variable_key
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_variable_key`;
CREATE TABLE `linkis_ps_variable_key` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `key` varchar(50) DEFAULT NULL COMMENT 'Key of the global variable',
  `description` varchar(200) DEFAULT NULL COMMENT 'Reserved word',
  `name` varchar(50) DEFAULT NULL COMMENT 'Reserved word',
  `application_id` bigint(20) DEFAULT NULL COMMENT 'Reserved word',
  `default_value` varchar(200) DEFAULT NULL COMMENT 'Reserved word',
  `value_type` varchar(50) DEFAULT NULL COMMENT 'Reserved word',
  `value_regex` varchar(100) DEFAULT NULL COMMENT 'Reserved word',
  PRIMARY KEY (`id`),
  KEY `idx_aid` (`application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_datasource_access
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_datasource_access`;
CREATE TABLE `linkis_ps_datasource_access` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `table_id` bigint(20) NOT NULL,
  `visitor` varchar(16) COLLATE utf8_bin NOT NULL,
  `fields` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `application_id` int(4) NOT NULL,
  `access_time` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_datasource_field
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_datasource_field`;
CREATE TABLE `linkis_ps_datasource_field` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `table_id` bigint(20) NOT NULL,
  `name` varchar(64) COLLATE utf8_bin NOT NULL,
  `alias` varchar(64) COLLATE utf8_bin DEFAULT NULL,
  `type` varchar(64) COLLATE utf8_bin NOT NULL,
  `comment` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `express` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `rule` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `is_partition_field` tinyint(1) NOT NULL,
  `is_primary` tinyint(1) NOT NULL,
  `length` int(11) DEFAULT NULL,
  `mode_info` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_datasource_import
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_datasource_import`;
CREATE TABLE `linkis_ps_datasource_import` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `table_id` bigint(20) NOT NULL,
  `import_type` int(4) NOT NULL,
  `args` varchar(255) COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_datasource_lineage
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_datasource_lineage`;
CREATE TABLE `linkis_ps_datasource_lineage` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `table_id` bigint(20) DEFAULT NULL,
  `source_table` varchar(64) COLLATE utf8_bin DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_datasource_table
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_datasource_table`;
CREATE TABLE `linkis_ps_datasource_table` (
  `id` bigint(255) NOT NULL AUTO_INCREMENT,
  `database` varchar(64) COLLATE utf8_bin NOT NULL,
  `name` varchar(64) COLLATE utf8_bin NOT NULL,
  `alias` varchar(64) COLLATE utf8_bin DEFAULT NULL,
  `creator` varchar(16) COLLATE utf8_bin NOT NULL,
  `comment` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `create_time` datetime NOT NULL,
  `product_name` varchar(64) COLLATE utf8_bin DEFAULT NULL,
  `project_name` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `usage` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `lifecycle` int(4) NOT NULL,
  `use_way` int(4) NOT NULL,
  `is_import` tinyint(1) NOT NULL,
  `model_level` int(4) NOT NULL,
  `is_external_use` tinyint(1) NOT NULL,
  `is_partition_table` tinyint(1) NOT NULL,
  `is_available` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_db_name` (`database`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_datasource_table_info
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_datasource_table_info`;
CREATE TABLE `linkis_ps_datasource_table_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `table_id` bigint(20) NOT NULL,
  `table_last_update_time` datetime NOT NULL,
  `row_num` bigint(20) NOT NULL,
  `file_num` int(11) NOT NULL,
  `table_size` varchar(32) COLLATE utf8_bin NOT NULL,
  `partitions_num` int(11) NOT NULL,
  `update_time` datetime NOT NULL,
  `field_num` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;




-- ----------------------------
-- Table structure for linkis_ps_cs_context_map
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_cs_context_map`;
CREATE TABLE `linkis_ps_cs_context_map` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(128) DEFAULT NULL,
  `context_scope` varchar(32) DEFAULT NULL,
  `context_type` varchar(32) DEFAULT NULL,
  `props` text,
  `value` mediumtext,
  `context_id` int(11) DEFAULT NULL,
  `keywords` varchar(255) DEFAULT NULL,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
  `access_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'last access time',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_key_cid_ctype` (`key`,`context_id`,`context_type`),
  KEY `idx_keywords` (`keywords`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_cs_context_map_listener
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_cs_context_map_listener`;
CREATE TABLE `linkis_ps_cs_context_map_listener` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `listener_source` varchar(255) DEFAULT NULL,
  `key_id` int(11) DEFAULT NULL,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
  `access_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'last access time',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_cs_context_history
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_cs_context_history`;
CREATE TABLE `linkis_ps_cs_context_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `context_id` int(11) DEFAULT NULL,
  `source` text,
  `context_type` varchar(32) DEFAULT NULL,
  `history_json` text,
  `keyword` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
  `access_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'last access time',
  KEY `idx_keyword` (`keyword`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_cs_context_id
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_cs_context_id`;
CREATE TABLE `linkis_ps_cs_context_id` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(32) DEFAULT NULL,
  `application` varchar(32) DEFAULT NULL,
  `source` varchar(255) DEFAULT NULL,
  `expire_type` varchar(32) DEFAULT NULL,
  `expire_time` datetime DEFAULT NULL,
  `instance` varchar(64) DEFAULT NULL,
  `backup_instance` varchar(64) DEFAULT NULL,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
  `access_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'last access time',
  PRIMARY KEY (`id`),
  KEY `idx_instance` (`instance`),
  KEY `idx_backup_instance` (`backup_instance`),
  KEY `idx_instance_bin` (`instance`,`backup_instance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_cs_context_listener
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_cs_context_listener`;
CREATE TABLE `linkis_ps_cs_context_listener` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `listener_source` varchar(255) DEFAULT NULL,
  `context_id` int(11) DEFAULT NULL,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
  `access_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'last access time',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


DROP TABLE IF EXISTS `linkis_ps_bml_resources`;
CREATE TABLE if not exists `linkis_ps_bml_resources` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `resource_id` varchar(50) NOT NULL COMMENT 'resource uuid',
  `is_private` TINYINT(1) DEFAULT 0 COMMENT 'Whether the resource is private, 0 means private, 1 means public',
  `resource_header` TINYINT(1) DEFAULT 0 COMMENT 'Classification, 0 means unclassified, 1 means classified',
	`downloaded_file_name` varchar(200) DEFAULT NULL COMMENT 'File name when downloading',
	`sys` varchar(100) NOT NULL COMMENT 'Owning system',
	`create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created time',
	`owner` varchar(200) NOT NULL COMMENT 'Resource owner',
	`is_expire` TINYINT(1) DEFAULT 0 COMMENT 'Whether expired, 0 means not expired, 1 means expired',
	`expire_type` varchar(50) DEFAULT null COMMENT 'Expiration type, date refers to the expiration on the specified date, TIME refers to the time',
	`expire_time` varchar(50) DEFAULT null COMMENT 'Expiration time, one day by default',
	`max_version` int(20) DEFAULT 10 COMMENT 'The default is 10, which means to keep the latest 10 versions',
	`update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Updated time',
	`updator` varchar(50) DEFAULT NULL COMMENT 'updator',
	`enable_flag` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Status, 1: normal, 0: frozen',
	unique key `uniq_rid_eflag`(`resource_id`, `enable_flag`),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


DROP TABLE IF EXISTS `linkis_ps_bml_resources_version`;
CREATE TABLE if not exists `linkis_ps_bml_resources_version` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `resource_id` varchar(50) NOT NULL COMMENT 'Resource uuid',
  `file_md5` varchar(32) NOT NULL COMMENT 'Md5 summary of the file',
  `version` varchar(20) NOT NULL COMMENT 'Resource version (v plus five digits)',
	`size` int(10) NOT NULL COMMENT 'File size',
	`start_byte` BIGINT(20) UNSIGNED NOT NULL DEFAULT 0,
	`end_byte` BIGINT(20) UNSIGNED NOT NULL DEFAULT 0,
	`resource` varchar(2000) NOT NULL COMMENT 'Resource content (file information including path and file name)',
	`description` varchar(2000) DEFAULT NULL COMMENT 'description',
	`start_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Started time',
	`end_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Stoped time',
	`client_ip` varchar(200) NOT NULL COMMENT 'Client ip',
	`updator` varchar(50) DEFAULT NULL COMMENT 'updator',
	`enable_flag` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Status, 1: normal, 0: frozen',
	unique key `uniq_rid_version`(`resource_id`, `version`),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;



DROP TABLE IF EXISTS `linkis_ps_bml_resources_permission`;
CREATE TABLE if not exists `linkis_ps_bml_resources_permission` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `resource_id` varchar(50) NOT NULL COMMENT 'Resource uuid',
  `permission` varchar(10) NOT NULL COMMENT 'permission',
	`create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'created time',
	`system` varchar(50) default "dss" COMMENT 'creator',
	`update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'updated time',
	`updator` varchar(50) NOT NULL COMMENT 'updator',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;



DROP TABLE IF EXISTS `linkis_ps_resources_download_history`;
CREATE TABLE if not exists `linkis_ps_resources_download_history` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'primary key',
	`start_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'start time',
	`end_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'stop time',
	`client_ip` varchar(200) NOT NULL COMMENT 'client ip',
	`state` TINYINT(1) NOT NULL COMMENT 'Download status, 0 download successful, 1 download failed',
	 `resource_id` varchar(50) not null,
	 `version` varchar(20) not null,
	`downloader` varchar(50) NOT NULL COMMENT 'Downloader',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;




-- 创建资源任务表,包括上传,更新,下载
DROP TABLE IF EXISTS `linkis_ps_bml_resources_task`;
CREATE TABLE if not exists `linkis_ps_bml_resources_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `resource_id` varchar(50) DEFAULT NULL COMMENT 'resource uuid',
  `version` varchar(20) DEFAULT NULL COMMENT 'Resource version number of the current operation',
  `operation` varchar(20) NOT NULL COMMENT 'Operation type. upload = 0, update = 1',
  `state` varchar(20) NOT NULL DEFAULT 'Schduled' COMMENT 'Current status of the task:Schduled, Running, Succeed, Failed,Cancelled',
  `submit_user` varchar(20) NOT NULL DEFAULT '' COMMENT 'Job submission user name',
  `system` varchar(20) DEFAULT 'dss' COMMENT 'Subsystem name: wtss',
  `instance` varchar(128) NOT NULL COMMENT 'Material library example',
  `client_ip` varchar(50) DEFAULT NULL COMMENT 'Request IP',
  `extra_params` text COMMENT 'Additional key information. Such as the resource IDs and versions that are deleted in batches, and all versions under the resource are deleted',
  `err_msg` varchar(2000) DEFAULT NULL COMMENT 'Task failure information.e.getMessage',
  `start_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Starting time',
  `end_time` datetime DEFAULT NULL COMMENT 'End Time',
  `last_update_time` datetime NOT NULL COMMENT 'Last update time',
   unique key `uniq_rid_version` (resource_id, version),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;



DROP TABLE IF EXISTS `linkis_ps_bml_project`;
create table if not exists linkis_ps_bml_project(
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) DEFAULT NULL,
  `system` varchar(64) not null default "dss",
  `source` varchar(1024) default null,
  `description` varchar(1024) default null,
  `creator` varchar(128) not null,
  `enabled` tinyint default 1,
  `create_time` datetime DEFAULT now(),
  unique key `uniq_name` (`name`),
PRIMARY KEY (`id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=COMPACT;



DROP TABLE IF EXISTS `linkis_ps_bml_project_user`;
create table if not exists linkis_ps_bml_project_user(
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `project_id` int(10) NOT NULL,
  `username` varchar(64) DEFAULT NULL,
  `priv` int(10) not null default 7, -- rwx 421 The permission value is 7. 8 is the administrator, which can authorize other users
  `creator` varchar(128) not null,
  `create_time` datetime DEFAULT now(),
  `expire_time` datetime default null,
  unique key `uniq_name_pid`(`username`, `project_id`),
PRIMARY KEY (`id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=COMPACT;


DROP TABLE IF EXISTS `linkis_ps_bml_project_resource`;
create table if not exists linkis_ps_bml_project_resource(
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `project_id` int(10) NOT NULL,
  `resource_id` varchar(128) DEFAULT NULL,
PRIMARY KEY (`id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=COMPACT;


DROP TABLE IF EXISTS `linkis_ps_instance_label`;
CREATE TABLE `linkis_ps_instance_label` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `label_key` varchar(32) COLLATE utf8_bin NOT NULL COMMENT 'string key',
  `label_value` varchar(128) COLLATE utf8_bin NOT NULL COMMENT 'string value',
  `label_feature` varchar(16) COLLATE utf8_bin NOT NULL COMMENT 'store the feature of label, but it may be redundant',
  `label_value_size` int(20) NOT NULL COMMENT 'size of key -> value map',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_lk_lv` (`label_key`,`label_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


DROP TABLE IF EXISTS `linkis_ps_instance_label_value_relation`;
CREATE TABLE `linkis_ps_instance_label_value_relation` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `label_value_key` varchar(128) COLLATE utf8_bin NOT NULL COMMENT 'value key',
  `label_value_content` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT 'value content',
  `label_id` int(20) DEFAULT NULL COMMENT 'id reference linkis_ps_instance_label -> id',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'create unix timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_lvk_lid` (`label_value_key`,`label_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_ps_instance_label_relation`;
CREATE TABLE `linkis_ps_instance_label_relation` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `label_id` int(20) DEFAULT NULL COMMENT 'id reference linkis_ps_instance_label -> id',
  `service_instance` varchar(128) NOT NULL COLLATE utf8_bin COMMENT 'structure like ${host|machine}:${port}',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'create unix timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_lid_instance` (`label_id`,`service_instance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


DROP TABLE IF EXISTS `linkis_ps_instance_info`;
CREATE TABLE `linkis_ps_instance_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `instance` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT 'structure like ${host|machine}:${port}',
  `name` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT 'equal application name in registry',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'update unix timestamp',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'create unix timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_instance` (`instance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_ps_error_code`;
CREATE TABLE `linkis_ps_error_code` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `error_code` varchar(50) NOT NULL,
  `error_desc` varchar(1024) NOT NULL,
  `error_regex` varchar(1024) DEFAULT NULL,
  `error_type` int(3) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `idx_error_regex` (error_regex(191))
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_manager_service_instance`;
CREATE TABLE `linkis_cg_manager_service_instance` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `instance` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `name` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `owner` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `mark` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `identifier` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `ticketId` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `mapping_host` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `mapping_ports` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `updator` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `creator` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `params` text COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_instance` (`instance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_manager_linkis_resources`;
CREATE TABLE `linkis_cg_manager_linkis_resources` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `max_resource` varchar(1020) COLLATE utf8_bin DEFAULT NULL,
  `min_resource` varchar(1020) COLLATE utf8_bin DEFAULT NULL,
  `used_resource` varchar(1020) COLLATE utf8_bin DEFAULT NULL,
  `left_resource` varchar(1020) COLLATE utf8_bin DEFAULT NULL,
  `expected_resource` varchar(1020) COLLATE utf8_bin DEFAULT NULL,
  `locked_resource` varchar(1020) COLLATE utf8_bin DEFAULT NULL,
  `resourceType` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `ticketId` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `updator` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `creator` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_manager_lock`;
CREATE TABLE `linkis_cg_manager_lock` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lock_object` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `time_out` longtext COLLATE utf8_bin,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_rm_external_resource_provider`;
CREATE TABLE `linkis_cg_rm_external_resource_provider` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `resource_type` varchar(32) NOT NULL,
  `name` varchar(32) NOT NULL,
  `labels` varchar(32) DEFAULT NULL,
  `config` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_manager_engine_em`;
CREATE TABLE `linkis_cg_manager_engine_em` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `engine_instance` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `em_instance` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_manager_label`;
CREATE TABLE `linkis_cg_manager_label` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `label_key` varchar(32) COLLATE utf8_bin NOT NULL,
  `label_value` varchar(128) COLLATE utf8_bin NOT NULL,
  `label_feature` varchar(16) COLLATE utf8_bin NOT NULL,
  `label_value_size` int(20) NOT NULL,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_lk_lv` (`label_key`,`label_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_manager_label_value_relation`;
CREATE TABLE `linkis_cg_manager_label_value_relation` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `label_value_key` varchar(128) COLLATE utf8_bin NOT NULL,
  `label_value_content` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `label_id` int(20) DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_lvk_lid` (`label_value_key`,`label_id`),
  UNIQUE KEY `unlid_lvk_lvc` (`label_id`,`label_value_key`,`label_value_content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_manager_label_resource`;
CREATE TABLE `linkis_cg_manager_label_resource` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `label_id` int(20) DEFAULT NULL,
  `resource_id` int(20) DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_label_id` (`label_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_ec_resource_info_record`;
CREATE TABLE `linkis_cg_ec_resource_info_record` (
    `id` INT(20) NOT NULL AUTO_INCREMENT,
    `label_value` VARCHAR(128) NOT NULL COMMENT 'ec labels stringValue',
    `create_user` VARCHAR(128) NOT NULL COMMENT 'ec create user',
    `service_instance` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT 'ec instance info',
    `ecm_instance` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT 'ecm instance info ',
    `ticket_id` VARCHAR(36) NOT NULL COMMENT 'ec ticket id',
    `status` varchar(50) DEFAULT NULL COMMENT 'EC status: Starting,Unlock,Locked,Idle,Busy,Running,ShuttingDown,Failed,Success',
    `log_dir_suffix` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT 'log path',
    `request_times` INT(8) COMMENT 'resource request times',
    `request_resource` VARCHAR(1020) COMMENT 'request resource',
    `used_times` INT(8) COMMENT 'resource used times',
    `used_resource` VARCHAR(1020) COMMENT 'used resource',
    `metrics` TEXT DEFAULT NULL COMMENT 'ec metrics',
    `release_times` INT(8) COMMENT 'resource released times',
    `released_resource` VARCHAR(1020)  COMMENT 'released resource',
    `release_time` datetime DEFAULT NULL COMMENT 'released time',
    `used_time` datetime DEFAULT NULL COMMENT 'used time',
    `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
    PRIMARY KEY (`id`),
    KEY `idx_ticket_id` (`ticket_id`),
    UNIQUE KEY `uniq_tid_lv` (`ticket_id`,`label_value`),
    UNIQUE KEY `uniq_sinstance_status_cuser_ctime` (`service_instance`, `status`, `create_user`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_manager_label_service_instance`;
CREATE TABLE `linkis_cg_manager_label_service_instance` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `label_id` int(20) DEFAULT NULL,
  `service_instance` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_lid_instance` (`label_id`,`service_instance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


DROP TABLE IF EXISTS `linkis_cg_manager_label_user`;
CREATE TABLE `linkis_cg_manager_label_user` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `label_id` int(20) DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


DROP TABLE IF EXISTS `linkis_cg_manager_metrics_history`;
CREATE TABLE `linkis_cg_manager_metrics_history` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `instance_status` int(20) DEFAULT NULL,
  `overload` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `heartbeat_msg` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `healthy_status` int(20) DEFAULT NULL,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `creator` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `ticketID` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `serviceName` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `instance` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_manager_service_instance_metrics`;
CREATE TABLE `linkis_cg_manager_service_instance_metrics` (
  `instance` varchar(128) COLLATE utf8_bin NOT NULL,
  `instance_status` int(11) DEFAULT NULL,
  `overload` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `heartbeat_msg` text COLLATE utf8_bin DEFAULT NULL,
  `healthy_status` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `description` varchar(256) COLLATE utf8_bin NOT NULL DEFAULT '',
  PRIMARY KEY (`instance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

DROP TABLE IF EXISTS `linkis_cg_engine_conn_plugin_bml_resources`;
CREATE TABLE `linkis_cg_engine_conn_plugin_bml_resources` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `engine_conn_type` varchar(100) NOT NULL COMMENT 'Engine type',
  `version` varchar(100) COMMENT 'version',
  `file_name` varchar(255) COMMENT 'file name',
  `file_size` bigint(20)  DEFAULT 0 NOT NULL COMMENT 'file size',
  `last_modified` bigint(20)  COMMENT 'File update time',
  `bml_resource_id` varchar(100) NOT NULL COMMENT 'Owning system',
  `bml_resource_version` varchar(200) NOT NULL COMMENT 'Resource owner',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'created time',
  `last_update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'updated time',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_dm_datasource
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_dm_datasource`;
CREATE TABLE `linkis_ps_dm_datasource`
(
    `id`                   int(11)                       NOT NULL AUTO_INCREMENT,
    `datasource_name`      varchar(255) COLLATE utf8_bin NOT NULL,
    `datasource_desc`      varchar(255) COLLATE utf8_bin      DEFAULT NULL,
    `datasource_type_id`   int(11)                       NOT NULL,
    `create_identify`      varchar(255) COLLATE utf8_bin      DEFAULT NULL,
    `create_system`        varchar(255) COLLATE utf8_bin      DEFAULT NULL,
    `parameter`            varchar(2048) COLLATE utf8_bin NULL DEFAULT NULL,
    `create_time`          datetime                      NULL DEFAULT CURRENT_TIMESTAMP,
    `modify_time`          datetime                      NULL DEFAULT CURRENT_TIMESTAMP,
    `create_user`          varchar(255) COLLATE utf8_bin      DEFAULT NULL,
    `modify_user`          varchar(255) COLLATE utf8_bin      DEFAULT NULL,
    `labels`               varchar(255) COLLATE utf8_bin      DEFAULT NULL,
    `version_id`           int(11)                            DEFAULT NULL COMMENT 'current version id',
    `expire`               tinyint(1)                         DEFAULT 0,
    `published_version_id` int(11)                            DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uniq_datasource_name` (`datasource_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_dm_datasource_env
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_dm_datasource_env`;
CREATE TABLE `linkis_ps_dm_datasource_env`
(
    `id`                 int(11)                       NOT NULL AUTO_INCREMENT,
    `env_name`           varchar(32) COLLATE utf8_bin  NOT NULL,
    `env_desc`           varchar(255) COLLATE utf8_bin          DEFAULT NULL,
    `datasource_type_id` int(11)                       NOT NULL,
    `parameter`          varchar(2048) COLLATE utf8_bin          DEFAULT NULL,
    `create_time`        datetime                      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `create_user`        varchar(255) COLLATE utf8_bin NULL     DEFAULT NULL,
    `modify_time`        datetime                      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `modify_user`        varchar(255) COLLATE utf8_bin NULL     DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_env_name` (`env_name`),
    UNIQUE INDEX `uniq_name_dtid` (`env_name`, `datasource_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


-- ----------------------------
-- Table structure for linkis_ps_dm_datasource_type
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_dm_datasource_type`;
CREATE TABLE `linkis_ps_dm_datasource_type`
(
    `id`          int(11)                      NOT NULL AUTO_INCREMENT,
    `name`        varchar(32) COLLATE utf8_bin NOT NULL,
    `description` varchar(255) COLLATE utf8_bin DEFAULT NULL,
    `option`      varchar(32) COLLATE utf8_bin  DEFAULT NULL,
    `classifier`  varchar(32) COLLATE utf8_bin NOT NULL,
    `icon`        varchar(255) COLLATE utf8_bin DEFAULT NULL,
    `layers`      int(3)                       NOT NULL,
    `description_en` varchar(255) DEFAULT NULL COMMENT 'english description',
    `option_en` varchar(32) DEFAULT NULL COMMENT 'english option',
    `classifier_en` varchar(32) DEFAULT NULL COMMENT 'english classifier',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uniq_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_dm_datasource_type_key
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_dm_datasource_type_key`;
CREATE TABLE `linkis_ps_dm_datasource_type_key`
(
    `id`                  int(11)                       NOT NULL AUTO_INCREMENT,
    `data_source_type_id` int(11)                       NOT NULL,
    `key`                 varchar(32) COLLATE utf8_bin  NOT NULL,
    `name`                varchar(32) COLLATE utf8_bin  NOT NULL,
    `name_en`             varchar(32) COLLATE utf8_bin  NULL     DEFAULT NULL,
    `default_value`       varchar(50) COLLATE utf8_bin  NULL     DEFAULT NULL,
    `value_type`          varchar(50) COLLATE utf8_bin  NOT NULL,
    `scope`               varchar(50) COLLATE utf8_bin  NULL     DEFAULT NULL,
    `require`             tinyint(1)                    NULL     DEFAULT 0,
    `description`         varchar(200) COLLATE utf8_bin NULL     DEFAULT NULL,
    `description_en`      varchar(200) COLLATE utf8_bin NULL     DEFAULT NULL,
    `value_regex`         varchar(200) COLLATE utf8_bin NULL     DEFAULT NULL,
    `ref_id`              bigint(20)                    NULL     DEFAULT NULL,
    `ref_value`           varchar(50) COLLATE utf8_bin  NULL     DEFAULT NULL,
    `data_source`         varchar(200) COLLATE utf8_bin NULL     DEFAULT NULL,
    `update_time`         datetime                      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `create_time`         datetime                      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_dstid_key` (`data_source_type_id`, `key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
-- ----------------------------
-- Table structure for linkis_ps_dm_datasource_version
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_dm_datasource_version`;
CREATE TABLE `linkis_ps_dm_datasource_version`
(
    `version_id`    int(11)                        NOT NULL AUTO_INCREMENT,
    `datasource_id` int(11)                        NOT NULL,
    `parameter`     varchar(2048) COLLATE utf8_bin NULL DEFAULT NULL,
    `comment`       varchar(255) COLLATE utf8_bin  NULL DEFAULT NULL,
    `create_time`   datetime(0)                    NULL DEFAULT CURRENT_TIMESTAMP,
    `create_user`   varchar(255) COLLATE utf8_bin  NULL DEFAULT NULL,
    PRIMARY KEY `uniq_vid_did` (`version_id`, `datasource_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_mg_gateway_auth_token
-- ----------------------------
DROP TABLE IF EXISTS `linkis_mg_gateway_auth_token`;
CREATE TABLE `linkis_mg_gateway_auth_token` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `token_name` varchar(128) NOT NULL,
     `legal_users` text,
     `legal_hosts` text,
     `business_owner` varchar(32),
     `create_time` DATE DEFAULT NULL,
     `update_time` DATE DEFAULT NULL,
     `elapse_day` BIGINT DEFAULT NULL,
     `update_by` varchar(32),
PRIMARY KEY (`id`),
UNIQUE KEY `uniq_token_name` (`token_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;



-- ----------------------------
-- Table structure for linkis_cg_tenant_label_config
-- ----------------------------
DROP TABLE IF EXISTS `linkis_cg_tenant_label_config`;
CREATE TABLE `linkis_cg_tenant_label_config` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `user` varchar(50) COLLATE utf8_bin NOT NULL,
  `creator` varchar(50) COLLATE utf8_bin NOT NULL,
  `tenant_value` varchar(128) COLLATE utf8_bin NOT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `desc` varchar(100) COLLATE utf8_bin NOT NULL,
  `bussiness_user` varchar(50) COLLATE utf8_bin NOT NULL,
  `is_valid` varchar(1) COLLATE utf8_bin NOT NULL DEFAULT 'Y' COMMENT 'is valid',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_user_creator` (`user`,`creator`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_cg_user_ip_config
-- ----------------------------
DROP TABLE IF EXISTS `linkis_cg_user_ip_config`;
CREATE TABLE `linkis_cg_user_ip_config` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `user` varchar(50) COLLATE utf8_bin NOT NULL,
  `creator` varchar(50) COLLATE utf8_bin NOT NULL,
  `ip_list` text COLLATE utf8_bin NOT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `desc` varchar(100) COLLATE utf8_bin NOT NULL,
  `bussiness_user` varchar(50) COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_user_creator` (`user`,`creator`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;



-- ----------------------------
-- Table structure for linkis_org_user
-- ----------------------------
DROP TABLE IF EXISTS `linkis_org_user`;
CREATE TABLE `linkis_org_user` (
    `cluster_code` varchar(16) COMMENT 'cluster code',
    `user_type` varchar(64) COMMENT 'user type',
    `user_name` varchar(128) COMMENT 'username',
    `org_id` varchar(16) COMMENT 'org id',
    `org_name` varchar(64) COMMENT 'org name',
    `queue_name` varchar(64) COMMENT 'yarn queue name',
    `db_name` varchar(64) COMMENT 'default db name',
    `interface_user` varchar(64) COMMENT 'interface user',
    `is_union_analyse` varchar(64) COMMENT 'is union analyse',
    `create_time` varchar(64) COMMENT 'create time',
    `user_itsm_no` varchar(64) COMMENT 'user itsm no',
    PRIMARY KEY (`user_name`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE=utf8mb4_bin COMMENT ='user org info';






-- 商业化 未开源的放在最后面 上面的sql 和开源保持一致
-- ----------------------------
-- Table structure for linkis_cg_synckey
-- ----------------------------
DROP TABLE IF EXISTS `linkis_cg_synckey`;
CREATE TABLE `linkis_cg_synckey` (
    `username` char(32) NOT NULL,
    `synckey` char(32) NOT NULL,
    `instance` varchar(32) NOT NULL,
    `create_time` datetime(3) NOT NULL,
    PRIMARY KEY (`username`, `synckey`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;



-- ----------------------------
-- Table structure for linkis_et_validator_checkinfo
-- ----------------------------
DROP TABLE IF EXISTS `linkis_et_validator_checkinfo`;
CREATE TABLE `linkis_et_validator_checkinfo` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `execute_user` varchar(64) COLLATE utf8_bin NOT NULL,
  `db_name` varchar(64) COLLATE utf8_bin DEFAULT NULL,
  `params` text COLLATE utf8_bin,
  `code_type` varchar(32) COLLATE utf8_bin NOT NULL,
  `operation_type` varchar(32) COLLATE utf8_bin NOT NULL,
  `status` tinyint(4) DEFAULT NULL,
  `code` text COLLATE utf8_bin,
  `msg` text COLLATE utf8_bin,
  `risk_level` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `hit_rules` text COLLATE utf8_bin,
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_bml_cleaned_resources_version
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_bml_cleaned_resources_version`;
CREATE TABLE `linkis_ps_bml_cleaned_resources_version` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `resource_id` varchar(50) NOT NULL COMMENT '资源id，资源的uuid',
  `file_md5` varchar(32) NOT NULL COMMENT '文件的md5摘要',
  `version` varchar(20) NOT NULL COMMENT '资源版本（v 加上 五位数字）',
  `size` int(10) NOT NULL COMMENT '文件大小',
  `start_byte` bigint(20) unsigned NOT NULL DEFAULT '0',
  `end_byte` bigint(20) unsigned NOT NULL DEFAULT '0',
  `resource` varchar(2000) NOT NULL COMMENT '资源内容（文件信息 包括 路径和文件名）',
  `description` varchar(2000) DEFAULT NULL COMMENT '描述',
  `start_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '结束时间',
  `client_ip` varchar(200) NOT NULL COMMENT '客户端ip',
  `updator` varchar(50) DEFAULT NULL COMMENT '修改者',
  `enable_flag` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态，1：正常，0：冻结',
  `old_resource` varchar(2000) NOT NULL COMMENT '旧的路径',
  PRIMARY KEY (`id`),
  UNIQUE KEY `resource_id_version` (`resource_id`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


-- ----------------------------
-- Table structure for linkis_ps_configuration_across_cluster_rule
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_configuration_across_cluster_rule`;
CREATE TABLE `linkis_ps_configuration_across_cluster_rule` (
    id INT AUTO_INCREMENT COMMENT '规则ID，自增主键',
    cluster_name char(32) NOT NULL COMMENT '集群名称，不能为空',
    creator char(32) NOT NULL COMMENT '创建者，不能为空',
    username char(32) NOT NULL COMMENT '用户，不能为空',
    create_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间，不能为空',
    create_by char(32) NOT NULL COMMENT '创建者，不能为空',
    update_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间，不能为空',
    update_by char(32) NOT NULL COMMENT '更新者，不能为空',
    rules varchar(512) NOT NULL COMMENT '规则内容，不能为空',
    is_valid VARCHAR(2) DEFAULT 'N' COMMENT '是否有效 Y/N',
    PRIMARY KEY (id),
    UNIQUE KEY idx_creator_username (creator, username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_configuration_template_config_key
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_configuration_template_config_key`;
CREATE TABLE `linkis_ps_configuration_template_config_key` (
	`id` BIGINT(20) NOT NULL AUTO_INCREMENT,
	`template_name` VARCHAR(200) NOT NULL COMMENT '配置模板名称 冗余存储',
	`template_uuid` VARCHAR(36) NOT NULL COMMENT 'uuid  第三方侧记录的模板id',
	`key_id` BIGINT(20) NOT NULL COMMENT 'id of linkis_ps_configuration_config_key',
	`config_value` VARCHAR(200) NULL DEFAULT NULL COMMENT '配置值',
	`max_value` VARCHAR(50) NULL DEFAULT NULL COMMENT '上限值',
	`min_value` VARCHAR(50) NULL DEFAULT NULL COMMENT '下限值（预留）',
	`validate_range` VARCHAR(50) NULL DEFAULT NULL COMMENT '校验正则(预留) ',
	`is_valid` VARCHAR(2)   DEFAULT 'Y' COMMENT '是否有效 预留 Y/N',
	`create_by` VARCHAR(50) NOT NULL COMMENT '创建人',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
	`update_by` VARCHAR(50) NULL DEFAULT NULL COMMENT '更新人',
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'update time',
	PRIMARY KEY (`id`),
	UNIQUE INDEX `uniq_tid_kid` (`template_uuid`, `key_id`),
	UNIQUE INDEX `uniq_tname_kid` (`template_uuid`, `key_id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_configuration_key_limit_for_user
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_configuration_key_limit_for_user`;
CREATE TABLE `linkis_ps_configuration_key_limit_for_user` (
	`id` BIGINT(20) NOT NULL AUTO_INCREMENT,
	`user_name` VARCHAR(50) NOT NULL COMMENT '用户名',
	`combined_label_value` VARCHAR(128) NOT NULL COMMENT '组合标签 combined_userCreator_engineType  如 hadoop-IDE,spark-2.4.3',
	`key_id` BIGINT(20) NOT NULL COMMENT 'id of linkis_ps_configuration_config_key',
    `config_value` VARCHAR(200) NULL DEFAULT NULL COMMENT '配置值',
    `max_value` VARCHAR(50) NULL DEFAULT NULL COMMENT '上限值',
    `min_value` VARCHAR(50) NULL DEFAULT NULL COMMENT '下限值（预留）',
	`latest_update_template_uuid` VARCHAR(36) NOT NULL COMMENT 'uuid  第三方侧记录的模板id',
	`is_valid` VARCHAR(2)  DEFAULT 'Y' COMMENT '是否有效 预留 Y/N',
	`create_by` VARCHAR(50) NOT NULL COMMENT '创建人',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'create time',
	`update_by` VARCHAR(50) NULL DEFAULT NULL COMMENT '更新人',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'update time',
	PRIMARY KEY (`id`),
	UNIQUE INDEX `uniq_com_label_kid` (`combined_label_value`, `key_id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;



-- ----------------------------
-- Table structure for linkis_org_user_sync
-- ----------------------------
DROP TABLE IF EXISTS `linkis_org_user_sync`;
CREATE TABLE `linkis_org_user_sync` (
   `cluster_code` varchar(16) COMMENT '集群',
   `user_type` varchar(64) COMMENT '用户类型',
   `user_name` varchar(128) COMMENT '授权用户',
   `org_id` varchar(16) COMMENT '部门ID',
   `org_name` varchar(64) COMMENT '部门名字',
   `queue_name` varchar(64) COMMENT '默认资源队列',
   `db_name` varchar(64) COMMENT '默认操作数据库',
   `interface_user` varchar(64) COMMENT '接口人',
   `is_union_analyse` varchar(64) COMMENT '是否联合分析人',
   `create_time` varchar(64) COMMENT '用户创建时间',
   `user_itsm_no` varchar(64) COMMENT '用户创建单号',
   PRIMARY KEY (`user_name`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE=utf8mb4_bin COMMENT ='用户部门统计INC表';

-- ----------------------------
-- Table structure for linkis_cg_tenant_department_config
-- ----------------------------
DROP TABLE IF EXISTS `linkis_cg_tenant_department_config`;
CREATE TABLE `linkis_cg_tenant_department_config` (
  `id` int(20) NOT NULL AUTO_INCREMENT  COMMENT 'ID',
  `creator` varchar(50) COLLATE utf8_bin NOT NULL  COMMENT '应用',
  `department` varchar(64) COLLATE utf8_bin NOT NULL  COMMENT '部门名称',
  `department_id` varchar(16) COLLATE utf8_bin NOT NULL COMMENT '部门ID',
  `tenant_value` varchar(128) COLLATE utf8_bin NOT NULL  COMMENT '部门租户标签',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP  COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP  COMMENT '更新时间',
  `create_by` varchar(50) COLLATE utf8_bin NOT NULL  COMMENT '创建用户',
  `is_valid` varchar(1) COLLATE utf8_bin NOT NULL DEFAULT 'Y' COMMENT '是否有效',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_creator_department` (`creator`,`department`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_mg_gateway_whitelist_config
-- ----------------------------
DROP TABLE IF EXISTS `linkis_mg_gateway_whitelist_config`;
CREATE TABLE `linkis_mg_gateway_whitelist_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `allowed_user` varchar(128) COLLATE utf8_bin NOT NULL,
  `client_address` varchar(128) COLLATE utf8_bin NOT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `address_uniq` (`allowed_user`, `client_address`),
  KEY `linkis_mg_gateway_whitelist_config_allowed_user` (`allowed_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_mg_gateway_whitelist_sensitive_user
-- ----------------------------
DROP TABLE IF EXISTS `linkis_mg_gateway_whitelist_sensitive_user`;
CREATE TABLE `linkis_mg_gateway_whitelist_sensitive_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sensitive_username` varchar(128) COLLATE utf8_bin NOT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sensitive_username` (`sensitive_username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- ----------------------------
-- Table structure for linkis_ps_python_module_info
-- ----------------------------
DROP TABLE IF EXISTS `linkis_ps_python_module_info`;
CREATE TABLE `linkis_ps_python_module_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `name` varchar(255) NOT NULL COMMENT 'python模块名称',
  `description` text COMMENT 'python模块描述',
  `path` varchar(255) NOT NULL COMMENT 'hdfs路径',
  `engine_type` varchar(50) NOT NULL COMMENT '引擎类型，python/spark/all',
  `create_user` varchar(50) NOT NULL COMMENT '创建用户',
  `update_user` varchar(50) NOT NULL COMMENT '修改用户',
  `is_load` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否加载，0-未加载，1-已加载',
  `is_expire` tinyint(1) DEFAULT NULL COMMENT '是否过期，0-未过期，1-已过期）',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='Python模块包信息表';
/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */



SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

-- 变量：
SET @SPARK_LABEL="spark-3.2.1";
SET @HIVE_LABEL="hive-3.1.3";
SET @PYTHON_LABEL="python-python2";
SET @PIPELINE_LABEL="pipeline-1";
SET @JDBC_LABEL="jdbc-4";
SET @PRESTO_LABEL="presto-0.234";
SET @TRINO_LABEL="trino-371";
SET @IO_FILE_LABEL="io_file-1.0";
SET @OPENLOOKENG_LABEL="openlookeng-1.5.0";
SET @ELASTICSEARCH_LABEL="elasticsearch-7.6.2";
SET @NEBULA_LABEL="nebula-3.0.0";

-- 衍生变量：
SET @SPARK_ALL=CONCAT('*-*,',@SPARK_LABEL);
SET @SPARK_IDE=CONCAT('*-IDE,',@SPARK_LABEL);
SET @SPARK_NODE=CONCAT('*-nodeexecution,',@SPARK_LABEL);
SET @SPARK_VISUALIS=CONCAT('*-Visualis,',@SPARK_LABEL);

SET @HIVE_ALL=CONCAT('*-*,',@HIVE_LABEL);
SET @HIVE_IDE=CONCAT('*-IDE,',@HIVE_LABEL);
SET @HIVE_NODE=CONCAT('*-nodeexecution,',@HIVE_LABEL);

SET @PYTHON_ALL=CONCAT('*-*,',@PYTHON_LABEL);
SET @PYTHON_IDE=CONCAT('*-IDE,',@PYTHON_LABEL);
SET @PYTHON_NODE=CONCAT('*-nodeexecution,',@PYTHON_LABEL);

SET @PIPELINE_ALL=CONCAT('*-*,',@PIPELINE_LABEL);
SET @PIPELINE_IDE=CONCAT('*-IDE,',@PIPELINE_LABEL);

SET @JDBC_ALL=CONCAT('*-*,',@JDBC_LABEL);
SET @JDBC_IDE=CONCAT('*-IDE,',@JDBC_LABEL);

SET @PRESTO_ALL=CONCAT('*-*,',@PRESTO_LABEL);
SET @PRESTO_IDE=CONCAT('*-IDE,',@PRESTO_LABEL);

SET @IO_FILE_ALL=CONCAT('*-*,',@IO_FILE_LABEL);
SET @IO_FILE_IDE=CONCAT('*-IDE,',@IO_FILE_LABEL);

SET @OPENLOOKENG_ALL=CONCAT('*-*,',@OPENLOOKENG_LABEL);
SET @OPENLOOKENG_IDE=CONCAT('*-IDE,',@OPENLOOKENG_LABEL);

SET @TRINO_ALL=CONCAT('*-*,',@TRINO_LABEL);
SET @TRINO_IDE=CONCAT('*-IDE,',@TRINO_LABEL);

SET @IO_FILE_ALL=CONCAT('*-*,',@IO_FILE_LABEL);
SET @IO_FILE_IDE=CONCAT('*-IDE,',@IO_FILE_LABEL);

SET @ELASTICSEARCH_ALL=CONCAT('*-*,',@ELASTICSEARCH_LABEL);
SET @ELASTICSEARCH_IDE=CONCAT('*-IDE,',@ELASTICSEARCH_LABEL);

SET @NEBULA_ALL=CONCAT('*-*,',@NEBULA_LABEL);
SET @NEBULA_IDE=CONCAT('*-IDE,',@NEBULA_LABEL);

-- Global Settings
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.rm.yarnqueue', 'yarn队列名', 'yarn队列名', 'default', 'None', NULL, '0', '0', '1', '队列资源');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.rm.yarnqueue.instance.max', '取值范围：1-128，单位：个', '队列实例最大个数', '30', 'Regex', '^(?:[1-9]\\d?|[1234]\\d{2}|128)$', '0', '0', '1', '队列资源');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.rm.yarnqueue.cores.max', '取值范围：1-4000，单位：个', '队列CPU使用上限', '150', 'Regex', '^(?:[1-9]\\d{0,2}|[1-3]\\d{3}|4000)$', '0', '0', '1', '队列资源');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.rm.yarnqueue.memory.max', '取值范围：1-10000，单位：G', '队列内存使用上限', '300G', 'Regex', '^(?:[1-9]\\d{0,3}|10000)(G|g)$', '0', '0', '1', '队列资源');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.rm.client.memory.max', '取值范围：1-100，单位：G', '全局各个引擎内存使用上限', '20G', 'Regex', '^([1-9]\\d{0,1}|100)(G|g)$', '0', '0', '1', '队列资源');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.rm.client.core.max', '取值范围：1-128，单位：个', '全局各个引擎核心个数上限', '10', 'Regex', '^(?:[1-9]\\d?|[1][0-2][0-8])$', '0', '0', '1', '队列资源');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.rm.instance', '范围：1-20，单位：个', '全局各个引擎最大并发数', '10', 'NumInterval', '[1,20]', '0', '0', '1', '队列资源');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`, `boundary_type`, `en_description`, `en_name`, `en_treeName`, `template_required`) VALUES ('linkis.entrance.creator.job.concurrency.limit', 'Creator级别限制，范围：1-10000，单位：个', 'Creator最大并发数', '10000', 'NumInterval', '[1,10000]', '', 0, 1, 1, '队列资源', 3, 'creator maximum task limit', 'creator maximum task limit', 'QueueResources', '1');
-- spark
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`, `template_required`) VALUES ('wds.linkis.rm.instance', '范围：1-20，单位：个', 'spark引擎最大并发数', '10', 'NumInterval', '[1,20]', '0', '0', '1', '队列资源', 'spark', '1');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`, `template_required`) VALUES ('spark.executor.instances', '取值范围：1-40，单位：个', 'spark执行器实例最大并发数', '1', 'NumInterval', '[1,40]', '0', '0', '2', 'spark资源设置', 'spark', '1');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('spark.executor.cores', '取值范围：1-8，单位：个', 'spark执行器核心个数',  '1', 'NumInterval', '[1,8]', '0', '0', '1','spark资源设置', 'spark');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`, `template_required`) VALUES ('spark.executor.memory', '取值范围：1-28，单位：G', 'spark执行器内存大小', '1g', 'Regex', '^([1-9]|1[0-9]|2[0-8])(G|g)$', '0', '0', '3', 'spark资源设置', 'spark', '1');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('spark.driver.cores', '取值范围：只能取1，单位：个', 'spark驱动器核心个数', '1', 'NumInterval', '[1,1]', '0', '1', '1', 'spark资源设置','spark');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`, `template_required`) VALUES ('spark.driver.memory', '取值范围：1-15，单位：G', 'spark驱动器内存大小','1g', 'Regex', '^([1-9]|1[0-5])(G|g)$', '0', '0', '1', 'spark资源设置', 'spark', '1');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.engineconn.max.free.time', '取值范围：3m,15m,30m,1h,2h,6h,12h', '引擎空闲退出时间','1h', 'OFT', '[\"1h\",\"2h\",\"6h\",\"12h\",\"30m\",\"15m\",\"3m\"]', '0', '0', '1', 'spark引擎设置', 'spark');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('spark.python.version', '取值范围：python2,python3', 'python版本','python2', 'OFT', '[\"python3\",\"python2\"]', '0', '0', '1', 'spark引擎设置', 'spark');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`, `boundary_type`, `en_treeName`, `en_description`, `en_name`) VALUES ('spark.conf', '多个参数使用分号[;]分隔 例如spark.shuffle.compress=true;', 'spark自定义配置参数',null, 'None', NULL, 'spark',0, 1, 1,'spark资源设置', 0, 'Spark Resource Settings','Multiple parameters are separated by semicolons [;] For example, spark.shuffle.compress=true;', 'Spark Custom Configuration Parameters');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`, `boundary_type`, `en_treeName`, `en_description`, `en_name`) VALUES ('spark.locality.wait', '范围：0-3，单位：秒', '任务调度本地等待时间', '3s', 'OFT', '[\"0s\",\"1s\",\"2s\",\"3s\"]', 'spark', 0, 1, 1, 'spark资源设置', 0, 'Spark Resource Settings', 'Range: 0-3, Unit: second', 'Task Scheduling Local Waiting Time');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`, `boundary_type`, `en_treeName`, `en_description`, `en_name`) VALUES ('spark.memory.fraction', '范围：0.4,0.5,0.6，单位：百分比', '执行内存和存储内存的百分比', '0.6', 'OFT', '[\"0.4\",\"0.5\",\"0.6\"]', 'spark', 0, 1, 1, 'spark资源设置', 0, 'Spark Resource Settings', 'Range: 0.4, 0.5, 0.6, in percentage', 'Percentage Of Execution Memory And Storage Memory');

-- hive
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`, `template_required`) VALUES ('wds.linkis.rm.instance', '范围：1-20，单位：个', 'hive引擎最大并发数', '10', 'NumInterval', '[1,20]', '0', '0', '1', '队列资源', 'hive', '1');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`, `template_required`) VALUES ('wds.linkis.engineconn.java.driver.memory', '取值范围：1-10，单位：G', 'hive引擎初始化内存大小','1g', 'Regex', '^([1-9]|10)(G|g)$', '0', '0', '1', 'hive引擎设置', 'hive', '1');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('hive.client.java.opts', 'hive客户端进程参数', 'hive引擎启动时jvm参数','', 'None', NULL, '1', '1', '1', 'hive引擎设置', 'hive');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.engineconn.max.free.time', '取值范围：3m,15m,30m,1h,2h', '引擎空闲退出时间','1h', 'OFT', '[\"1h\",\"2h\",\"30m\",\"15m\",\"3m\"]', '0', '0', '1', 'hive引擎设置', 'hive');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`,`en_description`, `en_name`, `en_treeName`, `template_required`) VALUES ("mapreduce.job.running.reduce.limit", '范围：10-999，单位：个', 'hive引擎reduce限制', '999', 'NumInterval', '[10,999]', '0', '1', '1', 'MapReduce设置', 'hive','Value Range: 10-999, Unit: Piece', 'Number Limit Of MapReduce Job Running Reduce', 'MapReduce Settings', '1');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`,`en_description`, `en_name`, `en_treeName`, `template_required`) VALUES ('mapreduce.job.reduce.slowstart.completedmaps', '取值范围：0-1', 'Map任务数与总Map任务数之间的比例','0.05', 'Regex', '^(0(\\.\\d{1,2})?|1(\\.0{1,2})?)$', '0', '0', '1', 'hive引擎设置', 'hive', 'Value Range: 0-1', 'The Ratio Between The Number Of Map Tasks And The Total Number Of Map Tasks', 'Hive Engine Settings', '1');
-- python
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.rm.client.memory.max', '取值范围：1-100，单位：G', 'python驱动器内存使用上限', '20G', 'Regex', '^([1-9]\\d{0,1}|100)(G|g)$', '0', '0', '1', '队列资源', 'python');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.rm.client.core.max', '取值范围：1-128，单位：个', 'python驱动器核心个数上限', '10', 'Regex', '^(?:[1-9]\\d?|[1234]\\d{2}|128)$', '0', '0', '1', '队列资源', 'python');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.rm.instance', '范围：1-20，单位：个', 'python引擎最大并发数', '10', 'NumInterval', '[1,20]', '0', '0', '1', '队列资源', 'python');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.engineconn.java.driver.memory', '取值范围：1-2，单位：G', 'python引擎初始化内存大小', '1g', 'Regex', '^([1-2])(G|g)$', '0', '0', '1', 'python引擎设置', 'python');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('python.version', '取值范围：python2,python3', 'python版本','python2', 'OFT', '[\"python3\",\"python2\"]', '0', '0', '1', 'python引擎设置', 'python');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.engineconn.max.free.time', '取值范围：3m,15m,30m,1h,2h', '引擎空闲退出时间','1h', 'OFT', '[\"1h\",\"2h\",\"30m\",\"15m\",\"3m\"]', '0', '0', '1', 'python引擎设置', 'python');

-- pipeline
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('pipeline.output.mold', '取值范围：csv或excel', '结果集导出类型','csv', 'OFT', '[\"csv\",\"excel\"]', '0', '0', '1', 'pipeline引擎设置', 'pipeline');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('pipeline.field.split', '取值范围：,或\\t或;或|', 'csv分隔符',',', 'OFT', '[\",\",\"\\\\t\",\"\\\\;\",\"\\\\|\"]', '0', '0', '1', 'pipeline引擎设置', 'pipeline');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('pipeline.output.charset', '取值范围：utf-8或gbk', '结果集导出字符集','gbk', 'OFT', '[\"utf-8\",\"gbk\"]', '0', '0', '1', 'pipeline引擎设置', 'pipeline');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('pipeline.output.isoverwrite', '取值范围：true或false', '是否覆写','true', 'OFT', '[\"true\",\"false\"]', '0', '0', '1', 'pipeline引擎设置', 'pipeline');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.rm.instance', '范围：1-3，单位：个', 'pipeline引擎最大并发数','3', 'NumInterval', '[1,3]', '0', '0', '1', 'pipeline引擎设置', 'pipeline');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.engineconn.java.driver.memory', '取值范围：1-10，单位：G', 'pipeline引擎初始化内存大小','2g', 'Regex', '^([1-9]|10)(G|g)$', '0', '0', '1', 'pipeline资源设置', 'pipeline');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('pipeline.output.shuffle.null.type', '取值范围：NULL或者BLANK', '空值替换','NULL', 'OFT', '[\"NULL\",\"BLANK\"]', '0', '0', '1', 'pipeline引擎设置', 'pipeline');
-- jdbc
insert into `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.jdbc.connect.url', '例如:jdbc:mysql://127.0.0.1:10000', 'jdbc连接地址', 'jdbc:mysql://127.0.0.1:10000', 'Regex', '^\\s*jdbc:\\w+://([^:]+)(:\\d+)(/[^\\?]+)?(\\?\\S*)?$', '0', '0', '1', '数据源配置', 'jdbc');
insert into `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.jdbc.driver', '例如:com.mysql.jdbc.Driver', 'jdbc连接驱动', '', 'None', '', '0', '0', '1', '用户配置', 'jdbc');
insert into `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.jdbc.version', '取值范围：jdbc3,jdbc4', 'jdbc版本','jdbc4', 'OFT', '[\"jdbc3\",\"jdbc4\"]', '0', '0', '1', '用户配置', 'jdbc');
insert into `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.jdbc.username', 'username', '数据库连接用户名', '', 'None', '', '0', '0', '1', '用户配置', 'jdbc');
insert into `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.jdbc.password', 'password', '数据库连接密码', '', 'None', '', '0', '0', '1', '用户配置', 'jdbc');
insert into `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.jdbc.connect.max', '范围：1-20，单位：个', 'jdbc引擎最大连接数', '10', 'NumInterval', '[1,20]', '0', '0', '1', '数据源配置', 'jdbc');

-- io_file
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.rm.instance', '范围：1-20，单位：个', 'io_file引擎最大并发数', '10', 'NumInterval', '[1,20]', '0', '0', '1', 'io_file引擎资源上限', 'io_file');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.rm.client.memory.max', '取值范围：1-50，单位：G', 'io_file引擎最大内存', '20G', 'Regex', '^([1-9]\\d{0,1}|100)(G|g)$', '0', '0', '1', 'io_file引擎资源上限', 'io_file');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `is_hidden`, `is_advanced`, `level`, `treeName`, `engine_conn_type`) VALUES ('wds.linkis.rm.client.core.max', '取值范围：1-100，单位：个', 'io_file引擎最大核心数', '40', 'Regex', '^(?:[1-9]\\d?|[1234]\\d{2}|128)$', '0', '0', '1', 'io_file引擎资源上限', 'io_file');

-- openlookeng
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.openlookeng.url', '例如:http://127.0.0.1:8080', '连接地址', 'http://127.0.0.1:8080', 'Regex', '^\\s*http://([^:]+)(:\\d+)(/[^\\?]+)?(\\?\\S*)?$', 'openlookeng', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.openlookeng.catalog', 'catalog', 'catalog', 'system', 'None', '', 'openlookeng', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.openlookeng.source', 'source', 'source', 'global', 'None', '', 'openlookeng', 0, 0, 1, '数据源配置');

-- elasticsearch
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.cluster', '例如:http://127.0.0.1:9200', '连接地址', 'http://127.0.0.1:9200', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.datasource', '连接别名', '连接别名', 'hadoop', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.username', 'username', 'ES集群用户名', '无', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.password', 'password', 'ES集群密码', '无', 'None', '','elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.auth.cache', '客户端是否缓存认证', '客户端是否缓存认证', 'false', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.sniffer.enable', '客户端是否开启 sniffer', '客户端是否开启 sniffer', 'false', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.http.method', '调用方式', 'HTTP请求方式', 'GET', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.http.endpoint', '/_search', 'JSON 脚本调用的 Endpoint', '/_search', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.sql.endpoint', '/_sql', 'SQL 脚本调用的 Endpoint', '/_sql', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.sql.format', 'SQL 脚本调用的模板，%s 替换成 SQL 作为请求体请求Es 集群', '请求体', '{"query":"%s"}', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.es.headers.*', '客户端 Headers 配置', '客户端 Headers 配置', '无', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.engineconn.concurrent.limit', '引擎最大并发', '引擎最大并发', '100', 'None', '', 'elasticsearch', 0, 0, 1, '数据源配置');

-- presto
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.presto.url', 'Presto 集群连接', 'presto连接地址', 'http://127.0.0.1:8080', 'None', NULL, 'presto', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.presto.catalog', '查询的 Catalog ', 'presto连接的catalog', 'hive', 'None', NULL, 'presto', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.presto.schema', '查询的 Schema ', '数据库连接schema', '', 'None', NULL, 'presto', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('wds.linkis.presto.source', '查询使用的 source ', '数据库连接source', '', 'None', NULL, 'presto', 0, 0, 1, '数据源配置');

-- trino
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.default.limit', '查询的结果集返回条数限制', '结果集条数限制', '5000', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.http.connectTimeout', '连接Trino服务器的超时时间', '连接超时时间（秒）', '60', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.http.readTimeout', '等待Trino服务器返回数据的超时时间', '传输超时时间（秒）', '60', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.resultSet.cache.max', 'Trino结果集缓冲区大小', '结果集缓冲区', '512k', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.url', 'Trino服务器URL', 'Trino服务器URL', 'http://127.0.0.1:9401', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.user', '用于连接Trino查询服务的用户名', '用户名', 'null', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.password', '用于连接Trino查询服务的密码', '密码', 'null', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.passwordCmd', '用于连接Trino查询服务的密码回调命令', '密码回调命令', 'null', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.catalog', '连接Trino查询时使用的catalog', 'Catalog', 'system', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.schema', '连接Trino查询服务的默认schema', 'Schema', '', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.ssl.insecured', '是否忽略服务器的SSL证书', '验证SSL证书', 'false', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.engineconn.concurrent.limit', '引擎最大并发', '引擎最大并发', '100', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.ssl.keystore', 'Trino服务器SSL keystore路径', 'keystore路径', 'null', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.ssl.keystore.type', 'Trino服务器SSL keystore类型', 'keystore类型', 'null', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.ssl.keystore.password', 'Trino服务器SSL keystore密码', 'keystore密码', 'null', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.ssl.truststore', 'Trino服务器SSL truststore路径', 'truststore路径', 'null', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.ssl.truststore.type', 'Trino服务器SSL truststore类型', 'truststore类型', 'null', 'None', '', 'trino', 0, 0, 1, '数据源配置');
INSERT INTO `linkis_ps_configuration_config_key` (`key`, `description`, `name`, `default_value`, `validate_type`, `validate_range`, `engine_conn_type`, `is_hidden`, `is_advanced`, `level`, `treeName`) VALUES ('linkis.trino.ssl.truststore.password', 'Trino服务器SSL truststore密码', 'truststore密码', 'null', 'None', '', 'trino', 0, 0, 1, '数据源配置');

-- nebula
INSERT INTO `linkis_ps_configuration_config_key` (`key`,description,name,default_value,validate_type,validate_range,engine_conn_type,is_hidden,is_advanced,`level`,treeName,boundary_type,en_treeName,en_description,en_name,template_required) VALUES
('linkis.nebula.host','Nebula 连接地址','Nebula 连接地址',NULL,'None',NULL,'nebula',0,0,1,'Necula引擎设置',0,'Nebula Engine Settings','Nebula Host','Nebula Host',0);
INSERT INTO `linkis_ps_configuration_config_key` (`key`,description,name,default_value,validate_type,validate_range,engine_conn_type,is_hidden,is_advanced,`level`,treeName,boundary_type,en_treeName,en_description,en_name,template_required) VALUES
('linkis.nebula.port','Nebula 连接端口','Nebula 连接端口',NULL,'None',NULL,'nebula',0,0,1,'Necula引擎设置',0,'Nebula Engine Settings','Nebula Port','Nebula Port',0);
INSERT INTO `linkis_ps_configuration_config_key` (`key`,description,name,default_value,validate_type,validate_range,engine_conn_type,is_hidden,is_advanced,`level`,treeName,boundary_type,en_treeName,en_description,en_name,template_required) VALUES
('linkis.nebula.username','Nebula 连接用户名','Nebula 连接用户名',NULL,'None',NULL,'nebula',0,0,1,'Necula引擎设置',0,'Nebula Engine Settings','Nebula Username','Nebula Username',0);
INSERT INTO `linkis_ps_configuration_config_key` (`key`,description,name,default_value,validate_type,validate_range,engine_conn_type,is_hidden,is_advanced,`level`,treeName,boundary_type,en_treeName,en_description,en_name,template_required) VALUES
('linkis.nebula.password','Nebula 连接密码','Nebula 连接密码',NULL,'None',NULL,'nebula',0,0,1,'Necula引擎设置',0,'Nebula Engine Settings','Nebula Password','Nebula Password',0);
INSERT INTO `linkis_ps_configuration_config_key` (`key`,description,name,default_value,validate_type,validate_range,engine_conn_type,is_hidden,is_advanced,`level`,treeName,boundary_type,en_treeName,en_description,en_name,template_required) VALUES
('linkis.nebula.space', 'Nebula 图空间', 'Nebula 图空间', NULL, 'None', NULL, 'nebula', 0, 0, 1, 'Necula引擎设置', 0, 'Nebula Engine Settings', 'Nebula Space', 'Nebula Space', 0);

-- Configuration first level directory
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType','*-全局设置,*-*', 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType','*-IDE,*-*', 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType','*-Visualis,*-*', 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType','*-nodeexecution,*-*', 'OPTIONAL', 2, now(), now());


-- Engine level default configuration
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType','*-*,*-*', 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@SPARK_ALL, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@HIVE_ALL, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@PYTHON_ALL, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@PIPELINE_ALL, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@JDBC_ALL, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@OPENLOOKENG_ALL, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType', @ELASTICSEARCH_ALL, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType', @PRESTO_ALL, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType', @TRINO_ALL, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType', @NEBULA_IDE,'OPTIONAL',2,now(),now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType', @NEBULA_ALL,'OPTIONAL',2,now(),now());
-- Custom correlation engine (e.g. spark) and configKey value
-- Global Settings
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = '' and label.label_value = "*-*,*-*");

-- spark(Here choose to associate all spark type Key values with spark)
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'spark' and label.label_value = @SPARK_ALL);

-- hive
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'hive' and label_value = @HIVE_ALL);

-- python-python2
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'python' and label_value = @PYTHON_ALL);

-- pipeline-*
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'pipeline' and label_value = @PIPELINE_ALL);

-- jdbc-4
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'jdbc' and label_value = @JDBC_ALL);

-- io_file-1.0
INSERT INTO `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(SELECT config.id AS `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'io_file' and label_value = @IO_FILE_ALL);

-- openlookeng-*
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'openlookeng' and label_value = @OPENLOOKENG_ALL);

-- elasticsearch-7.6.2
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'elasticsearch' and label_value = @ELASTICSEARCH_ALL);

-- presto-0.234
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as `config_key_id`, label.id AS `engine_type_label_id` FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'presto' and label_value = @PRESTO_ALL);


-- trino-371
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as config_key_id, label.id AS engine_type_label_id FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'trino' and label_value = @TRINO_ALL);

-- nebula-3.0.0
insert into `linkis_ps_configuration_key_engine_relation` (`config_key_id`, `engine_type_label_id`)
(select config.id as config_key_id, label.id AS engine_type_label_id FROM linkis_ps_configuration_config_key config
INNER JOIN linkis_cg_manager_label label ON config.engine_conn_type = 'nebula' and label_value = @NEBULA_ALL);

-- If you need to customize the parameters of the new engine, the following configuration does not need to write SQL initialization
-- Just write the SQL above, and then add applications and engines to the management console to automatically initialize the configuration


-- Configuration secondary directory (creator level default configuration)
-- IDE
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@SPARK_IDE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@HIVE_IDE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@PYTHON_IDE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@PIPELINE_IDE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@JDBC_IDE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@OPENLOOKENG_IDE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType', @ELASTICSEARCH_IDE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType', @PRESTO_IDE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType', @TRINO_IDE, 'OPTIONAL', 2, now(), now());

-- Visualis
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@SPARK_VISUALIS, 'OPTIONAL', 2, now(), now());
-- nodeexecution
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@SPARK_NODE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@HIVE_NODE, 'OPTIONAL', 2, now(), now());
insert into `linkis_cg_manager_label` (`label_key`, `label_value`, `label_feature`, `label_value_size`, `update_time`, `create_time`) VALUES ('combined_userCreator_engineType',@PYTHON_NODE, 'OPTIONAL', 2, now(), now());


-- Associate first-level and second-level directories
select @label_id := id from linkis_cg_manager_label where `label_value` = '*-全局设置,*-*';
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 1);

select @label_id := id from linkis_cg_manager_label where `label_value` = '*-IDE,*-*';
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 1);

select @label_id := id from linkis_cg_manager_label where `label_value` = '*-Visualis,*-*';
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 1);

select @label_id := id from linkis_cg_manager_label where `label_value` = '*-nodeexecution,*-*';
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 1);

select @label_id := id from linkis_cg_manager_label where `label_value` = @SPARK_IDE;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

select @label_id := id from linkis_cg_manager_label where `label_value` = @HIVE_IDE;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

select @label_id := id from linkis_cg_manager_label where `label_value` = @PYTHON_IDE;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

select @label_id := id from linkis_cg_manager_label where `label_value` = @PIPELINE_IDE;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

select @label_id := id from linkis_cg_manager_label where `label_value` = @JDBC_IDE;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

select @label_id := id from linkis_cg_manager_label where `label_value` = @OPENLOOKENG_IDE;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

select @label_id := id from linkis_cg_manager_label where `label_value` =  @SPARK_VISUALIS;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

select @label_id := id from linkis_cg_manager_label where `label_value` = @SPARK_NODE;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

select @label_id := id from linkis_cg_manager_label where `label_value` = @HIVE_NODE;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

select @label_id := id from linkis_cg_manager_label where `label_value` = @PYTHON_NODE;
insert into linkis_ps_configuration_category (`label_id`, `level`) VALUES (@label_id, 2);

-- Associate label and default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select `relation`.`config_key_id` AS `config_key_id`, '' AS `config_value`, `relation`.`engine_type_label_id` AS `config_label_id` FROM linkis_ps_configuration_key_engine_relation relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = '*-*,*-*');

-- spark default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select `relation`.`config_key_id` AS `config_key_id`, '' AS `config_value`, `relation`.`engine_type_label_id` AS `config_label_id` FROM linkis_ps_configuration_key_engine_relation relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @SPARK_ALL);

-- hive default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select `relation`.`config_key_id` AS `config_key_id`, '' AS `config_value`, `relation`.`engine_type_label_id` AS `config_label_id` FROM linkis_ps_configuration_key_engine_relation relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @HIVE_ALL);

-- python default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select `relation`.`config_key_id` AS `config_key_id`, '' AS `config_value`, `relation`.`engine_type_label_id` AS `config_label_id` FROM linkis_ps_configuration_key_engine_relation relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @PYTHON_ALL);

-- pipeline default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select `relation`.`config_key_id` AS `config_key_id`, '' AS `config_value`, `relation`.`engine_type_label_id` AS `config_label_id` FROM linkis_ps_configuration_key_engine_relation relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @PIPELINE_ALL);

-- jdbc default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select `relation`.`config_key_id` AS `config_key_id`, '' AS `config_value`, `relation`.`engine_type_label_id` AS `config_label_id` FROM linkis_ps_configuration_key_engine_relation relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @JDBC_ALL);

-- openlookeng default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select `relation`.`config_key_id` AS `config_key_id`, '' AS `config_value`, `relation`.`engine_type_label_id` AS `config_label_id` FROM linkis_ps_configuration_key_engine_relation relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @OPENLOOKENG_ALL);

-- elasticsearch default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select `relation`.`config_key_id` AS `config_key_id`, '' AS `config_value`, `relation`.`engine_type_label_id` AS `config_label_id` FROM linkis_ps_configuration_key_engine_relation relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @ELASTICSEARCH_ALL);

-- presto default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select `relation`.`config_key_id` AS `config_key_id`, '' AS `config_value`, `relation`.`engine_type_label_id` AS `config_label_id` FROM linkis_ps_configuration_key_engine_relation relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @PRESTO_ALL);

-- trino default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select relation.config_key_id AS config_key_id, '' AS config_value, relation.engine_type_label_id AS config_label_id FROM `linkis_ps_configuration_key_engine_relation` relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @TRINO_ALL);


-- nebula default configuration
insert into `linkis_ps_configuration_config_value` (`config_key_id`, `config_value`, `config_label_id`)
(select relation.config_key_id AS config_key_id, '' AS config_value, relation.engine_type_label_id AS config_label_id FROM `linkis_ps_configuration_key_engine_relation` relation
INNER JOIN linkis_cg_manager_label label ON relation.engine_type_label_id = label.id AND label.label_value = @NEBULA_ALL);

insert  into `linkis_cg_rm_external_resource_provider`(`id`,`resource_type`,`name`,`labels`,`config`) values
(1,'Yarn','default',NULL,'{"rmWebAddress":"@YARN_RESTFUL_URL","hadoopVersion":"@HADOOP_VERSION","authorEnable":@YARN_AUTH_ENABLE,"user":"@YARN_AUTH_USER","pwd":"@YARN_AUTH_PWD","kerberosEnable":@YARN_KERBEROS_ENABLE,"principalName":"@YARN_PRINCIPAL_NAME","keytabPath":"@YARN_KEYTAB_PATH","krb5Path":"@YARN_KRB5_PATH"}');

-- errorcode
-- 01 linkis server
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01001','您的任务没有路由到后台ECM，请联系管理员','The em of labels',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01002','任务运行内存超过设置内存限制，导致Linkis服务负载过高，请在管理台调整Driver内存或联系管理员扩容','Unexpected end of file from server',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01003','任务运行内存超过设置内存限制，导致Linkis服务负载过高，请在管理台调整Driver内存或联系管理员扩容','failed to ask linkis Manager Can be retried SocketTimeoutException',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01004','引擎在启动时被Kill，请联系管理员',' [0-9]+ Killed',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01005','请求Yarn获取队列信息重试2次仍失败，请联系管理员','Failed to request external resourceClassCastException',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01006','没有健康可用的ecm节点，可能任务量大,导致节点资源处于不健康状态，尝试kill空闲引擎释放资源','There are corresponding ECM tenant labels',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01007','文件编码格式异常,请联系管理人员处理','UnicodeEncodeError.*characters',0);

-- 11 linkis resource 12 user resource 13 user task resouce
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01101','ECM资源不足，请联系管理员扩容','ECM resources are insufficient',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01102','ECM 内存资源不足，可以设置更低的驱动内存','ECM memory resources are insufficient',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01103','ECM CPU资源不足，请联系管理员扩容','ECM CPU resources are insufficient',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01104','ECM 实例资源不足，请联系管理员扩容','ECM Insufficient number of instances',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('01105','机器内存不足，请联系管理员扩容','Cannot allocate memory',0);

INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12001','队列CPU资源不足，可以调整Spark执行器个数','Queue CPU resources are insufficient',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12002','队列内存资源不足，可以调整Spark执行器个数','Insufficient queue memory',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12003','队列实例数超过限制','Insufficient number of queue instances',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12004','全局驱动器内存使用上限，可以设置更低的驱动内存','Drive memory resources are insufficient',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12005','超出全局驱动器CPU个数上限，可以清理空闲引擎','Drive core resources are insufficient',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12006','超出引擎最大并发数上限，可以清理空闲引擎','Insufficient number of instances',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12008','获取Yarn队列信息异常,可能是您设置的yarn队列不存在','获取Yarn队列信息异常',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12009','会话创建失败，%s队列不存在，请检查队列设置是否正确','queue (\\S+) does not exist in YARN',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12010','集群队列内存资源不足，可以联系组内人员释放资源','Insufficient cluster queue memory',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12011','集群队列CPU资源不足，可以联系组内人员释放资源','Insufficient cluster queue cpu',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12012','集群队列实例数超过限制','Insufficient cluster queue instance',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12013','资源不足导致启动引擎超时，您可以进行任务重试','wait for DefaultEngineConn',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12014','请求引擎超时，可能是因为队列资源不足导致，请重试','wait for engineConn initial timeout',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('12015','您设置的执行器内存已经超过了集群的限定值%s，请减少到限定值以下','is above the max threshold (\\S+.+\\))',0);


INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13001','Java进程内存溢出，建议优化脚本内容','OutOfMemoryError',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13002','任务运行内存超过设置内存限制，请在管理台增加executor内存或在提交任务时通过spark.executor.memory或spark.executor.memoryOverhead调整内存','Container killed by YARN for exceeding memory limits',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13003','任务运行内存超过设置内存限制，请在管理台增加executor内存或调优sql后执行','read record exception',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13004','任务运行内存超过设置内存限制，导致引擎意外退出，请在管理台增加executor内存或在提交任务时通过spark.executor.memory或spark.executor.memoryOverhead调整内存','failed because the engine quitted unexpectedly',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13005','任务运行内存超过设置内存限制，导致Spark app应用退出，请在管理台增加driver内存或在提交任务时通过spark.driver.memory调整内存','Spark application has already stopped',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13006','任务运行内存超过设置内存限制，导致Spark context应用退出，请在管理台增加driver内存或在提交任务时通过spark.driver.memory调整内存','Spark application sc has already stopped',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13007','任务运行内存超过设置内存限制，导致Pyspark子进程退出，请在管理台增加executor内存或在提交任务时通过spark.executor.memory或spark.executor.memoryOverhead调整内存','Pyspark process  has stopped',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13008','任务产生的序列化结果总大小超过了配置的spark.driver.maxResultSize限制。请检查您的任务，看看是否有可能减小任务产生的结果大小，或则可以考虑压缩或合并结果，以减少传输的数据量','is bigger than spark.driver.maxResultSize',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13009','您的任务因为引擎退出（退出可能是引擎进程OOM或者主动kill引擎）导致失败','ERROR EC exits unexpectedly and actively kills the task',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13010','任务运行内存超过设置内存限制，请在管理台增加executor内存或在提交任务时通过spark.executor.memory或spark.executor.memoryOverhead调整内存','Container exited with a non-zero exit code',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13011','广播表过大导致driver内存溢出，请在执行sql前增加参数后重试：set spark.sql.autoBroadcastJoinThreshold=-1;','dataFrame to local exception',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13012','driver内存不足，请增加driver内存后重试','Failed to allocate a page (\\S+.*\\)), try again.',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('13013','使用spark默认变量sc导致后续代码执行失败','sc.setJobGroup(\\S+.*\\))',0);
-- 21 cluster Authority  22 db Authority
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('21001','会话创建失败，用户%s不能提交应用到队列：%s，请联系提供队列给您的人员','User (\\S+) cannot submit applications to queue ([A-Za-z._0-9]+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('21002','创建Python解释器失败，请联系管理员','initialize python executor failed',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('21003','创建单机Python解释器失败，请联系管理员','PythonSession process cannot be initialized',0);

INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22001','%s无权限访问，请申请开通数据表权限，请联系您的数据管理人员','Permission denied:\\s*user=[a-zA-Z0-9_]+[,，]\\s*access=[a-zA-Z0-9_]+\\s*[,，]\\s*inode="([a-zA-Z0-9/_\\.]+)"',0);
-- INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22002','您可能没有相关权限','Permission denied',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22003','所查库表无权限','Authorization failed:No privilege',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22004','用户%s在机器不存在，请确认是否申请了相关权限','user (\\S+) does not exist',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22005','用户在机器不存在，请确认是否申请了相关权限','engineConnExec.sh: Permission denied',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22006','用户在机器不存在，请确认是否申请了相关权限','at com.sun.security.auth.UnixPrincipal',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22007','用户在机器不存在，请确认是否申请了相关权限','LoginException: java.lang.NullPointerException: invalid null input: name',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22008','用户在机器不存在，请确认是否申请了相关权限','User not known to the underlying authentication module',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22009','用户组不存在','FileNotFoundException: /tmp/?',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('22010','用户组不存在','error looking up the name of group',0);

-- 30 Space exceeded 31 user operation
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('30001','库超过限制','is exceeded',0);

INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('31001','用户主动kill任务','is killed by user',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('31002','您提交的EngineTypeLabel没有对应的引擎版本','EngineConnPluginNotFoundException',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('30003','用户Token下发失败，请确认用户初始化是否成功。可联系BDP Hive运维处理','Auth failed for User',0);

-- 41 not exist 44 sql  43 python 44 shell 45 scala 46 importExport
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41001','数据库%s不存在，请检查引用的数据库是否有误','Database ''([a-zA-Z_0-9]+)'' not found',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41001','数据库%s不存在，请检查引用的数据库是否有误','Database does not exist: ([a-zA-Z_0-9]+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41002','表%s不存在，请检查引用的表是否有误','Table or view not found: ([`\\.a-zA-Z_0-9]+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41002','表%s不存在，请检查引用的表是否有误','Table not found ''([a-zA-Z_0-9]+)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41002','表%s不存在，请检查引用的表是否有误','Table ([a-zA-Z_0-9]+) not found',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41003','字段%s不存在，请检查引用的字段是否有误','cannot resolve ''`(.+)`'' given input columns',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41003','字段%s不存在，请检查引用的字段是否有误',' Invalid table alias or column reference ''(.+)'':',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41003','字段%s不存在，请检查引用的字段是否有误','Column ''(.+)'' cannot be resolved',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41004','分区字段%s不存在，请检查引用的表%s是否为分区表或分区字段有误','([a-zA-Z_0-9]+) is not a valid partition column in table ([`\\.a-zA-Z_0-9]+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41004','分区字段%s不存在，请检查引用的表是否为分区表或分区字段有误','Partition spec \\{(\\S+)\\} contains non-partition columns',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41004','分区字段%s不存在，请检查引用的表是否为分区表或分区字段有误','table is not partitioned but partition spec exists:\\{(.+)\\}',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41004','表对应的路径不存在，请联系您的数据管理人员','Path does not exist: viewfs',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('41005','文件%s不存在','Caused by:\\s*java.io.FileNotFoundException',0);

-- 42 sql
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42001','括号不匹配，请检查代码中括号是否前后匹配','extraneous input ''\\)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42002','非聚合函数%s必须写在group by中，请检查代码的group by语法','expression ''(\\S+)'' is neither present in the group by',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42002','非聚合函数%s必须写在group by中，请检查代码的group by语法','grouping expressions sequence is empty,\\s?and ''(\\S+)'' is not an aggregate function',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42002','非聚合函数%s必须写在group by中，请检查代码的group by语法','Expression not in GROUP BY key ''(\\S+)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42003','未知函数%s，请检查代码中引用的函数是否有误','Undefined function: ''(\\S+)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42003','未知函数%s，请检查代码中引用的函数是否有误','Invalid function ''(\\S+)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42004','字段%s存在名字冲突，请检查子查询内是否有同名字段','Reference ''(\\S+)'' is ambiguous',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42004','字段%s存在名字冲突，请检查子查询内是否有同名字段','Ambiguous column Reference ''(\\S+)'' in subquery',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42005','字段%s必须指定表或者子查询别名，请检查该字段来源','Column ''(\\S+)'' Found in more than One Tables/Subqueries',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42006','表%s在数据库%s中已经存在，请删除相应表后重试','Table or view ''(\\S+)'' already exists in database ''(\\S+)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42006','表%s在数据库中已经存在，请删除相应表后重试','Table (\\S+) already exists',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42006','表%s在数据库中已经存在，请删除相应表后重试','Table already exists',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42006','表%s在数据库中已经存在，请删除相应表后重试','AnalysisException: (\\S+) already exists',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42007','插入目标表字段数量不匹配,请检查代码！','requires that the data to be inserted have the same number of columns as the target table',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42008','数据类型不匹配，请检查代码！','due to data type mismatch: differing types in',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42009','字段%s引用有误，请检查字段是否存在！','Invalid column reference (\\S+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42010','字段%s提取数据失败','Can''t extract value from (\\S+): need',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42011','括号或者关键字不匹配，请检查代码！','mismatched input ''(\\S+)'' expecting',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42012','group by 位置2不在select列表中，请检查代码！','GROUP BY position (\\S+) is not in select list',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42013','字段提取数据失败请检查字段类型','Can''t extract value from (\\S+): need struct type but got string',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42014','插入数据未指定目标表字段%s，请检查代码！','Cannot insert into target table because column number/types are different ''(S+)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42015','表别名%s错误，请检查代码！','Invalid table alias ''(\\S+)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42016','UDF函数未指定参数，请检查代码！','UDFArgumentException Argument expected',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42017','聚合函数%s不能写在group by 中，请检查代码！','aggregate functions are not allowed in GROUP BY',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42018','您的代码有语法错误，请您修改代码之后执行','SemanticException Error in parsing',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42019','表不存在，请检查引用的表是否有误','table not found',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42020','函数使用错误，请检查您使用的函数方式','No matching method',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42021','您的sql代码可能有语法错误，请检查sql代码','FAILED: ParseException',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42022','您的sql代码可能有语法错误，请检查sql代码','org.apache.spark.sql.catalyst.parser.ParseException',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42022','您的sql代码可能有语法错误，请检查sql代码','org.apache.hadoop.hive.ql.parse.ParseException',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42023','聚合函数不能嵌套','aggregate function in the argument of another aggregate function',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42024','聚合函数不能嵌套','aggregate function parameters overlap with the aggregation',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42025','union 的左右查询字段不一致','Union can only be performed on tables',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42025','hql报错，union 的左右查询字段不一致','both sides of union should match',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42025','union左表和右表类型不一致','on first table and type',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42026','您的建表sql不能推断出列信息','Unable to infer the schema',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42027','动态分区的严格模式需要指定列，您可用通过设置set hive.exec.dynamic.partition.mode=nostrict','requires at least one static partition',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42028','函数输入参数有误','Invalid number of arguments for function',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42029','sql语法报错，select * 与group by无法一起使用','not allowed in select list when GROUP BY  ordinal',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42030','where/having子句之外不支持引用外部查询的表达式','the outer query are not supported outside of WHERE',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42031','sql语法报错，group by 后面不能跟一个表','show up in the GROUP BY list',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42032','hql报错，窗口函数中的字段重复','check for circular dependencies',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42033','sql中出现了相同的字段','Found duplicate column',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42034','sql语法不支持','not supported in current context',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42035','hql语法报错，嵌套子查询语法问题','Unsupported SubQuery Expression',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('42036','hql报错，子查询中in 用法有误','in definition of SubQuery',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43037','表字段类型修改导致的转型失败，请联系修改人员','cannot be cast to',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43038','select 的表可能有误','Invalid call to toAttribute on unresolved object',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43039','语法问题，请检查脚本','Distinct window functions are not supported',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43040','查询一定要指定数据源和库信息','Schema must be specified when session schema is not set',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43041','用户UDF函数 %s 加载失败，请检查后再执行','Invalid function (\\S+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43042','插入数据表动态分区数超过配置值 %s ，请优化sql或调整配置hive.exec.max.dynamic.partitions后重试','Maximum was set to (\\S+) partitions per node',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43043','执行任务消耗内存超过限制，hive任务请修改map或reduce的内存，spark任务请修改executor端内存','Error：java heap space',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43044','表 %s 分区数超过阈值 %s，需要分批删除分区，再删除表','the partitions of table (\\S+) exceeds threshold (\\S+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43045','查询/操作的表 %s 分区数为 %s ，超过阈值 %s ，需要限制查询/操作的分区数量','Number of partitions scanned \\(=(\\d+)\\) on table (\\S+) exceeds limit \\(=(\\d+)\\)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43046','动态分区一次性写入分区数 %s ，超过阈值  %s,请减少一次性写入的分区数','Number of dynamic partitions created is (\\S+), which is more than (\\S+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43047','动态分区一次性写入分区数 %s ，超过阈值  %s,请减少一次性写入的分区数','Maximum was set to (\\S+) partitions per node, number of dynamic partitions on this node: (\\S+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43048','参数引用错误，请检查参数 %s 是否正常引用','UnboundLocalError.*local variable (\\S+) referenced before assignment',0);
--  43 python
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43001','代码中存在NoneType空类型变量，请检查代码','''NoneType'' object',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43002','数组越界','IndexError:List index out of range',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43003','您的代码有语法错误，请您修改代码之后执行','SyntaxError',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43004','python代码变量%s未定义','name ''(\\S+)'' is not defined',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43005','python udf %s 未定义','Undefined function:s+''(\\S+)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43006','python执行不能将%s和%s两种类型进行连接','cannot concatenate ''(\\S+)'' and ''(\\S+)''',0);
-- INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43007','pyspark执行失败，可能是语法错误或stage失败','Py4JJavaError: An error occurred',0);
-- INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43008','python代码缩进对齐有误','unexpected indent',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43009','python代码缩进有误','unexpected indent',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43010','python代码反斜杠后面必须换行','unexpected character after line',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43011','导出Excel表超过最大限制1048575','Invalid row number',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43012','python save as table未指定格式，默认用parquet保存，hive查询报错','parquet.io.ParquetDecodingException',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43013','索引使用错误','IndexError',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43014','sql语法有问题','raise ParseException',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43015','python代码变量%s未定义','ImportError: ''(\\S+)''',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43015','当前节点需要的CS表解析失败，请检查当前CSID对应的CS表是否存在','Cannot parse cs table for node',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43016','模块 %s 没有属性 %s ，请确认代码引用是否正常','AttributeError: \'(\\S+)\' object has no attribute \'(\\S+)\'',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43017','存在参数无效或拼写错误，请确认 %s 参数正确性','KeyError: (.*)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43018','文件未找到，请确认该路径( %s )是否存在','FileNotFoundError.*No such file or directory\\:\\s\'(\\S+)\'',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43019','执行表在元数据库中存在meta缓存，meta信息与缓存不一致导致，请增加参数(--conf spark.sql.hive.convertMetastoreOrc=false)后重试','Unable to alter table.*Table is not allowed to be altered',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('43020','Python 进程已停止，查询失败！','python process has stopped',0);

-- 46 importExport
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('46001','找不到导入文件地址：%s','java.io.FileNotFoundException: (\\S+) \\(No such file or directory\\)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('46002','导出为excel时临时文件目录权限异常','java.io.IOException: Permission denied(.+)at org.apache.poi.xssf.streaming.SXSSFWorkbook.createAndRegisterSXSSFSheet',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('46003','导出文件时无法创建目录：%s','java.io.IOException: Mkdirs failed to create (\\S+) (.+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('46004','导入模块错误，系统没有%s模块，请联系运维人员安装','ImportError: No module named (\\S+)',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('46005','导出语句错误，请检查路径或命名','Illegal out script',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('46006','可能是并发访问同一个HDFS文件，导致Filesystem closed问题，尝试重试','java.io.IOException: Filesystem closed\\n\\s+(at org.apache.hadoop.hdfs.DFSClient.checkOpen)',0);
-- 47 tuning
-- INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('47001','诊断任务异常：%s，详细异常: %s','Tuning-Code: (\\S+), Tuning-Desc: (.+)',0);


-- 91 wtss
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('91001','找不到变量值，请确认您是否设置相关变量','not find variable substitution for',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('91002','不存在的代理用户，请检查你是否申请过平台层（bdp或者bdap）用户','failed to change current working directory ownership',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('91003','请检查提交用户在WTSS内是否有该代理用户的权限，代理用户中是否存在特殊字符，是否用错了代理用户，OS层面是否有该用户，系统设置里面是否设置了该用户为代理用户','没有权限执行当前任务',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('91004','平台层不存在您的执行用户，请在ITSM申请平台层（bdp或者bdap）用户','使用chown命令修改',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('91005','未配置代理用户，请在ITSM走WTSS用户变更单，为你的用户授权改代理用户','请联系系统管理员为您的用户添加该代理用户',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('91006','您的用户初始化有问题，请联系管理员','java: No such file or directory',0);
INSERT INTO linkis_ps_error_code (error_code,error_desc,error_regex,error_type) VALUES ('91007','JobServer中不存在您的脚本文件，请将你的脚本文件放入对应的JobServer路径中', 'Could not open input file for reading%does not exist',0);

-- ----------------------------
-- Default Tokens
-- ----------------------------
INSERT INTO `linkis_mg_gateway_auth_token`(`token_name`,`legal_users`,`legal_hosts`,`business_owner`,`create_time`,`update_time`,`elapse_day`,`update_by`) VALUES ('LINKIS-UNAVAILABLE-TOKEN','*','*','BDP',curdate(),curdate(),-1,'LINKIS');
INSERT INTO `linkis_mg_gateway_auth_token`(`token_name`,`legal_users`,`legal_hosts`,`business_owner`,`create_time`,`update_time`,`elapse_day`,`update_by`) VALUES ('WS-UNAVAILABLE-TOKEN','*','*','BDP',curdate(),curdate(),-1,'LINKIS');
INSERT INTO `linkis_mg_gateway_auth_token`(`token_name`,`legal_users`,`legal_hosts`,`business_owner`,`create_time`,`update_time`,`elapse_day`,`update_by`) VALUES ('DSS-UNAVAILABLE-TOKEN','*','*','BDP',curdate(),curdate(),-1,'LINKIS');
INSERT INTO `linkis_mg_gateway_auth_token`(`token_name`,`legal_users`,`legal_hosts`,`business_owner`,`create_time`,`update_time`,`elapse_day`,`update_by`) VALUES ('QUALITIS-UNAVAILABLE-TOKEN','*','*','BDP',curdate(),curdate(),-1,'LINKIS');
INSERT INTO `linkis_mg_gateway_auth_token`(`token_name`,`legal_users`,`legal_hosts`,`business_owner`,`create_time`,`update_time`,`elapse_day`,`update_by`) VALUES ('VALIDATOR-UNAVAILABLE-TOKEN','*','*','BDP',curdate(),curdate(),-1,'LINKIS');
INSERT INTO `linkis_mg_gateway_auth_token`(`token_name`,`legal_users`,`legal_hosts`,`business_owner`,`create_time`,`update_time`,`elapse_day`,`update_by`) VALUES ('LINKISCLI-UNAVAILABLE-TOKEN','*','*','BDP',curdate(),curdate(),-1,'LINKIS');
INSERT INTO `linkis_mg_gateway_auth_token`(`token_name`,`legal_users`,`legal_hosts`,`business_owner`,`create_time`,`update_time`,`elapse_day`,`update_by`) VALUES ('DSM-UNAVAILABLE-TOKEN','*','*','BDP',curdate(),curdate(),-1,'LINKIS');

INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('kafka', 'kafka', 'kafka', '消息队列', '', 2, 'Kafka', 'Kafka', 'Message Queue');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('hive', 'hive数据库', 'hive', '大数据存储', '', 3, 'Hive Database', 'Hive', 'Big Data storage');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('elasticsearch', 'elasticsearch数据源', 'es无结构化存储', '分布式全文索引', '', 3, 'Elasticsearch Datasource', 'Es No Structured Storage', 'Distributed Full-Text Indexing');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('mongodb', 'mongodb', 'NoSQL文档存储', 'NoSQL', null, 3, 'mongodb', 'NoSQL Document Storage', 'NOSQL');

-- jdbc
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('mysql', 'mysql数据库', 'mysql数据库', '关系型数据库', '', 3, 'Mysql Database', 'Mysql Database', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('oracle', 'oracle数据库', 'oracle', '关系型数据库', '', 3, 'Oracle Database', 'Oracle Relational Database', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('dm', '达梦数据库', 'dm', '关系型数据库', '', 3, 'Dameng Database', 'Dm', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('kingbase', '人大金仓数据库', 'kingbase', '关系型数据库', '', 3, 'Renmin Jincang Database', 'Kingbase', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('postgresql', 'postgresql数据库', 'postgresql', '关系型数据库', '', 3, 'Postgresql Database', 'Postgresql', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('sqlserver', 'sqlserver数据库', 'sqlserver', '关系型数据库', '', 3, 'Sqlserver Database', 'Sqlserver', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('db2', 'db2数据库', 'db2', '关系型数据库', '', 3, 'Db2 Database', 'Db2', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('greenplum', 'greenplum数据库', 'greenplum', '关系型数据库', '', 3, 'Greenplum Database', 'Greenplum', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('doris', 'doris数据库', 'doris', 'olap', '', 4, 'Doris Database', 'Doris', 'Olap');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('clickhouse', 'clickhouse数据库', 'clickhouse', 'olap', '', 4, 'Clickhouse Database', 'Clickhouse', 'Olap');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('tidb', 'tidb数据库', 'tidb', '关系型数据库', '', 3, 'TiDB Database', 'TiDB', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('starrocks', 'starrocks数据库', 'starrocks', 'olap', '', 4, 'StarRocks Database', 'StarRocks', 'Olap');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('gaussdb', 'gaussdb数据库', 'gaussdb', '关系型数据库', '', 3, 'GaussDB Database', 'GaussDB', 'Relational Database');
INSERT INTO `linkis_ps_dm_datasource_type` (`name`, `description`, `option`, `classifier`, `icon`, `layers`, `description_en`, `option_en`, `classifier_en`) VALUES ('oceanbase', 'oceanbase数据库', 'oceanbase', 'olap', '', 4, 'oceanbase Database', 'oceanbase', 'Olap');

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'hive';
SET @data_source=CONCAT('/data-source-manager/env-list/all/type/',@data_source_type_id);
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'envId', '集群环境(Cluster env)', 'Cluster env', NULL, 'SELECT', NULL, 1, '集群环境(Cluster env)', 'Cluster env', NULL, NULL, NULL, @data_source, now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'kafka';
SET @data_source=CONCAT('/data-source-manager/env-list/all/type/',@data_source_type_id);
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'envId', '集群环境(Cluster env)', 'Cluster env', NULL, 'SELECT', NULL, 1, '集群环境(Cluster env)', 'Cluster env', NULL, NULL, NULL, @data_source, now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'mongodb';
SET @data_source=CONCAT('/data-source-manager/env-list/all/type/',@data_source_type_id);
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'username', '用户名', 'Username', NULL, 'TEXT', NULL, 1, '用户名', 'Username', '^[0-9A-Za-z_-]+$', NULL, '', NULL, now(), now()),
	   (@data_source_type_id, 'password', '密码', 'Password', NULL, 'PASSWORD', NULL, 1, '密码', 'Password', '', NULL, '', NULL,  now(), now()),
	   (@data_source_type_id, 'database', '默认库', 'Database', NULL, 'TEXT', NULL, 1, '默认库', 'Database', '^[0-9A-Za-z_-]+$', NULL, '', NULL,  now(), now()),
	   (@data_source_type_id, 'host', 'Host', 'Host', NULL, 'TEXT', NULL, 1, 'mongodb Host', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
	   (@data_source_type_id, 'port', '端口', 'Port', NULL, 'TEXT', NULL, 1, '端口', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
	   (@data_source_type_id, 'params', '连接参数', 'Params', NULL, 'TEXT', NULL, 0, '输入JSON格式: {"param":"value"}', 'Input JSON Format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'elasticsearch';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'username', '用户名(Username)' , 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, '', NULL, now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, '', NULL, now(), now()),
       (@data_source_type_id, 'elasticUrls', 'ES连接URL(Elastic Url)', 'Elastic Url', NULL, 'TEXT', NULL, 1, 'ES连接URL(Elastic Url)', 'Elastic Url', '', NULL, '', NULL, now(), now());

-- https://dev.mysql.com/doc/connector-j/8.0/en/connector-j-reference-jdbc-url-format.html
select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'mysql';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 0, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)','Port', NULL, 'TEXT', NULL, 0, '端口号(Port)','Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'com.mysql.jdbc.Driver', 'TEXT', NULL, 0, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 0, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 0, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'databaseName', '数据库名(Database name)', 'Database name', NULL, 'TEXT', NULL, 0, '数据库名(Database name)', 'Database name', NULL, NULL, NULL, NULL,  now(), now());

-- https://docs.oracle.com/en/database/oracle/oracle-database/21/jajdb/oracle/jdbc/OracleDriver.html
select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'oracle';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'oracle.jdbc.driver.OracleDriver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'sid', 'SID', 'SID', NULL, 'TEXT', NULL, 0, 'SID', 'SID', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'serviceName', 'service_name', 'service_name', NULL, 'TEXT', NULL, 0, 'service_name', 'service_name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'server', 'server', 'server', NULL, 'TEXT', NULL, 0, 'server', 'server', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 0, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'dm';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'dm.jdbc.driver.DmDriver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'kingbase';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'com.kingbase8.Driver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'instance', NULL, NULL, NULL, NULL,  now(), now());

-- https://jdbc.postgresql.org/documentation/use/
select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'postgresql';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'org.postgresql.Driver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

-- https://learn.microsoft.com/zh-cn/sql/connect/jdbc/building-the-connection-url?redirectedfrom=MSDN&view=sql-server-ver16
select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'sqlserver';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'com.microsoft.sqlserver.jdbc.SQLServerDriver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

-- https://www.ibm.com/docs/en/db2/11.5?topic=cdsudidsdjs-url-format-data-server-driver-jdbc-sqlj-type-4-connectivity
select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'db2';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'com.ibm.db2.jcc.DB2Driver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

-- https://greenplum.docs.pivotal.io/6-1/datadirect/datadirect_jdbc.html#topic_ylk_pbx_2bb
select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'greenplum';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'com.pivotal.jdbc.GreenplumDriver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'doris';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'com.mysql.jdbc.Driver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

-- https://github.com/ClickHouse/clickhouse-jdbc/tree/master/clickhouse-jdbc
select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'clickhouse';
INSERT INTO `linkis_ps_dm_datasource_type_key`
    (`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'ru.yandex.clickhouse.ClickHouseDriver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());


select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'hive';
INSERT INTO `linkis_ps_dm_datasource_env` (`env_name`, `env_desc`, `datasource_type_id`, `parameter`, `create_time`, `create_user`, `modify_time`, `modify_user`) VALUES ('测试环境SIT', '测试环境SIT', @data_source_type_id, '{"uris":"thrift://localhost:9083", "hadoopConf":{"hive.metastore.execute.setugi":"true"}}',  now(), NULL,  now(), NULL);
INSERT INTO `linkis_ps_dm_datasource_env` (`env_name`, `env_desc`, `datasource_type_id`, `parameter`, `create_time`, `create_user`, `modify_time`, `modify_user`) VALUES ('测试环境UAT', '测试环境UAT', @data_source_type_id, '{"uris":"thrift://localhost:9083", "hadoopConf":{"hive.metastore.execute.setugi":"true"}}',  now(), NULL,  now(), NULL);

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'kafka';
INSERT INTO `linkis_ps_dm_datasource_env` (`env_name`, `env_desc`, `datasource_type_id`, `parameter`, `create_time`, `create_user`, `modify_time`, `modify_user`) VALUES ('kafka测试环境SIT', '开源测试环境SIT', @data_source_type_id, '{"uris":"thrift://localhost:9092"}',  now(), NULL,  now(), NULL);

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'tidb';
INSERT INTO `linkis_ps_dm_datasource_type_key`
(`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'com.mysql.jdbc.Driver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 0, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'starrocks';
INSERT INTO `linkis_ps_dm_datasource_type_key`
(`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'com.mysql.jdbc.Driver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 0, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'gaussdb';
INSERT INTO `linkis_ps_dm_datasource_type_key`
(`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'org.postgresql.Driver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'oceanbase';
INSERT INTO `linkis_ps_dm_datasource_type_key`
(`data_source_type_id`, `key`, `name`, `name_en`, `default_value`, `value_type`, `scope`, `require`, `description`, `description_en`, `value_regex`, `ref_id`, `ref_value`, `data_source`, `update_time`, `create_time`)
VALUES (@data_source_type_id, 'address', '地址', 'Address', NULL, 'TEXT', NULL, 0, '地址(host1:port1,host2:port2...)', 'Address(host1:port1,host2:port2...)', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'host', '主机名(Host)', 'Host', NULL, 'TEXT', NULL, 1, '主机名(Host)', 'Host', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'port', '端口号(Port)', 'Port', NULL, 'TEXT', NULL, 1, '端口号(Port)', 'Port', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'driverClassName', '驱动类名(Driver class name)', 'Driver class name', 'com.mysql.jdbc.Driver', 'TEXT', NULL, 1, '驱动类名(Driver class name)', 'Driver class name', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'params', '连接参数(Connection params)', 'Connection params', NULL, 'TEXT', NULL, 0, '输入JSON格式(Input JSON format): {"param":"value"}', 'Input JSON format: {"param":"value"}', NULL, NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'username', '用户名(Username)', 'Username', NULL, 'TEXT', NULL, 1, '用户名(Username)', 'Username', '^[0-9A-Za-z_-]+$', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'password', '密码(Password)', 'Password', NULL, 'PASSWORD', NULL, 1, '密码(Password)', 'Password', '', NULL, NULL, NULL,  now(), now()),
       (@data_source_type_id, 'instance', '实例名(instance)', 'Instance', NULL, 'TEXT', NULL, 1, '实例名(instance)', 'Instance', NULL, NULL, NULL, NULL,  now(), now());

select @data_source_type_id := id from `linkis_ps_dm_datasource_type` where `name` = 'doris';
UPDATE linkis_ps_dm_datasource_type_key SET `require` = 0 WHERE `key` ="password" and `data_source_type_id` = @data_source_type_id;
