"use client";

import { FormEvent, useState } from "react";

type Shop = { name: string; initials: string; neighborhood: string; distance: string; rating: string; reviews: number; price: number; turnaround: string; specialties: string[]; open: boolean; color: string };

const shops: Shop[] = [
  { name: "North Loop Blades", initials: "NL", neighborhood: "North Loop", distance: "1.2 mi", rating: "5.0", reviews: 42, price: 9, turnaround: "Ready in 2 hrs", specialties: ["Hockey", "Figure"], open: true, color: "coral" },
  { name: "Jess’s Edge Studio", initials: "JE", neighborhood: "Northeast", distance: "2.4 mi", rating: "4.9", reviews: 31, price: 10, turnaround: "Tonight", specialties: ["Figure", "Goalie"], open: true, color: "yellow" },
  { name: "Lake Street Sharpening", initials: "LS", neighborhood: "Uptown", distance: "3.1 mi", rating: "5.0", reviews: 18, price: 8, turnaround: "Tomorrow", specialties: ["Hockey", "Kids"], open: false, color: "blue" },
];

export default function Home() {
  const [selected, setSelected] = useState(0);
  const [query, setQuery] = useState("");
  const [notice, setNotice] = useState("");
  const [hostModal, setHostModal] = useState(false);
  const visible = shops.filter((shop) => `${shop.name} ${shop.neighborhood}`.toLowerCase().includes(query.toLowerCase()));
  const submit = (event: FormEvent<HTMLFormElement>) => { event.preventDefault(); setNotice("You’re on the list — we’ll let you know when we launch in your neighborhood."); };

  return <main>
    <nav className="nav shell">
      <a className="brand" href="#top"><i>✦</i>edge<span>nearby</span></a>
      <div className="nav-links"><a href="#how">How it works</a><a href="#shops">For sharpeners</a></div>
      <button className="nav-cta" onClick={() => setHostModal(true)}>List your setup <b>↗</b></button>
    </nav>

    <section id="top" className="hero shell">
      <div className="hero-copy">
        <p className="eyebrow"><b /> The easy way to find a sharp edge</p>
        <h1>Great skates.<br /><em>Right around the corner.</em></h1>
        <p className="hero-sub">Connect with trusted local sharpeners, see exactly what they offer, and get back on the ice faster.</p>
        <div className="hero-actions"><button className="button primary" onClick={() => document.querySelector("#shops")?.scrollIntoView({ behavior: "smooth" })}>Find a sharpener <b>→</b></button><button className="text-button" onClick={() => setHostModal(true)}>I have a machine <b>↗</b></button></div>
        <div className="trust"><div className="faces"><b>R</b><b>J</b><b>M</b><b>S</b></div><span><strong>200+ skaters</strong> are already finding<br />their neighborhood sharpener</span></div>
      </div>
      <div className="hero-art">
        <div className="art-card open-card"><span><i /> Open today</span><b>6 places nearby</b></div>
        <div className="skate"><div className="cuff" /><div className="boot"><i /><i /><i /><i /></div><div className="sole" /><div className="blade" /></div>
        <div className="art-card score-card"><b>★ 4.9</b><span>average local rating</span></div>
      </div>
    </section>

    <section className="value-strip"><div className="shell value-grid"><p><b>10–20 min</b><span>saved on every trip</span></p><p><b>$8–12</b><span>typical local price</span></p><p><b>Your schedule</b><span>drop off when it works</span></p><p><b>Real people</b><span>who know a great edge</span></p></div></section>

    <section id="shops" className="discover shell">
      <div className="section-heading"><div><p className="eyebrow">Browse local shops</p><h2>A better edge is closer<br />than you think.</h2></div><button className="location">⌖ Minneapolis, MN <b>⌄</b></button></div>
      <div className="finder">
        <div className="map-panel"><div className="map-grid" /><div className="river" /><small className="street one">WASHINGTON AVE</small><small className="street two">HENNEPIN AVE</small><small className="street three">N 1ST ST</small>
          {shops.map((shop, index) => <button key={shop.name} className={`pin pin${index} ${selected === index ? "chosen" : ""}`} onClick={() => setSelected(index)}><span className={shop.color}>{index + 1}</span></button>)}
          <div className="map-overlay">⌖&nbsp; Search this area</div>
        </div>
        <div className="shops-panel"><label className="search">⌕<input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search neighborhood or shop" /></label><div className="filter-row"><button className="filter active">Available today</button><button className="filter">Hockey</button><button className="filter">Figure</button><button className="filter filter-icon">☷</button></div><p className="results">{visible.length} sharpeners near you</p>
          {visible.map((shop) => { const index = shops.indexOf(shop); return <button onClick={() => setSelected(index)} key={shop.name} className={`shop-row ${selected === index ? "selected" : ""}`}><span className={`avatar ${shop.color}`}>{shop.initials}</span><span className="shop-info"><span><strong>{shop.name}</strong><em className={shop.open ? "open" : "closed"}>{shop.open ? "Open" : "Next day"}</em></span><small>★ {shop.rating} <i>({shop.reviews})</i> · {shop.distance}</small><span className="tags">{shop.specialties.map((tag) => <i key={tag}>{tag}</i>)}</span></span><span className="shop-price"><b>${shop.price}</b><small>per pair</small><em>{shop.turnaround}</em></span></button>; })}
          <button className="view-all">View all sharpeners <b>→</b></button>
        </div>
      </div>
    </section>

    <section id="how" className="how"><div className="shell"><div className="section-heading"><div><p className="eyebrow">How EdgeNearby works</p><h2>Simple as a fresh cut.</h2></div><p className="section-note">No more calling around or rushing to make store hours.<br />Find the right edge, on your time.</p></div><div className="steps"><article><b>01</b><i>⌖</i><h3>Find your person</h3><p>Browse nearby sharpeners, their machine, specialties, reviews, and availability.</p></article><article><b>02</b><i>▱</i><h3>Set up a drop-off</h3><p>Choose a time that works. See clear directions and any shop-specific notes.</p></article><article><b>03</b><i>✦</i><h3>Get back out there</h3><p>Pick up your skates and hit the ice with a crisp, consistent edge.</p></article></div></div></section>

    <section className="host shell"><div className="host-copy"><p className="eyebrow">Got the gear? Share the edge.</p><h2>Turn your setup into<br /><em>a neighborhood shop.</em></h2><p>Make your machine work harder. Create your storefront, set your rates and hours, and welcome skaters from around town.</p><button className="button cream" onClick={() => setHostModal(true)}>List your setup <b>→</b></button><small>✓ You choose the schedule &nbsp;&nbsp; ✓ You set the price</small></div><div className="machine"><i /><b /><em /><span>● &nbsp; ● &nbsp; ●</span></div></section>

    <section className="cta"><div className="shell"><p className="eyebrow">Launching around the cities</p><h2>Keep your crew<br /><em>on a sharp edge.</em></h2><form onSubmit={submit}><input required type="email" placeholder="Your email address" /><button className="button primary">Get early access <b>→</b></button></form>{notice && <p className="notice">{notice}</p>}</div></section>
    <footer className="footer shell"><a className="brand" href="#top"><i>✦</i>edge<span>nearby</span></a><p>Built for skaters, by skaters.</p><div><a href="#how">How it works</a><a href="#shops">For sharpeners</a><a href="#top">Contact</a></div></footer>
    {hostModal && <div className="modal-backdrop"><div className="modal"><button className="close" onClick={() => setHostModal(false)}>×</button><p className="eyebrow">For sharpeners</p><h2>Put your shop on the map.</h2><p>Tell us where you sharpen and we’ll invite you to create your storefront first.</p><form onSubmit={(event) => { submit(event); setHostModal(false); }}><input required type="email" placeholder="Your email address" /><button className="button primary">Join the sharpener list <b>→</b></button></form></div></div>}
  </main>;
}
