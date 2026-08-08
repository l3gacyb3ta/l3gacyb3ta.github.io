// resume.typ — Arcade Wise

#let ink = rgb("#0a0a0a")
#let ink-muted = rgb("#666666")
#let rule-color = rgb("#e2e2e2")

#let edition = datetime.today().display("[year]-[month]-[day]")

#set page(
  paper: "us-letter",
  margin: (x: 0.85in, top: 0.7in, bottom: 0.75in),
  footer: context [
    #set text(font: "DejaVu Sans Mono", size: 7.5pt, fill: ink-muted)
    resume.typ - last edit #edition - latest: #link("https://arcades.agency/media/Arcade.pdf")[arcades.agency]
  ],
)

#set text(font: "Liberation Sans", size: 10pt, fill: ink)
#set par(leading: 0.52em, spacing: 0.7em)
#show link: underline

// h2: uppercase, spaced, sits on a rule. Case does the work, not weight.
#let section(title) = {
  v(1.1em)
  line(length: 100%, stroke: 0.5pt + rule-color)
  v(-0.35em)
  text(size: 9pt, tracking: 0.12em, weight: "regular", upper(title))
  v(0.35em)
}

// One entry: role/org left, dates right in muted mono.
#let entry(role, org, dates, body) = {
  grid(
    columns: (1fr, auto),
    align: (left, right),
    [#role #text(fill: ink-muted)[— #org]],
    text(font: "DejaVu Sans Mono", size: 8.5pt, fill: ink-muted, dates),
  )
  v(-0.1em)
  block(inset: (left: 1em), stroke: (left: 0.5pt + rule-color), body)
  v(0.55em)
}

#set list(marker: text(fill: ink-muted)[·], indent: 0em, body-indent: 0.5em)

// ---------------------------------------------------------------- header

#text(size: 17pt, weight: "regular")[Arcade Wise] #h(0.4em) #text(size: 9pt, fill: ink-muted)[(they/them)]

#v(0.1em)
I design programs that get teenagers to ship real software, and I build the infrastructure that runs them.

#v(0.2em)
#text(font: "DejaVu Sans Mono", size: 8.5pt, fill: ink-muted)[
  Burlington, VT + Anywhere Else -
  #link("mailto:arcade.b.wise@gmail.com")[arcade.b.wise\@gmail.com] \
  #link("https://arcades.agency")[arcades.agency] -
  #link("https://github.com/l3gacyb3ta")[github.com/l3gacyb3ta] -
  #link("https://www.linkedin.com/in/arcade-wise")[linkedin.com/in/arcade-wise]
]

// ---------------------------------------------------------------- experience

#section[Experience]

#entry[Gap Year Fellow][Hack Club][Jun 2026 to present - Burlington, VT][
  Design and run *You Ship, We Ship* programs: challenges that get teenagers
  all across the globe to build and ship open-source projects for rewards, tangible and intangible. Built and ran so far:
  Tape to Tape, Entropy, and the #link("https://smol.hackclub.com")[smol] program platform.

  - *Entropy*: ship a project built on randomization, we send you a custom dice set (made by me!): 15 teen makers
    across 5 countries, 48 tracked build-hours in a short two-week run. I designed the incentive
    mechanics end to end, with wonderful art help from my coworker Nick Do. 
  - *Tape to Tape*: teens compose original tracks in Sonic Pi, I'll release on a real Bandcamp
    album. Designed the per-hour payout mechanism so participants get a stake in what they make.
  - Build the infrastructure each program runs on: Astro sites on Cloudflare Pages, GitHub
    App–based repo provisioning, Vercel and Fillout API integrations, DNS automation via
    pull request, and custom review UIs for judging submissions, and all that's for a smaller program.
]

#entry[Systems Administrator][Cornell College CS Department][Oct 2025 to May 2026 - Mount Vernon, IA][
  - I ran the department's legacy Proxmox cluster and built out its replacement.
  - Rebuilt the SOPs from a monolithic Google Doc into a MediaWiki with supporting scripts
    and tooling (automated user creation), so successors inherit a working system instead of folklore.
]

#entry[Freelance Software Engineer][Vivoh][Nov 2023 to May 2025 - remote][
  - Video streaming and peer-to-peer delivery in a C++ and Rust codebase; improved
    portability and build processes; QUIC transport work.
]

#entry[Volunteer Software Engineer][Folk Computer][ongoing][
  - Contributions to the projected-AR "tangible computing" system: PNG rendering, error
    handling, and a very cool orbital-mechanics demo I can show you.
]

// ---------------------------------------------------------------- projects

#section[Projects]

#entry[Lamplight][personal, "build out loud"][2026][
  A note-taking app + Realtalk-style reactive rules with Datalog: notes as facts,
  queries as views, explainable by default, and a replacement for the wallpaper!
  Working prototype currently; developed in public at #link("https://arcades.agency/log.html")[arcades.agency/log].
]

#entry[aethopica][arcades.agency][ongoing][
  My personal website, as an SSG in C89 of all languages: essays, a weekly lab log, RSS and atproto syndication,
  IndieWeb h-card. The site itself is plain, semantic HTML, with all the bells and whistles I can add!
  It's been something to hack on for years, and I'll keep at it.
]

// ---------------------------------------------------------------- education & skills

#section[Education]

#entry[Cornell College][BA, Computer Science & German Studies][2025 to 2029 (on leave)][
  On leave 2026–27 for the Hack Club fellowship.
]

#section[Skills & Languages]

#block(inset: (left: 1em), stroke: (left: 0.5pt + rule-color))[
  *Code* — Rust, Python, C/C++, TypeScript/JavaScript - Astro/Next/JSX, Cloudflare Pages & Workers,
  Vercel - Linux and Proxmox administration - local-first architecture (Automerge, CRDTs)

  *Human* — English (native), French and German (fluent), Spanish (basic)
]
