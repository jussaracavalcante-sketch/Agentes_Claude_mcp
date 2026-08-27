/** Tipos espelhados dos schemas da API (apps/api/app/schemas). */

export type ServiceType = 'conversation' | 'task' | 'copilot'
export type ServiceStatus = 'draft' | 'active' | 'inactive' | 'archived'

export interface CurrentUser {
  uid: string
  email: string
  name: string
  job_title: string | null
  tenant_uid: string
  tenant_slug: string
  tenant_name: string
  roles: string[]
  permissions: string[]
}

export interface Page<T> {
  items: T[]
  total: number
  page: number
  page_size: number
}

export interface Service {
  uid: string
  name: string
  slug: string
  type: ServiceType
  status: ServiceStatus
  description: string
  channels_json: string[]
  owner_email: string | null
  active_version: string | null
  has_draft: boolean
  created_at: string
  updated_at: string
  created_by: string | null
  updated_by: string | null
}

export interface ServiceAgentLink {
  uid: string
  agent_uid: string
  agent_name: string
  agent_role: string
  is_supervisor: boolean
  position: number
}

export interface ServiceStage {
  uid: string
  code: string
  name: string
  instruction: string
  exit_condition: string
  position: number
}

export interface ServiceDetail extends Service {
  instruction: string
  objectives_json: string[]
  handoff_enabled: boolean
  data_classification: string
  unit_uid: string | null
  config_json: Record<string, unknown>
  agents: ServiceAgentLink[]
  stages: ServiceStage[]
}

export interface Agent {
  uid: string
  name: string
  slug: string
  role: string
  description: string
  instruction: string
  temperature: number
  max_tokens: number
  autonomy: string
  owner_email: string | null
  model_code: string | null
  is_enabled: boolean
  tool_uids: string[]
  skill_uids: string[]
  updated_at: string
}

export interface Skill {
  uid: string
  name: string
  description: string
  tags_json: string[]
  is_enabled: boolean
  created_by: string | null
}

export interface Tool {
  uid: string
  name: string
  kind: string
  description: string
  requires_approval: boolean
  is_enabled: boolean
}

export interface Integration {
  uid: string
  name: string
  kind: string
  system: string
  auth_type: string
  base_url: string | null
  rate_limit_per_min: number
  status: string
  last_error: string | null
}

export interface KnowledgeBase {
  uid: string
  name: string
  description: string
  embedding_model: string
  data_classification: string
  is_enabled: boolean
  document_count: number
}

export interface LLMModelRow {
  uid: string
  code: string
  name: string
  provider: string
  provider_code: string
  input_cost_per_1k: number
  output_cost_per_1k: number
  context_window: number
  is_enabled: boolean
}

export interface Conversation {
  uid: string
  public_id: number
  service_uid: string
  service_name: string
  contact: string | null
  channel: string
  status: string
  started_at: string
  ended_at: string | null
  last_message: string
  handoff_at: string | null
  intent: string | null
  csat: number | null
  is_recurrent: boolean
  tokens_total: number
  cost_usd: number
  trace_uid: string | null
}

export interface ConversationMessage {
  uid: string
  role: string
  author: string | null
  content: string
  sent_at: string
  tokens: number
}

export interface ConversationDetail extends Conversation {
  handoff_reason: string | null
  messages: ConversationMessage[]
}

export interface TaskRun {
  uid: string
  public_id: number
  service_uid: string
  service_name: string
  trigger: string
  status: string
  started_at: string
  finished_at: string | null
  duration_ms: number
  steps_total: number
  steps_done: number
  requires_human: boolean
  error: string | null
  tokens_total: number
  cost_usd: number
  trace_uid: string | null
}

export interface Span {
  uid: string
  parent_uid: string | null
  name: string
  kind: 'chain' | 'model' | 'tool' | 'skill' | 'retrieval' | 'guardrail' | 'handoff'
  status: string
  started_at: string
  duration_ms: number
  position: number
  depth: number
  tokens_in: number
  tokens_out: number
  cost_usd: number
  model: string | null
  input_json: Record<string, unknown>
  output_json: Record<string, unknown>
  metadata_json: Record<string, unknown>
  error: string | null
}

export interface Trace {
  uid: string
  service_uid: string
  service_name: string
  origin: 'chat' | 'task'
  reference_label: string
  provider: string | null
  model: string | null
  status: string
  started_at: string
  duration_ms: number
  tokens_in: number
  tokens_out: number
  tokens_reasoning: number
  cost_usd: number
  span_count: number
}

export interface TraceDetail extends Trace {
  conversation_uid: string | null
  task_run_uid: string | null
  spans: Span[]
}

export interface SeriesPoint {
  label: string
  value: number
}

export interface NamedSeries {
  name: string
  points: SeriesPoint[]
}

export interface HomeOverview {
  greeting_date: string
  conversation_services: number
  task_services: number
  copilot_services: number
  conversations_today: number
  tasks_today: number
  open_incidents: number
}

