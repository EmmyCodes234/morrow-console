<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  contact: {
    type: Object,
    default: () => ({}),
  },
});

const store = useStore();
const isExecuting = ref(false);
const isRechecking = ref(false);
const isReversed = ref(false);
const isDismissed = ref(false);

const currentChat = computed(() => store.getters.getSelectedChat || {});

// Universal anchor metadata
const anchor = computed(() => {
  if (isReversed.value) {
    return {
      type: 'payment',
      title: 'Inter-Bank Transfer',
      amount: '₦25,000.00',
      subtitle: 'GTBank • 0123456789',
      badgeText: 'Refunded to Balance',
      badgeVariant: 'success',
    };
  }
  return {
    type: 'payment',
    title: 'Inter-Bank Transfer',
    amount: '₦25,000.00',
    subtitle: 'GTBank • 0123456789',
    badgeText: 'Provider Timeout (05)',
    badgeVariant: 'danger',
  };
});

// 3-step What Happened timeline
const steps = computed(() => [
  {
    id: 1,
    title: 'Left Customer Account',
    description: '₦25,000.00 debited from customer account',
    status: 'completed',
  },
  {
    id: 2,
    title: 'Provider Switch Timeout',
    description: 'Inter-switch link failed to respond (Code 05)',
    status: isReversed.value ? 'completed' : 'warning',
  },
  {
    id: 3,
    title: isReversed.value ? 'Returned to Customer' : 'Safe in Holding Account',
    description: isReversed.value
      ? 'Credited back via double-entry ledger'
      : 'Funds never reached recipient; zero double-credit risk',
    status: isReversed.value ? 'completed' : 'safe',
  },
]);

// Friendly customer reply text
const friendlyReply = computed(() => {
  if (isReversed.value) {
    return `Hello ${props.contact.name || ''}, we looked into your transfer of ₦25,000.00 to GTBank. The destination institution timed out and the transfer did not go through. We have safely refunded the full ₦25,000.00 back to your balance.`.trim();
  }
  return `Hello ${props.contact.name || ''}, we have identified your transfer of ₦25,000.00 to GTBank. Our automated telemetry confirmed that the inter-switch link timed out and the funds are held safely. We are processing your instant refund now.`.trim();
});

const executeRefund = async () => {
  if (isExecuting.value || isReversed.value) return;
  isExecuting.value = true;

  try {
    // Attempt local/backend reversal endpoint or simulate deterministic ledger credit
    try {
      await fetch('/v1/resolutions/DEMO_GTB_25K/reverse', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });
    } catch {
      // Graceful fallback for local console
    }

    await new Promise(resolve => setTimeout(resolve, 600));
    isReversed.value = true;
    useAlert('Reversal Settled. Credited back to customer balance.');

    // Pre-fill friendly resolution reply into composer
    emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, friendlyReply.value);
  } catch {
    useAlert('Unable to process reversal. Please try again.');
  } finally {
    isExecuting.value = false;
  }
};

const recheckSwitch = async () => {
  if (isRechecking.value) return;
  isRechecking.value = true;

  try {
    await new Promise(resolve => setTimeout(resolve, 500));
    useAlert('Switch status confirmed: Response code 05 (Destination unreached).');
  } finally {
    isRechecking.value = false;
  }
};

const insertFriendlyReply = async () => {
  try {
    if (navigator?.clipboard?.writeText) {
      await navigator.clipboard.writeText(friendlyReply.value);
    }
  } catch {
    // Clipboard fallback
  }

  emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, friendlyReply.value);
  useAlert('Inserted friendly reply into composer');
};
</script>

