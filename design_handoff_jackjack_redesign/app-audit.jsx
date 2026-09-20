// Jack Jack — App screens compliance audit (proposed, DS-compliant rebuilds).
// Faithful to the shipped screens' structure & functionality; only the styling
// is brought into line with the design system:
//   • warm SLATE text ramp (was cool Untitled-UI grays)
//   • Fredoka for screen titles (was Nunito Sans everywhere)
//   • token radii (was hardcoded radius 8)
//   • coral / yellow status accents (was hue-rotated sage)
// Reuses Phone / StatusBar from frame.jsx.

// ---- Icon set (Feather-style) ----
const IP = {
  home: 'M3 9.5L12 3l9 6.5V20a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1V9.5z',
  cog: window.APP_P.cog,
  bell: window.APP_P.bell,
  mic: window.APP_P.mic,
  bluetooth: window.APP_P.bluetooth,
  battery: window.APP_P.battery,
  check: window.APP_P.check,
  arrowLeft: window.APP_P.arrowLeft,
  chevronDown: 'M6 9l6 6 6-6',
  chevronRight: 'M9 6l6 6-6 6',
  refresh: ['M23 4v6h-6', 'M20.5 15a9 9 0 11-2.1-9.4L23 10'],
  play: 'M6 4l14 8-14 8V4z',
  stop: 'M6 6h12v12H6z',
  scan: 'M7 7l10 10-5 5V2l5 5L7 17',
  info: ['M12 22a10 10 0 100-20 10 10 0 000 20z', 'M12 16v-4', 'M12 8h.01'],
  help: ['M12 22a10 10 0 100-20 10 10 0 000 20z', 'M9.1 9a3 3 0 015.8 1c0 2-3 3-3 3', 'M12 17h.01'],
  mail: ['M4 5h16a1 1 0 011 1v12a1 1 0 01-1 1H4a1 1 0 01-1-1V6a1 1 0 011-1z', 'M3 7l9 6 9-6'],
  star: 'M12 3l2.9 5.9 6.5.9-4.7 4.6 1.1 6.5L12 17.8 6.2 21l1.1-6.5L2.6 9.8l6.5-.9L12 3z',
  volume: ['M11 5L6 9H2v6h4l5 4V5z', 'M19 8a5 5 0 010 8'],
  clock: ['M12 22a10 10 0 100-20 10 10 0 000 20z', 'M12 7v5l3 2'],
  status: 'M22 12h-4l-3 9L9 3l-3 9H2',
};
const Ic = (name, { size = 22, color = 'currentColor', sw = 2 } = {}) => {
  const d = IP[name];
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
      {Array.isArray(d) ? d.map((p, i) => <path key={i} d={p} />) : <path d={d} />}
    </svg>
  );
};

// ---- Palette context: false = current (mono-sage), true = colour-diverse ----
const PaletteCtx = React.createContext(false);
const useRich = () => React.useContext(PaletteCtx);
const ACC =      { sage: 'var(--color-sage)', coral: '#D98A7C', yellow: '#E5C13D' }; // dots / fills
const ACC_ICON = { sage: 'var(--color-sage)', coral: '#C77A6C', yellow: '#B99114' }; // icon strokes

const DISPLAY = { fontFamily: 'var(--font-display)' };
const Title = ({ children, size = 20 }) => (
  <span style={{ ...DISPLAY, fontWeight: 600, fontSize: size, color: 'var(--color-slate)', letterSpacing: '.01em', whiteSpace: 'nowrap' }}>{children}</span>
);
const Eyebrow = ({ children, tone = 'yellow' }) => {
  const rich = useRich();
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 10, fontWeight: 700, letterSpacing: 'var(--tracking-widest)', textTransform: 'uppercase', color: 'var(--slate-60)' }}>
      {rich && <span style={{ width: 5, height: 5, borderRadius: '50%', background: ACC[tone], flexShrink: 0 }} />}
      {children}
    </div>
  );
};
const cardBase = { background: 'var(--color-white)', border: '1px solid var(--border-card)', borderRadius: 'var(--radius-lg)', boxShadow: 'var(--shadow-sm)' };