export interface MonitoringOverview {
  period: string
  conversations: number
  live_chats: number
  tasks: number
  traces: number
  conversations_by_service: SeriesPoint[]
  recent_conversations: Conversation[]
  recent_tasks: TaskRun[]
}

export interface ServiceAnalytics {
  period: string
  total_conversations: number
  total_tasks: number
  active_services: number
  ranking_conversations: SeriesPoint[]
  ranking_tasks: SeriesPoint[]
  conversations_per_day: NamedSeries[]
  tasks_per_day: NamedSeries[]
}

export interface LLMConsumption {
  period: string
  tokens_in: number
  tokens_out: number
  cost_usd: number
  by_model: SeriesPoint[]
  by_provider: SeriesPoint[]
  by_service: SeriesPoint[]
  cost_per_day: SeriesPoint[]
}

export interface Version {
  uid: string
  service_uid: string
  service_name: string
  version: string
  status: string
  is_active: boolean
  tags_json: string[]
  changelog: string
  approved_by: string | null
  created_at: string
  created_by: string | null
}

export interface Deployment {
  uid: string
  version_uid: string
  environment: string
  status: string
  requested_by: string | null
  approved_by: string | null
  finished_at: string | null
  notes: string
  created_at: string
}

export interface SecurityOverview {
  users_total: number
  users_active: number
  roles_total: number
  api_keys_active: number
  units_total: number
  audit_events_30d: number
}

export interface UserRow {
  uid: string
  email: string
  name: string
  job_title: string | null
  is_active: boolean
  must_change_password: boolean
  last_login_at: string | null
  created_at: string
  unit: { uid: string; code: string; name: string } | null
  roles: string[]
}

export interface RoleRow {
  uid: string
  code: string
  name: string
  description: string
  is_system: boolean
  permissions: string[]
}

export interface ApiKeyRow {
  uid: string
  name: string
  prefix: string
  scopes_json: string[]
  is_active: boolean
  expires_at: string | null
  last_used_at: string | null
  created_at: string
  created_by: string | null
}

export interface AuditLogRow {
  uid: string
  created_at: string
  actor_email: string | null
  action: string
  resource_type: string
  resource_uid: string | null
  summary: string
  ip_address: string | null
}

export interface UnitRow {
  uid: string
  code: string
  name: string
  cost_center: string | null
  monthly_budget_brl: number
}

export interface FeatureFlagRow {
  uid: string
  code: string
  name: string
  description: string
  enabled: boolean
}

export interface CurationItem {
  uid: string
  service_uid: string
  service_name: string
  question: string
  answer: string
  reason: string
  decision: string
  reviewer_email: string | null
  created_at: string
}

export interface EvaluationRow {
  uid: string
  service_name: string
  name: string
  metric: string
  threshold: number
  is_gate: boolean
  case_count: number
  last_score: number | null
  last_passed: boolean | null
}

export interface PrivacyPolicyRow {
  uid: string
  name: string
  data_category: string
  legal_basis: string
  retention_days: number
  redact_pii: boolean
  allow_provider_training: boolean
  storage_region: string
}

export interface BudgetRow {
  uid: string
  scope: string
  scope_label: string
  period: string
  limit_usd: number
  alert_at_percent: number
  hard_stop: boolean
  is_enabled: boolean
  consumed_usd: number
}

export interface PortabilityJobRow {
  uid: string
  direction: string
  scope_json: string[]
  status: string
  item_count: number
  checksum: string | null
  message: string
  created_at: string
  created_by: string | null
}

// ── Execução ──────────────────────────────────────────────────────────────────
export interface ToolCallResult {
  tool: string
  arguments: Record<string, unknown>
  ok: boolean
  erro?: string | null
}

export interface RunResponse {
  status: string
  text: string
  trace_uid: string
  conversation_uid: string | null
  tokens_in: number
  tokens_out: number
  cost_usd: number
  provider: string | null
  model: string | null
  pending_action_uid: string | null
  tool_calls: ToolCallResult[]
}

export interface PendingAction {
  uid: string
  service_uid: string
  service_name: string
  tool_name: string
  arguments_json: Record<string, unknown>
  reason: string
  status: string
  conversation_uid: string | null
  task_run_uid: string | null
  trace_uid: string | null
  decided_by: string | null
  decided_at: string | null
  result_json: Record<string, unknown>
  error: string | null
  created_at: string
}

export interface RetrievedChunk {
  chunk_uid: string
  document_uid: string
  document_title: string
  base_uid: string
  ordinal: number
  content: string
  score: number
}

export interface RetrieveResponse {
  query: string
  embedder: string
  hits: number
  chunks: RetrievedChunk[]
}

export interface IndexResponse {
  base_uid: string
  base_name: string
  documents: number
  chunks: number
  embedder: string
}
