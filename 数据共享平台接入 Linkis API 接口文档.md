# 数据共享平台接入 Linkis API 接口文档

本文档专供**数据共享平台**对接 Linkis 计算中间件以执行 Trino SQL 查询使用。接口基于 HTTP RESTful 规范，采用专属 Token 机制进行免登认证。

---

## 1. 接入基本信息

### 1.1 网关访问地址
* **集群外部访问地址（推荐）**：`http://188.107.223.29:9001`
* **K8s 集群内部访问地址**：`http://linkis-backend-clusterip.wgzcb-sjkkkcx.svc.cluster.local:9001`

### 1.2 专属鉴权凭证（M2M Token）
外部系统调用无需维护 Session 或 Cookie，只需在**所有 HTTP 请求头（Headers）**中携带以下信息：

| 请求头 Key | 说明 | 取值 |
| :--- | :--- | :--- |
| `Content-Type` | 请求体格式 | `application/json;charset=UTF-8` |
| `Token-Code` | 平台专属认证 Token | `SJGX-AUTH-TOKEN-8B2F6E3A` |
| `Token-User` | 平台专属系统账号 | `sjgx` |

---

## 2. 接口调用整体流程

```
数据共享平台                       Linkis Gateway                       Trino 集群
    │                                  │                                   │
    │── 1. 提交执行任务 (POST execute) ─▶│                                   │
    │◀─ 返回 taskID / execID ──────────│                                   │
    │                                  │── 调度 Trino 引擎并执行 SQL ───────▶│
    │── 2. 轮询状态 (GET status) ──────▶│                                   │
    │◀─ 返回 Running / Succeed ────────│◀─ 查询完成，结果写回存储 ─────────────│
    │                                  │                                   │
    │── 3. 获取结果集路径 (GET jobhistory)▶│                               │
    │◀─ 返回 resultLocation ───────────│                                   │
    │                                  │                                   │
    │── 4. 读取结果集数据 (GET openFile)─▶│                                │
    │◀─ 返回表格列与数据行 ──────────────│                                   │
```

---

## 3. 详细接口说明

### 3.1 提交 SQL 执行任务

* **请求方式**：`POST`
* **请求路径**：`/api/rest_j/v1/entrance/execute`
* **接口描述**：提交一条或多条 Trino SQL，任务将异步排队并调度至 Trino 引擎执行。

#### 请求体（Body）参数说明

| 字段路径 | 类型 | 是否必填 | 说明 |
| :--- | :--- | :--- | :--- |
| `executionContent.code` | String | 是 | 要执行的 SQL 语句（以分号结尾） |
| `executionContent.runType`| String | 是 | 固定传 `"trino"` |
| `labels.engineType` | String | 是 | 引擎类型，固定传 `"trino-371"` |
| `labels.userCreator` | String | 是 | 标识调用方，固定传 `"sjgx-SHARE"` |
| `params.configuration.startup` | Object | 否 | 引擎启动及网络参数（已配置全局可不传） |

#### 请求体示例
```json
{
  "executionContent": {
    "code": "SELECT * FROM mysql.telecom_db.customer_info LIMIT 10;",
    "runType": "trino"
  },
  "params": {
    "variable": {},
    "configuration": {
      "runtime": {},
      "startup": {
        "linkis.trino.url": "https://trino2-clusterip.wgzcb-sjkkkcx.svc.cluster.local:8080",
        "linkis.trino.ssl.insecured": "true",
        "linkis.trino.catalog": "mysql"
      }
    }
  },
  "labels": {
    "engineType": "trino-371",
    "userCreator": "sjgx-SHARE"
  }
}
```

#### 响应体示例
```json
{
  "method": "/api/entrance/execute",
  "status": 0,
  "message": "OK",
  "data": {
    "taskID": 101,
    "execID": "exec_id018036linkis-cg-entrancelinkis-backend-xxx:9104IDE_sjgx_trino_0"
  }
}
```
> **注意**：请妥善保存返回的 `execID`（用于状态与日志轮询）和 `taskID`（用于结果集定位）。

---

### 3.2 轮询任务执行状态

