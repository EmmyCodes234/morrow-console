<script setup>
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <img
    v-if="globalConfig.logoThumbnail"
    v-bind="attrs"
    :src="globalConfig.logoThumbnail"
  />
  <svg
    v-else
    v-once
    v-bind="attrs"
    width="16"
    height="16"
    viewBox="0 0 16 16"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <rect x="0.5" y="0.5" width="15" height="15" rx="3.5" fill="#059669" />
    <path
      d="M3.75 11.75V4.75C3.75 4.5 3.95 4.25 4.25 4.25H5.6L8 7.5L10.4 4.25H11.75C12.05 4.25 12.25 4.5 12.25 4.75V11.75H10.4V6.75L8 9.9L5.6 6.75V11.75H3.75Z"
      fill="white"
    />
  </svg>
</template>
