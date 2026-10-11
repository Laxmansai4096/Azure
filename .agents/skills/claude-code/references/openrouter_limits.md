# OpenRouter Limits & Budget Management Reference

OpenRouter enforces three distinct categories of limits: **Credit Limits (402)**, **Budget Limits (403)**, and **Rate Limits (429)**.

---

## 1. Limits Summary

| Limit Type | Governs | HTTP Error | Key Response Fields & Headers |
| :--- | :--- | :--- | :--- |
| **Credit limits** | Account balance, per-key credit caps, in-flight spending hold | **402** | `GET /api/v1/key` → `limit_remaining`<br>`error.metadata.limit_source` |
| **Budget limits** | Spend caps (guardrail budgets, workspace budgets, key limits) | **403** | `GET /api/v1/key` → `budgets`, `effective_budget`<br>`error.metadata` (`scope`, `resets_at`) |
| **Rate limits** | Free-model daily/min limits, Cloudflare DDoS, provider throughput | **429** | `X-RateLimit-*` headers, `Retry-After`<br>`error.metadata.provider_code` |

---

## 2. Checking Limits and Budgets via API

Endpoint:
```http
GET https://openrouter.ai/api/v1/key
Authorization: Bearer <OPENROUTER_API_KEY>
```

### Response Schema & Key Fields

```typescript
type Budget = {
  scope: 'workspace_default_member' | 'workspace_default_key' | 'member' | 'api_key' | 'workspace' | 'key_limit';
  guardrail_id: string | null;
  budget_id: string | null;
  limit_usd: number;
  spend_usd: number;
  remaining_usd: number;       // <= 0 blocks requests
  reset_interval: 'daily' | 'weekly' | 'monthly' | null;
  resets_at: string | null;    // ISO 8601 UTC timestamp
  include_byok: boolean;
};

type Key = {
  data: {
    label: string;
    limit: number | null;            // Credit limit on key
    limit_remaining: number | null;  // Remaining credits for key
    budgets: Budget[];               // Evaluated in order of enforcement
    effective_budget: Budget | null; // The strictest active budget that blocks first
    usage: number;                   // All-time credits
    usage_daily: number;
    usage_weekly: number;
    usage_monthly: number;
    is_free_tier: boolean;
    free_model_daily_requests: {
      used: number;
      limit: number;
      remaining: number;
    };
  };
};
```

---

## 3. Credit Limits & In-Flight Spending Holds (402)

### In-Flight Spending Budget
When Claude Code or an agent submits requests, OpenRouter holds an estimated token cost up front against your credit balance (`input tokens + estimated max_tokens`).
- **Hold Duration**: Held while running, replaced by actual cost during a short settlement window, then released.
- **Budget Size**: A proportion of your current credit balance up to a ceiling.

### 402 Error Metadata & Solutions:
1. `"reason": "in_flight_budget_exhausted"` (`limit_source: "openrouter_in_flight_budget"`):
   - **Cause**: Active and settling requests currently occupy your hold budget.
   - **Remedy**: Wait for the duration indicated in the `Retry-After` header and retry. Adding credits raises the ceiling.
2. `"reason": "weight_exceeds_budget"` (`limit_source: "openrouter_credits"`):
   - **Cause**: A single request's prompt/max_tokens estimate exceeds your total in-flight allowance.
   - **Remedy**: Reduce prompt size, reduce `max_tokens`, or add credits to the account.
3. `"limit_source": "openrouter_key_limit"`:
   - **Cause**: The individual key's credit limit is spent.
   - **Remedy**: Increase the key's limit in the OpenRouter dashboard or wait for `limit_reset`.

---

## 4. Budget Limits (403)

Budget caps are checked in this hierarchical order:
1. **Guardrail budgets** (workspace default member spend, key spend, assigned guardrail).
2. **Workspace budgets** (workspace-level caps).
3. **The key's own limit**.

### 403 Response Example:
```json
{
  "error": {
    "code": 403,
    "message": "Org member budget limit exceeded (weekly limit)...",
    "metadata": {
      "limit_source": "openrouter_guardrail_budget",
      "scope": "member",
      "limit_usd": 50,
      "spend_usd": 52,
      "resets_at": "2026-10-12T00:00:00.000Z"
    }
  }
}
```
> [!NOTE]
> Unlike 402 errors, 403 errors have no `Retry-After` header because budget windows reset on UTC boundaries (Daily at 00:00 UTC, Weekly on Mondays 00:00 UTC, Monthly on the 1st 00:00 UTC). Do not retry automatically before `resets_at`.

---

## 5. Rate Limits & Free Tiers (429)

### Free-Tier Request Caps
For model variants ending in `:free`:
- **< 10 credits purchased all-time**: 20 requests/min, 50 requests/day.
- **≥ 10 credits purchased all-time**: 20 requests/min, 1,000 requests/day.

### Upstream Provider Rate Limits
- When an upstream provider rate limits, OpenRouter automatically uses fallback provider routing for that model.
- If all providers fail, a 429 is returned with `error.metadata.provider_code`.

### Mid-Stream SSE Rate Limits
If rate-limited after the response HTTP 200 header was already sent, OpenRouter emits an SSE chunk with:
```json
data: {
  "choices": [{"delta": {"content": ""}, "finish_reason": "error"}],
  "error": {"code": 429, "message": "Rate limit exceeded"}
}
```
Coding agents and streaming clients must check `finish_reason: "error"` on SSE chunks to catch mid-stream throttling.