* **请求方式**：`GET`
* **请求路径**：`/api/rest_j/v1/entrance/{execID}/status`
* **接口描述**：根据提交接口返回的 `execID` 轮询任务状态（建议每隔 1~2 秒轮询一次）。

#### 响应体示例
```json
{
  "method": "/api/entrance/exec_id.../status",
  "status": 0,
  "message": "OK",
  "data": {
    "execID": "exec_id018036linkis-cg-entrancelinkis-backend-xxx:9104IDE_sjgx_trino_0",
    "status": "Succeed"
  }
}
```

#### 任务状态（status）取值字典
| 状态值 | 说明 |
| :--- | :--- |
| `Inited` | 任务已初始化，等待排队 |
| `Scheduled` | 任务已被调度器接收 |
| `Running` | 引擎正在执行查询中 |
| `Succeed` | **执行成功，可去拉取结果集** |
| `Failed` | **执行失败，需查看日志分析原因** |
| `Cancelled` | 任务被主动取消或杀死 |
| `Timeout` | 任务执行超时 |

---

### 3.3 查询任务日志（可选 / 排查失败原因时使用）

* **请求方式**：`GET`
* **请求路径**：`/api/rest_j/v1/entrance/{execID}/log`
* **接口描述**：获取实时或最终的执行日志，包括 SQL 语法错误、Trino 服务端异常等详细堆栈。

#### 响应体示例
```json
{
  "method": "/api/entrance/exec_id.../log",
  "status": 0,
  "message": "OK",
  "data": {
    "execID": "exec_id...",
    "log": [
      "2026-09-20 06:19:25 INFO Program is substituting variables for you...",
      "2026-09-20 06:19:39 INFO Trino query id:[20260920_xxx]...",
      "2026-09-20 06:19:40 INFO Congratulations. Your job completed with status Success."
    ],
    "fromLine": 1
  }
}
```

---

### 3.4 获取结果集存储路径

* **请求方式**：`GET`
* **请求路径**：`/api/rest_j/v1/jobhistory/{taskID}/get`
* **接口描述**：当任务状态变为 `Succeed` 后，通过 `taskID` 查询结果集落盘的具体路径。

#### 响应体示例
```json
{
  "method": "/api/jobhistory/101/get",
  "status": 0,
  "message": "OK",
  "data": {
    "task": {
      "taskID": 101,
      "status": "Succeed",
      "costTime": 2500,
      "resultLocation": "file:///tmp/linkis/resultset/result/2026-09-20/SHARE/sjgx/101"
    }
  }
}
```
> 取出其中的 `resultLocation` 字符串，用于下一步读取数据。

---

### 3.5 直接下载结果集文件（CSV / Excel 导出）

* **请求方式**：`GET`
* **请求路径**：`/api/rest_j/v1/filesystem/resultsetToExcel`
* **接口描述**：在 3.4 获取到 `resultLocation` 后，若不想通过 JSON 分页拉取，可以直接调用该接口**以标准文件流的形式下载 CSV 或 Excel (.xlsx) 表格文件**。浏览器打开会直接弹出下载保存，后端调用直接将 Response 流写入本地文件即可。

#### 请求参数（Query Parameters）

| 参数名 | 类型 | 是否必填 | 默认值 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| `path` | String | 是 | - | 必须在 `resultLocation` 路径末尾追加 `/_0.dolphin` |
| `outputFileType` | String | 否 | `csv` | 导出格式：可选 **`csv`** 或 **`xlsx`**（Excel） |
| `outputFileName` | String | 否 | `downloadResultset` | 导出的文件名（无需带扩展名，系统会自动追加） |
| `charset` | String | 否 | `utf-8` | 字符编码，默认 `utf-8` |
| `csvSeparator` | String | 否 | `,` | CSV 列分隔符，默认逗号 |

#### 调用示例（cURL 直接下载为 CSV）
```bash
curl -H "Token-Code: SJGX-AUTH-TOKEN-8B2F6E3A" \
     -H "Token-User: sjgx" \
     -o "my_result.csv" \
     "http://188.107.223.29:9001/api/rest_j/v1/filesystem/resultsetToExcel?path=file:///tmp/linkis/resultset/result/2026-09-20/SHARE/sjgx/101/_0.dolphin&outputFileType=csv&outputFileName=my_result"
```

