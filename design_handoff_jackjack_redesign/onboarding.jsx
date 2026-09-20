// Jack Jack — idealized onboarding flow.
// Replaces the old app's stale marketing screenshots (onboarding0/1/2.png) with
// fresh, in-brand previews of the CURRENT Jack Jack screens + warmer, product-
// specific copy. Reuses Phone / StatusBar / AppIcon from frame.jsx.
const Aio = (name, extra) => <window.AppIcon path={window.APP_P[name]} {...extra} />;

// Organic "Jack Jack" device blob, reused across heroes.
const JackJackDevice = ({ size = 88 }) => (
  <span style={{ width: size, height: size, borderRadius: '46% 54% 52% 48% / 56% 50% 50% 44%', background: 'linear-gradient(150deg,#A6C7BA,#6E9E8D)', flexShrink: 0, boxShadow: '0 10px 22px -10px rgba(74,85,104,.4)', display: 'inline-block' }} />
);

// ---------- HERO 0 · brand moment: the Jack Jack, listening ----------
function HeroWelcome() {
  return (
    <div style={{ position: 'relative', width: 200, height: 200, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      {[0, 1, 2].map((i) => (
        <span key={i} style={{ position: 'absolute', width: 96, height: 96, borderRadius: '50%', border: '2px solid var(--sage-20)', animation: `jjpulse 2.6s ease-out ${i * 0.85}s infinite` }} />
      ))}
      <span style={{ position: 'absolute', width: 150, height: 150, borderRadius: '50%', background: 'var(--sage-10)' }} />
      <JackJackDevice size={92} />
    </div>
  );
}

// ---------- HERO 1 · fresh preview of the current Pair screen ----------
function HeroConnect() {
  return (
    <MiniCard>
      <div style={{ width: 60, height: 60, borderRadius: '50%', background: 'var(--sage-10)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-sage)', position: 'relative' }}>
        {Aio('bluetooth', { size: 26 })}
        <span style={{ position: 'absolute', inset: -6, borderRadius: '50%', border: '2px solid var(--sage-20)', animation: 'jjpulse 1.8s ease-out infinite' }} />
      </div>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 15, color: 'var(--color-slate)' }}>Jack Jack found</div>
      <div style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 10, background: 'var(--color-bg)', border: '1px solid var(--border-card)', borderRadius: 'var(--radius-md)', padding: '9px 11px' }}>
        <JackJackDevice size={26} />
        <div style={{ flex: 1, textAlign: 'left' }}>
          <div style={{ fontWeight: 700, fontSize: 11.5, color: 'var(--color-slate)' }}>The Jack Jack</div>
          <div style={{ fontSize: 9.5, color: 'var(--slate-60)' }}>Signal strong · 82%</div>
        </div>
        <span style={{ color: 'var(--color-sage)' }}>{Aio('check', { size: 16 })}</span>
      </div>
    </MiniCard>
  );
}

// ---------- HERO 2 · fresh preview of the current Monitor screen ----------
function HeroMonitor() {
  const bars = [10, 16, 24, 34, 22, 14, 20, 30, 40, 26, 16, 10, 18, 28, 20, 12];
  return (
    <MiniCard>
      <div style={{ width: 70, height: 70, borderRadius: '50%', background: 'var(--sage-10)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-sage)' }}>
        {Aio('mic', { size: 30 })}
      </div>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 17, color: 'var(--color-slate)' }}>Quiet</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 3, height: 42 }}>
        {bars.map((h, i) => (
          <span key={i} style={{ width: 4, height: h, borderRadius: 2, background: i > 7 && i < 11 ? 'var(--color-sage)' : 'var(--sage-20)' }} />
        ))}
      </div>
      <div style={{ width: '100%', height: 5, borderRadius: 3, background: 'var(--sage-20)', position: 'relative' }}>
        <span style={{ position: 'absolute', left: '62%', top: '50%', width: 14, height: 14, borderRadius: '50%', background: 'var(--color-sage)', transform: 'translate(-50%,-50%)', boxShadow: 'var(--shadow-sm)' }} />
      </div>
    </MiniCard>
  );
}