// ---- shared bits ----
function Toggle({ on }) {
  return (
    <span style={{ width: 44, height: 26, borderRadius: 9999, background: on ? 'var(--color-sage)' : 'var(--slate-20)', position: 'relative', flexShrink: 0, display: 'inline-block' }}>
      <span style={{ position: 'absolute', top: 3, left: on ? 21 : 3, width: 20, height: 20, borderRadius: '50%', background: '#fff', boxShadow: 'var(--shadow-sm)' }} />
    </span>
  );
}
function Pill({ children, tone = 'sage' }) {
  const map = { sage: ['var(--sage-10)', 'var(--color-sage)'], coral: ['var(--coral-10)', '#C77A6C'], yellow: ['var(--yellow-20)', '#9A7B12'] };
  const [bg, fg] = map[tone];
  return <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, background: bg, color: fg, fontSize: 10, fontWeight: 700, padding: '3px 9px', borderRadius: 'var(--radius-full)', whiteSpace: 'nowrap' }}>{children}</span>;
}
function Dot({ color }) { return <span style={{ width: 7, height: 7, borderRadius: '50%', background: color, display: 'inline-block' }} />; }

// ---- Radial gauge: in rich mode the arc tracks state vs threshold ----
function gaugeColor(value, threshold, rich) {
  if (!rich) return 'var(--color-sage)';
  const r = value / threshold;
  if (r >= 1) return 'var(--color-coral)';
  if (r >= 0.82) return 'var(--color-yellow)';
  return 'var(--color-sage)';
}
function Gauge({ name, value = 42, threshold = 85, max = 120 }) {
  const rich = useRich();
  const deg = Math.max(0, Math.min(1, value / max)) * 270;
  const arc = gaugeColor(value, threshold, rich);
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
      <div style={{ width: 150, height: 150, borderRadius: '50%', background: `conic-gradient(from 225deg, ${arc} 0deg ${deg}deg, var(--sage-20) ${deg}deg 270deg, transparent 270deg 360deg)`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ width: 118, height: 118, borderRadius: '50%', background: 'var(--color-bg)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ ...DISPLAY, fontWeight: 500, fontSize: 36, color: 'var(--color-slate)', lineHeight: 1 }}>{value}</span>
          <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--slate-60)', letterSpacing: '.06em' }}>dB</span>
        </div>
      </div>
      <div style={{ fontSize: 12.5, fontWeight: 700, color: 'var(--color-slate)', whiteSpace: 'nowrap' }}>{name}</div>
      <div style={{ fontSize: 11, color: 'var(--slate-60)', whiteSpace: 'nowrap' }}>Threshold · {threshold} dB</div>
    </div>
  );
}

function Indicator({ title, value, icon }) {
  return (
    <div style={{ ...cardBase, flex: 1, padding: 14 }}>
      <div style={{ fontSize: 11.5, color: 'var(--slate-60)', marginBottom: 6 }}>{title}</div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--color-slate)', whiteSpace: 'nowrap' }}>{value}</span>
        <span style={{ color: 'var(--color-sage)' }}>{Ic(icon, { size: 18 })}</span>
      </div>
    </div>
  );
}

function ScreenScroll({ children }) {
  return <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>{children}</div>;
}

// ---- Bottom nav: notched bar + sage scanner FAB ----
function Nav({ active }) {
  const item = (id, label, icon) => {
    const on = active === id;
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, color: on ? 'var(--color-sage)' : 'var(--slate-60)', width: 64 }}>
        {Ic(icon, { size: 22 })}
        <span style={{ fontSize: 10, fontWeight: on ? 700 : 600 }}>{label}</span>
      </div>
    );
  };
  return (
    <div style={{ position: 'relative', height: 62, background: 'var(--color-white)', borderTop: '1px solid var(--border-nav)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 26px' }}>
      {item('home', 'Home', 'home')}
      <span style={{ width: 64 }} />
      {item('settings', 'Settings', 'cog')}
      <span style={{ position: 'absolute', top: -24, left: '50%', transform: 'translateX(-50%)', width: 56, height: 56, borderRadius: '50%', background: 'var(--color-sage)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', boxShadow: active === 'scan' ? '0 8px 20px -6px rgba(142,184,168,.9)' : 'var(--shadow-md)', border: '4px solid var(--color-bg)' }}>
        {Ic('scan', { size: 22 })}
      </span>
    </div>
  );
}