#### 调用示例（cURL 直接下载为 Excel）
```bash
curl -H "Token-Code: SJGX-AUTH-TOKEN-8B2F6E3A" \
     -H "Token-User: sjgx" \
     -o "my_result.xlsx" \
     "http://188.107.223.29:9001/api/rest_j/v1/filesystem/resultsetToExcel?path=file:///tmp/linkis/resultset/result/2026-09-20/SHARE/sjgx/101/_0.dolphin&outputFileType=xlsx&outputFileName=my_result"
```

---

### 3.6 读取结果集具体数据（JSON 分页读取）

* **请求方式**：`GET`
* **请求路径**：`/api/rest_j/v1/filesystem/openFile`
* **接口描述**：读取指定结果文件中的列名与行记录，支持分页。

#### 请求参数（Query Parameters）

| 参数名 | 类型 | 是否必填 | 示例/默认值 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| `path` | String | 是 | `file:///tmp/.../101/_0.dolphin` | 必须在 `resultLocation` 后追加 `/_0.dolphin` |
| `page` | Integer | 否 | `1` | 当前请求页码，从 1 开始 |
| `pageSize` | Integer | 否 | `5000` | 每页行数限制（默认最多 5000 条） |

#### 响应体示例
```json
{
  "method": "/api/filesystem/openFile",
  "status": 0,
  "message": "OK",
  "data": {
    "metadata": [
      { "columnName": "user_id", "comment": "", "dataType": "bigint" },
      { "columnName": "user_name", "comment": "", "dataType": "varchar" },
      { "columnName": "phone_no", "comment": "", "dataType": "varchar" }
    ],
    "fileContent": [
      [ "10001", "张三", "13800000000" ],
      [ "10002", "李四", "13900000000" ]
    ],
    "totalLine": 2,
    "totalPage": 1,
    "page": 1
  }
}
```

---

### 3.7 终止 / 杀死任务（可选）

* **请求方式**：`GET`
* **请求路径**：`/api/rest_j/v1/entrance/{execID}/kill`
* **接口描述**：若前端用户取消查询或超时，可主动终止正在运行的 Trino 任务，释放集群资源。

#### 响应体示例
```json
{
  "method": "/api/entrance/exec_id.../kill",
  "status": 0,
  "message": "Kill job succeed."
}
```

---

## 4. 客户端对接代码示例

### Python 3 示例脚本

```python
import time
import requests

BASE_URL = "http://188.107.223.29:9001"
HEADERS = {
    "Content-Type": "application/json;charset=UTF-8",
    "Token-Code": "SJGX-AUTH-TOKEN-8B2F6E3A",
    "Token-User": "sjgx",
}

def execute_query(sql: str):
    # 1. 提交任务
    submit_url = f"{BASE_URL}/api/rest_j/v1/entrance/execute"
    payload = {
        "executionContent": {
            "code": sql,
            "runType": "trino"
        },
        "params": {
            "variable": {},
            "configuration": {
                "runtime": {},
                "startup": {
                    "linkis.trino.url": "https://trino2-clusterip.wgzcb-sjkkkcx.svc.cluster.local:8080",
                    "linkis.trino.ssl.insecured": "true",
                    "linkis.trino.catalog": "system"
                }
            }
        },
        "labels": {
            "engineType": "trino-371",
            "userCreator": "sjgx-SHARE"
        }
    }

    res = requests.post(submit_url, json=payload, headers=HEADERS).json()
    if res.get("status") != 0:
        raise Exception(f"任务提交失败: {res.get('message')}")

    task_id = res["data"]["taskID"]
    exec_id = res["data"]["execID"]
    print(f"任务已提交，TaskID={task_id}, ExecID={exec_id}")

    # 2. 轮询状态
    status_url = f"{BASE_URL}/api/rest_j/v1/entrance/{exec_id}/status"
    while True:
        status_res = requests.get(status_url, headers=HEADERS).json()
        current_status = status_res["data"]["status"]
        print(f"当前执行状态: {current_status}")

        if current_status == "Succeed":
            break
        elif current_status in ["Failed", "Cancelled", "Timeout"]:
            # 获取错误日志
            log_url = f"{BASE_URL}/api/rest_j/v1/entrance/{exec_id}/log"
            logs = requests.get(log_url, headers=HEADERS).json().get("data", {}).get("log", [])
            raise Exception(f"任务执行失败:\n" + "\n".join(logs[-10:]))
        time.sleep(2)

    # 3. 获取结果集文件路径
    job_url = f"{BASE_URL}/api/rest_j/v1/jobhistory/{task_id}/get"
    job_res = requests.get(job_url, headers=HEADERS).json()
    result_location = job_res["data"]["task"]["resultLocation"]

    # 4. 读取结果集
    result_file = f"{result_location}/_0.dolphin"
    file_url = f"{BASE_URL}/api/rest_j/v1/filesystem/openFile"
    data_res = requests.get(file_url, params={"path": result_file, "page": 1, "pageSize": 5000}, headers=HEADERS).json()

    columns = [col["columnName"] for col in data_res["data"]["metadata"]]
    rows = data_res["data"]["fileContent"]
    
    print(f"查询成功！返回列: {columns}")
    for row in rows[:5]:  # 打印前5条
        print(row)

if __name__ == "__main__":
    execute_query("show catalogs;")
```