const MiniCard = ({ children }) => (
  <div style={{ width: 176, background: 'var(--color-white)', border: '1px solid var(--border-card)', borderRadius: 'var(--radius-xl)', boxShadow: '0 18px 40px -20px rgba(74,85,104,.45)', padding: '20px 16px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
    {children}
  </div>
);

const PAGES = [
  { hero: HeroWelcome, title: 'Meet Jack Jack', body: 'Your Jack Jack listens to the room so you don\u2019t have to \u2014 real-time sound levels, live audio, and a gentle nudge only when it matters.' },
  { hero: HeroConnect, title: 'Pairs in seconds', body: 'Hold your phone close and connect the Jack Jack over Bluetooth. No accounts, no cables \u2014 just tap and you\u2019re listening.' },
  { hero: HeroMonitor, title: 'Listen in, anytime', body: 'Watch live sound, set a threshold that fits your home, and stream audio straight from the Jack Jack whenever you want to check in.' },
];

function OnboardingScreen({ onDone }) {
  const [page, setPage] = React.useState(0);
  const last = page === PAGES.length - 1;
  const P = PAGES[page];
  const Hero = P.hero;
  const next = () => (last ? onDone && onDone() : setPage((p) => p + 1));
  return (
    <>
      <window.StatusBar />
      {/* Hero stage */}
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '8px 24px 0', background: 'radial-gradient(120% 80% at 50% 18%, var(--sage-10), transparent 70%)' }}>
        <div key={page} style={{ animation: 'jjfade 320ms ease' }}>
          <Hero />
        </div>
      </div>

      {/* Curved bottom sheet */}
      <div style={{ background: 'var(--color-white)', borderTopLeftRadius: 34, borderTopRightRadius: 34, boxShadow: '0 -10px 30px -16px rgba(74,85,104,.22)', padding: '26px 26px 30px', display: 'flex', flexDirection: 'column' }}>
        <h1 key={'t' + page} style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 23, color: 'var(--color-slate)', margin: '0 0 8px', animation: 'jjfade 320ms ease' }}>{P.title}</h1>
        <p key={'b' + page} style={{ fontSize: 13.5, lineHeight: 1.55, color: 'var(--slate-70)', margin: '0 0 20px', minHeight: 64, animation: 'jjfade 320ms ease' }}>{P.body}</p>

        {/* Dots */}
        <div style={{ display: 'flex', gap: 7, justifyContent: 'center', marginBottom: 20 }}>
          {PAGES.map((_, i) => (
            <button key={i} onClick={() => setPage(i)} aria-label={`Page ${i + 1}`}
              style={{ width: i === page ? 22 : 8, height: 8, borderRadius: 9999, border: 'none', padding: 0, cursor: 'pointer', background: i === page ? 'var(--color-sage)' : 'var(--slate-20)', transition: 'width 220ms ease, background 220ms ease' }} />
          ))}
        </div>

        {/* Actions */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {!last && (
            <button onClick={onDone} style={{ flex: '0 0 auto', padding: '13px 22px', borderRadius: 'var(--radius-full)', border: '1px solid var(--slate-10)', background: 'var(--color-white)', color: 'var(--slate-70)', fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 14, cursor: 'pointer' }}>Skip</button>
          )}
          <button onClick={next} style={{ flex: 1, padding: '13px', borderRadius: 'var(--radius-full)', border: 'none', background: 'var(--color-sage)', color: '#fff', fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 14, cursor: 'pointer', boxShadow: '0 8px 18px -8px rgba(142,184,168,.9)' }}>
            {last ? 'Get Started' : 'Continue'}
          </button>
        </div>
      </div>
    </>
  );
}

// ---------- BEFORE · faithful recreation of the shipped onboarding ----------
// Generic "Sound Sensing App" copy + a photographic screenshot of the OLD app.
function LegacyOnboardingScreen() {
  return (
    <>
      <window.StatusBar />
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px 26px 0' }}>
        {/* stale-screenshot placeholder — this is onboarding0.png in the real app */}
        <div style={{ width: 200, height: 232, borderRadius: 18, border: '1px solid var(--border-card)', background: 'repeating-linear-gradient(135deg, var(--slate-05) 0 10px, transparent 10px 20px), var(--color-white)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 8, textAlign: 'center', padding: 16 }}>
          <div style={{ fontFamily: 'ui-monospace, Menlo, monospace', fontSize: 11, fontWeight: 700, color: 'var(--slate-60)' }}>onboarding0.png</div>
          <div style={{ fontFamily: 'ui-monospace, Menlo, monospace', fontSize: 10, color: 'var(--slate-60)', lineHeight: 1.5 }}>screenshot of the<br />OLD app UI</div>
        </div>
      </div>
      <div style={{ background: 'var(--color-white)', borderTopLeftRadius: 34, borderTopRightRadius: 34, boxShadow: '0 -10px 30px -16px rgba(74,85,104,.22)', padding: '26px 26px 30px' }}>
        <h1 style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 22, color: 'var(--color-slate)', margin: '0 0 8px' }}>Welcome to Sound Sensing App</h1>
        <p style={{ fontSize: 13, lineHeight: 1.5, color: 'var(--slate-60)', margin: '0 0 18px' }}>Quickly connect to your sound sensing device via Bluetooth and gain instant access to real-time sound levels, live audio monitoring, and alerts.</p>
        <div style={{ display: 'flex', gap: 7, justifyContent: 'center', marginBottom: 18 }}>
          {[0, 1, 2].map((i) => (
            <span key={i} style={{ width: 14, height: 14, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <span style={{ width: 8, height: 8, borderRadius: '50%', background: i === 0 ? 'var(--color-sage)' : 'var(--pill, #D0D5DD)' }} />
            </span>
          ))}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <button style={{ flex: '0 0 auto', padding: '13px 22px', borderRadius: 'var(--radius-full)', border: '1px solid var(--slate-10)', background: 'var(--color-white)', color: 'var(--slate-70)', fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 14 }}>Skip</button>
          <button style={{ flex: 1, padding: '13px', borderRadius: 'var(--radius-full)', border: 'none', background: 'var(--color-sage)', color: '#fff', fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 14 }}>Continue</button>
        </div>
      </div>
    </>
  );
}

window.OnboardingScreen = OnboardingScreen;
window.LegacyOnboardingScreen = LegacyOnboardingScreen;