// ============ HOME ============
function batteryColor(pct, rich) {
  if (!rich) return 'var(--slate-60)';
  if (pct < 30) return '#C77A6C';
  if (pct < 50) return '#B99114';
  return 'var(--slate-60)';
}
function HomeScreen() {
  const rich = useRich();
  return (
    <>
      <window.StatusBar />
      <ScreenScroll>
        <div style={{ padding: '2px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Title>Jack Jack</Title>
          <button style={{ width: 40, height: 40, borderRadius: 'var(--radius-full)', border: '1px solid var(--border-nav)', background: 'var(--color-white)', color: 'var(--color-slate)', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
            {Ic('bell', { size: 20 })}
            <span style={{ position: 'absolute', top: 8, right: 9, width: 8, height: 8, borderRadius: '50%', background: 'var(--color-coral)', border: '1.5px solid #fff' }} />
          </button>
        </div>
        <div style={{ padding: '16px 20px 0', display: 'flex', flexDirection: 'column', gap: 12 }}>
          <Gauge name="The Jack Jack" value={42} threshold={85} />
          <div style={{ display: 'flex', gap: 12 }}>
            <Indicator title="Battery" value="82%" icon="battery" />
            <Indicator title="Status" value="Connected" icon="status" />
          </div>
          <Eyebrow>Devices</Eyebrow>
          {[['The Jack Jack', true, 82, 'Connected', '85', 'sage'], ['Nursery Pod', false, 24, 'Idle', '70', 'coral']].map(([nm, cur, bat, st, th, tone]) => (
            <div key={nm} style={{ ...cardBase, padding: '13px 15px', display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ width: 34, height: 34, borderRadius: 'var(--radius-device)', background: (rich && tone === 'coral') ? 'linear-gradient(150deg,#F0C3BA,#D98A7C)' : 'linear-gradient(150deg,#A6C7BA,#6E9E8D)', flexShrink: 0 }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'nowrap' }}>
                  <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--color-slate)', whiteSpace: 'nowrap' }}>{nm}</span>
                  {cur && <Pill tone="coral"><Dot color="#C77A6C" />Current</Pill>}
                </div>
                <div style={{ fontSize: 11, color: 'var(--slate-60)', marginTop: 2, display: 'flex', alignItems: 'center', gap: 6, whiteSpace: 'nowrap' }}>
                  <span style={{ color: batteryColor(bat, rich), fontWeight: batteryColor(bat, rich) === 'var(--slate-60)' ? 400 : 700 }}>{bat}%</span><Dot color="var(--slate-20)" /><span>{st}</span><Dot color="var(--slate-20)" /><span>{th} dB</span>
                </div>
              </div>
              <span style={{ color: 'var(--slate-60)' }}>{Ic('chevronDown', { size: 18 })}</span>
            </div>
          ))}
        </div>
      </ScreenScroll>
      <Nav active="home" />
    </>
  );
}

// ============ CONNECT DEVICE (Pairing) ============
function ConnectScreen() {
  return (
    <>
      <window.StatusBar />
      <ScreenScroll>
        <div style={{ padding: '2px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Title>Connect Device</Title>
          <button style={{ background: 'none', border: 'none', color: 'var(--color-sage)', fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, padding: 4 }}>Refresh</button>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '18px 20px 0' }}>
          <div style={{ position: 'relative', width: 150, height: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {[0, 1].map((i) => <span key={i} style={{ position: 'absolute', width: 78, height: 78, borderRadius: '50%', border: '2px solid var(--sage-20)', animation: `jjpulse 2.4s ease-out ${i}s infinite` }} />)}
            <span style={{ width: 118, height: 118, borderRadius: '50%', background: 'var(--sage-10)' }} />
            <span style={{ position: 'absolute', color: 'var(--color-sage)' }}>{Ic('bluetooth', { size: 40 })}</span>
          </div>
          <div style={{ ...DISPLAY, fontWeight: 600, fontSize: 17, color: 'var(--color-slate)', margin: '16px 0 20px' }}>Scan Complete</div>
        </div>
        <div style={{ padding: '0 20px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Eyebrow>Paired Devices</Eyebrow>
          <DeviceRow name="The Jack Jack" meta="Signal strong · 82%" paired tone="sage" />
          <Eyebrow>Available Devices</Eyebrow>
          <DeviceRow name="Nursery Pod" meta="Signal 61%" tone="coral" />
          <DeviceRow name="JJ-4471" meta="Signal 44%" tone="yellow" />
        </div>
      </ScreenScroll>
      <Nav active="scan" />
    </>
  );
}
function DeviceRow({ name, meta, paired, tone = 'sage' }) {
  const rich = useRich();
  const t = rich ? tone : 'sage';
  const bg = t === 'coral' ? 'var(--coral-10)' : t === 'yellow' ? 'var(--yellow-10)' : 'var(--sage-10)';
  const fg = ACC_ICON[t];
  return (
    <div style={{ ...cardBase, padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12 }}>
      <span style={{ width: 36, height: 36, borderRadius: 'var(--radius-md)', background: bg, color: fg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{Ic('bluetooth', { size: 18 })}</span>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--color-slate)', whiteSpace: 'nowrap' }}>{name}</div>
        <div style={{ fontSize: 11, color: 'var(--slate-60)', whiteSpace: 'nowrap' }}>{meta}</div>
      </div>
      {paired
        ? <Pill tone="sage"><Dot color="var(--color-sage)" />Paired</Pill>
        : <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--color-sage)', display: 'inline-flex', alignItems: 'center', whiteSpace: 'nowrap' }}>Connect {Ic('chevronRight', { size: 16 })}</span>}
    </div>
  );
}

// ============ MANUAL MONITORING (streaming) ============
function ManualScreen() {
  return (
    <>
      <window.StatusBar />
      <div style={{ padding: '2px 20px 0', display: 'flex', alignItems: 'center', gap: 12 }}>
        <button style={{ background: 'none', border: 'none', color: 'var(--color-slate)', padding: 0 }}>{Ic('arrowLeft', { size: 22 })}</button>
        <Title size={17}>Manual Monitoring</Title>
      </div>
      <ScreenScroll>
        <div style={{ padding: '18px 20px 0', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
          <Gauge name="The Jack Jack" value={88} threshold={85} />
          <Pill tone="coral"><Dot color="#C77A6C" />Streaming · 00:01:23</Pill>
          <div style={{ display: 'flex', gap: 12, width: '100%' }}>
            <Indicator title="Battery" value="82%" icon="battery" />
            <Indicator title="Status" value="Connected" icon="status" />
          </div>
          <div style={{ ...cardBase, width: '100%', padding: '12px 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ color: 'var(--color-sage)' }}>{Ic('volume', { size: 20 })}</span>
              <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--color-slate)', whiteSpace: 'nowrap' }}>Background Audio</span>
            </span>
            <Toggle on />
          </div>
        </div>
      </ScreenScroll>
      <div style={{ padding: '0 20px 20px' }}>
        <button style={{ width: '100%', padding: 14, borderRadius: 'var(--radius-full)', border: 'none', background: 'var(--color-sage)', color: '#fff', fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 14, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, boxShadow: '0 8px 18px -8px rgba(142,184,168,.9)' }}>
          {Ic('stop', { size: 16 })} Stop Streaming
        </button>
      </div>
    </>
  );
}

// ============ SETTINGS ============
function SettingsScreen() {
  const rich = useRich();
  const section = (label, rows, accent = 'sage', ebTone = 'yellow') => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <Eyebrow tone={ebTone}>{label}</Eyebrow>
      <div style={{ ...cardBase, overflow: 'hidden' }}>
        {rows.map((r, i) => (
          <div key={r[0]} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '13px 15px', borderTop: i ? '1px solid var(--border-card)' : 'none' }}>
            <span style={{ color: rich ? ACC_ICON[accent] : 'var(--slate-60)' }}>{Ic(r[1], { size: 18 })}</span>
            <span style={{ flex: 1, fontSize: 12.5, fontWeight: 600, color: 'var(--color-slate)', whiteSpace: 'nowrap' }}>{r[0]}</span>
            {r[2]}
          </div>
        ))}
      </div>
    </div>
  );
  const drop = (t) => <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, border: '1px solid var(--border-input)', borderRadius: 'var(--radius-md)', padding: '5px 10px', fontSize: 11.5, fontWeight: 700, color: 'var(--slate-70)', whiteSpace: 'nowrap' }}>{t} {Ic('chevronDown', { size: 14 })}</span>;
  const chev = <span style={{ color: 'var(--slate-60)' }}>{Ic('chevronRight', { size: 18 })}</span>;
  return (
    <>
      <window.StatusBar />
      <div style={{ padding: '2px 20px 0' }}><Title>Settings</Title></div>
      <ScreenScroll>
        <div style={{ padding: '14px 20px 0', display: 'flex', flexDirection: 'column', gap: 16 }}>
          {section('General', [['BLE Auto Connect', 'bluetooth', <Toggle on />], ['Notification Timeout', 'clock', drop('15s')]], 'sage', 'sage')}
          {section('Notification Sounds', [['Connect Sound', 'volume', drop('Default')], ['Disconnect Sound', 'volume', drop('Ping')], ['Threshold Sound', 'volume', drop('Level Up')]], 'yellow', 'yellow')}
          {section('Support', [['Help', 'help', chev], ['Contact Us', 'mail', chev], ['Rate App', 'star', chev]], 'coral', 'coral')}
          {section('About App', [['App Info', 'info', chev]], 'sage', 'sage')}
        </div>
      </ScreenScroll>
      <Nav active="settings" />
    </>
  );
}

Object.assign(window, { AuditHome: HomeScreen, AuditConnect: ConnectScreen, AuditManual: ManualScreen, AuditSettings: SettingsScreen, JJPaletteCtx: PaletteCtx });
