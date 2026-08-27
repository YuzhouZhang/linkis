#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Apache Linkis Python API 调用示例
用于通过 Linkis Gateway 提交和执行作业（Shell、Python、JDBC、Trino 等）
"""

import json
import time
import urllib.request
import urllib.error

LINKIS_GATEWAY_URL = "http://127.0.0.1:9001"
TOKEN_CODE = "LINKIS-UNAVAILABLE-TOKEN"
TOKEN_USER = "hadoop"

HEADERS = {
    "Token-Code": TOKEN_CODE,
    "Token-User": TOKEN_USER,
    "Content-Type": "application/json",
}


def request_post(path, data):
    url = f"{LINKIS_GATEWAY_URL}{path}"
    req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


def request_get(path):
    url = f"{LINKIS_GATEWAY_URL}{path}"
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


def submit_job(engine_type, run_type, code, params=None):
    """
    提交作业到 Linkis
    :param engine_type: 执行引擎，如 'shell', 'python', 'jdbc', 'trino'
    :param run_type: 运行类型，如 'shell', 'python', 'sql', 'trino'
    :param code: 待执行的代码或脚本
    """
    if params is None:
        params = {"variable": {}, "configuration": {}}

    payload = {
        "method": "/api/rest_j/v1/entrance/execute",
        "params": params,
        "executeApplicationName": engine_type,
        "executionCode": code,
        "runType": run_type,
    }
    print(f"\n[1] 正在提交作业 [{engine_type}/{run_type}] ...")
    resp = request_post("/api/rest_j/v1/entrance/execute", payload)
    if resp.get("status") == 0:
        exec_id = resp["data"]["execID"]
        task_id = resp["data"]["taskID"]
        print(f"-> 提交成功! execID: {exec_id}, taskID: {task_id}")
        return exec_id, task_id
    else:
        print(f"-> 提交失败: {resp.get('message')}")
        return None, None


def wait_for_job_complete(exec_id, timeout=60):
    """
    轮询等待任务完成并获取状态
    """
    print(f"[2] 开始轮询任务状态: {exec_id}")
    start_time = time.time()
    while time.time() - start_time < timeout:
        status_resp = request_get(f"/api/rest_j/v1/entrance/{exec_id}/status")
        if status_resp.get("status") == 0:
            status = status_resp["data"]["status"]
            progress_resp = request_get(f"/api/rest_j/v1/entrance/{exec_id}/progress")
            progress = progress_resp.get("data", {}).get("progress", 0)
            print(f"-> 状态: {status}, 进度: {progress * 100:.1f}%")

            if status in ["Success", "Failed", "Cancelled", "Timeout"]:
                return status
        time.sleep(2)
    return "Timeout"


def get_job_log(exec_id):
    """
    获取任务日志
    """
    resp = request_get(f"/api/rest_j/v1/entrance/{exec_id}/log")
    if resp.get("status") == 0:
        logs = resp["data"].get("log", [])
        return "\n".join(logs)
    return "无法获取日志"


if __name__ == "__main__":
    print("==================================================")
    print("Apache Linkis 任务提交与执行 Demo")
    print("==================================================")

    # 1. 执行一段 Shell 脚本
    shell_code = "echo 'Hello Linkis!'; uptime; date"
    exec_id, task_id = submit_job(engine_type="shell", run_type="shell", code=shell_code)

    if exec_id:
        final_status = wait_for_job_complete(exec_id)
        print(f"\n[3] 最终任务状态: {final_status}")
        log_content = get_job_log(exec_id)
        print(f"[4] 任务日志:\n{log_content}")