---

### Java (OkHttp) 示例代码片段

```java
import okhttp3.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

public class LinkisClient {
    private static final String BASE_URL = "http://188.107.223.29:9001";
    private static final OkHttpClient client = new OkHttpClient();
    private static final ObjectMapper mapper = new ObjectMapper();

    public static void main(String[] args) throws Exception {
        String sql = "show catalogs;";
        String jsonPayload = "{"
            + "\"executionContent\":{\"code\":\"" + sql + "\",\"runType\":\"trino\"},"
            + "\"params\":{\"variable\":{},\"configuration\":{\"runtime\":{},\"startup\":{\"linkis.trino.url\":\"https://trino2-clusterip.wgzcb-sjkkkcx.svc.cluster.local:8080\",\"linkis.trino.ssl.insecured\":\"true\",\"linkis.trino.catalog\":\"system\"}}},"
            + "\"labels\":{\"engineType\":\"trino-371\",\"userCreator\":\"sjgx-SHARE\"}"
            + "}";

        Request request = new Request.Builder()
            .url(BASE_URL + "/api/rest_j/v1/entrance/execute")
            .header("Content-Type", "application/json;charset=UTF-8")
            .header("Token-Code", "SJGX-AUTH-TOKEN-8B2F6E3A")
            .header("Token-User", "sjgx")
            .post(RequestBody.create(jsonPayload, MediaType.parse("application/json")))
            .build();

        try (Response response = client.newCall(request).execute()) {
            JsonNode root = mapper.readTree(response.body().string());
            System.out.println("Submit Response: " + root.toString());
        }
    }
}
```

---

## 5. 常见问题排查与注意事项

1. **状态码规范**：
   * HTTP 状态码为 `200`，接口业务状态码判断应以 JSON 响应中的 `"status"` 字段为准：
     * `status: 0` 代表接口调用成功。
     * `status != 0` 代表接口失败，详细原因见 `message` 字段。
2. **Token 鉴权失败 (`status: 1, message: "Token authentication failed..."`)**：
   * 检查请求头是否包含了 `Token-Code: SJGX-AUTH-TOKEN-8B2F6E3A` 与 `Token-User: sjgx`（大小写敏感）。
3. **查询语句规范**：
   * 语句末尾建议带分号 `;`。
   * Trino 表名建议采用 `catalog.schema.table` 的全限定三段式规范（例如 `mysql.telecom_db.customer`），避免跨库查询时上下文混乱。
4. **单次查询行数与超时时间**：
   * 默认单次拉取结果上限为 5000 行，若需全量导出或超大分页，请配合 `LIMIT / OFFSET` 或多次请求分页接口。
