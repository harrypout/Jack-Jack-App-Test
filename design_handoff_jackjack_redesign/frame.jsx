// Jack Jack mobile app — the actual product UI. Terse, functional, no marketing copy.
const JJAPP = window.JackJackDesignSystem_285275;
const AppIcon = ({ path, size = 24, ...rest }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
    strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...rest}>
    {Array.isArray(path) ? path.map((d, i) => <path key={i} d={d} />) : <path d={path} />}
  </svg>
);
const P = {
  mic: 'M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z',
  bluetooth: 'M7 7l10 10-5 5V2l5 5L7 17',
  bell: 'M15 17h5l-1.4-1.4A2 2 0 0118 14.2V11a6 6 0 10-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5m6 0a3 3 0 11-6 0',
  cog: ['M12 15a3 3 0 100-6 3 3 0 000 6z', 'M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 11-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 11-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 112.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 112.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z'],
  battery: 'M3 8a2 2 0 012-2h11a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8zm18 2v4',
  check: 'M5 13l4 4L19 7',
  arrowLeft: 'M19 12H5m0 0l7 7m-7-7l7-7',
};

// ---- Phone frame ----
function Phone({ children }) {
  return (
    <div style={{ width: 320, height: 640, border: '10px solid #16181d', borderRadius: 52, background: '#16181d', boxShadow: 'var(--shadow-2xl)', padding: 0, position: 'relative' }}>
      <div style={{ position: 'absolute', top: 14, left: '50%', transform: 'translateX(-50%)', width: 110, height: 26, background: '#16181d', borderRadius: 14, zIndex: 5 }} />
      <div style={{ width: '100%', height: '100%', borderRadius: 42, overflow: 'hidden', background: 'var(--color-bg)', display: 'flex', flexDirection: 'column' }}>
        {children}
      </div>
    </div>
  );
}

const StatusBar = ({ dark }) => (
  <div style={{ height: 44, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', padding: '0 26px 6px', fontSize: 13, fontWeight: 700, color: dark ? '#fff' : 'var(--color-slate)' }}>
    <span>9:41</span>
    <span style={{ display: 'inline-flex', gap: 5, alignItems: 'center' }}>
      <span style={{ fontSize: 11 }}>5G</span>
      <span style={{ width: 22, height: 11, border: `1.5px solid currentColor`, borderRadius: 3, display: 'inline-block', position: 'relative', opacity: .9 }}>
        <span style={{ position: 'absolute', inset: 1.5, right: 6, background: 'currentColor', borderRadius: 1 }} />
      </span>
    </span>
  </div>
);

window.AppIcon = AppIcon;
window.APP_P = P;
window.Phone = Phone;
window.StatusBar = StatusBar;
