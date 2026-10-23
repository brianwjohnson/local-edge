"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

type Shop = { id: string; name: string; neighborhood: string; city: string; is_published: boolean };
export default function DashboardPage() {
  const [shop, setShop] = useState<Shop | null>(null); const [loading, setLoading] = useState(true); const [message, setMessage] = useState("");
  useEffect(() => { void (async () => { const { data: { user } } = await supabase.auth.getUser(); if (user) { const { data } = await supabase.from("sharpeners").select("id,name,neighborhood,city,is_published").eq("owner_id", user.id).maybeSingle(); setShop(data); } setLoading(false); })(); }, []);
  async function togglePublish() { if (!shop) return; const { error } = await supabase.from("sharpeners").update({ is_published: !shop.is_published }).eq("id", shop.id); if (error) { setMessage(error.message); return; } setShop({ ...shop, is_published: !shop.is_published }); }
  return <main className="onboard-page"><nav className="nav shell"><Link className="brand" href="/"><i>✦</i>local<span>edge</span></Link><Link className="text-button" href="/">View directory →</Link></nav><section className="onboard shell"><p className="eyebrow">Shop dashboard</p><h1>{loading ? "Loading your shop…" : shop ? shop.name : "You don’t have a shop yet."}</h1>{!loading && !shop && <Link className="button primary" href="/onboard">Create your shop →</Link>}{shop && <div className="onboard-card dashboard-card"><p><strong>{shop.neighborhood}, {shop.city}</strong></p><p className="status-line">Status: <b className={shop.is_published ? "open" : "closed"}>{shop.is_published ? "Published" : "Private"}</b></p><p>{shop.is_published ? "Your shop is visible in the public directory." : "Only you can see this shop. Publish when your services and hours are ready."}</p><button className="button primary" onClick={() => void togglePublish()}>{shop.is_published ? "Make private" : "Publish shop"} →</button>{message && <p className="notice">{message}</p>}</div>}</section></main>;
}