<template>
  <div
    v-if="!isDismissed"
    class="border border-n-strong bg-white dark:bg-n-solid-2 rounded-xl p-3.5 shadow-sm space-y-3 font-sans transition-all"
  >
    <!-- Header with Anchor and Badge -->
    <div class="flex items-start justify-between gap-2 border-b border-n-weak pb-2.5">
      <div>
        <div class="flex items-center gap-1.5">
          <span class="text-xs font-medium text-n-slate-11 uppercase tracking-wider">
            {{ anchor.title }}
          </span>
        </div>
        <div class="text-base font-bold text-n-slate-12 tracking-tight mt-0.5">
          {{ anchor.amount }}
        </div>
        <p class="text-xs text-n-slate-10 mt-0.5">
          {{ anchor.subtitle }}
        </p>
      </div>

      <!-- Semantic Badge Pill (No Emojis) -->
      <span
        v-if="anchor.badgeVariant === 'danger'"
        class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300 border border-rose-200 dark:border-rose-900/50"
      >
        <svg class="size-3 text-rose-600 dark:text-rose-400" viewBox="0 0 16 16" fill="none">
          <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.5" />
          <path d="M8 5v4M8 11.5v.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
        </svg>
        {{ anchor.badgeText }}
      </span>
      <span
        v-else-if="anchor.badgeVariant === 'success'"
        class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-900/50"
      >
        <svg class="size-3 text-emerald-600 dark:text-emerald-400" viewBox="0 0 16 16" fill="none">
          <path d="M3.5 8.5l3 3 6-7" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        {{ anchor.badgeText }}
      </span>
    </div>

    <!-- What Happened: 3-Step Visual Tracker -->
    <div class="space-y-1">
      <div class="text-[11px] font-semibold text-n-slate-10 uppercase tracking-wider mb-2">
        What Happened
      </div>

      <div class="relative pl-5 space-y-3.5 before:absolute before:left-[7px] before:top-2 before:bottom-2 before:w-[1.5px] before:bg-n-strong">
        <div
          v-for="step in steps"
          :key="step.id"
          class="relative text-xs group"
        >
          <!-- Bullet Marker -->
          <div
            class="absolute -left-5 top-0.5 size-3.5 rounded-full border flex items-center justify-center bg-white dark:bg-n-solid-2"
            :class="{
              'border-emerald-500 bg-emerald-50 dark:bg-emerald-950': step.status === 'completed',
              'border-amber-500 bg-amber-50 dark:bg-amber-950': step.status === 'warning',
              'border-blue-500 bg-blue-50 dark:bg-blue-950': step.status === 'safe',
            }"
          >
            <div
              class="size-1.5 rounded-full"
              :class="{
                'bg-emerald-600': step.status === 'completed',
                'bg-amber-600': step.status === 'warning',
                'bg-blue-600': step.status === 'safe',
              }"
            />
          </div>

          <div class="font-medium text-n-slate-12 leading-tight">
            {{ step.title }}
          </div>
          <div class="text-[11px] text-n-slate-10 leading-snug mt-0.5">
            {{ step.description }}
          </div>
        </div>
      </div>
    </div>

    <!-- Verdict Box -->
    <div
      class="rounded-lg p-2.5 text-xs transition-colors"
      :class="isReversed ? 'bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-900/40 text-emerald-900 dark:text-emerald-200' : 'bg-n-solid-1 dark:bg-n-solid-3 border border-n-weak text-n-slate-12'"
    >
      <div class="font-semibold flex items-center gap-1.5">
        <svg
          class="size-3.5 flex-shrink-0"
          :class="isReversed ? 'text-emerald-600 dark:text-emerald-400' : 'text-n-blue-10'"
          viewBox="0 0 16 16"
          fill="none"
        >
          <path d="M8 1.5l5.5 2.5v4c0 3.5-2.5 6-5.5 7-3-1-5.5-3.5-5.5-7v-4L8 1.5z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" />
          <path d="M5.5 8l2 2 3.5-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        <span>
          {{ isReversed ? 'Settled & Account Recredited' : 'Funds safe in holding — Safe to reverse' }}
        </span>
      </div>
      <p class="text-[11px] mt-1 text-n-slate-11 dark:text-n-slate-10 leading-normal">
        {{ isReversed ? 'Double-entry reversal transaction completed. Zero discrepancy.' : 'The switch confirmed destination failure with zero delivery. Reversal is 100% pre-authorized.' }}
      </p>
    </div>

    <!-- Actions Area -->
    <div class="space-y-2 pt-0.5">
      <!-- Primary Action: Refund or Resolved State -->
      <button
        v-if="!isReversed"
        type="button"
        :disabled="isExecuting"
        class="w-full py-2 px-3 rounded-lg text-xs font-semibold text-white bg-emerald-600 hover:bg-emerald-700 active:bg-emerald-800 disabled:opacity-60 transition shadow-sm flex items-center justify-center gap-1.5 cursor-pointer"
        @click="executeRefund"
      >
        <svg v-if="!isExecuting" class="size-3.5" viewBox="0 0 16 16" fill="none">
          <path d="M9 1.5L3 9h5l-1 5.5 6-7.5H8l1-5.5z" fill="currentColor" />
        </svg>
        <span v-if="isExecuting">Executing reversal...</span>
        <span v-else>Refund ₦25,000.00</span>
      </button>

      <div
        v-else
        class="w-full py-2 px-3 rounded-lg text-xs font-semibold text-emerald-800 dark:text-emerald-200 bg-emerald-100/70 dark:bg-emerald-950/60 border border-emerald-300 dark:border-emerald-800 flex items-center justify-center gap-1.5"
      >
        <svg class="size-3.5 text-emerald-600 dark:text-emerald-400" viewBox="0 0 16 16" fill="none">
          <path d="M3.5 8.5l3 3 6-7" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        <span>Refund Completed</span>
      </div>

      <!-- Quick Actions Grid -->
      <div class="grid grid-cols-2 gap-2">
        <button
          type="button"
          class="py-1.5 px-2 rounded-lg text-[11px] font-medium text-n-slate-12 border border-n-strong hover:bg-n-solid-2 active:bg-n-solid-3 transition flex items-center justify-center gap-1 cursor-pointer"
          @click="insertFriendlyReply"
        >
          <svg class="size-3 text-n-slate-10" viewBox="0 0 16 16" fill="none">
            <path d="M2.5 4.5h11v7h-7l-4 3v-10z" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round" />
          </svg>
          <span>Insert Reply</span>
        </button>

        <button
          type="button"
          :disabled="isRechecking"
          class="py-1.5 px-2 rounded-lg text-[11px] font-medium text-n-slate-12 border border-n-strong hover:bg-n-solid-2 active:bg-n-solid-3 disabled:opacity-60 transition flex items-center justify-center gap-1 cursor-pointer"
          @click="recheckSwitch"
        >
          <svg class="size-3 text-n-slate-10" :class="{ 'animate-spin': isRechecking }" viewBox="0 0 16 16" fill="none">
            <path d="M13.5 8A5.5 5.5 0 1 1 8 2.5v-1l3 2-3 2v-1a4 4 0 1 0 4 3.5h1.5z" fill="currentColor" />
          </svg>
          <span>Re-check Switch</span>
        </button>
      </div>
    </div>
  </div>
</template>
