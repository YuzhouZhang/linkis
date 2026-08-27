<!--
  ~ Licensed to the Apache Software Foundation (ASF) under one or more
  ~ contributor license agreements.  See the NOTICE file distributed with
  ~ this work for additional information regarding copyright ownership.
  ~ The ASF licenses this file to You under the Apache License, Version 2.0
  ~ (the "License"); you may not use this file except in compliance with
  ~ the License.  You may obtain a copy of the License at
  ~
  ~   http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  -->

<template>
    <div class="engine-management">
        <div class="header-bar">
            <FButton type="link" @click="handleBack">
                &lt; {{ t('message.linkis.back') || 'Back' }}
            </FButton>
            <h2>{{ instance }} - {{ t('message.linkis.engineList') || 'Engine List' }}</h2>
        </div>
        <FTable :data-source="engineList" :loading="loading">
            <FTableColumn
                prop="engineType"
                :label="t('message.linkis.engineType') || 'Engine Type'"
            />
            <FTableColumn
                prop="engineStatus"
                :label="t('message.linkis.tableColumns.status') || 'Status'"
            />
            <FTableColumn
                prop="usedResource"
                :label="t('message.linkis.tableColumns.usedResource') || 'Used Resource'"
            />
            <FTableColumn
                prop="createTime"
                :label="t('message.linkis.tableColumns.createdTime') || 'Created Time'"
            />
        </FTable>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import api from '@/service/api';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const instance = ref(route.params.instance as string);
const loading = ref(false);
const engineList = ref([]);

const handleBack = () => {
    router.back();
};

const fetchEngineList = async () => {
    loading.value = true;
    try {
        const res: any = await api.fetch('/linkisManager/listEMEngines', {
            em: {
                instance: instance.value,
            },
        });
        if (res && res.engines) {
            engineList.value = res.engines;
        }
    } catch (e) {
        console.error(e);
    } finally {
        loading.value = false;
    }
};

onMounted(() => {
    if (instance.value) {
        fetchEngineList();
    }
});
</script>

<style scoped>
.engine-management {
    padding: 16px;
    background: #fff;
    border-radius: 4px;
}
.header-bar {
    display: flex;
    align-items: center;
    gap: 16px;
    margin-bottom: 16px;
}
</style>
