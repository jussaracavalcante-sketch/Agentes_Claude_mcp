/** Ícones em traço, no mesmo peso visual do console de referência. */

type Props = { className?: string }

// O tamanho vem sempre da base; `className` só acrescenta (cor, margem) — e pode
// sobrepor o tamanho porque as classes do chamador vêm depois na string.
const base = 'h-4 w-4 shrink-0'

function Svg({ className, children }: Props & { children: React.ReactNode }) {
  return (
    <svg
      className={className ? `${base} ${className}` : base}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.7}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {children}
    </svg>
  )
}

export const IconHome = (p: Props) => (
  <Svg {...p}>
    <path d="M3 10.5 12 3l9 7.5" />
    <path d="M5 9.5V21h14V9.5" />
  </Svg>
)
export const IconChat = (p: Props) => (
  <Svg {...p}>
    <path d="M21 12a8 8 0 0 1-8 8H4l2-3a8 8 0 1 1 15-5Z" />
  </Svg>
)
export const IconTask = (p: Props) => (
  <Svg {...p}>
    <rect x="3" y="4" width="18" height="16" rx="2" />
    <path d="m8 12 2.5 2.5L16 9" />
  </Svg>
)
export const IconTrace = (p: Props) => (
  <Svg {...p}>
    <path d="M4 18h3l2.5-9 3 13 2.5-8h5" />
  </Svg>
)
export const IconStudio = (p: Props) => (
  <Svg {...p}>
    <path d="m12 3 1.9 4.6L18.5 9l-4.6 1.4L12 15l-1.9-4.6L5.5 9l4.6-1.4Z" />
    <path d="M18 16.5 18.8 19 21 19.8 18.8 20.6 18 23l-.8-2.4L15 19.8l2.2-.8Z" />
  </Svg>
)
export const IconEye = (p: Props) => (
  <Svg {...p}>
    <path d="M2 12s3.6-6.5 10-6.5S22 12 22 12s-3.6 6.5-10 6.5S2 12 2 12Z" />
    <circle cx="12" cy="12" r="2.6" />
  </Svg>
)
export const IconFlow = (p: Props) => (
  <Svg {...p}>
    <rect x="3" y="3" width="7" height="6" rx="1.5" />
    <rect x="14" y="15" width="7" height="6" rx="1.5" />
    <path d="M6.5 9v5a4 4 0 0 0 4 4H14" />
  </Svg>
)
export const IconOps = (p: Props) => (
  <Svg {...p}>
    <path d="M4 7h16M4 12h16M4 17h10" />
  </Svg>
)
export const IconLifecycle = (p: Props) => (
  <Svg {...p}>
    <path d="M20 12a8 8 0 1 1-2.6-5.9" />
    <path d="M20 4v4h-4" />
  </Svg>
)
export const IconAnalytics = (p: Props) => (
  <Svg {...p}>
    <path d="M4 20V10M10 20V4M16 20v-7M22 20H2" />
  </Svg>
)
export const IconGateway = (p: Props) => (
  <Svg {...p}>
    <path d="M12 3v6M12 15v6M3 12h6M15 12h6" />
    <circle cx="12" cy="12" r="3" />
  </Svg>
)
export const IconCuration = (p: Props) => (
  <Svg {...p}>
    <path d="M4 6h16M4 12h10M4 18h7" />
    <path d="m16 17 2 2 4-4" />
  </Svg>
)
export const IconEval = (p: Props) => (
  <Svg {...p}>
    <path d="M9 4h6l1 4H8Z" />
    <path d="M8 8v9a3 3 0 0 0 3 3h2a3 3 0 0 0 3-3V8" />
  </Svg>
)
export const IconPrivacy = (p: Props) => (
  <Svg {...p}>
    <path d="M12 3 5 6v6c0 4.4 2.9 7.9 7 9 4.1-1.1 7-4.6 7-9V6Z" />
  </Svg>
)
export const IconLock = (p: Props) => (
  <Svg {...p}>
    <rect x="4" y="10" width="16" height="10" rx="2" />
    <path d="M8 10V7a4 4 0 0 1 8 0v3" />
  </Svg>
)
export const IconDev = (p: Props) => (
  <Svg {...p}>
    <path d="m8 8-4 4 4 4M16 8l4 4-4 4M14 4l-4 16" />
  </Svg>
)
export const IconUsers = (p: Props) => (
  <Svg {...p}>
    <circle cx="9" cy="8" r="3.2" />
    <path d="M3 20a6 6 0 0 1 12 0" />
    <path d="M16 5.5a3.2 3.2 0 0 1 0 6M17 14a6 6 0 0 1 4 6" />
  </Svg>
)
export const IconSearch = (p: Props) => (
  <Svg {...p}>
    <circle cx="11" cy="11" r="7" />
    <path d="m20 20-3.5-3.5" />
  </Svg>
)
export const IconPlus = (p: Props) => (
  <Svg {...p}>
    <path d="M12 5v14M5 12h14" />
  </Svg>
)
export const IconChevronRight = (p: Props) => (
  <Svg {...p}>
    <path d="m9 6 6 6-6 6" />
  </Svg>
)
export const IconChevronDown = (p: Props) => (
  <Svg {...p}>
    <path d="m6 9 6 6 6-6" />
  </Svg>
)
export const IconArrowRight = (p: Props) => (
  <Svg {...p}>
    <path d="M4 12h15M13 6l6 6-6 6" />
  </Svg>
)
export const IconArrowLeft = (p: Props) => (
  <Svg {...p}>
    <path d="M20 12H5M11 6l-6 6 6 6" />
  </Svg>
)
export const IconClose = (p: Props) => (
  <Svg {...p}>
    <path d="M6 6l12 12M18 6 6 18" />
  </Svg>
)
export const IconPlay = (p: Props) => (
  <Svg {...p}>
    <path d="M7 4.5 19 12 7 19.5Z" />
  </Svg>
)
export const IconSave = (p: Props) => (
  <Svg {...p}>
    <path d="M5 4h11l3 3v13H5Z" />
    <path d="M9 4v5h6V4M8 20v-5h8v5" />
  </Svg>
)
export const IconEdit = (p: Props) => (
  <Svg {...p}>
    <path d="M4 20h4L20 8l-4-4L4 16Z" />
  </Svg>
)
export const IconMore = (p: Props) => (
  <Svg {...p}>
    <circle cx="5" cy="12" r="1" />
    <circle cx="12" cy="12" r="1" />
    <circle cx="19" cy="12" r="1" />
  </Svg>
)
export const IconMonitor = (p: Props) => (
  <Svg {...p}>
    <rect x="3" y="4" width="18" height="12" rx="2" />
    <path d="M9 20h6M12 16v4" />
  </Svg>
)
export const IconBook = (p: Props) => (
  <Svg {...p}>
    <path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5Z" />
  </Svg>
)
export const IconTool = (p: Props) => (
  <Svg {...p}>
    <path d="M14.7 6.3a4 4 0 0 1 5.3 4.9l-9 9-3.2-3.2 9-9a4 4 0 0 1-2.1-1.7Z" />
    <path d="m5 19 1.5-4.5" />
  </Svg>
)
export const IconPlug = (p: Props) => (
  <Svg {...p}>
    <path d="M9 2v6M15 2v6" />
    <path d="M6 8h12v3a6 6 0 0 1-12 0Z" />
    <path d="M12 17v5" />
  </Svg>
)
export const IconKey = (p: Props) => (
  <Svg {...p}>
    <circle cx="8" cy="12" r="4" />
    <path d="M12 12h9M18 12v3M15.5 12v2.5" />
  </Svg>
)
export const IconShield = IconPrivacy
export const IconAlert = (p: Props) => (
  <Svg {...p}>
    <path d="M12 4 2.5 20h19Z" />
    <path d="M12 10v4M12 17.5v.5" />
  </Svg>
)
export const IconCheck = (p: Props) => (
  <Svg {...p}>
    <path d="m5 13 4.5 4.5L19 7" />
  </Svg>
)
export const IconRefresh = (p: Props) => (
  <Svg {...p}>
    <path d="M20 11a8 8 0 1 0-1.7 6" />
    <path d="M20 20v-5h-5" />
  </Svg>
)
export const IconExport = (p: Props) => (
  <Svg {...p}>
    <path d="M12 3v12M8 7l4-4 4 4" />
    <path d="M4 17v3h16v-3" />
  </Svg>
)
